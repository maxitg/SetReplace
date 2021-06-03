#include "HypergraphMatcher.hpp"

#include <algorithm>
#include <atomic>
#include <functional>
#include <limits>
#include <map>
#include <memory>
#include <mutex>
#include <random>
#include <set>
#include <shared_mutex>  // NOLINT cpplint thinks this is a C system header for some reason
#include <thread>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

#include "Parallelism.hpp"

namespace SetReplace {
namespace {
class MatchComparator {
 private:
  const HypergraphMatcher::OrderingSpec orderingSpec_;

  template <typename T>
  static int compare(T a, T b) {
    return a < b ? -1 : static_cast<int>(a > b);
  }

 public:
  explicit MatchComparator(HypergraphMatcher::OrderingSpec orderingSpec) : orderingSpec_(std::move(orderingSpec)) {}

  bool operator()(const MatchPtr& a, const MatchPtr& b) const {
    for (const auto& ordering : orderingSpec_) {
      int comparison = compare(a, b, ordering.first);
      if (comparison != 0) {
        switch (ordering.second) {
          case HypergraphMatcher::OrderingDirection::Normal:
            break;
          case HypergraphMatcher::OrderingDirection::Reverse:
            comparison = -comparison;
            break;
          default:
            return false;  // throw is called in constructor of Matcher::Implementation
        }
        return comparison < 0;
      }
    }
    return false;
  }

  static int compare(const MatchPtr& a, const MatchPtr& b, const HypergraphMatcher::OrderingFunction& ordering) {
    switch (ordering) {
      case HypergraphMatcher::OrderingFunction::SortedInputTokenIndices:
        return compareSortedIDs(a, b, false);

      case HypergraphMatcher::OrderingFunction::ReverseSortedInputTokenIndices:
        return compareSortedIDs(a, b, true);

      case HypergraphMatcher::OrderingFunction::InputTokenIndices:
        return compareUnsortedIDs(a, b);

      case HypergraphMatcher::OrderingFunction::RuleIndex:
        return compare(a->rule, b->rule);

      default:
        return 0;  // throw is called in constructor of Matcher::Implementation
    }
  }

  static int compareVectors(const std::vector<TokenID>& first, const std::vector<TokenID>& second) {
    const auto mismatchingIterators = std::mismatch(first.begin(), first.end(), second.begin(), second.end());
    if (mismatchingIterators.first != first.end() && mismatchingIterators.second != second.end()) {
      return compare(*mismatchingIterators.first, *mismatchingIterators.second);
    } else {
      return compare(first.size(), second.size());
    }
  }

  static int compareSortedIDs(const MatchPtr& a, const MatchPtr& b, const bool reverseOrder) {
    std::vector<TokenID> aTokens(a->inputTokens.begin(), a->inputTokens.end());
    std::vector<TokenID> bTokens(b->inputTokens.begin(), b->inputTokens.end());

    if (!reverseOrder) {
      std::sort(aTokens.begin(), aTokens.end(), std::less<>());
      std::sort(bTokens.begin(), bTokens.end(), std::less<>());
    } else {
      std::sort(aTokens.begin(), aTokens.end(), std::greater<>());
      std::sort(bTokens.begin(), bTokens.end(), std::greater<>());
    }
    return compareVectors(aTokens, bTokens);
  }

  static int compareUnsortedIDs(const MatchPtr& a, const MatchPtr& b) {
    return compareVectors(a->inputTokens, b->inputTokens);
  }
};

// Hashes the values of the matches, not the pointer itself.
class MatchHasher {
 public:
  size_t operator()(const MatchPtr& ptr) const {
    std::size_t result = 0;
    hash_combine(&result, ptr->rule);
    for (const auto token : ptr->inputTokens) {
      hash_combine(&result, token);
    }
    return result;
  }

