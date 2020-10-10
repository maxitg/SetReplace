#include "Match.hpp"

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

namespace SetReplace {
class MatchComparator {
 private:
  const Matcher::OrderingSpec orderingSpec_;

  template <typename T>
  static int compare(T a, T b) {
    return a < b ? -1 : static_cast<int>(a > b);
  }

 public:
  explicit MatchComparator(Matcher::OrderingSpec orderingSpec) : orderingSpec_(std::move(orderingSpec)) {}

  bool operator()(const MatchPtr& a, const MatchPtr& b) const {
    for (const auto& ordering : orderingSpec_) {
      int comparison = compare(a, b, ordering.first);
      if (comparison != 0) {
        switch (ordering.second) {
          case Matcher::OrderingDirection::Normal:
            break;
          case Matcher::OrderingDirection::Reverse:
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

  static int compare(const MatchPtr& a, const MatchPtr& b, const Matcher::OrderingFunction& ordering) {
    switch (ordering) {
      case Matcher::OrderingFunction::SortedExpressionIDs:
        return compareSortedIDs(a, b, false);

      case Matcher::OrderingFunction::ReverseSortedExpressionIDs:
        return compareSortedIDs(a, b, true);

      case Matcher::OrderingFunction::ExpressionIDs:
        return compareUnsortedIDs(a, b);

      case Matcher::OrderingFunction::RuleIndex:
        return compare(a->rule, b->rule);

      default:
        return 0;  // throw is called in constructor of Matcher::Implementation
    }
  }

  static int compareVectors(const std::vector<ExpressionID>& first, const std::vector<ExpressionID>& second) {
    const auto mismatchingIterators = std::mismatch(first.begin(), first.end(), second.begin(), second.end());
    if (mismatchingIterators.first != first.end() && mismatchingIterators.second != second.end()) {
      return compare(*mismatchingIterators.first, *mismatchingIterators.second);
    } else {
      return compare(first.size(), second.size());
    }
  }

  static int compareSortedIDs(const MatchPtr& a, const MatchPtr& b, const bool reverseOrder) {
    std::vector<ExpressionID> aExpressions(a->inputExpressions.begin(), a->inputExpressions.end());
    std::vector<ExpressionID> bExpressions(b->inputExpressions.begin(), b->inputExpressions.end());

    if (!reverseOrder) {
      std::sort(aExpressions.begin(), aExpressions.end(), std::less<>());
      std::sort(bExpressions.begin(), bExpressions.end(), std::less<>());
    } else {
      std::sort(aExpressions.begin(), aExpressions.end(), std::greater<>());
      std::sort(bExpressions.begin(), bExpressions.end(), std::greater<>());
    }
    return compareVectors(aExpressions, bExpressions);
  }

  static int compareUnsortedIDs(const MatchPtr& a, const MatchPtr& b) {
    return compareVectors(a->inputExpressions, b->inputExpressions);
  }
};

// Hashes the values of the matches, not the pointer itself.
class MatchHasher {
 public:
  size_t operator()(const MatchPtr& ptr) const {
    std::size_t result = 0;
    hash_combine(&result, ptr->rule);
    for (const auto expression : ptr->inputExpressions) {
      hash_combine(&result, expression);
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
    if (a->rule != b->rule || a->inputExpressions.size() != b->inputExpressions.size()) {
      return false;
    }

    const auto mismatchedIterators = std::mismatch(
        a->inputExpressions.begin(), a->inputExpressions.end(), b->inputExpressions.begin(), b->inputExpressions.end());
    return mismatchedIterators.first == a->inputExpressions.end() &&
           mismatchedIterators.second == b->inputExpressions.end();
  }
};

class Matcher::Implementation {
 private:
  const std::vector<Rule>& rules_;
  AtomsIndex& atomsIndex_;
  const GetAtomsVectorFunc getAtomsVector_;
  const GetExpressionsSeparationFunc getExpressionsSeparation_;

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
  std::unordered_map<ExpressionID, std::unordered_set<MatchPtr, MatchHasher, MatchEquality>> expressionToMatches_;

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
                 GetExpressionsSeparationFunc getExpressionsSeparation,
                 const OrderingSpec& orderingSpec,
                 const EventDeduplication& eventDeduplication,
                 const unsigned int randomSeed)
      : rules_(rules),
        atomsIndex_(*atomsIndex),
        getAtomsVector_(std::move(getAtomsVector)),
        getExpressionsSeparation_(std::move(getExpressionsSeparation)),
        matchQueue_(MatchComparator(orderingSpec)),
        randomGenerator_(randomSeed),
        eventDeduplication_(eventDeduplication),
        newMatches_(MatchComparator(newMatchesOrderingSpec(orderingSpec))),
        currentError(None) {
    for (const auto& ordering : orderingSpec) {
      if (ordering.first < OrderingFunction::First || ordering.first >= OrderingFunction::Last) {
        throw Matcher::Error::InvalidOrderingFunction;
      } else if (ordering.second < OrderingDirection::First || ordering.second >= OrderingDirection::Last) {
        throw Matcher::Error::InvalidOrderingDirection;
      }
    }
  }

  void addMatchesInvolvingExpressions(const std::vector<ExpressionID>& expressionIDs,
                                      const std::function<bool()>& abortRequested) {
    // If one thread errors, alert other threads with this function
    const std::function<bool()> shouldAbort = [this, &abortRequested]() {
      return getCurrentError() != None || abortRequested();
    };

    // Only create threads if there is more than one rule and hardware has more than one thread
    const uint64_t numHardwareThreads = std::thread::hardware_concurrency();  // returns 0 if unknown
    const uint64_t numThreadsToUse = rules_.size() > 1 && numHardwareThreads > 1
                                         ? std::min(static_cast<uint64_t>(rules_.size()), numHardwareThreads)
                                         : 0;

    auto addMatchesForRuleRange = [=](uint64_t start) {
      for (uint64_t i = start; i < static_cast<uint64_t>(rules_.size()); i += numThreadsToUse) {
        addMatchesForRule(expressionIDs, i, shouldAbort);
      }
    };

    if (numThreadsToUse > 0) {
      // Multi-threaded path
      std::vector<std::thread> threads(numThreadsToUse);
      for (uint64_t i = 0; i < numThreadsToUse; ++i) {
        threads[i] = std::thread(addMatchesForRuleRange, i);
      }
      for (auto& thread : threads) {
        thread.join();
      }
    } else {
      // Single-threaded path
      for (size_t i = 0; i < rules_.size(); ++i) {
        addMatchesForRule(expressionIDs, i, shouldAbort);
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

    chooseNextMatch();
  }

  // Note, deletion changes the ordering of allMatchIterators_, therefore
  // deletion should be done in deterministic order, otherwise, the random replacements will not be deterministic
  void removeMatchesInvolvingExpressions(const std::vector<ExpressionID>& expressionIDs) {
    // do not use unordered_set, as it make order undeterministic
    // any ordering spec works here, as long as it's complete.
    OrderingSpec fullOrderingSpec = {{OrderingFunction::ExpressionIDs, OrderingDirection::Normal},
                                     {OrderingFunction::RuleIndex, OrderingDirection::Normal}};
    std::set<MatchPtr, MatchComparator> matchesToDelete((MatchComparator(fullOrderingSpec)));

    for (const auto& expression : expressionIDs) {
      const auto& matches = expressionToMatches_[expression];
      matchesToDelete.insert(matches.begin(), matches.end());
    }

    for (const auto& match : matchesToDelete) {
      deleteMatch(match);
    }

    chooseNextMatch();
  }

  void deleteMatch(const MatchPtr& matchPtr) {
    allMatches_.erase(matchPtr);

    const auto& expressions = matchPtr->inputExpressions;
    for (const auto expression : expressions) {
      expressionToMatches_[expression].erase(matchPtr);
      if (expressionToMatches_[expression].empty()) expressionToMatches_.erase(expression);
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
    std::vector<AtomsVector> inputExpressions;
    inputExpressions.reserve(match->inputExpressions.size());
    for (const auto& expressionID : match->inputExpressions) {
      inputExpressions.emplace_back(getAtomsVector_(expressionID));
    }
    return inputExpressions;
  }

  std::vector<AtomsVector> matchOutputAtomsVectors(const MatchPtr& match) const {
    return outputAtomsVectors(rules_.at(match->rule), matchInputAtomsVectors(match));
  }

 private:
  void addMatchesForRule(const std::vector<ExpressionID>& expressionIDs,
                         const RuleID& ruleID,
                         const std::function<bool()>& shouldAbort) {
    const auto& ruleInputExpressions = rules_[ruleID].inputs;
    for (size_t i = 0; i < ruleInputExpressions.size(); ++i) {
      const Match emptyMatch{ruleID, std::vector<ExpressionID>(ruleInputExpressions.size(), -1)};
      completeMatchesStartingWithInput(
          emptyMatch, ruleInputExpressions, rules_[ruleID].eventSelectionFunction, i, expressionIDs, shouldAbort);
    }
  }

  void completeMatchesStartingWithInput(const Match& incompleteMatch,
                                        const std::vector<AtomsVector>& partiallyMatchedInputs,
                                        const EventSelectionFunction eventSelectionFunction,
                                        const size_t nextInputIdx,
                                        const std::vector<ExpressionID>& potentialExpressionIDs,
                                        const std::function<bool()>& shouldAbort) {
    for (const auto expressionID : potentialExpressionIDs) {
      if (getCurrentError() != None) {
        return;
      }
      if (isExpressionUnused(incompleteMatch, expressionID)) {
        attemptMatchExpressionToInput(
            incompleteMatch, partiallyMatchedInputs, eventSelectionFunction, nextInputIdx, expressionID, shouldAbort);
      }
    }
  }

  static bool isExpressionUnused(const Match& match, const ExpressionID expressionID) {
    return std::find(match.inputExpressions.begin(), match.inputExpressions.end(), expressionID) ==
           match.inputExpressions.end();
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

  void attemptMatchExpressionToInput(const Match& incompleteMatch,
                                     const std::vector<AtomsVector>& partiallyMatchedInputs,
                                     const EventSelectionFunction eventSelectionFunction,
                                     const size_t nextInputIdx,
                                     const ExpressionID potentialExpressionID,
                                     const std::function<bool()>& shouldAbort) {
    // If WL wants to abort, abort
    if (shouldAbort()) {
      setCurrentErrorIfNone(Error::Aborted);
      return;
    }

    const auto& input = partiallyMatchedInputs[nextInputIdx];
    const auto& expressionAtoms = getAtomsVector_(potentialExpressionID);

    // edges (expressions) of different sizes, cannot match
    if (input.size() != expressionAtoms.size()) {
      return;
    }

    Match newMatch = incompleteMatch;
    newMatch.inputExpressions[nextInputIdx] = potentialExpressionID;

    auto newInputs = partiallyMatchedInputs;
    if (!substituteMissingAtomsIfPossible(input, expressionAtoms, &newInputs)) {
      return;
    }
    if (eventSelectionFunction == EventSelectionFunction::Spacelike &&
        !isSpacelikeSeparated(potentialExpressionID, newMatch.inputExpressions)) {
      return;
    }

    if (isMatchComplete(newMatch)) {
      insertMatch(newMatch);
      return;
    }

    const auto nextInputIdxAndCandidateExpressions = nextBestInputAndExpressionsToTry(newMatch, newInputs);
    completeMatchesStartingWithInput(newMatch,
                                     newInputs,
                                     eventSelectionFunction,
                                     nextInputIdxAndCandidateExpressions.first,
                                     nextInputIdxAndCandidateExpressions.second,
                                     shouldAbort);
  }

  bool isSpacelikeSeparated(const ExpressionID newExpression, const std::vector<ExpressionID>& previousExpressions) {
    for (const auto& previousExpression : previousExpressions) {
      if (previousExpression == newExpression || previousExpression < 0) continue;
      const auto separation = getExpressionsSeparation_(previousExpression, newExpression);
      if (separation != SeparationType::Spacelike) {
        return false;
      }
    }

    return true;
  }

  void insertMatch(const Match& newMatch) {
    // careful, don't create different pointers to the same match!
    const auto matchPtr = std::make_shared<Match>(newMatch);

    std::lock_guard<std::mutex> lock(matchMutex);

    if (!allMatches_.insert(matchPtr).second) {
      return;
    }

    const auto bucketIt = matchQueue_.emplace(matchPtr, Bucket()).first;  // works because comparison is smart
    auto& bucket = bucketIt->second;
    if (!bucket.first.count(matchPtr)) {  // works because hashing is smart
      bucket.second.push_back(matchPtr);
      bucket.first[matchPtr] = bucket.second.size() - 1;

      const auto& expressions = matchPtr->inputExpressions;
      for (const auto expression : expressions) {
        expressionToMatches_[expression].insert(matchPtr);
      }
    }

    if (eventDeduplication_ == EventDeduplication::SameInputSetIsomorphicOutputs) {
      newMatches_.insert(matchPtr);
    }
  }

  static bool isMatchComplete(const Match& match) {
    return std::find_if(match.inputExpressions.begin(), match.inputExpressions.end(), [](const auto& ex) -> bool {
             return ex < 0;
           }) == match.inputExpressions.end();
  }

  std::pair<size_t, std::vector<ExpressionID>> nextBestInputAndExpressionsToTry(
      const Match& incompleteMatch, const std::vector<AtomsVector>& partiallyMatchedInputs) const {
    int64_t nextInputIdx = -1;
    std::vector<ExpressionID> nextExpressionsToTry;

    // For each input, we will see how many expressions in the set contain atoms appearing in this input.
    // The fewer there are, the less branching we will have to do.
    for (size_t i = 0; i < partiallyMatchedInputs.size(); ++i) {
      if (incompleteMatch.inputExpressions[i] != -1) continue;

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

      // For each expression, we will count how many of the input atoms appear in it.
      // We will then only use expressions that have all the required atoms.
      std::unordered_map<ExpressionID, uint64_t> inputAtomsCountByExpression;
      for (const auto atom : appearingAtoms) {
        for (const auto expression : atomsIndex_.expressionsContainingAtom(atom)) {
          inputAtomsCountByExpression[expression]++;
        }
      }

      // Here we will collect all expressions that contain all the required atoms.
      std::vector<ExpressionID> potentialExpressions;
      for (const auto& expressionAndCount : inputAtomsCountByExpression) {
        if (expressionAndCount.second == appearingAtoms.size()) {
          potentialExpressions.push_back(expressionAndCount.first);
        }
      }

      // If there are fewer expressions, that is what we'll want to try first.
      // Note, if there are zero matching expressions, it means the match is not possible, because none of the
      // expressions contain all the atoms needed.
      if (nextInputIdx == -1 || potentialExpressions.size() < nextExpressionsToTry.size()) {
        nextExpressionsToTry = potentialExpressions;
        nextInputIdx = static_cast<int64_t>(i);
      }
    }

    if (nextInputIdx == -1) {
      // We could not find any potential inputs, which means, all inputs not already matched are fully patterns,
      // and don't have any specific atom references.
      // That implies rule inputs are not a connected graph, which is not supported at the moment,
      // and would require custom logic to implement efficiently.
      setCurrentErrorIfNone(DisconnectedInputs);
      return {{}, {}};
    } else {
      return {nextInputIdx, nextExpressionsToTry};
    }
  }

  // This should be called every time matches are updated.
  void chooseNextMatch() {
    if (empty()) return;
    const auto& allPossibleMatches = matchQueue_.begin()->second.second;
    auto distribution = std::uniform_int_distribution<size_t>(0, allPossibleMatches.size() - 1);
    nextMatch_ = allPossibleMatches[distribution(randomGenerator_)];
  }

  // Ordering spec that is used in newMatches_ set.
  static OrderingSpec newMatchesOrderingSpec(const OrderingSpec& orderingSpec) {
    // newMatches_ is used for deduplication so its contents should be arranged by the input set
    OrderingSpec newMatchesOrderingSpec = {{OrderingFunction::SortedExpressionIDs, OrderingDirection::Normal}};
    // We expect the smallest match (according to the user specified spec) to be selected as a canonical
    // one, so we then sort by the user specification
    newMatchesOrderingSpec.insert(newMatchesOrderingSpec.end(), orderingSpec.begin(), orderingSpec.end());
    // Finally, we need to ensure the sorting is deterministic
    newMatchesOrderingSpec.push_back({OrderingFunction::ExpressionIDs, OrderingDirection::Normal});
    newMatchesOrderingSpec.push_back({OrderingFunction::RuleIndex, OrderingDirection::Normal});
    return newMatchesOrderingSpec;
  }

  // Look through matches in newMatches_, and delete the duplicates.
  // The copy remaining must be the smallest according to orderingSpec_
  void removeIdenticalMatches(const std::function<bool()>& abortRequested) {
    std::unordered_set<ExpressionID> currentInputsSet;
    std::vector<MatchPtr> addedSameInputMatches;
    for (const auto& newMatch : newMatches_) {
      if (!sameInputSet(newMatch, currentInputsSet)) {
        // matches are ordered by their input sets, so if it's different, a batch with the new inputs is starting.
        currentInputsSet.clear();
        currentInputsSet.insert(newMatch->inputExpressions.begin(), newMatch->inputExpressions.end());
        addedSameInputMatches.clear();
      }

      bool matchAppearedBefore = false;
      for (const auto& addedMatch : addedSameInputMatches) {
        if (sameOutcomeAssumingSameInputs(newMatch, addedMatch, abortRequested)) {
          matchAppearedBefore = true;
        }
        if (getCurrentError() != None) {
          return;
        }
      }
      if (matchAppearedBefore) {
        deleteMatch(newMatch);
      } else {  // same input set, but a different outcome
        addedSameInputMatches.emplace_back(newMatch);
      }
    }
    newMatches_.clear();
  }

  // Checks if the input expression IDs in match are the same as referenceInputExpressions
  static bool sameInputSet(const MatchPtr& match, const std::unordered_set<ExpressionID>& referenceInputExpressions) {
    if (match->inputExpressions.size() != referenceInputExpressions.size()) return false;
    for (const auto& input : match->inputExpressions) {
      if (!referenceInputExpressions.count(input)) {  // note, expression IDs in a match never repeat
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

  // Uses Matcher itself to determine if two sets are isomorphic.
  // Isomorphism in this case refers to a renaming of *pattern* (negative) atoms in one of the sets to
  // make it identical to the other one. Positive atoms are not attempted to be renamed.
  // Thus, for example, {{-1, -2}, {-2, -3}} is isomorphic to {{-3, -4}, {-5, -3}},
  // but {{1, -2}, {-2, 3}} is not isomorphic to {{3, -2}, {-2, 1}}.
  static bool isomorphic(const std::vector<AtomsVector>& firstSet,
                         const std::vector<AtomsVector>& secondSet,
                         const std::function<bool()>& abortRequested) {
    if (firstSet.size() != secondSet.size()) return false;
    if (firstSet.size() == 0) return true;

    // Matcher does not support disconnected rules, so append the same atom to each expression to ensure connectivity
    // The atom here is just an arbitrary large number
    constexpr Atom connectingAtom = 943106676560858694;

    // We will use the same set as an input to a rule
    const std::vector<Rule> rules = {
        {appendAtomToEveryExpression(firstSet, connectingAtom), {}, EventSelectionFunction::All}};

    // And the second set as an initial condition (with patterns instantiated)
    // If the two sets are isomorphic, the rule will match. Note, it cannot match to a subset because the number of
    // expressions is the same, and multiple parts of the rule input cannot match to the same expression.
    auto connectedSecondSet = appendAtomToEveryExpression(secondSet, connectingAtom);
    instantiatePatternAtoms(&connectedSecondSet);
    const GetAtomsVectorFunc getAtomsVector =
        [&connectedSecondSet](const ExpressionID& expressionID) -> const AtomsVector& {
      return connectedSecondSet.at(expressionID);
    };

    // We don't need this function, but we need to pass something.
    const GetExpressionsSeparationFunc getExpressionsSeparation =
        [](const ExpressionID&, const ExpressionID&) -> SeparationType { return SeparationType::Unknown; };

    AtomsIndex atomsIndex(getAtomsVector);
    std::vector<ExpressionID> allExpressionIDs(firstSet.size());
    for (ExpressionID i = 0; i < static_cast<ExpressionID>(firstSet.size()); ++i) {
      allExpressionIDs.emplace_back(i);
    }
    atomsIndex.addExpressions(allExpressionIDs);

    Matcher matcher(rules, &atomsIndex, getAtomsVector, getExpressionsSeparation, {}, EventDeduplication::None);
    // We only need to pass one expression because any expression will need to be included in the match.
    matcher.addMatchesInvolvingExpressions({0}, abortRequested);
    return !matcher.empty();
  }

  // Finds the largest atom in a set of expressions
  static Atom largestAtom(const std::vector<AtomsVector>& set) {
    Atom result = std::numeric_limits<Atom>::min();
    for (const auto& expression : set) {
      result = std::max(result, *std::max_element(expression.begin(), expression.end()));
    }
    return result;
  }

  // Appends the same specified atom to every expression in the given set
  static std::vector<AtomsVector> appendAtomToEveryExpression(const std::vector<AtomsVector>& set, const Atom atom) {
    auto result = set;
    for (auto& expression : result) {
      expression.emplace_back(atom);
    }
    return result;
  }

  // Selects names and renames all pattern (negative) atoms in a given set
  static void instantiatePatternAtoms(std::vector<AtomsVector>* set) {
    Atom maxAtom = largestAtom(*set);
    std::unordered_map<Atom, Atom> patternToAtom;
    for (auto& expression : *set) {
      for (auto& atom : expression) {
        if (atom < 0) {
          if (!patternToAtom.count(atom)) {
            patternToAtom[atom] = ++maxAtom;
          }
          atom = patternToAtom[atom];
        }
      }
    }
  }

  // Returns the result of applying a rule to a set of input expressions.
  // New atoms are not named and are left as patterns.
  static std::vector<AtomsVector> outputAtomsVectors(const Rule& rule,
                                                     const std::vector<AtomsVector>& inputExpressions) {
    auto explicitRuleOutputs = rule.outputs;
    substituteMissingAtomsIfPossible(rule.inputs, inputExpressions, &explicitRuleOutputs);
    return explicitRuleOutputs;
  }

  // Infers atom names by comparing referenceExpressions and referencePattern, and then replaces the infered atoms in
  // place of patterns in expressionsToInstantiate.
  static bool substituteMissingAtomsIfPossible(const std::vector<AtomsVector>& referencePattern,
                                               const std::vector<AtomsVector>& referenceExpressions,
                                               std::vector<AtomsVector>* expressionsToInstantiate = nullptr) {
    if (referencePattern.size() != referenceExpressions.size()) return false;

    std::unordered_map<Atom, Atom> match;
    for (size_t i = 0; i < referencePattern.size(); ++i) {
      if (!substituteMissingAtomsIfPossible(referencePattern[i], referenceExpressions[i], &match)) return false;
    }
    instantiateExpressions(expressionsToInstantiate, match);
    return true;
  }

  static bool substituteMissingAtomsIfPossible(const AtomsVector& pattern,
                                               const AtomsVector& patternMatch,
                                               std::vector<AtomsVector>* expressionsToInstantiate = nullptr) {
    std::unordered_map<Atom, Atom> match;
    if (!substituteMissingAtomsIfPossible(pattern, patternMatch, &match)) return false;
    instantiateExpressions(expressionsToInstantiate, match);
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

  static void instantiateExpressions(std::vector<AtomsVector>* expressionsToInstantiate,
                                     const std::unordered_map<Atom, Atom>& match) {
    if (expressionsToInstantiate) {
      for (auto& atomsVectorToReplace : *expressionsToInstantiate) {
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

Matcher::Matcher(const std::vector<Rule>& rules,
                 AtomsIndex* atomsIndex,
                 const GetAtomsVectorFunc& getAtomsVector,
                 const GetExpressionsSeparationFunc& getExpressionsSeparation,
                 const OrderingSpec& orderingSpec,
                 const EventDeduplication& eventDeduplication,
                 const unsigned int randomSeed)
    : implementation_(std::make_shared<Implementation>(
          rules, atomsIndex, getAtomsVector, getExpressionsSeparation, orderingSpec, eventDeduplication, randomSeed)) {}

void Matcher::addMatchesInvolvingExpressions(const std::vector<ExpressionID>& expressionIDs,
                                             const std::function<bool()>& shouldAbort) {
  implementation_->addMatchesInvolvingExpressions(expressionIDs, shouldAbort);
}

void Matcher::removeMatchesInvolvingExpressions(const std::vector<ExpressionID>& expressionIDs) {
  implementation_->removeMatchesInvolvingExpressions(expressionIDs);
}

void Matcher::deleteMatch(const MatchPtr matchPtr) { implementation_->deleteMatch(matchPtr); }

bool Matcher::empty() const { return implementation_->empty(); }

MatchPtr Matcher::nextMatch() const { return implementation_->nextMatch(); }

std::vector<MatchPtr> Matcher::allMatches() const { return implementation_->allMatches(); }

std::vector<AtomsVector> Matcher::matchInputAtomsVectors(const MatchPtr& match) const {
  return implementation_->matchInputAtomsVectors(match);
}

std::vector<AtomsVector> Matcher::matchOutputAtomsVectors(const MatchPtr& match) const {
  return implementation_->matchOutputAtomsVectors(match);
}

}  // namespace SetReplace
