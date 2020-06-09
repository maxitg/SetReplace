#include "Match.hpp"

#include <algorithm>
#include <atomic>
#include <functional>
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
  const std::function<AtomsVector(ExpressionID)> getAtomsVector_;

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
                 std::function<AtomsVector(ExpressionID)> getAtomsVector,
                 const OrderingSpec& orderingSpec,
                 const unsigned int randomSeed)
      : rules_(rules),
        atomsIndex_(*atomsIndex),
        getAtomsVector_(std::move(getAtomsVector)),
        matchQueue_(MatchComparator(orderingSpec)),
        randomGenerator_(randomSeed),
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

    auto& bucket = matchQueue_[matchPtr];
    const auto bucketIndex = bucket.first.at(matchPtr);
    // O(1) order-non-preserving deletion from a vector
    std::swap(bucket.second[bucketIndex], bucket.second[bucket.second.size() - 1]);
    bucket.first[bucket.second[bucketIndex]] = bucketIndex;
    bucket.first.erase(bucket.second[bucket.second.size() - 1]);
    bucket.second.pop_back();
    if (bucket.first.empty()) matchQueue_.erase(matchPtr);
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

 private:
  void addMatchesForRule(const std::vector<ExpressionID>& expressionIDs,
                         const RuleID& ruleID,
                         const std::function<bool()>& shouldAbort) {
    const auto& ruleInputExpressions = rules_[ruleID].inputs;
    for (size_t i = 0; i < ruleInputExpressions.size(); ++i) {
      const Match emptyMatch{ruleID, std::vector<ExpressionID>(ruleInputExpressions.size(), -1)};
      completeMatchesStartingWithInput(emptyMatch, ruleInputExpressions, i, expressionIDs, shouldAbort);
    }
  }

  void completeMatchesStartingWithInput(const Match& incompleteMatch,
                                        const std::vector<AtomsVector>& partiallyMatchedInputs,
                                        const size_t nextInputIdx,
                                        const std::vector<ExpressionID>& potentialExpressionIDs,
                                        const std::function<bool()>& shouldAbort) {
    for (const auto expressionID : potentialExpressionIDs) {
      if (getCurrentError() != None) {
        return;
      }
      if (isExpressionUnused(incompleteMatch, expressionID)) {
        attemptMatchExpressionToInput(incompleteMatch, partiallyMatchedInputs, nextInputIdx, expressionID, shouldAbort);
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
    if (input.size() != expressionAtoms.size()) return;

    Match newMatch = incompleteMatch;
    newMatch.inputExpressions[nextInputIdx] = potentialExpressionID;

    auto newInputs = partiallyMatchedInputs;
    if (!Matcher::substituteMissingAtomsIfPossible({input}, {expressionAtoms}, &newInputs)) return;

    if (isMatchComplete(newMatch)) {
      insertMatch(newMatch);
      return;
    }

    const auto nextInputIdxAndCandidateExpressions = nextBestInputAndExpressionsToTry(newMatch, newInputs);
    completeMatchesStartingWithInput(newMatch,
                                     newInputs,
                                     nextInputIdxAndCandidateExpressions.first,
                                     nextInputIdxAndCandidateExpressions.second,
                                     shouldAbort);
  }

  void insertMatch(const Match& newMatch) {
    // careful, don't create different pointers to the same match!
    const auto matchPtr = std::make_shared<Match>(newMatch);

    std::lock_guard<std::mutex> lock(matchMutex);

    if (!allMatches_.insert(matchPtr).second) {
      return;
    }

    auto bucketIt = matchQueue_.find(matchPtr);  // works because comparison is smart
    if (bucketIt == matchQueue_.end()) {
      bucketIt = matchQueue_.insert({matchPtr, {{}, {}}}).first;
    }
    auto& bucket = bucketIt->second;
    if (!bucket.first.count(matchPtr)) {  // works because hashing is smart
      bucket.second.push_back(matchPtr);
      bucket.first[matchPtr] = bucket.second.size() - 1;

      const auto& expressions = matchPtr->inputExpressions;
      for (const auto expression : expressions) {
        expressionToMatches_[expression].insert(matchPtr);
      }
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
};

Matcher::Matcher(const std::vector<Rule>& rules,
                 AtomsIndex* atomsIndex,
                 const std::function<AtomsVector(ExpressionID)>& getAtomsVector,
                 const OrderingSpec& orderingSpec,
                 const unsigned int randomSeed)
    : implementation_(std::make_shared<Implementation>(rules, atomsIndex, getAtomsVector, orderingSpec, randomSeed)) {}

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

bool Matcher::substituteMissingAtomsIfPossible(const std::vector<AtomsVector>& inputPatterns,
                                               const std::vector<AtomsVector>& patternMatches,
                                               std::vector<AtomsVector>* atomsToReplace) {
  if (inputPatterns.size() != patternMatches.size()) return false;

  std::unordered_map<Atom, Atom> match;
  for (size_t i = 0; i < inputPatterns.size(); ++i) {
    const auto& pattern = inputPatterns[i];
    const auto& patternMatch = patternMatches[i];
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
  }

  for (auto& atomsVectorToReplace : *atomsToReplace) {
    for (auto& atomToReplace : atomsVectorToReplace) {
      const auto matchIterator = match.find(atomToReplace);
      if (matchIterator != match.end()) {
        atomToReplace = matchIterator->second;
      }
    }
  }
  return true;
}

std::vector<MatchPtr> Matcher::allMatches() const { return implementation_->allMatches(); }
}  // namespace SetReplace