 private:
  // https://stackoverflow.com/a/2595226
  template <class T>
  static void hash_combine(std::size_t* seed, const T& value) {
    std::hash<T> hasher;
    *seed ^= hasher(value) + 0x9e3779b9 + (*seed << 6) + (*seed >> 2);
  }
};

class MatchEquality {
 public:
  size_t operator()(const MatchPtr& a, const MatchPtr& b) const {
    if (a->rule != b->rule || a->inputTokens.size() != b->inputTokens.size()) {
      return false;
    }

    const auto mismatchedIterators =
        std::mismatch(a->inputTokens.begin(), a->inputTokens.end(), b->inputTokens.begin(), b->inputTokens.end());
    return mismatchedIterators.first == a->inputTokens.end() && mismatchedIterators.second == b->inputTokens.end();
  }
};
}  // namespace

class HypergraphMatcher::Implementation {
 private:
  const std::vector<Rule>& rules_;
  AtomsIndex& atomsIndex_;
  const GetAtomsVectorFunc getAtomsVector_;
  const GetTokenSeparationFunc getTokenSeparation_;
  const OrderingSpec orderingSpec_;

  // Matches are arranged in buckets. Each bucket contains matches that are equivalent in terms of the ordering
  // function, however, buckets themselves are ordered according to that function.
  // To select next match, we select a random element from the first bucket.
  // That in particular means the random ordering function will automatically be used if ordering
  // specification is incomplete.

  // We use MatchPtr instead of Match to save memory, however, they are hashed and sorted according to their
  // dereferenced values in the corresponding classes above.

  // We cannot directly select a random element from an unordered_map, which is why we use a vector here.
  using Bucket = std::pair<std::unordered_map<MatchPtr, size_t, MatchHasher, MatchEquality>, std::vector<MatchPtr>>;
  std::map<MatchPtr, Bucket, MatchComparator> matchQueue_;
  std::unordered_map<TokenID, std::unordered_set<MatchPtr, MatchHasher, MatchEquality>> tokensToMatches_;

  // A frequent operation here is detection of duplicate matches. Hashing is much faster than searching for
  // duplicates in a std::map, so we separately keep a flat hash table of all matches to speed that up.
  // That's purely an optimization.
  std::unordered_set<MatchPtr, MatchHasher, MatchEquality> allMatches_;

  std::mt19937 randomGenerator_;
  MatchPtr nextMatch_;

  const EventDeduplication eventDeduplication_;
  // Newly created matches for which the advanced deduplication algorithm has not yet been run.
  // We sort them by sets they match to, and then by the chosen ordering function,
  // so that each batch with identical inputs can be processed together, and it's obvious which copy should be retained.
  std::set<MatchPtr, MatchComparator> newMatches_;

  /**
   * This variable is typically monitored in shouldAbort such that other threads can check if they should abort.
   * It is volatile, but not atomic because it is locked before being written to.
   */
  mutable volatile Error currentError;
  mutable std::shared_mutex currentErrorMutex;

  /**
   * This mutex should be used to gain access to the above match structures.
   * Currently only insertMatch is executed concurrently, and therefore it is only used there (for now).
   */
  mutable std::mutex matchMutex;

 public:
  Implementation(const std::vector<Rule>& rules,
                 AtomsIndex* atomsIndex,
                 GetAtomsVectorFunc getAtomsVector,
                 GetTokenSeparationFunc getTokenSeparation,
                 const OrderingSpec& orderingSpec,
                 const EventDeduplication& eventDeduplication,
                 const unsigned int randomSeed)
      : rules_(rules),
        atomsIndex_(*atomsIndex),
        getAtomsVector_(std::move(getAtomsVector)),
        getTokenSeparation_(std::move(getTokenSeparation)),
        orderingSpec_(orderingSpec),
        matchQueue_(MatchComparator(orderingSpec)),
        randomGenerator_(randomSeed),
        eventDeduplication_(eventDeduplication),
        newMatches_(MatchComparator(newMatchesOrderingSpec(orderingSpec))),
        currentError(None) {
    for (const auto& ordering : orderingSpec) {
      if (ordering.first < OrderingFunction::First || ordering.first >= OrderingFunction::Last) {
        throw HypergraphMatcher::Error::InvalidOrderingFunction;
      } else if (ordering.second < OrderingDirection::First || ordering.second >= OrderingDirection::Last) {
        throw HypergraphMatcher::Error::InvalidOrderingDirection;
      }
    }
  }

