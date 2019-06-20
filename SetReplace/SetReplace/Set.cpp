#include "Match.hpp"
#include "Set.hpp"

#include <set>
#include <string>
#include <unordered_map>
#include <unordered_set>

namespace SetReplace {
    class Set::Implementation {
    private:
        const std::vector<Rule> rules_;
        
        using ExpressionID = int;
        std::unordered_map<ExpressionID, Expression> expressions_;
        int nextExpressionID = 0;
        int nextAtomID = 0;
        
        std::unordered_map<AtomID, std::unordered_set<ExpressionID>> atomsIndex_;
        
        std::set<Match> matches_;
        
        struct IteratorHash {
            size_t operator()(std::set<Match>::const_iterator it) const {
                return std::hash<int64_t>()((int64_t)&(*it));
            }
        };
        std::unordered_map<ExpressionID, std::unordered_set<std::set<Match>::const_iterator, IteratorHash>> matchesIndex_;
        
        const std::function<bool()>& shouldAbort_;

    public:
        Implementation(const std::vector<Rule>& rules,
                       const std::vector<Expression>& initialExpressions,
                       const std::function<bool()>& shouldAbort) : rules_(rules), shouldAbort_(shouldAbort) {
            for (const auto& expression : initialExpressions) {
                for (const auto& atom : expression) {
                    nextAtomID = std::max(nextAtomID - 1, atom) + 1;
                }
            }
            addExpressions(initialExpressions);
        }
        
        int replace() {
            if (matches_.empty()) {
                return 0;
            }
            
            Match match = *matches_.begin();
            
            const auto& ruleInputs = rules_[match.ruleID].inputs;
            std::vector<Expression> inputExpressions;
            for (const auto& expressionID : match.expressionIDs) {
                inputExpressions.push_back(expressions_[expressionID]);
            }
            
            auto explicitRuleInputs = ruleInputs;
            replaceExplicit(ruleInputs, inputExpressions, explicitRuleInputs);
            auto explicitRuleOutputs = rules_[match.ruleID].outputs;
            replaceExplicit(ruleInputs, inputExpressions, explicitRuleOutputs);
            const auto namedRuleOutputs = nameAnonymousAtoms(explicitRuleOutputs);
            
            removeMatches(match.expressionIDs);
            removeFromAtomsIndex(match.expressionIDs);
            removeExpressions(match.expressionIDs);
            
            addExpressions(namedRuleOutputs);
            
            return 1;
        }
        
