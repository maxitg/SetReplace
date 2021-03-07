#include "Event.hpp"

#include <algorithm>
#include <memory>
#include <unordered_map>
#include <vector>

namespace SetReplace {
class CausalGraph::Implementation {
  // the first event is the "fake" initialization event
  std::vector<Event> events_;
  std::vector<EventID> expressionIDsToCreatorEvents_;
  std::vector<uint64_t> expressionIDsToDestroyerEventsCount_;

  // needed to return the largest generation in O(1)
  Generation largestGeneration_ = 0;

  SeparationTrackingMethod separationTrackingMethod_;

  // Allows one to determine the type of separation between expressions.
  // Addressed as destroyerChoices[eventID][expressionID] -> eventID.
  // For each event E, tells one which events need to be chosen as destroyers for each of the expressions in order to
  // make E possible. If there is no value for a given expression, it means any destroyer can be chosen.
  std::vector<std::unordered_map<ExpressionID, EventID>> destroyerChoices_;

  // If false, destroyerChoices is meaningless, and not computed.
  bool isSpacelikeEvolution_ = true;

 public:
  explicit Implementation(const int initialExpressionsCount, const SeparationTrackingMethod separationTrackingMethod)
      : separationTrackingMethod_(separationTrackingMethod) {
    addEvent(initialConditionRule, {}, initialExpressionsCount);
  }

  std::vector<ExpressionID> addEvent(const RuleID ruleID,
                                     const std::vector<ExpressionID>& inputExpressions,
                                     const int outputExpressionsCount) {
    updateDestroyerEventsCount(inputExpressions);
    const auto newExpressions = createExpressions(events_.size(), outputExpressionsCount);
    const Generation generation = newEventGeneration(inputExpressions);
    events_.push_back({ruleID, inputExpressions, newExpressions, generation});
    largestGeneration_ = std::max(largestGeneration_, generation);
    if (separationTrackingMethod_ == SeparationTrackingMethod::DestroyerChoices) addLastEventDestroyerChoices();
    return newExpressions;
  }

  const std::vector<Event>& events() const { return events_; }

  size_t eventsCount() const { return events_.size() - 1; }

  std::vector<ExpressionID> allExpressionIDs() const { return idsRange(0, expressionIDsToCreatorEvents_.size()); }

  size_t expressionsCount() const { return expressionIDsToCreatorEvents_.size(); }

  Generation expressionGeneration(const ExpressionID id) const {
    return events_[expressionIDsToCreatorEvents_[id]].generation;
  }

  Generation largestGeneration() const { return largestGeneration_; }

  SeparationType expressionsSeparation(const ExpressionID first, const ExpressionID second) const {
    if (!isSpacelikeEvolution_ || separationTrackingMethod_ == SeparationTrackingMethod::None) {
      // This approach does not work with branchlike or timelike rules.
      // For example, if a branchlike rule merges two branches and generates multiple expressions, this approach will
      // not be able to determine that the output expressions are spacelike separated.
      return SeparationType::Unknown;
    } else if (first == second) {
      return SeparationType::Identical;
    }

    const auto& firstDestroyerChoices = destroyerChoices_.at(expressionIDsToCreatorEvents_.at(first));
    const auto& secondDestroyerChoices = destroyerChoices_.at(expressionIDsToCreatorEvents_.at(second));

    if (firstDestroyerChoices.count(second) || secondDestroyerChoices.count(first)) {
      // This implies one expression is required for another one to be possible. So, they are causally related.
      return SeparationType::Timelike;
    }

    for (const auto& firstExpressionAndChosenEvent : firstDestroyerChoices) {
      const auto& expression = firstExpressionAndChosenEvent.first;
      const auto& chosenEvent = firstExpressionAndChosenEvent.second;
      if (secondDestroyerChoices.count(expression) && secondDestroyerChoices.at(expression) != chosenEvent) {
        // Both `first` and `second` expressions require a particular destroyer event to be chosen for `expression`
        // to exist. However, these destroyer events have to be different (`chosenEvent` and
        // `secondDestroyerChoices.at(expression)`). So, the expressions are on different multiway branches.
        return SeparationType::Branchlike;
      }
    }

    return SeparationType::Spacelike;
  }

  uint64_t destroyerEventsCount(const ExpressionID id) { return expressionIDsToDestroyerEventsCount_[id]; }