  void addMatchesInvolvingTokens(const std::vector<TokenID>& tokenIDs, const std::function<bool()>& abortRequested) {
    // If one thread errors, alert other threads with this function
    const std::function<bool()> shouldAbort = [this, &abortRequested]() {
      return getCurrentError() != None || abortRequested();
    };

    {
      // Only create threads if there is more than one rule
      const auto threadAcquisitionToken =
          Parallelism::acquire(Parallelism::HardwareType::StdCpu, static_cast<int>(rules_.size()));
      const int& numThreadsToUse = threadAcquisitionToken->numThreads();

      auto addMatchesForRuleRange = [=](RuleID start) {
        for (RuleID i = start; i < static_cast<RuleID>(rules_.size()); i += numThreadsToUse) {
          addMatchesForRule(tokenIDs, i, shouldAbort);
        }
      };

      if (numThreadsToUse > 0) {
        // Multi-threaded path
        std::vector<std::thread> threads(numThreadsToUse);
        for (int i = 0; i < numThreadsToUse; ++i) {
          threads[i] = std::thread(addMatchesForRuleRange, i);
        }
        for (auto& thread : threads) {
          thread.join();
        }
      } else {
        // Single-threaded path
        for (RuleID i = 0; i < static_cast<RuleID>(rules_.size()); ++i) {
          addMatchesForRule(tokenIDs, i, shouldAbort);
        }
      }
    }
    if (currentError != None) {
      // Reset currentError before throwing
      Error toThrow(currentError);
      currentError = None;
      throw toThrow;
    }

    if (eventDeduplication_ == EventDeduplication::SameInputSetIsomorphicOutputs) {
      removeIdenticalMatches(abortRequested);
    }

    insertNewMatches();
    chooseNextMatch();
  }

  // Note, deletion changes the ordering of allMatchIterators_, therefore
  // deletion should be done in deterministic order, otherwise, the random replacements will not be deterministic
  void removeMatchesInvolvingTokens(const std::vector<TokenID>& tokenIDs) {
    // do not use unordered_set, as it make order undeterministic
    // any ordering spec works here, as long as it's complete.
    OrderingSpec fullOrderingSpec = {{OrderingFunction::InputTokenIndices, OrderingDirection::Normal},
                                     {OrderingFunction::RuleIndex, OrderingDirection::Normal}};
    std::set<MatchPtr, MatchComparator> matchesToDelete((MatchComparator(fullOrderingSpec)));

    for (const auto& token : tokenIDs) {
      const auto& matches = tokensToMatches_[token];
      matchesToDelete.insert(matches.begin(), matches.end());
    }

    for (const auto& match : matchesToDelete) {
      deleteMatch(match);
    }

    chooseNextMatch();
  }

  void deleteMatch(const MatchPtr& matchPtr) {
    allMatches_.erase(matchPtr);

    const auto& tokens = matchPtr->inputTokens;
    for (const auto token : tokens) {
      tokensToMatches_[token].erase(matchPtr);
      if (tokensToMatches_[token].empty()) tokensToMatches_.erase(token);
    }

    const auto bucketIt = matchQueue_.find(matchPtr);
    auto& bucket = bucketIt->second;
    const auto bucketIndex = bucket.first.at(matchPtr);
    // O(1) order-non-preserving deletion from a vector
    std::swap(bucket.second[bucketIndex], bucket.second[bucket.second.size() - 1]);
    bucket.first[bucket.second[bucketIndex]] = bucketIndex;
    bucket.first.erase(bucket.second[bucket.second.size() - 1]);
    bucket.second.pop_back();
    if (bucket.first.empty()) matchQueue_.erase(bucketIt);
  }

  bool empty() const { return matchQueue_.empty(); }

  MatchPtr nextMatch() const { return nextMatch_; }

  std::vector<MatchPtr> allMatches() const {
    std::vector<MatchPtr> result;
    for (const auto& exampleAndBucket : matchQueue_) {
      result.insert(result.end(), exampleAndBucket.second.second.begin(), exampleAndBucket.second.second.end());
    }
    return result;
  }

  std::vector<AtomsVector> matchInputAtomsVectors(const MatchPtr& match) const {
    std::vector<AtomsVector> inputTokens;
    inputTokens.reserve(match->inputTokens.size());
    for (const auto& tokenID : match->inputTokens) {
      inputTokens.emplace_back(getAtomsVector_(tokenID));
    }
    return inputTokens;
  }