        void removeMatches(const std::vector<ExpressionID>& expressionIDs) {
            std::unordered_set<std::set<Match>::const_iterator, IteratorHash> matchIteratorsToDelete;
            for (const auto& id : expressionIDs) {
                const auto& matches = matchesIndex_[id];
                for (const auto& matchIterator : matches) {
                    matchIteratorsToDelete.insert(matchIterator);
                }
            }
            
            std::unordered_set<ExpressionID> involvedExpressions;
            for (const auto& iterator : matchIteratorsToDelete) {
                for (const auto& expression : iterator->expressionIDs) {
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
        
        void removeFromAtomsIndex(const std::vector<ExpressionID>& expressionIDs) {
            std::unordered_set<ExpressionID> expressionsToDelete;
            for (const auto& expression : expressionIDs) {
                expressionsToDelete.insert(expression);
            }
            
            std::unordered_set<AtomID> involedAtoms;
            for (const auto& expression : expressionIDs) {
                for (const auto& atom : expressions_[expression]) {
                    involedAtoms.insert(atom);
                }
            }
            
            for (const auto& atom : involedAtoms) {
                auto expressionIterator = atomsIndex_[atom].begin();
                while (expressionIterator != atomsIndex_[atom].end()) {
                    if (expressionsToDelete.count(*expressionIterator)) {
                        expressionIterator = atomsIndex_[atom].erase(expressionIterator);
                    } else {
                        ++expressionIterator;
                    }
                }
                if (atomsIndex_[atom].empty()) {
                    atomsIndex_.erase(atom);
                }
            }
        }
        
        void removeExpressions(const std::vector<ExpressionID>& expressionIDs) {
            for (const auto& expression : expressionIDs) {
                expressions_.erase(expression);
            }
        }
        
        int replace(const int stepCount) {
            int count = 0;
            for (int i = 0; i < stepCount; ++i) {
                count += replace();
            }
            return count;
        }
        
        std::vector<Expression> expressions() const {
          std::vector<std::pair<ExpressionID, Expression>> idExpressions;
          idExpressions.reserve(expressions_.size());
          for (const auto& idExpression : expressions_) {
            idExpressions.push_back(idExpression);
          }
          std::sort(idExpressions.begin(), idExpressions.end());
          std::vector<Expression> result;
          result.reserve(idExpressions.size());
          for (const auto& idExpression : idExpressions) {
            result.push_back(idExpression.second);
          }
          return result;
        }
        
    private:
        std::vector<Expression> nameAnonymousAtoms(const std::vector<Expression>& expressions) {
            std::unordered_map<AtomID, AtomID> names;
            std::vector<Expression> result = expressions;
            for (auto& expression : result) {
                for (auto& atom : expression) {
                    if (atom < 0 && names.count(atom) == 0) {
                        names[atom] = nextAtomID++;
                    }
                    if (atom < 0) {
                        atom = names[atom];
                    }
                }
            }
            return result;
        }
        
        void addExpressions(const std::vector<Expression>& expressions) {
            const auto ids = assignExpressionIDs(expressions);
            addToAtomsIndex(ids);
            addMatches(ids);
        }
        
        std::vector<ExpressionID> assignExpressionIDs(const std::vector<Expression>& expressions) {
            std::vector<ExpressionID> ids;
            for (const auto& expression : expressions) {
                ids.push_back(nextExpressionID);
                expressions_.insert(std::make_pair(nextExpressionID++, expression));
            }
            return ids;
        }
        
        void addToAtomsIndex(const std::vector<ExpressionID>& ids) {
            for (const auto expressionID : ids) {
                for (const auto atom : expressions_.at(expressionID)) {
                    atomsIndex_[atom].insert(expressionID);
                }
            }
        }
        
        void addMatches(const std::vector<ExpressionID>& ids) {
            for (int i = 0; i < rules_.size(); ++i) {
                addMatches(ids, i);
            }
        }
        
        void addMatches(const std::vector<ExpressionID>& expressionIDs, const int ruleID) {
            for (int i = 0; i < rules_[ruleID].inputs.size(); ++i) {
                Match emptyMatch{ruleID, std::vector<ExpressionID>(rules_[ruleID].inputs.size(), -1)};
                addMatches(emptyMatch, rules_[ruleID].inputs, i, expressionIDs);
            }
        }
        
        void addMatches(const Match& currentMatch,
                        const std::vector<Expression>& inputs,
                        const int nextInputID,
                        const std::vector<ExpressionID>& potentialExpressionIDs) {
            for (const auto expressionID : potentialExpressionIDs) {
                if (expressionUnused(currentMatch, expressionID)) {
                    addMatches(currentMatch, inputs, nextInputID, expressionID);
                }
            }
        }
        
        bool expressionUnused(const Match& match, const ExpressionID expressionID) {
            for (int i = 0; i < match.expressionIDs.size(); ++i) {
                if (match.expressionIDs[i] == expressionID) return false;
            }
            return true;
        }
        
        void addMatches(const Match& currentMatch,
                        const std::vector<Expression>& inputs,
                        const int nextInputID,
                        const ExpressionID expressionID) {
            const auto& input = inputs[nextInputID];
            const auto& expression = expressions_[expressionID];
            if (input.size() != expression.size()) return;
            
            Match newCurrentMatch = currentMatch;
            newCurrentMatch.expressionIDs[nextInputID] = expressionID;
            
            auto newInputs = inputs;
            if (replaceExplicit({input}, {expression}, newInputs)) {
                addMatches(newCurrentMatch, newInputs);
            }
        }
        
        bool replaceExplicit(const std::vector<Expression> patterns,
                             const std::vector<Expression> patternMatches,
                             std::vector<Expression>& expressions) {
            if (patterns.size() != patternMatches.size()) return false;
            
            std::unordered_map<AtomID, AtomID> match;
            for (int i = 0; i < patterns.size(); ++i) {
                const auto& pattern = patterns[i];
                const auto& patternMatch = patternMatches[i];
                if (pattern.size() != patternMatch.size()) return false;;
                for (int j = 0; j < pattern.size(); ++j) {
                    AtomID inputAtom;
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
            
            for (int i = 0; i < expressions.size(); ++i) {
                for (int j = 0; j < expressions[i].size(); ++j) {
                    if (match.count(expressions[i][j])) {
                        expressions[i][j] = match[expressions[i][j]];
                    }
                }
            }
            return true;
        }
        
        void addMatches(const Match& currentMatch, const std::vector<Expression>& inputs) {
            if (shouldAbort_()) {
                throw Error::Aborted;
            }
            if (matchComplete(currentMatch)) {
                const auto iterator = matches_.insert(currentMatch).first;
                for (const auto& expressionID : currentMatch.expressionIDs) {
                    matchesIndex_[expressionID].insert(iterator);
                }
                return;
            }
            
            int nextInputID = -1;
            std::vector<ExpressionID> potentialExpressionIDs;
            bool anonymousAtomsPresent = false;
            
            for (int i = 0; i < inputs.size(); ++i) {
                if (currentMatch.expressionIDs[i] != -1) continue;
                
                std::unordered_set<AtomID> requiredAtoms;
                bool allAnonymous = true;
                for (const auto atom : inputs[i]) {
                    if (atom >= 0) {
                        requiredAtoms.insert(atom);
                        allAnonymous = false;
                    } else if (atom < 0) {
                        anonymousAtomsPresent = true;
                    }
                }
                if (allAnonymous) continue;
                
                std::unordered_map<ExpressionID, int> requiredAtomsCounts;
                for (const auto atom : requiredAtoms) {
                    for (const auto expression : atomsIndex_[atom]) {
                        requiredAtomsCounts[expression]++;
                    }
                }
                
                std::vector<ExpressionID> candidateExpressionIDs;
                for (const auto& expressionCount : requiredAtomsCounts) {
                    if (expressionCount.second == requiredAtoms.size()) {
                        candidateExpressionIDs.push_back(expressionCount.first);
                    }
                }
                
                if (nextInputID == -1 || candidateExpressionIDs.size() < potentialExpressionIDs.size()) {
                    potentialExpressionIDs = candidateExpressionIDs;
                    nextInputID = i;
                }
            }
            
            if (nextInputID == -1 && anonymousAtomsPresent) {
                throw std::string("Inputs of rule ") + std::to_string(currentMatch.ruleID) + std::string(" are not connected.");
            } else if (nextInputID == -1) {
                return;
            }
            
            addMatches(currentMatch, inputs, nextInputID, potentialExpressionIDs);
        }
        
        bool matchComplete(const Match& match) {
            for (int i = 0; i < match.expressionIDs.size(); ++i) {
                if (match.expressionIDs[i] < 0) return false;
            }
            return true;
        }
    };
    
    Set::Set(const std::vector<Rule>& rules, const std::vector<Expression>& initialExpressions, const std::function<bool()>& shouldAbort) {
        implementation_ = std::make_shared<Implementation>(rules, initialExpressions, shouldAbort);
    }
    
    int Set::replace() {
        return implementation_->replace();
    }
    
    int Set::replace(const int stepCount) {
        return implementation_->replace(stepCount);
    }
    
    std::vector<Expression> Set::expressions() const {
        return implementation_->expressions();
    }
}
