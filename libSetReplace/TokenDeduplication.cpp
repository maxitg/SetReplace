#include "TokenDeduplication.hpp"

#include <algorithm>
#include <deque>
#include <map>
#include <memory>
#include <numeric>
#include <optional>
#include <set>
#include <tuple>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

namespace SetReplace {
namespace {
constexpr TokenID noTokenID = -1;
constexpr EventID noEventID = -1;

/** @brief Union-find where the class representative is always the smallest member ID.
 */
class UnionFind {
 public:
  explicit UnionFind(const size_t size) : parents_(size) { std::iota(parents_.begin(), parents_.end(), 0); }

  int64_t root(int64_t id) const {
    while (parents_[id] != id) id = parents_[id];
    return id;
  }

  void merge(const int64_t first, const int64_t second) {
    auto firstRoot = root(first);
    auto secondRoot = root(second);
    if (firstRoot == secondRoot) return;
    if (secondRoot < firstRoot) std::swap(firstRoot, secondRoot);
    parents_[secondRoot] = firstRoot;
  }

 private:
  std::vector<int64_t> parents_;
};

/** @brief Tentative merges on top of a UnionFind that can be discarded if they turn out to be inconsistent.
 * @details Also keeps track of which base classes were merged together, which is needed for validation and to commit.
 */
class TrialUnionFind {
 public:
  explicit TrialUnionFind(const UnionFind* base) : base_(base) {}

  int64_t root(int64_t id) const {
    id = base_->root(id);
    auto nextParent = parents_.find(id);
    while (nextParent != parents_.end()) {
      id = nextParent->second;
      nextParent = parents_.find(id);
    }
    return id;
  }

  // Returns true if the classes were previously separate.
  bool merge(const int64_t first, const int64_t second) {
    auto firstRoot = root(first);
    auto secondRoot = root(second);
    if (firstRoot == secondRoot) return false;
    if (secondRoot < firstRoot) std::swap(firstRoot, secondRoot);
    parents_[secondRoot] = firstRoot;
    auto mergedGroup = takeGroup(firstRoot);
    const auto secondGroup = takeGroup(secondRoot);
    mergedGroup.insert(mergedGroup.end(), secondGroup.begin(), secondGroup.end());
    groups_[firstRoot] = std::move(mergedGroup);
    return true;
  }

  // Base class representatives merged together during the trial, grouped by the trial class they became.
  const std::unordered_map<int64_t, std::vector<int64_t>>& groups() const { return groups_; }

 private:
  std::vector<int64_t> takeGroup(const int64_t groupRoot) {
    const auto group = groups_.find(groupRoot);
    if (group == groups_.end()) return {groupRoot};
    auto result = std::move(group->second);
    groups_.erase(group);
    return result;
  }

  const UnionFind* base_;
  std::unordered_map<int64_t, int64_t> parents_;
  std::unordered_map<int64_t, std::vector<int64_t>> groups_;
};

struct PairHash {
  size_t operator()(const std::pair<int64_t, int64_t>& pair) const {
    return std::hash<int64_t>()(pair.first) ^ (std::hash<int64_t>()(pair.second) * 2654435761);
  }
};

/** @brief Computes the token deduplication classes for a fixed token-event graph.
 * @details Tokens are attempted to be merged in a canonical order (pairs of the smallest IDs first). Merging a pair of
 * tokens requires constructing a correspondence between their futures (and, where their contexts differ, pasts), which
 * is realized as tentative merges of further token, event and atom classes. If the correspondence closes without
 * contradictions, and all atom identifications it makes are between independent atoms, it is committed. This
 * corresponds to quotienting the multihistory by an isomorphism between the multihistories with the pasts of the two
 * tokens deleted, and merges entire orbits at once (so time-translation symmetries collapse into cycles).
 */
class Deduplicator {
 public:
  Deduplicator(const std::vector<AtomsVector>& tokenContents,
               const std::vector<Event>& events,
               const Generation completeGenerations,
               const Atom largestNamedAtom,
               const std::function<bool()>& shouldAbort)
      : tokenContents_(tokenContents),
        events_(events),
        completeGenerations_(completeGenerations),
        largestNamedAtom_(largestNamedAtom),
        shouldAbort_(shouldAbort) {
    indexAtoms();
    replayCausalGraph();
    buildIncidence();
    tokenClasses_ = std::make_unique<UnionFind>(tokenContents_.size());
    eventClasses_ = std::make_unique<UnionFind>(events_.size());
    atomClasses_ = std::make_unique<UnionFind>(atomValues_.size());
    atomClassMembers_.resize(atomValues_.size());
    for (size_t atomIndex = 0; atomIndex < atomValues_.size(); ++atomIndex) {
      atomClassMembers_[atomIndex] = {static_cast<int64_t>(atomIndex)};
    }
    exploredRepresentatives_.resize(tokenContents_.size());
    tokenClassMembers_.resize(tokenContents_.size());
    for (TokenID token = 0; token < static_cast<TokenID>(tokenContents_.size()); ++token) {
      exploredRepresentatives_[token] = isFutureComplete(token) ? token : noTokenID;
      tokenClassMembers_[token] = {token};
    }
  }

  TokenDeduplicationResult compute() {
    bool mergedDuringPass = true;
    while (mergedDuringPass) {
      mergedDuringPass = false;
      for (int phase = 0; phase <= 2 && !mergedDuringPass; ++phase) {
        mergedDuringPass = mergePass(phase);
      }
    }
    validateClasses();
    return buildResult();
  }

