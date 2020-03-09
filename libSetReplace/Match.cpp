#include "Match.hpp"

#include <algorithm>
#include <map>
#include <random>
#include <unordered_map>

namespace SetReplace {
    class MatchComparator {
    private:
        const Matcher::OrderingSpec orderingSpec_;
        
    public:
        MatchComparator(const Matcher::OrderingSpec& orderingSpec) : orderingSpec_(orderingSpec) {}
        
        bool operator()(const MatchPtr a, const MatchPtr b) const {
            for (const auto& ordering : orderingSpec_) {
                int comparison = compare(a, b, ordering.first);
                if (comparison != 0) {
                    if (ordering.second == Matcher::OrderingDirection::Reverse) comparison = -comparison;
                    return comparison < 0;
                }
            }
            return false;
        }
        
        static int compare(const MatchPtr a, const MatchPtr b, const Matcher::OrderingFunction ordering) {
            switch (ordering) {
                case Matcher::OrderingFunction::SortedExpressionIDs:
                    return compareSortedIDs(a, b, false);
                    
                case Matcher::OrderingFunction::ReverseSortedExpressionIDs:
                    return compareSortedIDs(a, b, true);
                    
                case Matcher::OrderingFunction::ExpressionIDs:
                    return compareUnsortedIDs(a, b);
                    
                case Matcher::OrderingFunction::RuleID:
                    if (a->rule < b->rule) return -1;
                    else if (a->rule > b->rule) return +1;
                    else return 0;
            }
        }
        
        static int compareVectors(const std::vector<ExpressionID>& first, const std::vector<ExpressionID>& second) {
            for (int i = 0; i < std::min(first.size(), second.size()); ++i) {
                if (first[i] < second[i]) return -1;
                else if (first[i] > second[i]) return +1;
            }
            
            if (first.size() < second.size()) return -1;
            else if (first.size() > second.size()) return 1;
            else return 0;
        }
        
        static int compareSortedIDs(const MatchPtr a, const MatchPtr b, const bool reverseOrder) {
            std::vector<ExpressionID> aExpressions = a->inputExpressions;
            std::sort(aExpressions.begin(), aExpressions.end());
            
            std::vector<ExpressionID> bExpressions = b->inputExpressions;
            std::sort(bExpressions.begin(), bExpressions.end());
            
            if (reverseOrder) {
                std::reverse(aExpressions.begin(), aExpressions.end());
                std::reverse(bExpressions.begin(), bExpressions.end());
            }
            return compareVectors(aExpressions, bExpressions);
        }
        
        static int compareUnsortedIDs(const MatchPtr a, const MatchPtr& b) {
            return compareVectors(a->inputExpressions, b->inputExpressions);
        }
    };

    // Hashes the values of the matches, not the pointer itself.
    class MatchHasher {
    public:
        size_t operator()(MatchPtr ptr) const {
            std::size_t result = 0;
            hash_combine(result, ptr->rule);
            for (const auto expression : ptr->inputExpressions) {
                hash_combine(result, expression);
            }
            return result;
        }
        
    private:
        // https://stackoverflow.com/a/2595226
        template <class T>
        static void hash_combine(std::size_t& seed, const T& value) {
            std::hash<T> hasher;
            seed ^= hasher(value) + 0x9e3779b9 + (seed << 6) + (seed >> 2);
        }
    };