  std::vector<AtomsVector> matchOutputAtomsVectors(const MatchPtr& match) const {
    return outputAtomsVectors(rules_.at(match->rule), matchInputAtomsVectors(match));
  }

 private:
  void addMatchesForRule(const std::vector<TokenID>& tokenIDs,
                         const RuleID& ruleID,
                         const std::function<bool()>& shouldAbort) {
    const auto& ruleInputTokens = rules_[ruleID].inputs;
    for (size_t i = 0; i < ruleInputTokens.size(); ++i) {
      const Match emptyMatch{ruleID, std::vector<TokenID>(ruleInputTokens.size(), -1)};
      completeMatchesStartingWithInput(
          emptyMatch, ruleInputTokens, rules_[ruleID].eventSelectionFunction, i, tokenIDs, shouldAbort);
    }
  }

  void completeMatchesStartingWithInput(const Match& incompleteMatch,
                                        const std::vector<AtomsVector>& partiallyMatchedInputs,
                                        const EventSelectionFunction eventSelectionFunction,
                                        const size_t nextInputIdx,
                                        const std::vector<TokenID>& potentialTokenIDs,
                                        const std::function<bool()>& shouldAbort) {
    for (const auto tokenID : potentialTokenIDs) {
      if (getCurrentError() != None) {
        return;
      }
      if (isTokenUnused(incompleteMatch, tokenID)) {
        attemptMatchTokenToInput(
            incompleteMatch, partiallyMatchedInputs, eventSelectionFunction, nextInputIdx, tokenID, shouldAbort);
      }
    }
  }

  static bool isTokenUnused(const Match& match, const TokenID tokenID) {
    return std::find(match.inputTokens.begin(), match.inputTokens.end(), tokenID) == match.inputTokens.end();
  }

  void setCurrentErrorIfNone(Error newError) const {
    std::unique_lock lock(currentErrorMutex);
    if (currentError == None) {
      currentError = newError;
    }
  }

  Error getCurrentError() const {
    std::shared_lock lock(currentErrorMutex);
    return currentError;
  }

  void attemptMatchTokenToInput(const Match& incompleteMatch,
                                const std::vector<AtomsVector>& partiallyMatchedInputs,
                                const EventSelectionFunction eventSelectionFunction,
                                const size_t nextInputIdx,
                                const TokenID potentialTokenID,
                                const std::function<bool()>& shouldAbort) {
    // If WL wants to abort, abort
    if (shouldAbort()) {
      setCurrentErrorIfNone(Error::Aborted);
      return;
    }

    const auto& input = partiallyMatchedInputs[nextInputIdx];
    const auto& tokenAtoms = getAtomsVector_(potentialTokenID);

    // tokens (hyperedges) of different sizes, cannot match
    if (input.size() != tokenAtoms.size()) {
      return;
    }

    Match newMatch = incompleteMatch;
    newMatch.inputTokens[nextInputIdx] = potentialTokenID;

    auto newInputs = partiallyMatchedInputs;
    if (!substituteMissingAtomsIfPossible(input, tokenAtoms, &newInputs)) {
      return;
    }
    if (eventSelectionFunction == EventSelectionFunction::Spacelike &&
        !isSpacelikeSeparated(potentialTokenID, newMatch.inputTokens)) {
      return;
    }

    if (isMatchComplete(newMatch)) {
      std::lock_guard<std::mutex> lock(matchMutex);
      newMatches_.insert(std::make_shared<Match>(newMatch));
      return;
    }

    const auto nextInputIdxAndCandidateTokens = nextBestInputAndTokensToTry(newMatch, newInputs);
    completeMatchesStartingWithInput(newMatch,
                                     newInputs,
                                     eventSelectionFunction,
                                     nextInputIdxAndCandidateTokens.first,
                                     nextInputIdxAndCandidateTokens.second,
                                     shouldAbort);
  }