  // Number of classes in the pair whose futures are not completely known (i.e., contain no token before the event
  // horizon). Their merges are progressively less constrained.
  int candidatePhase(const TokenID first, const TokenID second) const {
    return (exploredRepresentatives_[first] == noTokenID ? 1 : 0) +
           (exploredRepresentatives_[second] == noTokenID ? 1 : 0);
  }

  // Attempts to merge class representative pairs of the given phase in a canonical order. Merges between classes with
  // completely known futures (phase 0) are done first because merges involving horizon classes are optimistic:
  // performed too early, they can irreversibly glue tokens with genuinely different futures together and block the
  // constrained merges (e.g., glue the event horizon of a periodic evolution directly to its initial condition
  // instead of rolling up the period). For the same reason, only a single optimistic merge is done per pass, after
  // which constrained merging restarts.
  bool mergePass(const int phase) {
    const auto tokenCount = static_cast<TokenID>(tokenContents_.size());
    bool mergedDuringPass = false;
    for (TokenID first = 0; first < tokenCount; ++first) {
      for (TokenID second = first + 1; second < tokenCount; ++second) {
        throwIfAborted();
        if (tokenClasses_->root(first) != first) break;  // no longer a class representative
        if (tokenClasses_->root(second) != second) continue;
        if (candidatePhase(first, second) != phase) continue;
        if (!quicklyCompatible(first, second)) continue;
        if (tryMergeWithAlignmentSearch(first, second)) {
          if (phase != 0) return true;
          mergedDuringPass = true;
        }
      }
    }
    return mergedDuringPass;
  }

 private:
  // Runs trials for the pair, enumerating the possible alignments of destroyer events that cannot be distinguished
  // locally (same token, same input index, same generation). A single trial commits to one alignment per such group;
  // enumerating all combinations across restarts makes the trial a complete isomorphism search rather than a greedy
  // heuristic, so an unfortunate local choice can no longer reject a valid merge. The first attempt (all choices 0)
  // reproduces the heuristic order, so unambiguous merges cost a single trial.
  bool tryMergeWithAlignmentSearch(const TokenID first, const TokenID second) {
    constexpr size_t maxAttempts = 64;
    std::vector<size_t> choices;
    for (size_t attempt = 0; attempt < maxAttempts; ++attempt) {
      std::vector<size_t> limits;
      Trial trial(this, first, second, &choices, &limits);
      if (trial.run()) {
        trial.commit();
        return true;
      }
      if (limits.empty()) return false;  // the failure did not involve any ambiguous alignments
      // Advance to the next combination of alignment choices (an odometer over the groups this attempt encountered).
      choices.resize(limits.size(), 0);
      bool advanced = false;
      size_t position = limits.size();
      while (position > 0 && !advanced) {
        --position;
        if (++choices[position] < limits[position]) {
          advanced = true;
        } else {
          choices[position] = 0;
        }
      }
      if (!advanced) return false;  // all combinations exhausted
    }
    return false;
  }

  /** @brief A single attempt to merge a pair of token classes, and everything that merge implies.
   */
  class Trial {
   public:
    Trial(Deduplicator* owner,
          const TokenID rootFirst,
          const TokenID rootSecond,
          const std::vector<size_t>* alignmentChoices,
          std::vector<size_t>* alignmentGroupLimits)
        : owner_(owner),
          rootFirst_(rootFirst),
          rootSecond_(rootSecond),
          alignmentChoices_(alignmentChoices),
          alignmentGroupLimits_(alignmentGroupLimits),
          tokens_(owner->tokenClasses_.get()),
          events_(owner->eventClasses_.get()),
          atoms_(owner->atomClasses_.get()) {}

    // Returns true if the merge is possible. In that case, commit() will apply it.
    bool run() {
      tokenPairQueue_.push_back({rootFirst_, rootSecond_});
      size_t processedCount = 0;
      const size_t processedCountLimit = 16 * (owner_->tokenContents_.size() + owner_->events_.size()) + 1024;
      while (!tokenPairQueue_.empty() || !eventPairQueue_.empty()) {
        owner_->throwIfAborted();
        if (++processedCount > processedCountLimit) return false;
        if (!eventPairQueue_.empty()) {
          const auto pair = eventPairQueue_.front();
          eventPairQueue_.pop_front();
          if (!processEventPair(pair.first, pair.second)) return false;
        } else {
          const auto pair = tokenPairQueue_.front();
          tokenPairQueue_.pop_front();
          if (!processTokenPair(pair.first, pair.second)) return false;
        }
      }
      return classFuturesConsistent() && tokenIdentificationsAllowed() && atomRenamingsAllowed();
    }