 private:
  std::vector<ExpressionID> createExpressions(const EventID creatorEvent, const int count) {
    const size_t beginIndex = expressionIDsToCreatorEvents_.size();
    expressionIDsToCreatorEvents_.insert(expressionIDsToCreatorEvents_.end(), count, creatorEvent);
    expressionIDsToDestroyerEventsCount_.insert(expressionIDsToDestroyerEventsCount_.end(), count, 0);
    return idsRange(beginIndex, expressionIDsToCreatorEvents_.size());
  }

  void updateDestroyerEventsCount(const std::vector<ExpressionID>& inputExpressions) {
    for (const auto& id : inputExpressions) {
      ++expressionIDsToDestroyerEventsCount_[id];
    }
  }

  static std::vector<ExpressionID> idsRange(const ExpressionID beginIndex, const ExpressionID endIndex) {
    std::vector<ExpressionID> result;
    result.reserve(endIndex - beginIndex);
    for (ExpressionID i = beginIndex; i < endIndex; ++i) {
      result.push_back(i);
    }
    return result;
  }

  Generation newEventGeneration(const std::vector<ExpressionID>& inputExpressions) const {
    Generation newEventGeneration = 0;
    for (const auto& inputExpression : inputExpressions) {
      newEventGeneration =
          std::max(newEventGeneration, events_[expressionIDsToCreatorEvents_[inputExpression]].generation + 1);
    }
    return newEventGeneration;
  }

  // append prerequisites of the most recently added event to destroyerChoices_
  void addLastEventDestroyerChoices() {
    if (!isSpacelikeEvolution_) return;  // only spacelike evolutions are supported at the moment
    const auto& lastEvent = events_.back();
    std::unordered_map<ExpressionID, EventID> newDestroyerChoices;

    // For lastEvent to exist, its direct prerequisites have to exist as well. So, merge the destroyer choices from
    // creator events of all inputs to the lastEvent.
    for (const auto& inputExpression : lastEvent.inputExpressions) {
      // the input expression itself needs to be destroyed by `lastEvent`.
      newDestroyerChoices[inputExpression] = events_.size() - 1;
      const auto& inputEvent = expressionIDsToCreatorEvents_.at(inputExpression);
      for (const auto& inputEventExpressionAndChosenEvent : destroyerChoices_.at(inputEvent)) {
        const auto& expression = inputEventExpressionAndChosenEvent.first;
        const auto& chosenEvent = inputEventExpressionAndChosenEvent.second;
        if (newDestroyerChoices.count(expression) && newDestroyerChoices.at(expression) != chosenEvent) {
          // the prerequisite events for the `lastEvent` have inconsistent requirements. The lastEvent is not spacelike.
          isSpacelikeEvolution_ = false;
          destroyerChoices_.clear();
          return;
        }
        newDestroyerChoices[expression] = chosenEvent;
      }
    }
    destroyerChoices_.emplace_back(newDestroyerChoices);
  }
};

CausalGraph::CausalGraph(const int initialExpressionsCount, const SeparationTrackingMethod separationTrackingMethod)
    : implementation_(std::make_shared<Implementation>(initialExpressionsCount, separationTrackingMethod)) {}

std::vector<ExpressionID> CausalGraph::addEvent(const RuleID ruleID,
                                                const std::vector<ExpressionID>& inputExpressions,
                                                const int outputExpressionsCount) {
  return implementation_->addEvent(ruleID, inputExpressions, outputExpressionsCount);
}

const std::vector<Event>& CausalGraph::events() const { return implementation_->events(); }

size_t CausalGraph::eventsCount() const { return implementation_->eventsCount(); }

std::vector<ExpressionID> CausalGraph::allExpressionIDs() const { return implementation_->allExpressionIDs(); }

size_t CausalGraph::expressionsCount() const { return implementation_->expressionsCount(); }

Generation CausalGraph::expressionGeneration(const ExpressionID id) const {
  return implementation_->expressionGeneration(id);
}

Generation CausalGraph::largestGeneration() const { return implementation_->largestGeneration(); }

SeparationType CausalGraph::expressionsSeparation(const ExpressionID first, const ExpressionID second) const {
  return implementation_->expressionsSeparation(first, second);
}

uint64_t CausalGraph::destroyerEventsCount(const ExpressionID id) const {
  return implementation_->destroyerEventsCount(id);
}
}  // namespace SetReplace