  bool isSpacelikeSeparated(const TokenID newToken, const std::vector<TokenID>& previousTokens) {
    for (const auto& previousToken : previousTokens) {
      if (previousToken == newToken || previousToken < 0) continue;
      const auto separation = getTokenSeparation_(previousToken, newToken);
      if (separation != SeparationType::Spacelike) {
        return false;
      }
    }

    return true;
  }

  void insertNewMatches() {
    std::vector<MatchPtr> sortedMatches(newMatches_.begin(), newMatches_.end());
    newMatches_.clear();
    // We should sort them in the same order they would be added if the evaluation was sequential.
    std::sort(sortedMatches.begin(), sortedMatches.end(), [](MatchPtr first, MatchPtr second) {
      return first->rule < second->rule;
    });
    for (const auto& match : sortedMatches) {
      insertMatch(match);
    }
  }

  void insertMatch(const MatchPtr matchPtr) {
    if (!allMatches_.insert(matchPtr).second) {
      return;
    }

    const auto bucketIt = matchQueue_.emplace(matchPtr, Bucket()).first;  // works because comparison is smart
    auto& bucket = bucketIt->second;
    if (!bucket.first.count(matchPtr)) {  // works because hashing is smart
      bucket.second.push_back(matchPtr);
      bucket.first[matchPtr] = bucket.second.size() - 1;

      const auto& tokens = matchPtr->inputTokens;
      for (const auto token : tokens) {
        tokensToMatches_[token].insert(matchPtr);
      }
    }
  }

  static bool isMatchComplete(const Match& match) {
    return std::find_if(match.inputTokens.begin(), match.inputTokens.end(), [](const auto& token) -> bool {
             return token < 0;
           }) == match.inputTokens.end();
  }

  std::pair<size_t, std::vector<TokenID>> nextBestInputAndTokensToTry(
      const Match& incompleteMatch, const std::vector<AtomsVector>& partiallyMatchedInputs) const {
    int64_t nextInputIdx = -1;
    std::vector<TokenID> nextTokensToTry;

    // For each input, we will see how many tokens in the hypergraph contain atoms appearing in this input.
    // The fewer there are, the less branching we will have to do.
    for (size_t i = 0; i < partiallyMatchedInputs.size(); ++i) {
      if (incompleteMatch.inputTokens[i] != -1) continue;

      std::unordered_set<Atom> appearingAtoms;
      bool allAtomsArePatterns = true;
      for (const auto atom : partiallyMatchedInputs[i]) {
        if (atom >= 0) {
          appearingAtoms.insert(atom);
          allAtomsArePatterns = false;
        }
      }

      // this input does not have any specific atom references,
      // there is nothing we can do unless we want to enumerate the entire set
      if (allAtomsArePatterns) continue;

      // For each token, we will count how many of the input atoms appear in it.
      // We will then only use tokens that have all the required atoms.
      std::unordered_map<TokenID, uint64_t> inputAtomsCountByToken;
      for (const auto atom : appearingAtoms) {
        for (const auto token : atomsIndex_.tokensContainingAtom(atom)) {
          inputAtomsCountByToken[token]++;
        }
      }

      // Here we will collect all tokens that contain all the required atoms.
      std::vector<TokenID> potentialTokens;
      for (const auto& tokenAndCount : inputAtomsCountByToken) {
        if (tokenAndCount.second == appearingAtoms.size()) {
          potentialTokens.push_back(tokenAndCount.first);
        }
      }

      // If there are fewer tokens, that is what we'll want to try first.
      // Note, if there are zero matching tokens, it means the match is not possible, because none of the tokens contain
      // all the atoms needed.
      if (nextInputIdx == -1 || potentialTokens.size() < nextTokensToTry.size()) {
        nextTokensToTry = potentialTokens;
        nextInputIdx = static_cast<int64_t>(i);
      }
    }

    if (nextInputIdx == -1) {
      // We could not find any potential inputs, which means, all inputs not already matched are fully patterns,
      // and don't have any specific atom references.
      // That implies rule inputs do not form a connected hypergraph, which is not supported at the moment,
      // and would require custom logic to implement efficiently.
      setCurrentErrorIfNone(DisconnectedInputs);
      return {{}, {}};
    } else {
      return {nextInputIdx, nextTokensToTry};
    }
  }