    void commit() {
      for (const auto& rootAndGroup : tokens_.groups()) {
        const auto& group = rootAndGroup.second;
        TokenID exploredRepresentative = noTokenID;
        std::vector<TokenID> mergedMembers;
        for (const auto member : group) {
          owner_->tokenClasses_->merge(group.front(), member);
          auto& members = owner_->tokenClassMembers_[member];
          mergedMembers.insert(mergedMembers.end(), members.begin(), members.end());
          members.clear();
          const auto memberRepresentative = owner_->exploredRepresentatives_[member];
          if (exploredRepresentative == noTokenID ||
              (memberRepresentative != noTokenID && memberRepresentative < exploredRepresentative)) {
            exploredRepresentative = memberRepresentative;
          }
        }
        const auto newRoot = owner_->tokenClasses_->root(group.front());
        owner_->tokenClassMembers_[newRoot] = std::move(mergedMembers);
        owner_->exploredRepresentatives_[newRoot] = exploredRepresentative;
      }
      for (const auto& rootAndGroup : events_.groups()) {
        const auto& group = rootAndGroup.second;
        for (const auto member : group) owner_->eventClasses_->merge(group.front(), member);
      }
      for (const auto& rootAndGroup : atoms_.groups()) {
        const auto& group = rootAndGroup.second;
        std::vector<int64_t> mergedMembers;
        for (const auto member : group) {
          owner_->atomClasses_->merge(group.front(), member);
          auto& members = owner_->atomClassMembers_[member];
          mergedMembers.insert(mergedMembers.end(), members.begin(), members.end());
          members.clear();
        }
        owner_->atomClassMembers_[owner_->atomClasses_->root(group.front())] = std::move(mergedMembers);
      }
    }

   private:
    struct TokenPair {
      TokenID first;
      TokenID second;
    };

    struct Past {
      std::unordered_set<EventID> events;
      std::unordered_set<TokenID> tokens;
    };

    // Everything to the past of the roots is considered deleted (on the corresponding side of the correspondence), and
    // does not constrain the merge.
    const Past& pastFirst() {
      if (!pastFirstOptional_) pastFirstOptional_ = computePast(rootFirst_);
      return *pastFirstOptional_;
    }

    const Past& pastSecond() {
      if (!pastSecondOptional_) pastSecondOptional_ = computePast(rootSecond_);
      return *pastSecondOptional_;
    }

    Past computePast(const TokenID token) const {
      Past past;
      std::deque<EventID> eventQueue = {owner_->creatorEvents_[token]};
      past.events.insert(owner_->creatorEvents_[token]);
      while (!eventQueue.empty()) {
        const auto event = eventQueue.front();
        eventQueue.pop_front();
        for (const auto inputToken : owner_->events_[event].inputTokens) {
          if (!past.tokens.insert(inputToken).second) continue;
          const auto creator = owner_->creatorEvents_[inputToken];
          if (past.events.insert(creator).second) eventQueue.push_back(creator);
        }
      }
      return past;
    }

    bool processTokenPair(const TokenID first, const TokenID second) {
      if (first == second) return true;
      if (!processedTokenPairs_.insert({first, second}).second) return true;

      // Tokens that coexist in possible states can never be identified: states are multisets, so the number of
      // identical tokens matters for matching.
      if (!owner_->tokensNeverCoexist(first, second)) return false;

      // Contents must have the same shape, and the corresponding atoms are identified.
      const auto& contentFirst = owner_->tokenContentAtomIndices_[first];
      const auto& contentSecond = owner_->tokenContentAtomIndices_[second];
      if (contentFirst.size() != contentSecond.size()) return false;
      for (size_t atomIndex = 0; atomIndex < contentFirst.size(); ++atomIndex) {
        atoms_.merge(contentFirst[atomIndex], contentSecond[atomIndex]);
      }

      mergeTokenClasses(first, second);

      // Creator events must correspond as well unless they are deleted, in which case they should be deleted on both
      // sides. Outputs of a single surviving event can never be identified because the correspondence would have to
      // map that event to itself, and it preserves output positions.
      const auto creatorFirst = owner_->creatorEvents_[first];
      const auto creatorSecond = owner_->creatorEvents_[second];
      const bool creatorFirstDeleted = static_cast<bool>(pastFirst().events.count(creatorFirst));
      const bool creatorSecondDeleted = static_cast<bool>(pastSecond().events.count(creatorSecond));
      if (creatorFirstDeleted != creatorSecondDeleted) return false;
      if (!creatorFirstDeleted) {
        if (creatorFirst == creatorSecond) return false;
        if (owner_->creatorOutputIndices_[first] != owner_->creatorOutputIndices_[second]) return false;
        eventPairQueue_.push_back({creatorFirst, creatorSecond});
      }

      return pairDestroyers(first, second);
    }

    void mergeTokenClasses(const TokenID first, const TokenID second) {
      const auto firstRoot = tokens_.root(first);
      const auto secondRoot = tokens_.root(second);
      if (firstRoot == secondRoot) return;
      const auto firstRepresentative = exploredRepresentative(firstRoot);
      const auto secondRepresentative = exploredRepresentative(secondRoot);
      tokens_.merge(firstRoot, secondRoot);
      const auto newRoot = tokens_.root(firstRoot);
      if (firstRepresentative != noTokenID && secondRepresentative != noTokenID) {
        trialExploredRepresentatives_[newRoot] = std::min(firstRepresentative, secondRepresentative);
        // Tokens can join the same class through horizon tokens without ever being compared directly. Their futures
        // are checked for consistency at the class level once the correspondence is complete. These are not
        // correspondence pairs, so running them through processTokenPair would incorrectly constrain their pasts.
        if (firstRepresentative != secondRepresentative) {
          pendingFutureChecks_.push_back({firstRepresentative, secondRepresentative});
        }
      } else {
        trialExploredRepresentatives_[newRoot] = std::max(firstRepresentative, secondRepresentative);
      }
    }