    class MatchEquality {
    public:
        size_t operator()(MatchPtr a, MatchPtr b) const {
            if (a->rule != b->rule || a->inputExpressions.size() != b->inputExpressions.size()) return false;
            for (int i = 0; i < a->inputExpressions.size(); ++i) {
                if (a->inputExpressions[i] != b->inputExpressions[i]) return false;
            }
            return true;
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
        using Bucket = std::pair<std::unordered_map<MatchPtr, int, MatchHasher, MatchEquality>, std::vector<MatchPtr>>;
        std::map<MatchPtr, Bucket, MatchComparator> matchQueue_;
        std::unordered_map<ExpressionID, std::unordered_set<MatchPtr, MatchHasher, MatchEquality>> expressionToMatches_;
        
        // A frequent operation here is detection of duplicate matches. Hashing is much faster than searching for
        // duplicates in a std::map, so we separately keep a flat hash table of all matches to speed that up.
        // That's purely an optimization.
        std::unordered_set<MatchPtr, MatchHasher, MatchEquality> allMatches_;
        
        std::mt19937 randomGenerator_;
        MatchPtr nextMatch_;
        
    public:
        Implementation(const std::vector<Rule>& rules,
                       AtomsIndex& atomsIndex,
                       const std::function<AtomsVector(ExpressionID)> getAtomsVector,
                       const OrderingSpec orderingSpec,
                       const unsigned int randomSeed) :
            rules_(rules),
            atomsIndex_(atomsIndex),
            getAtomsVector_(getAtomsVector),
            matchQueue_(orderingSpec),
            randomGenerator_(randomSeed) {}
        
        void addMatchesInvolvingExpressions(const std::vector<ExpressionID>& expressionIDs, const std::function<bool()> shouldAbort) {
            for (int i = 0; i < rules_.size(); ++i) {
                addMatchesForRule(expressionIDs, i, shouldAbort);
            }
            chooseNextMatch();
        }
        
        // Note, deletion changes the ordering of allMatchIterators_, therefore
        // deletion should be done in deterministic order, otherwise, the random replacements will not be deterministic
        void removeMatchesInvolvingExpressions(const std::vector<ExpressionID>& expressionIDs) {
            // do not use unordered_set, as it make order undeterministic
            // any ordering spec works here, as long as it's complete.
            OrderingSpec fullOrderingSpec = {
                {OrderingFunction::ExpressionIDs, OrderingDirection::Normal},
                {OrderingFunction::RuleID, OrderingDirection::Normal}};
            std::set<MatchPtr, MatchComparator> matchesToDelete(fullOrderingSpec);
            
            for (const auto& expression : expressionIDs) {
                const auto& matches = expressionToMatches_[expression];
                for (const auto& matchPtr : matches) {
                    matchesToDelete.insert(matchPtr);
                }
            }
            
            for (const auto& match : matchesToDelete) {
                deleteMatch(match);
            }
            
            chooseNextMatch();
        }
        
        bool empty() const {
            return matchQueue_.empty();
        }
        
        MatchPtr nextMatch() const {
            return nextMatch_;
        }
        
        const std::vector<MatchPtr> allMatches() const {
            std::vector<MatchPtr> result;
            for (const auto& exampleAndBucket : matchQueue_) {
                for (const auto& matchPtr : exampleAndBucket.second.second) {
                    result.push_back(matchPtr);
                }
            }
            return result;
        }
        
    private:
        void addMatchesForRule(const std::vector<ExpressionID>& expressionIDs, const RuleID& ruleID, const std::function<bool()> shouldAbort) {
            for (int i = 0; i < rules_[ruleID].inputs.size(); ++i) {
                Match emptyMatch{ruleID, std::vector<ExpressionID>(rules_[ruleID].inputs.size(), -1)};
                completeMatchesStartingWithInput(emptyMatch, rules_[ruleID].inputs, i, expressionIDs, shouldAbort);
            }
        }
        
        void completeMatchesStartingWithInput(const Match& incompleteMatch,
                                              const std::vector<AtomsVector>& partiallyMatchedInputs,
                                              const int nextInputIdx,
                                              const std::vector<ExpressionID>& potentialExpressionIDs,
                                              const std::function<bool()> shouldAbort) {
            for (const auto expressionID : potentialExpressionIDs) {
                if (isExpressionUnused(incompleteMatch, expressionID)) {
                    attemptMatchExpressionToInput(incompleteMatch, partiallyMatchedInputs, nextInputIdx, expressionID, shouldAbort);
                }
            }
        }
        
        static bool isExpressionUnused(const Match& match, const ExpressionID expressionID) {
            for (int i = 0; i < match.inputExpressions.size(); ++i) {
                if (match.inputExpressions[i] == expressionID) return false;
            }
            return true;
        }
        
        void attemptMatchExpressionToInput(const Match& incompleteMatch,
                                           const std::vector<AtomsVector>& partiallyMatchedInputs,
                                           const int nextInputIdx,
                                           const ExpressionID potentialExpressionID,
                                           const std::function<bool()> shouldAbort) {
            // If WL wants to abort, abort
            if (shouldAbort()) {
                throw Error::Aborted;
            }
            
            const auto& input = partiallyMatchedInputs[nextInputIdx];
            const auto& expressionAtoms = getAtomsVector_(potentialExpressionID);
            
            // edges (expressions) of different sizes, cannot match
            if (input.size() != expressionAtoms.size()) return;
            
            Match newMatch = incompleteMatch;
            newMatch.inputExpressions[nextInputIdx] = potentialExpressionID;
            
            auto newInputs = partiallyMatchedInputs;
            if (!Matcher::substituteMissingAtomsIfPossible({input}, {expressionAtoms}, newInputs)) return;
            
            if (isMatchComplete(newMatch)) {
                insertMatch(newMatch);
                return;
            }
            
            const auto nextInputIdxAndCandidateExpressions = nextBestInputAndExpressionsToTry(newMatch, newInputs);
            if (nextInputIdxAndCandidateExpressions.first >= 0) {
                completeMatchesStartingWithInput(newMatch,
                                                 newInputs,
                                                 nextInputIdxAndCandidateExpressions.first,
                                                 nextInputIdxAndCandidateExpressions.second,
                                                 shouldAbort);
            }
        }
        
        void insertMatch(const Match& newMatch) {
            // careful, don't create different pointers to the same match!
            const auto matchPtr = std::make_shared<Match>(newMatch);
            
            if (allMatches_.count(matchPtr)) {
                return;
            }
            else {
                allMatches_.insert(matchPtr);
            }
            
            auto bucketIt = matchQueue_.find(matchPtr); // works because comparison is smart
            if (bucketIt == matchQueue_.end()) {
                bucketIt = matchQueue_.insert({matchPtr, {{}, {}}}).first;
            }
            auto& bucket = bucketIt->second;
            if (!bucket.first.count(matchPtr)) { // works because hashing is smart
                bucket.second.push_back(matchPtr);
                bucket.first[matchPtr] = static_cast<int>(bucket.second.size()) - 1;
                
                const auto& expressions = matchPtr->inputExpressions;
                for (const auto expression : expressions) {
                    expressionToMatches_[expression].insert(matchPtr);
                }
            }
        }
        
        void deleteMatch(const MatchPtr matchPtr) {
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
        
        static bool isMatchComplete(const Match& match) {
            for (int i = 0; i < match.inputExpressions.size(); ++i) {
                if (match.inputExpressions[i] < 0) return false;
            }
            return true;
        }
        
        std::pair<int, std::vector<ExpressionID>> nextBestInputAndExpressionsToTry(const Match& incompleteMatch,
                                                                                   const std::vector<AtomsVector>& partiallyMatchedInputs) const {
            int nextInputIdx = -1;
            std::vector<ExpressionID> nextExpressionsToTry;
            
            // For each input, we will see how many expressions in the set contain atoms appearing in this input.
            // The fewer there are, the less branching we will have to do.
            for (int i = 0; i < partiallyMatchedInputs.size(); ++i) {
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
                std::unordered_map<ExpressionID, int> inputAtomsCountByExpression;
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
                // Note, if there are zero matching expressions, it means the match is not possible, because none of the expressions contain all the atoms needed.
                if (nextInputIdx == -1 || potentialExpressions.size() < nextExpressionsToTry.size()) {
                    nextExpressionsToTry = potentialExpressions;
                    nextInputIdx = i;
                }
            }
            
            if (nextInputIdx == -1) {
                // We could not find any potential inputs, which means, all inputs not already matched are fully patterns,
                // and don't have any specific atom references.
                // That implies rule inputs are not a connected graph, which is not supported at the moment,
                // and would require custom logic to implement efficiently.
                throw Error::DisconnectedInputs;
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
                     AtomsIndex& atomsIndex,
                     const std::function<AtomsVector(ExpressionID)> getAtomsVector,
                     const OrderingSpec orderingSpec,
                     const unsigned int randomSeed) {
        implementation_ = std::make_shared<Implementation>(rules, atomsIndex, getAtomsVector, orderingSpec, randomSeed);
    }
    
    void Matcher::addMatchesInvolvingExpressions(const std::vector<ExpressionID>& expressionIDs, const std::function<bool()> shouldAbort) {
        implementation_->addMatchesInvolvingExpressions(expressionIDs, shouldAbort);
    }
    
    void Matcher::removeMatchesInvolvingExpressions(const std::vector<ExpressionID>& expressionIDs) {
        implementation_->removeMatchesInvolvingExpressions(expressionIDs);
    }
    
    bool Matcher::empty() const {
        return implementation_->empty();
    }
    
    MatchPtr Matcher::nextMatch() const {
        return implementation_->nextMatch();
    }
    
    bool Matcher::substituteMissingAtomsIfPossible(const std::vector<AtomsVector> inputPatterns,
                                                   const std::vector<AtomsVector> patternMatches,
                                                   std::vector<AtomsVector> &atomsToReplace) {
        if (inputPatterns.size() != patternMatches.size()) return false;
        
        std::unordered_map<Atom, Atom> match;
        for (int i = 0; i < inputPatterns.size(); ++i) {
            const auto& pattern = inputPatterns[i];
            const auto& patternMatch = patternMatches[i];
            if (pattern.size() != patternMatch.size()) return false;;
            for (int j = 0; j < pattern.size(); ++j) {
                Atom inputAtom;
                if (match.count(pattern[j])) {
                    inputAtom = match.at(pattern[j]);
                } else {
                    inputAtom = pattern[j];
                }
                
                if (inputAtom < 0) { // pattern
                    match[inputAtom] = patternMatch[j];
                } else { // explicit atom ID
                    if (inputAtom != patternMatch[j]) return false;
                }
            }
        }
        
        for (int i = 0; i < atomsToReplace.size(); ++i) {
            for (int j = 0; j < atomsToReplace[i].size(); ++j) {
                if (match.count(atomsToReplace[i][j])) {
                    atomsToReplace[i][j] = match[atomsToReplace[i][j]];
                }
            }
        }
        return true;
    }

    const std::vector<MatchPtr> Matcher::allMatches() const {
        return implementation_->allMatches();
    }
}