  bool matchAny() { return !orderingSpec_.empty() && orderingSpec_.back().first == OrderingFunction::Any; }

  // This should be called every time matches are updated.
  void chooseNextMatch() {
    if (empty()) return;
    const auto& allPossibleMatches = matchQueue_.begin()->second.second;
    if (matchAny()) {
      nextMatch_ = allPossibleMatches.front();
    } else {
      auto distribution = std::uniform_int_distribution<size_t>(0, allPossibleMatches.size() - 1);
      nextMatch_ = allPossibleMatches[distribution(randomGenerator_)];
    }
  }

  // Ordering spec that is used in newMatches_ set.
  static OrderingSpec newMatchesOrderingSpec(const OrderingSpec& orderingSpec) {
    // newMatches_ is used for deduplication so its contents should be arranged by the input set
    OrderingSpec newMatchesOrderingSpec = {{OrderingFunction::SortedInputTokenIndices, OrderingDirection::Normal}};
    // We expect the smallest match (according to the user specified spec) to be selected as a canonical
    // one, so we then sort by the user specification
    newMatchesOrderingSpec.insert(newMatchesOrderingSpec.end(), orderingSpec.begin(), orderingSpec.end());
    // Finally, we need to ensure the sorting is deterministic
    newMatchesOrderingSpec.push_back({OrderingFunction::InputTokenIndices, OrderingDirection::Normal});
    newMatchesOrderingSpec.push_back({OrderingFunction::RuleIndex, OrderingDirection::Normal});
    return newMatchesOrderingSpec;
  }

  // Look through matches in newMatches_, and delete the duplicates.
  // The copy remaining must be the smallest according to orderingSpec_
  void removeIdenticalMatches(const std::function<bool()>& abortRequested) {
    std::unordered_set<TokenID> currentInputsSet;
    std::vector<MatchPtr> addedSameInputMatches;
    for (auto newMatchIt = newMatches_.begin(); newMatchIt != newMatches_.end();) {
      if (!sameInputSet(*newMatchIt, currentInputsSet)) {
        // matches are ordered by their input sets, so if it's different, a batch with the new inputs is starting.
        currentInputsSet.clear();
        currentInputsSet.insert((*newMatchIt)->inputTokens.begin(), (*newMatchIt)->inputTokens.end());
        addedSameInputMatches.clear();
      }

      bool matchAppearedBefore = false;
      for (const auto& addedMatch : addedSameInputMatches) {
        if (sameOutcomeAssumingSameInputs(*newMatchIt, addedMatch, abortRequested)) {
          matchAppearedBefore = true;
        }
        if (getCurrentError() != None) {
          return;
        }
      }
      if (matchAppearedBefore) {
        newMatchIt = newMatches_.erase(newMatchIt);
      } else {  // same input set, but a different outcome
        addedSameInputMatches.emplace_back(*newMatchIt);
        ++newMatchIt;
      }
    }
  }

  // Checks if the input token IDs in the match are the same as referenceInputTokens
  static bool sameInputSet(const MatchPtr& match, const std::unordered_set<TokenID>& referenceInputTokens) {
    if (match->inputTokens.size() != referenceInputTokens.size()) return false;
    for (const auto& input : match->inputTokens) {
      if (!referenceInputTokens.count(input)) {  // note, token IDs in a match never repeat
        return false;
      }
    }
    return true;
  }

  // Checks that the outputs created by the two matches are isomorphic
  bool sameOutcomeAssumingSameInputs(const MatchPtr& firstMatch,
                                     const MatchPtr& secondMatch,
                                     const std::function<bool()>& abortRequested) const {
    const auto firstOutputs = matchOutputAtomsVectors(firstMatch);
    const auto secondOutput = matchOutputAtomsVectors(secondMatch);
    return isomorphic(firstOutputs, secondOutput, abortRequested);
  }