    TokenID exploredRepresentative(const int64_t trialRoot) {
      const auto overlayRepresentative = trialExploredRepresentatives_.find(trialRoot);
      if (overlayRepresentative != trialExploredRepresentatives_.end()) return overlayRepresentative->second;
      return owner_->exploredRepresentatives_[trialRoot];
    }

    // Destroyer events must correspond one-to-one for each input index under the generation shift between the two
    // tokens: an event at generation g on the first side corresponds to one at generation g + shift on the second
    // side. A destroyer whose counterpart falls within completely evolved generations is required to exist. Beyond
    // them the counterpart cannot be verified yet, but since the future of a multihistory is determined by its
    // tokens, it is guaranteed to appear once the evolution is continued, so nothing is checked. Events deleted with
    // the past of the corresponding root do not count.
    bool pairDestroyers(const TokenID first, const TokenID second) {
      const Generation shift =
          owner_->causalGraph_->tokenGeneration(second) - owner_->causalGraph_->tokenGeneration(first);
      std::map<int, std::vector<EventID>> bucketsFirst, bucketsSecond;
      for (const auto& eventAndInputIndex : owner_->destroyerEvents_[first]) {
        if (!pastFirst().events.count(eventAndInputIndex.first)) {
          bucketsFirst[eventAndInputIndex.second].push_back(eventAndInputIndex.first);
        }
      }
      for (const auto& eventAndInputIndex : owner_->destroyerEvents_[second]) {
        if (!pastSecond().events.count(eventAndInputIndex.first)) {
          bucketsSecond[eventAndInputIndex.second].push_back(eventAndInputIndex.first);
        }
      }
      for (auto& indexAndEventsFirst : bucketsFirst) {
        const auto bucketSecond = bucketsSecond.find(indexAndEventsFirst.first);
        if (bucketSecond == bucketsSecond.end()) {
          for (const auto event : indexAndEventsFirst.second) {
            if (owner_->eventGeneration(event) + shift <= owner_->completeGenerations_) return false;
          }
          continue;
        }
        if (!pairDestroyerBucket(&indexAndEventsFirst.second, &bucketSecond->second, shift)) return false;
      }
      for (auto& indexAndEventsSecond : bucketsSecond) {
        if (bucketsFirst.count(indexAndEventsSecond.first)) continue;
        for (const auto event : indexAndEventsSecond.second) {
          if (owner_->eventGeneration(event) - shift <= owner_->completeGenerations_) return false;
        }
      }
      return true;
    }

    bool pairDestroyerBucket(std::vector<EventID>* eventsFirst,
                             std::vector<EventID>* eventsSecond,
                             const Generation shift) {
      // Events of the same generation using the token at the same input index cannot be distinguished locally: they
      // are paired in a heuristic order first, and if the trial fails, other alignments are enumerated through
      // nextAlignmentChoice restarts.
      sortDestroyerBucket(eventsFirst);
      sortDestroyerBucket(eventsSecond);
      size_t indexFirst = 0;
      size_t indexSecond = 0;
      while (indexFirst < eventsFirst->size() || indexSecond < eventsSecond->size()) {
        const bool firstRemaining = indexFirst < eventsFirst->size();
        const bool secondRemaining = indexSecond < eventsSecond->size();
        const Generation shiftedGenerationFirst =
            firstRemaining ? owner_->eventGeneration((*eventsFirst)[indexFirst]) + shift : 0;
        const Generation generationSecond = secondRemaining ? owner_->eventGeneration((*eventsSecond)[indexSecond]) : 0;
        if (!secondRemaining || (firstRemaining && shiftedGenerationFirst < generationSecond)) {
          if (shiftedGenerationFirst <= owner_->completeGenerations_) return false;  // required but missing
          ++indexFirst;
        } else if (!firstRemaining || generationSecond < shiftedGenerationFirst) {
          if (generationSecond - shift <= owner_->completeGenerations_) return false;
          ++indexSecond;
        } else {
          // Blocks of aligned generations on both sides.
          size_t endFirst = indexFirst;
          while (endFirst < eventsFirst->size() &&
                 owner_->eventGeneration((*eventsFirst)[endFirst]) + shift == generationSecond) {
            ++endFirst;
          }
          size_t endSecond = indexSecond;
          while (endSecond < eventsSecond->size() &&
                 owner_->eventGeneration((*eventsSecond)[endSecond]) == generationSecond) {
            ++endSecond;
          }
          const size_t blockFirst = endFirst - indexFirst;
          const size_t blockSecond = endSecond - indexSecond;
          std::vector<EventID> secondBlock(eventsSecond->begin() + indexSecond, eventsSecond->begin() + endSecond);
          constexpr size_t maxSearchedBlockSize = 4;
          if (blockFirst == blockSecond && blockSecond > 1 && blockSecond <= maxSearchedBlockSize) {
            permuteBlock(&secondBlock, nextAlignmentChoice(factorial(blockSecond)));
          }
          for (size_t pairIndex = 0; pairIndex < std::min(blockFirst, blockSecond); ++pairIndex) {
            eventPairQueue_.push_back({(*eventsFirst)[indexFirst + pairIndex], secondBlock[pairIndex]});
          }
          if (blockFirst > blockSecond && generationSecond <= owner_->completeGenerations_) {
            return false;  // required but missing
          }
          if (blockSecond > blockFirst && generationSecond - shift <= owner_->completeGenerations_) {
            return false;
          }
          indexFirst = endFirst;
          indexSecond = endSecond;
        }
      }
      return true;
    }

