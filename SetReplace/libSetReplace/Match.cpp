#include "Match.hpp"

#include <algorithm>
#include <unordered_map>

namespace SetReplace {
    namespace {
        int compareVectors(const std::vector<ExpressionID>& first, const std::vector<ExpressionID>& second) {
            for (int i = 0; i < std::min(first.size(), second.size()); ++i) {
                if (first[i] < second[i]) return -1;
                else if (first[i] > second[i]) return +1;
            }
            
            if (first.size() < second.size()) return -1;
            else if (first.size() > second.size()) return 1;
            else return 0;
        }
        
        int compareSortedIDs(const Match& first, const Match& second, bool reverseOrder = false) {
            std::vector<ExpressionID> thisExpressions = first.inputExpressions;
            std::sort(thisExpressions.begin(), thisExpressions.end());
            
            std::vector<ExpressionID> otherExpressions = second.inputExpressions;
            std::sort(otherExpressions.begin(), otherExpressions.end());
            
            if (reverseOrder) {
                std::reverse(thisExpressions.begin(), thisExpressions.end());
                std::reverse(otherExpressions.begin(), otherExpressions.end());
            }
            return compareVectors(thisExpressions, otherExpressions);
        }
        
        int compareUnsortedIDs(const Match& first, const Match& second) {
            return compareVectors(first.inputExpressions, second.inputExpressions);
        }
    }
    
    bool Match::operator<(const Match& other) const {
        // First, find which Match has oldest (lowest ID) expressions
        int sortedComparison = compareSortedIDs(*this, other, true);
        if (sortedComparison != 0) return sortedComparison < 0;

        // Then, if sets of expressions are the same, use smaller permutation
        int unsortedComparison = compareUnsortedIDs(*this, other);
        if (unsortedComparison != 0) return unsortedComparison < 0;
        
        // Finally, first rule goes first
        return rule < other.rule;
    }
    
    class Matcher::Implementation {
    private:
        const std::vector<Rule>& rules_;
        AtomsIndex& atomsIndex_;
        const std::function<AtomsVector(ExpressionID)> getAtomsVector_;
        
        std::set<Match> matches_; // sorted by priority, i.e., the first match is returned first.
        
        struct IteratorHash {
            size_t operator()(std::set<Match>::const_iterator it) const {
                return std::hash<int64_t>()((int64_t)&(*it));
            }
        };
        // Matches organized by expression IDs, useful for deleting matches for deleted expressions.
        std::unordered_map<ExpressionID, std::unordered_set<std::set<Match>::const_iterator, IteratorHash>> matchesIndex_;
        
    public:
        Implementation(const std::vector<Rule>& rules,
                       AtomsIndex& atomsIndex,
                       const std::function<AtomsVector(ExpressionID)> getAtomsVector) :
            rules_(rules), atomsIndex_(atomsIndex), getAtomsVector_(getAtomsVector) {}
        
        void addMatchesInvolvingExpressions(const std::vector<ExpressionID>& expressionIDs, const std::function<bool()> shouldAbort) {
            for (int i = 0; i < rules_.size(); ++i) {
                addMatchesForRule(expressionIDs, i, shouldAbort);
            }
        }
        
        void removeMatchesInvolvingExpressions(const std::vector<ExpressionID>& expressionIDs) {
            std::unordered_set<std::set<Match>::const_iterator, IteratorHash> matchIteratorsToDelete;
            for (const auto& expression : expressionIDs) {
                const auto& matches = matchesIndex_[expression];
                for (const auto& matchIterator : matches) {
                    matchIteratorsToDelete.insert(matchIterator);
                }
            }
            
            std::unordered_set<ExpressionID> involvedExpressions;
            for (const auto& iterator : matchIteratorsToDelete) {
                for (const auto& expression : iterator->inputExpressions) {
                    involvedExpressions.insert(expression);
                }
            }
            
            for (const auto& expression : involvedExpressions) {
                auto indexIterator = matchesIndex_[expression].begin();
                while (indexIterator != matchesIndex_[expression].end()) {
                    if (matchIteratorsToDelete.count(*indexIterator)) {
                        indexIterator = matchesIndex_[expression].erase(indexIterator);
                    } else {
                        ++indexIterator;
                    }
                }
                if (matchesIndex_[expression].empty()) {
                    matchesIndex_.erase(expression);
                }
            }
            
            for (const auto& matchIterator : matchIteratorsToDelete) {
                matches_.erase(matchIterator);
            }
        }
        
        int matchCount() const {
            return static_cast<int>(matches_.size());
        }
        
        Match nextMatch() const {
            return *matches_.begin();
        }
        
        const std::set<Match>& allMatches() {
            return matches_;
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
            const auto iterator = matches_.insert(newMatch).first;
            for (const auto& expression : newMatch.inputExpressions) {
                matchesIndex_[expression].insert(iterator);
            }
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
    };
    
    Matcher::Matcher(const std::vector<Rule>& rules,
                     AtomsIndex& atomsIndex,
                     const std::function<AtomsVector(ExpressionID)> getAtomsVector) {
        implementation_ = std::make_shared<Implementation>(rules, atomsIndex, getAtomsVector);
    }
    
    void Matcher::addMatchesInvolvingExpressions(const std::vector<ExpressionID>& expressionIDs, const std::function<bool()> shouldAbort) {
        implementation_->addMatchesInvolvingExpressions(expressionIDs, shouldAbort);
    }
    
    void Matcher::removeMatchesInvolvingExpressions(const std::vector<ExpressionID>& expressionIDs) {
        implementation_->removeMatchesInvolvingExpressions(expressionIDs);
    }
    
    int Matcher::matchCount() const {
        return implementation_->matchCount();
    }
    
    Match Matcher::nextMatch() const {
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

    const std::set<Match>& Matcher::allMatches() const {
        return implementation_->allMatches();
    }
}