  // Uses HypergraphMatcher itself to determine if two hypergraphs are isomorphic.
  // Isomorphism in this case refers to a renaming of *pattern* (negative) atoms in one of the hypergraphs to
  // make it identical to the other one. Positive atoms are not attempted to be renamed.
  // Thus, for example, {{-1, -2}, {-2, -3}} is isomorphic to {{-3, -4}, {-5, -3}},
  // but {{1, -2}, {-2, 3}} is not isomorphic to {{3, -2}, {-2, 1}}.
  static bool isomorphic(const std::vector<AtomsVector>& firstHypergraph,
                         const std::vector<AtomsVector>& secondHypergraph,
                         const std::function<bool()>& abortRequested) {
    if (firstHypergraph.size() != secondHypergraph.size()) return false;
    if (firstHypergraph.size() == 0) return true;

    // HypergraphMatcher does not support disconnected rules, so append the same atom to each token to ensure
    // connectivity. The atom here is just an arbitrary large number, which is unlikely to be reached.
    constexpr Atom connectingAtom = 943106676560858694;

    // We will use the same hypergraph as an input to a rule
    const std::vector<Rule> rules = {
        {appendAtomToEveryToken(firstHypergraph, connectingAtom), {}, EventSelectionFunction::All}};

    // And the second hypergraph as an initial state (with patterns instantiated)
    // If the two hypergraphs are isomorphic, the rule will match. Note, it cannot match to a subhypergraph because the
    // number of tokens (hyperedges) is the same, and multiple parts of the rule input cannot match to the same token.
    auto connectedSecondHypergraph = appendAtomToEveryToken(secondHypergraph, connectingAtom);
    instantiatePatternAtoms(&connectedSecondHypergraph);
    const GetAtomsVectorFunc getAtomsVector =
        [&connectedSecondHypergraph](const TokenID& tokenID) -> const AtomsVector& {
      return connectedSecondHypergraph.at(tokenID);
    };

    // We don't need this function, but we need to pass something.
    const GetTokenSeparationFunc getTokenSeparation = [](const TokenID&, const TokenID&) -> SeparationType {
      return SeparationType::Unknown;
    };

    AtomsIndex atomsIndex(getAtomsVector);
    std::vector<TokenID> allTokenIDs(firstHypergraph.size());
    for (TokenID i = 0; i < static_cast<TokenID>(firstHypergraph.size()); ++i) {
      allTokenIDs.emplace_back(i);
    }
    atomsIndex.addTokens(allTokenIDs);

    HypergraphMatcher matcher(rules, &atomsIndex, getAtomsVector, getTokenSeparation, {}, EventDeduplication::None);
    // We only need to pass one token because any token will need to be included in the match.
    matcher.addMatchesInvolvingTokens({0}, abortRequested);
    return !matcher.empty();
  }

  // Finds the largest atom in a set of tokens
  static Atom largestAtom(const std::vector<AtomsVector>& set) {
    Atom result = std::numeric_limits<Atom>::min();
    for (const auto& token : set) {
      result = std::max(result, *std::max_element(token.begin(), token.end()));
    }
    return result;
  }

  // Appends the same specified atom to every token in the given set
  static std::vector<AtomsVector> appendAtomToEveryToken(const std::vector<AtomsVector>& set, const Atom atom) {
    auto result = set;
    for (auto& token : result) {
      token.emplace_back(atom);
    }
    return result;
  }

  // Selects names and renames all pattern (negative) atoms in a given set
  static void instantiatePatternAtoms(std::vector<AtomsVector>* set) {
    Atom maxAtom = largestAtom(*set);
    std::unordered_map<Atom, Atom> patternToAtom;
    for (auto& token : *set) {
      for (auto& atom : token) {
        if (atom < 0) {
          if (!patternToAtom.count(atom)) {
            patternToAtom[atom] = ++maxAtom;
          }
          atom = patternToAtom[atom];
        }
      }
    }
  }

  // Returns the result of applying a rule to a set of input tokens.
  // New atoms are not named and are left as patterns.
  static std::vector<AtomsVector> outputAtomsVectors(const Rule& rule, const std::vector<AtomsVector>& inputTokens) {
    auto explicitRuleOutputs = rule.outputs;
    substituteMissingAtomsIfPossible(rule.inputs, inputTokens, &explicitRuleOutputs);
    return explicitRuleOutputs;
  }