    // Returns the alignment to use for the next ambiguous group, and records the group so that
    // tryMergeWithAlignmentSearch can enumerate all combinations across trial restarts.
    size_t nextAlignmentChoice(const size_t permutationCount) {
      const auto groupIndex = alignmentGroupLimits_->size();
      alignmentGroupLimits_->push_back(permutationCount);
      return groupIndex < alignmentChoices_->size() ? (*alignmentChoices_)[groupIndex] % permutationCount : 0;
    }

    static size_t factorial(const size_t value) {
      size_t result = 1;
      for (size_t factor = 2; factor <= value; ++factor) result *= factor;
      return result;
    }

    // Applies the permutation with the given lexicographic index (0 is the identity, preserving the heuristic order).
    static void permuteBlock(std::vector<EventID>* block, size_t permutationIndex) {
      std::vector<EventID> remaining = *block;
      block->clear();
      while (!remaining.empty()) {
        const size_t subpermutationCount = factorial(remaining.size() - 1);
        const size_t position = permutationIndex / subpermutationCount;
        permutationIndex %= subpermutationCount;
        block->push_back(remaining[position]);
        remaining.erase(remaining.begin() + static_cast<int64_t>(position));
      }
    }

    void sortDestroyerBucket(std::vector<EventID>* bucket) const {
      std::sort(bucket->begin(), bucket->end(), [this](const EventID first, const EventID second) {
        return owner_->eventSortingKey(first) < owner_->eventSortingKey(second);
      });
    }

    bool processEventPair(const EventID first, const EventID second) {
      if (first == second) return true;
      if (!processedEventPairs_.insert({first, second}).second) return true;
      const auto& eventFirst = owner_->events_[first];
      const auto& eventSecond = owner_->events_[second];
      if (eventFirst.rule != eventSecond.rule) return false;
      if (eventFirst.inputTokens.size() != eventSecond.inputTokens.size() ||
          eventFirst.outputTokens.size() != eventSecond.outputTokens.size()) {
        return false;
      }
      events_.merge(first, second);
      for (size_t inputIndex = 0; inputIndex < eventFirst.inputTokens.size(); ++inputIndex) {
        const auto inputFirst = eventFirst.inputTokens[inputIndex];
        const auto inputSecond = eventSecond.inputTokens[inputIndex];
        const bool inputFirstDeleted = static_cast<bool>(pastFirst().tokens.count(inputFirst));
        const bool inputSecondDeleted = static_cast<bool>(pastSecond().tokens.count(inputSecond));
        if (inputFirstDeleted != inputSecondDeleted) return false;
        if (!inputFirstDeleted) tokenPairQueue_.push_back({inputFirst, inputSecond});
      }
      for (size_t outputIndex = 0; outputIndex < eventFirst.outputTokens.size(); ++outputIndex) {
        tokenPairQueue_.push_back({eventFirst.outputTokens[outputIndex], eventSecond.outputTokens[outputIndex]});
      }
      return true;
    }

    // Tokens can join the same class transitively without being compared directly, so verify that no two members of
    // any changed class coexist. This is the token-level counterpart of atom independence: every state must map
    // injectively into the quotient.
    bool tokenIdentificationsAllowed() {
      for (const auto& rootAndGroup : tokens_.groups()) {
        const auto& group = rootAndGroup.second;
        for (size_t firstIndex = 0; firstIndex < group.size(); ++firstIndex) {
          for (size_t secondIndex = firstIndex + 1; secondIndex < group.size(); ++secondIndex) {
            owner_->throwIfAborted();
            for (const auto firstToken : owner_->tokenClassMembers_[group[firstIndex]]) {
              for (const auto secondToken : owner_->tokenClassMembers_[group[secondIndex]]) {
                if (!owner_->tokensNeverCoexist(firstToken, secondToken)) return false;
              }
            }
          }
        }
      }
      return true;
    }

    // Tokens with completely known futures that were joined into a single class must have the same destroyer
    // structure up to the classes formed by this trial. This is checked after the correspondence closes so that the
    // event classes have already converged.
    bool classFuturesConsistent() {
      for (const auto& pair : pendingFutureChecks_) {
        if (!classFuturesMatch(pair.first, pair.second)) return false;
      }
      return true;
    }

    // The signatures are compared under the generation shift between the tokens, and destroyers whose counterparts
    // would be beyond completely evolved generations are ignored — the same semantics pairDestroyers uses. Comparing
    // unshifted signatures would incorrectly reject merges whenever one of the tokens is re-consumed by later events
    // whose counterparts for the other token are beyond the horizon.
    bool classFuturesMatch(const TokenID first, const TokenID second) {
      const Generation shift =
          owner_->causalGraph_->tokenGeneration(second) - owner_->causalGraph_->tokenGeneration(first);
      std::set<std::tuple<int64_t, int, Generation>> signatureFirst;
      for (const auto& eventAndInputIndex : owner_->destroyerEvents_[first]) {
        const auto generation = owner_->eventGeneration(eventAndInputIndex.first);
        if (generation > owner_->completeGenerations_ || generation + shift > owner_->completeGenerations_) continue;
        signatureFirst.insert({events_.root(eventAndInputIndex.first), eventAndInputIndex.second, generation + shift});
      }
      std::set<std::tuple<int64_t, int, Generation>> signatureSecond;
      for (const auto& eventAndInputIndex : owner_->destroyerEvents_[second]) {
        const auto generation = owner_->eventGeneration(eventAndInputIndex.first);
        if (generation > owner_->completeGenerations_ || generation - shift > owner_->completeGenerations_) continue;
        signatureSecond.insert({events_.root(eventAndInputIndex.first), eventAndInputIndex.second, generation});
      }
      return signatureFirst == signatureSecond;
    }

