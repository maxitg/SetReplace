#include "TokenEventGraph.hpp"

#include <algorithm>
#include <memory>
#include <unordered_map>
#include <vector>

namespace SetReplace {
class TokenEventGraph::Implementation {
  // the first event is the "fake" initialization event
  std::vector<Event> events_;
  std::vector<EventID> tokenIDsToCreatorEvents_;
  std::vector<uint64_t> tokenIDsToDestroyerEventsCount_;

  // needed to return the largest generation in O(1)
  Generation largestGeneration_ = 0;

  SeparationTrackingMethod separationTrackingMethod_;

  // Allows one to determine the type of separation between tokens.
  // Addressed as destroyerChoices[eventID][tokenID] -> eventID.
  // For each event E, tells one which events need to be chosen as destroyers for each of the tokens in order to make E
  // possible. If there is no value for a given token, it means any destroyer can be chosen.
  std::vector<std::unordered_map<TokenID, EventID>> destroyerChoices_;

  // If false, destroyerChoices is meaningless, and not computed.
  bool isSpacelikeEvolution_ = true;

 public:
  explicit Implementation(const int initialTokenCount, const SeparationTrackingMethod separationTrackingMethod)
      : separationTrackingMethod_(separationTrackingMethod) {
    addEvent(initialConditionRule, {}, initialTokenCount);
  }

  std::vector<TokenID> addEvent(const RuleID ruleID,
                                const std::vector<TokenID>& initialTokens,
                                const int outputTokenCount) {
    incrementDestroyerEventsCount(initialTokens);
    const auto newTokens = createTokens(events_.size(), outputTokenCount);
    const Generation generation = newEventGeneration(initialTokens);
    events_.push_back({ruleID, initialTokens, newTokens, generation});
    largestGeneration_ = std::max(largestGeneration_, generation);
    if (separationTrackingMethod_ == SeparationTrackingMethod::DestroyerChoices) addLastEventDestroyerChoices();
    return newTokens;
  }

  const std::vector<Event>& events() const { return events_; }

  size_t eventsCount() const { return events_.size() - 1; }

  std::vector<TokenID> allTokenIDs() const { return idsRange(0, tokenIDsToCreatorEvents_.size()); }

  size_t tokenCount() const { return tokenIDsToCreatorEvents_.size(); }

  Generation tokenGeneration(const TokenID id) const { return events_[tokenIDsToCreatorEvents_[id]].generation; }

  Generation largestGeneration() const { return largestGeneration_; }

  SeparationType tokenSeparation(const TokenID first, const TokenID second) const {
    if (!isSpacelikeEvolution_ || separationTrackingMethod_ == SeparationTrackingMethod::None) {
      // This approach does not work with branchlike or timelike rules.
      // For example, if a branchlike rule merges two branches and generates multiple tokens, this approach will not be
      // able to determine that the output tokens are spacelike separated.
      return SeparationType::Unknown;
    } else if (first == second) {
      return SeparationType::Identical;
    }

    const auto& firstDestroyerChoices = destroyerChoices_.at(tokenIDsToCreatorEvents_.at(first));
    const auto& secondDestroyerChoices = destroyerChoices_.at(tokenIDsToCreatorEvents_.at(second));

    if (firstDestroyerChoices.count(second) || secondDestroyerChoices.count(first)) {
      // This implies one token is required for another one to be possible. So, they are causally related.
      return SeparationType::Timelike;
    }

    for (const auto& firstTokenAndChosenEvent : firstDestroyerChoices) {
      const auto& token = firstTokenAndChosenEvent.first;
      const auto& chosenEvent = firstTokenAndChosenEvent.second;
      if (secondDestroyerChoices.count(token) && secondDestroyerChoices.at(token) != chosenEvent) {
        // Both `first` and `second` tokens require a particular destroyer event to be chosen for `token` to exist.
        // However, these destroyer events have to be different (`chosenEvent` and `secondDestroyerChoices.at(token)`).
        // So, the tokens are on different multihistory branches.
        return SeparationType::Branchlike;
      }
    }

    return SeparationType::Spacelike;
  }

  uint64_t destroyerEventsCount(const TokenID id) { return tokenIDsToDestroyerEventsCount_[id]; }