  // Infers atom names by comparing referenceTokens and referencePattern, and then replaces the infered atoms in place
  // of patterns in tokensToInstantiate.
  static bool substituteMissingAtomsIfPossible(const std::vector<AtomsVector>& referencePattern,
                                               const std::vector<AtomsVector>& referenceTokens,
                                               std::vector<AtomsVector>* tokensToInstantiate = nullptr) {
    if (referencePattern.size() != referenceTokens.size()) return false;

    std::unordered_map<Atom, Atom> match;
    for (size_t i = 0; i < referencePattern.size(); ++i) {
      if (!substituteMissingAtomsIfPossible(referencePattern[i], referenceTokens[i], &match)) return false;
    }
    instantiateTokens(tokensToInstantiate, match);
    return true;
  }

  static bool substituteMissingAtomsIfPossible(const AtomsVector& pattern,
                                               const AtomsVector& patternMatch,
                                               std::vector<AtomsVector>* tokensToInstantiate = nullptr) {
    std::unordered_map<Atom, Atom> match;
    if (!substituteMissingAtomsIfPossible(pattern, patternMatch, &match)) return false;
    instantiateTokens(tokensToInstantiate, match);
    return true;
  }

  static bool substituteMissingAtomsIfPossible(const AtomsVector& pattern,
                                               const AtomsVector& patternMatch,
                                               std::unordered_map<Atom, Atom>* matchMap) {
    auto& match = *matchMap;
    if (pattern.size() != patternMatch.size()) return false;
    for (size_t j = 0; j < pattern.size(); ++j) {
      const auto matchIterator = match.find(pattern[j]);
      const Atom inputAtom = matchIterator != match.end() ? matchIterator->second : pattern[j];
      if (inputAtom < 0) {  // pattern
        match[inputAtom] = patternMatch[j];
      } else if (inputAtom != patternMatch[j]) {  // explicit atom ID
        return false;
      }
    }
    return true;
  }

  static void instantiateTokens(std::vector<AtomsVector>* tokensToInstantiate,
                                const std::unordered_map<Atom, Atom>& match) {
    if (tokensToInstantiate) {
      for (auto& atomsVectorToReplace : *tokensToInstantiate) {
        for (auto& atomToReplace : atomsVectorToReplace) {
          const auto matchIterator = match.find(atomToReplace);
          if (matchIterator != match.end()) {
            atomToReplace = matchIterator->second;
          }
        }
      }
    }
  }
};

HypergraphMatcher::HypergraphMatcher(const std::vector<Rule>& rules,
                                     AtomsIndex* atomsIndex,
                                     const GetAtomsVectorFunc& getAtomsVector,
                                     const GetTokenSeparationFunc& getTokenSeparation,
                                     const OrderingSpec& orderingSpec,
                                     const EventDeduplication& eventDeduplication,
                                     const unsigned int randomSeed)
    : implementation_(std::make_shared<Implementation>(
          rules, atomsIndex, getAtomsVector, getTokenSeparation, orderingSpec, eventDeduplication, randomSeed)) {}

void HypergraphMatcher::addMatchesInvolvingTokens(const std::vector<TokenID>& tokenIDs,
                                                  const std::function<bool()>& shouldAbort) {
  implementation_->addMatchesInvolvingTokens(tokenIDs, shouldAbort);
}

void HypergraphMatcher::removeMatchesInvolvingTokens(const std::vector<TokenID>& tokenIDs) {
  implementation_->removeMatchesInvolvingTokens(tokenIDs);
}

void HypergraphMatcher::deleteMatch(const MatchPtr matchPtr) { implementation_->deleteMatch(matchPtr); }

bool HypergraphMatcher::empty() const { return implementation_->empty(); }

MatchPtr HypergraphMatcher::nextMatch() const { return implementation_->nextMatch(); }

std::vector<MatchPtr> HypergraphMatcher::allMatches() const { return implementation_->allMatches(); }

std::vector<AtomsVector> HypergraphMatcher::matchInputAtomsVectors(const MatchPtr& match) const {
  return implementation_->matchInputAtomsVectors(match);
}

std::vector<AtomsVector> HypergraphMatcher::matchOutputAtomsVectors(const MatchPtr& match) const {
  return implementation_->matchOutputAtomsVectors(match);
}

}  // namespace SetReplace