    // Atoms can only be identified if they are independent, i.e., they never appear together in a spacelike set of
    // tokens. Otherwise, identifying them would change the contents of possible states of the system. In addition,
    // explicitly named atoms are never identified with each other because the evolution can distinguish them.
    bool atomRenamingsAllowed() {
      for (const auto& rootAndGroup : atoms_.groups()) {
        const auto& group = rootAndGroup.second;
        size_t namedAtomCount = 0;
        for (const auto baseRoot : group) {
          for (const auto member : owner_->atomClassMembers_[baseRoot]) {
            if (member < owner_->namedAtomIndexCount_) ++namedAtomCount;
          }
        }
        if (namedAtomCount > 1) return false;
        for (size_t firstIndex = 0; firstIndex < group.size(); ++firstIndex) {
          for (size_t secondIndex = firstIndex + 1; secondIndex < group.size(); ++secondIndex) {
            owner_->throwIfAborted();
            for (const auto firstAtom : owner_->atomClassMembers_[group[firstIndex]]) {
              for (const auto secondAtom : owner_->atomClassMembers_[group[secondIndex]]) {
                if (!owner_->atomsIndependent(firstAtom, secondAtom)) return false;
              }
            }
          }
        }
      }
      return true;
    }

    Deduplicator* owner_;
    const TokenID rootFirst_;
    const TokenID rootSecond_;
    const std::vector<size_t>* alignmentChoices_;
    std::vector<size_t>* alignmentGroupLimits_;
    TrialUnionFind tokens_;
    TrialUnionFind events_;
    TrialUnionFind atoms_;
    std::deque<TokenPair> tokenPairQueue_;
    std::deque<std::pair<EventID, EventID>> eventPairQueue_;
    std::vector<std::pair<TokenID, TokenID>> pendingFutureChecks_;
    std::unordered_set<std::pair<TokenID, TokenID>, PairHash> processedTokenPairs_;
    std::unordered_set<std::pair<EventID, EventID>, PairHash> processedEventPairs_;
    std::unordered_map<int64_t, TokenID> trialExploredRepresentatives_;
    std::optional<Past> pastFirstOptional_;
    std::optional<Past> pastSecondOptional_;
  };

  void indexAtoms() {
    for (const auto& content : tokenContents_) {
      for (const auto atom : content) atomValues_.push_back(atom);
    }
    std::sort(atomValues_.begin(), atomValues_.end());
    atomValues_.erase(std::unique(atomValues_.begin(), atomValues_.end()), atomValues_.end());
    namedAtomIndexCount_ = static_cast<int64_t>(
        std::upper_bound(atomValues_.begin(), atomValues_.end(), largestNamedAtom_) - atomValues_.begin());
    for (size_t atomIndex = 0; atomIndex < atomValues_.size(); ++atomIndex) {
      atomIndices_[atomValues_[atomIndex]] = static_cast<int64_t>(atomIndex);
    }
    tokenContentAtomIndices_.resize(tokenContents_.size());
    atomIndexTokens_.resize(atomValues_.size());
    for (TokenID token = 0; token < static_cast<TokenID>(tokenContents_.size()); ++token) {
      auto& contentIndices = tokenContentAtomIndices_[token];
      contentIndices.reserve(tokenContents_[token].size());
      for (const auto atom : tokenContents_[token]) {
        contentIndices.push_back(atomIndices_.at(atom));
        atomIndexTokens_[contentIndices.back()].push_back(token);
      }
    }
    for (auto& tokensOfAtom : atomIndexTokens_) {
      std::sort(tokensOfAtom.begin(), tokensOfAtom.end());
      tokensOfAtom.erase(std::unique(tokensOfAtom.begin(), tokensOfAtom.end()), tokensOfAtom.end());
    }
  }