 private:
  std::vector<TokenID> createTokens(const EventID creatorEvent, const int count) {
    const size_t beginIndex = tokenIDsToCreatorEvents_.size();
    tokenIDsToCreatorEvents_.insert(tokenIDsToCreatorEvents_.end(), count, creatorEvent);
    tokenIDsToDestroyerEventsCount_.insert(tokenIDsToDestroyerEventsCount_.end(), count, 0);
    return idsRange(beginIndex, tokenIDsToCreatorEvents_.size());
  }

  void incrementDestroyerEventsCount(const std::vector<TokenID>& inputTokens) {
    for (const auto& id : inputTokens) {
      ++tokenIDsToDestroyerEventsCount_[id];
    }
  }

  static std::vector<TokenID> idsRange(const TokenID beginIndex, const TokenID endIndex) {
    std::vector<TokenID> result;
    result.reserve(endIndex - beginIndex);
    for (TokenID i = beginIndex; i < endIndex; ++i) {
      result.push_back(i);
    }
    return result;
  }

  Generation newEventGeneration(const std::vector<TokenID>& inputTokens) const {
    Generation newEventGeneration = 0;
    for (const auto& inputToken : inputTokens) {
      newEventGeneration = std::max(newEventGeneration, events_[tokenIDsToCreatorEvents_[inputToken]].generation + 1);
    }
    return newEventGeneration;
  }

  // append prerequisites of the most recently added event to destroyerChoices_
  void addLastEventDestroyerChoices() {
    if (!isSpacelikeEvolution_) return;  // only spacelike evolutions are supported at the moment
    const auto& lastEvent = events_.back();
    std::unordered_map<TokenID, EventID> newDestroyerChoices;

    // For lastEvent to exist, its direct prerequisites have to exist as well. So, merge the destroyer choices from
    // creator events of all inputs to the lastEvent.
    for (const auto& inputToken : lastEvent.inputTokens) {
      // the input token itself needs to be destroyed by `lastEvent`.
      newDestroyerChoices[inputToken] = events_.size() - 1;
      const auto& inputEvent = tokenIDsToCreatorEvents_.at(inputToken);
      for (const auto& inputEventTokenAndChosenEvent : destroyerChoices_.at(inputEvent)) {
        const auto& token = inputEventTokenAndChosenEvent.first;
        const auto& chosenEvent = inputEventTokenAndChosenEvent.second;
        if (newDestroyerChoices.count(token) && newDestroyerChoices.at(token) != chosenEvent) {
          // the prerequisite events for the `lastEvent` have inconsistent requirements. The lastEvent is not spacelike.
          isSpacelikeEvolution_ = false;
          destroyerChoices_.clear();
          return;
        }
        newDestroyerChoices[token] = chosenEvent;
      }
    }
    destroyerChoices_.emplace_back(newDestroyerChoices);
  }
};

TokenEventGraph::TokenEventGraph(const int initialTokenCount, const SeparationTrackingMethod separationTrackingMethod)
    : implementation_(std::make_shared<Implementation>(initialTokenCount, separationTrackingMethod)) {}

std::vector<TokenID> TokenEventGraph::addEvent(const RuleID ruleID,
                                               const std::vector<TokenID>& inputTokens,
                                               const int outputTokenCount) {
  return implementation_->addEvent(ruleID, inputTokens, outputTokenCount);
}

const std::vector<Event>& TokenEventGraph::events() const { return implementation_->events(); }

size_t TokenEventGraph::eventsCount() const { return implementation_->eventsCount(); }

std::vector<TokenID> TokenEventGraph::allTokenIDs() const { return implementation_->allTokenIDs(); }

size_t TokenEventGraph::tokenCount() const { return implementation_->tokenCount(); }

Generation TokenEventGraph::tokenGeneration(const TokenID id) const { return implementation_->tokenGeneration(id); }

Generation TokenEventGraph::largestGeneration() const { return implementation_->largestGeneration(); }

SeparationType TokenEventGraph::tokenSeparation(const TokenID first, const TokenID second) const {
  return implementation_->tokenSeparation(first, second);
}

uint64_t TokenEventGraph::destroyerEventsCount(const TokenID id) const {
  return implementation_->destroyerEventsCount(id);
}
}  // namespace SetReplace
