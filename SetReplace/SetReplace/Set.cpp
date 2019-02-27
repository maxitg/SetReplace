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
        
        std::unordered_map<AtomID, std::unordered_set<ExpressionID>> atomsIndex_;
        
        std::set<Match> matches_;
        
    public:
        Implementation(const std::vector<Rule>& rules, const std::vector<Expression>& initialExpressions) : rules_(rules) {
            addExpressions(initialExpressions);
        }
        
        void replace() {
            // TODO: not implemented
        }
        
        void replace(const int stepCount) {
            // TODO: not implemented
        }
        
        std::vector<Expression> expressions() const {
            std::vector<Expression> result;
            for (const auto& idExpression : expressions_) {
                result.push_back(idExpression.second);
            }
            return result;
        }
        
    private:
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
            
            std::unordered_map<AtomID, AtomID> match;
            for (int i = 0; i < input.size(); ++i) {
                AtomID inputAtom;
                if (match.count(input[i])) {
                    inputAtom = match.at(input[i]);
                } else {
                    inputAtom = input[i];
                }
                
                if (inputAtom < 0) { // pattern
                    match[inputAtom] = expression[i];
                } else { // explicit atom ID
                    if (inputAtom != expression[i]) return; // inconsistency
                }
            }
            
            Match newCurrentMatch = currentMatch;
            newCurrentMatch.expressionIDs[nextInputID] = expressionID;
            
            std::vector<Expression> newInputs = inputs;
            for (int i = 0; i < newInputs.size(); ++i) {
                for (int j = 0; j < newInputs[i].size(); ++j) {
                    if (match.count(newInputs[i][j])) {
                        newInputs[i][j] = match[newInputs[i][j]];
                    }
                }
            }
            
            addMatches(newCurrentMatch, newInputs);
        }
        
        void addMatches(const Match& currentMatch, const std::vector<Expression>& inputs) {
            if (matchComplete(currentMatch)) {
                matches_.insert(currentMatch);
                return;
            }
            
            int nextInputID = -1;
            std::vector<ExpressionID> potentialExpressionIDs;
            bool anonymousAtomsPresent = false;
            
            for (int i = 0; i < inputs.size(); ++i) {
                if (currentMatch.expressionIDs[i] != -1) continue;
                
                std::unordered_set<AtomID> requiredAtoms;
                for (const auto atom : inputs[i]) {
                    if (atom >= 0) {
                        requiredAtoms.insert(atom);
                    } else if (atom < 0) {
                        anonymousAtomsPresent = true;
                    }
                }
                
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
    
    Set::Set(const std::vector<Rule>& rules, const std::vector<Expression>& initialExpressions) {
        implementation_ = std::make_shared<Implementation>(rules, initialExpressions);
    }
    
    Set Set::replace() {
        implementation_->replace();
        return *this;
    }
    
    Set Set::replace(const int stepCount) {
        implementation_->replace(stepCount);
        return *this;
    }
    
    std::vector<Expression> Set::expressions() const {
        return implementation_->expressions();
    }
}