  void buildIncidence() {
    const auto tokenCount = static_cast<TokenID>(tokenContents_.size());
    creatorEvents_.assign(tokenCount, noEventID);
    creatorOutputIndices_.assign(tokenCount, -1);
    destroyerEvents_.resize(tokenCount);
    for (EventID event = 0; event < static_cast<EventID>(events_.size()); ++event) {
      const auto& inputTokens = events_[event].inputTokens;
      for (int inputIndex = 0; inputIndex < static_cast<int>(inputTokens.size()); ++inputIndex) {
        const auto token = inputTokens[inputIndex];
        if (token < 0 || token >= tokenCount) throw TokenDeduplicationError::InconsistentInput;
        destroyerEvents_[token].push_back({event, inputIndex});
      }
      const auto& outputTokens = events_[event].outputTokens;
      for (int outputIndex = 0; outputIndex < static_cast<int>(outputTokens.size()); ++outputIndex) {
        const auto token = outputTokens[outputIndex];
        if (token < 0 || token >= tokenCount) throw TokenDeduplicationError::InconsistentInput;
        if (creatorEvents_[token] != noEventID) throw TokenDeduplicationError::InconsistentInput;
        creatorEvents_[token] = event;
        creatorOutputIndices_[token] = outputIndex;
      }
    }
    for (const auto creator : creatorEvents_) {
      if (creator == noEventID) throw TokenDeduplicationError::InconsistentInput;
    }
    // Signatures only include destroyers within completely evolved generations: later ones might be missing their
    // counterparts, so they cannot be compared directly.
    destroyerSignatures_.resize(tokenCount);
    for (TokenID token = 0; token < tokenCount; ++token) {
      auto& signature = destroyerSignatures_[token];
      signature.reserve(destroyerEvents_[token].size());
      for (const auto& eventAndInputIndex : destroyerEvents_[token]) {
        const auto event = eventAndInputIndex.first;
        if (eventGeneration(event) > completeGenerations_) continue;
        signature.push_back({eventAndInputIndex.second, eventGeneration(event), events_[event].rule});
      }
      std::sort(signature.begin(), signature.end());
    }
  }

  void replayCausalGraph() {
    if (events_.empty() || events_[0].rule != initialConditionRule || !events_[0].inputTokens.empty()) {
      throw TokenDeduplicationError::InconsistentInput;
    }
    const auto tokenCount = static_cast<TokenID>(tokenContents_.size());
    for (const auto& event : events_) {
      for (const auto& tokenLists : {&event.inputTokens, &event.outputTokens}) {
        for (const auto token : *tokenLists) {
          if (token < 0 || token >= tokenCount) throw TokenDeduplicationError::InconsistentInput;
        }
      }
    }
    causalGraph_ = std::make_unique<TokenEventGraph>(static_cast<int>(events_[0].outputTokens.size()),
                                                     TokenEventGraph::SeparationTrackingMethod::DestroyerChoices);
    for (TokenID token = 0; token < static_cast<TokenID>(events_[0].outputTokens.size()); ++token) {
      if (events_[0].outputTokens[token] != token) throw TokenDeduplicationError::InconsistentInput;
    }
    for (EventID event = 1; event < static_cast<EventID>(events_.size()); ++event) {
      const auto newTokenIDs = causalGraph_->addEvent(
          events_[event].rule, events_[event].inputTokens, static_cast<int>(events_[event].outputTokens.size()));
      if (newTokenIDs != events_[event].outputTokens) throw TokenDeduplicationError::InconsistentInput;
    }
    if (causalGraph_->tokenCount() != tokenContents_.size()) throw TokenDeduplicationError::InconsistentInput;
  }

  bool isFutureComplete(const TokenID token) const {
    return causalGraph_->tokenGeneration(token) < completeGenerations_;
  }

  bool quicklyCompatible(const TokenID first, const TokenID second) const {
    if (tokenContents_[first].size() != tokenContents_[second].size()) return false;
    // The signatures are only comparable directly if there is no generation shift between the tokens.
    if (causalGraph_->tokenGeneration(first) == causalGraph_->tokenGeneration(second) &&
        destroyerSignatures_[first] != destroyerSignatures_[second]) {
      return false;
    }
    return true;
  }

  Generation eventGeneration(const EventID event) const { return causalGraph_->events()[event].generation; }

  std::tuple<Generation, RuleID, std::vector<size_t>, EventID> eventSortingKey(const EventID event) const {
    std::vector<size_t> inputContentSizes;
    inputContentSizes.reserve(events_[event].inputTokens.size());
    for (const auto inputToken : events_[event].inputTokens) {
      inputContentSizes.push_back(tokenContents_[inputToken].size());
    }
    return {eventGeneration(event), events_[event].rule, std::move(inputContentSizes), event};
  }

  // True if the tokens can never appear in the same state, i.e., they are timelike or branchlike separated. Merging
  // coexisting (spacelike) tokens would change the multiset of tokens available for matching within a state.
  bool tokensNeverCoexist(const TokenID first, const TokenID second) const {
    const auto separation = causalGraph_->tokenSeparation(first, second);
    return separation == SeparationType::Timelike || separation == SeparationType::Branchlike;
  }

  bool atomsIndependent(const int64_t firstAtom, const int64_t secondAtom) const {
    for (const auto firstToken : atomIndexTokens_[firstAtom]) {
      for (const auto secondToken : atomIndexTokens_[secondAtom]) {
        const auto separation = causalGraph_->tokenSeparation(firstToken, secondToken);
        if (separation == SeparationType::Spacelike || separation == SeparationType::Identical ||
            separation == SeparationType::Unknown) {
          return false;
        }
      }
    }
    return true;
  }

  void throwIfAborted() const {
    if (shouldAbort_ && shouldAbort_()) throw TokenDeduplicationError::Aborted;
  }

  // The per-trial checks maintain these invariants incrementally. Verify them at the end as a safety net: if this ever
  // throws, it is a bug in the trial logic rather than in the input.
  void validateClasses() const {
    for (TokenID token = 0; token < static_cast<TokenID>(tokenContents_.size()); ++token) {
      const auto& members = tokenClassMembers_[token];
      for (size_t firstIndex = 0; firstIndex < members.size(); ++firstIndex) {
        for (size_t secondIndex = firstIndex + 1; secondIndex < members.size(); ++secondIndex) {
          if (!tokensNeverCoexist(members[firstIndex], members[secondIndex])) {
            throw TokenDeduplicationError::InconsistentClasses;
          }
        }
      }
    }
    for (TokenID token = 0; token < static_cast<TokenID>(tokenContents_.size()); ++token) {
      const auto representative = tokenClasses_->root(token);
      if (representative == token) continue;
      const auto& content = tokenContentAtomIndices_[token];
      const auto& representativeContent = tokenContentAtomIndices_[representative];
      if (content.size() != representativeContent.size()) throw TokenDeduplicationError::InconsistentClasses;
      for (size_t atomIndex = 0; atomIndex < content.size(); ++atomIndex) {
        if (atomClasses_->root(content[atomIndex]) != atomClasses_->root(representativeContent[atomIndex])) {
          throw TokenDeduplicationError::InconsistentClasses;
        }
      }
    }
    for (EventID event = 0; event < static_cast<EventID>(events_.size()); ++event) {
      const auto representative = eventClasses_->root(event);
      if (representative == event) continue;
      if (events_[event].rule != events_[representative].rule ||
          events_[event].outputTokens.size() != events_[representative].outputTokens.size() ||
          events_[event].inputTokens.size() != events_[representative].inputTokens.size()) {
        throw TokenDeduplicationError::InconsistentClasses;
      }
      for (size_t outputIndex = 0; outputIndex < events_[event].outputTokens.size(); ++outputIndex) {
        if (tokenClasses_->root(events_[event].outputTokens[outputIndex]) !=
            tokenClasses_->root(events_[representative].outputTokens[outputIndex])) {
          throw TokenDeduplicationError::InconsistentClasses;
        }
      }
    }
    for (size_t atomIndex = 0; atomIndex < atomValues_.size(); ++atomIndex) {
      const auto& members = atomClassMembers_[atomIndex];
      size_t namedAtomCount = 0;
      for (const auto member : members) {
        if (member < namedAtomIndexCount_) ++namedAtomCount;
      }
      if (namedAtomCount > 1) throw TokenDeduplicationError::InconsistentClasses;
      for (size_t firstIndex = 0; firstIndex < members.size(); ++firstIndex) {
        for (size_t secondIndex = firstIndex + 1; secondIndex < members.size(); ++secondIndex) {
          if (!atomsIndependent(members[firstIndex], members[secondIndex])) {
            throw TokenDeduplicationError::InconsistentClasses;
          }
        }
      }
    }
  }

  TokenDeduplicationResult buildResult() const {
    TokenDeduplicationResult result;
    result.tokenClasses.reserve(tokenContents_.size());
    for (TokenID token = 0; token < static_cast<TokenID>(tokenContents_.size()); ++token) {
      result.tokenClasses.push_back(tokenClasses_->root(token));
    }
    result.eventClasses.reserve(events_.size());
    for (EventID event = 0; event < static_cast<EventID>(events_.size()); ++event) {
      result.eventClasses.push_back(eventClasses_->root(event));
    }
    for (size_t atomIndex = 0; atomIndex < atomValues_.size(); ++atomIndex) {
      const auto representative = atomClasses_->root(static_cast<int64_t>(atomIndex));
      if (representative != static_cast<int64_t>(atomIndex)) {
        result.atomClasses[atomValues_[atomIndex]] = atomValues_[representative];
      }
    }
    return result;
  }

  const std::vector<AtomsVector>& tokenContents_;
  const std::vector<Event>& events_;
  const Generation completeGenerations_;
  const Atom largestNamedAtom_;
  const std::function<bool()>& shouldAbort_;

  // Atoms are renumbered to contiguous indices so that they can be used in a union-find directly. Named atoms have
  // the smallest values, so they come first, and there are namedAtomIndexCount_ of them.
  std::vector<Atom> atomValues_;
  std::unordered_map<Atom, int64_t> atomIndices_;
  int64_t namedAtomIndexCount_ = 0;
  std::vector<std::vector<int64_t>> tokenContentAtomIndices_;
  std::vector<std::vector<TokenID>> atomIndexTokens_;

  std::vector<EventID> creatorEvents_;
  std::vector<int> creatorOutputIndices_;
  std::vector<std::vector<std::pair<EventID, int>>> destroyerEvents_;
  std::vector<std::vector<std::tuple<int, Generation, RuleID>>> destroyerSignatures_;
  std::unique_ptr<TokenEventGraph> causalGraph_;

  std::unique_ptr<UnionFind> tokenClasses_;
  std::unique_ptr<UnionFind> eventClasses_;
  std::unique_ptr<UnionFind> atomClasses_;
  std::vector<std::vector<TokenID>> tokenClassMembers_;
  std::vector<std::vector<int64_t>> atomClassMembers_;
  // The smallest token with completely known future in each token class (noTokenID if none), addressed by class
  // representative.
  std::vector<TokenID> exploredRepresentatives_;
};
}  // namespace

TokenDeduplicationResult deduplicateTokens(const std::vector<AtomsVector>& tokens,
                                           const std::vector<Event>& events,
                                           const Generation completeGenerations,
                                           const Atom largestNamedAtom,
                                           const std::function<bool()>& shouldAbort) {
  Deduplicator deduplicator(tokens, events, completeGenerations, largestNamedAtom, shouldAbort);
  return deduplicator.compute();
}
}  // namespace SetReplace
