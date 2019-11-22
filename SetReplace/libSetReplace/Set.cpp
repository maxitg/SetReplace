#include "Match.hpp"
#include "Set.hpp"

#include <algorithm>
#include <set>
#include <string>
#include <unordered_map>
#include <unordered_set>

namespace SetReplace {
    class Set::Implementation {
    private:
        // Rules fundamentally cannot be changed during evaluation, don't try to remove const.
        // If rules do need to be changed, create another instance of Set and copy the expressions over.
        const std::vector<Rule> rules_;
        
        // Determines the limiting conditions for the evaluation.
        StepSpecification stepSpec_ = {0, 0, 0, 0};
        
        std::unordered_map<ExpressionID, SetExpression> expressions_;
        
        Atom nextAtom_ = 1;
        ExpressionID nextExpressionID_ = 0;
        EventID nextEventID_ = 1;
        
        // Largest generation produced so far.
        // Note, this is not the same as max of generations of all events,
        // because there might exist an event that deletes expressions, but does not create any new ones.
        Generation largestGeneration_ = 0;
        
        AtomsIndex atomsIndex_;
        
        Matcher matcher_;
        
        std::vector<ExpressionID> unindexedExpressions_;
        
    public:
        Implementation(const std::vector<Rule>& rules,
                       const std::vector<AtomsVector>& initialExpressions) :
            Implementation(rules, initialExpressions, [this](const int expressionID) {
                return expressions_.at(expressionID).atoms;
            }) {}
        
        int replaceOnce(const std::function<bool()> shouldAbort) {
            if (nextEventID_ > stepSpec_.maxEvents) return 0;
            
            indexNewExpressions(shouldAbort);
            if (matcher_.matchCount() == 0) return 0;
            Match match = matcher_.nextMatch();
            
            const auto& ruleInputs = rules_[match.rule].inputs;
            std::vector<AtomsVector> inputExpressions;
            for (const auto& expressionID : match.inputExpressions) {
                inputExpressions.push_back(expressions_.at(expressionID).atoms);
            }
            
            auto explicitRuleInputs = ruleInputs;
            Matcher::substituteMissingAtomsIfPossible(ruleInputs, inputExpressions, explicitRuleInputs);
            
            // Identify output atoms that appear in the input, that still leaves newly created atoms as patterns.
            auto explicitRuleOutputs = rules_[match.rule].outputs;
            Matcher::substituteMissingAtomsIfPossible(ruleInputs, inputExpressions, explicitRuleOutputs);
            
            if (willExceedAtomsLimit(explicitRuleInputs, explicitRuleOutputs)) return 0;
            // if (willExceedExpressionsLimit(explicitRuleInputs, explicitRuleOutputs)) return 0;
            
            // Name newly created atoms as well, now all atoms in the output are explicitly named.
            const auto namedRuleOutputs = nameAnonymousAtoms(explicitRuleOutputs);
            
            matcher_.removeMatchesInvolvingExpressions(match.inputExpressions);
            atomsIndex_.removeExpressions(match.inputExpressions);
            
            int outputGeneration = 0;
            for (const auto& inputExpression : match.inputExpressions) {
                outputGeneration = std::max(outputGeneration, expressions_[inputExpression].generation + 1);
            }
            largestGeneration_ = std::max(largestGeneration_, outputGeneration);
            
            const EventID eventID = nextEventID_++;
            addExpressions(namedRuleOutputs, eventID, outputGeneration);
            assignDestroyerEvent(match.inputExpressions, eventID);
            
            return 1;
        }
        
        int replace(const StepSpecification stepSpec, const std::function<bool()> shouldAbort) {
            updateStepSpec(stepSpec);
            int count = 0;
            while (true) {
                if (replaceOnce(shouldAbort)) {
                    ++count;
                } else {
                    return count;
                }
            }
        }
        
        std::vector<SetExpression> expressions() const {
            std::vector<std::pair<ExpressionID, SetExpression>> idsAndExpressions;
            idsAndExpressions.reserve(expressions_.size());
            for (const auto& idAndExpression : expressions_) {
                idsAndExpressions.push_back(idAndExpression);
            }
            std::sort(idsAndExpressions.begin(), idsAndExpressions.end(), [](const auto& a, const auto& b) {
                return a.first < b.first;
            });
            std::vector<SetExpression> result;
            result.reserve(idsAndExpressions.size());
            for (const auto& idAndExpression : idsAndExpressions) {
                result.push_back(idAndExpression.second);
            }
            return result;
        }
        
    private:
        Implementation(const std::vector<Rule>& rules,
                       const std::vector<AtomsVector>& initialExpressions,
                       const std::function<AtomsVector(ExpressionID)>& getAtomsVector) :
        rules_(rules),
        atomsIndex_(getAtomsVector),
        matcher_(rules_, atomsIndex_, getAtomsVector) {
            for (const auto& expression : initialExpressions) {
                for (const auto& atom : expression) {
                    if (atom <= 0) throw Error::NonPositiveAtoms;
                    nextAtom_ = std::max(nextAtom_ - 1, atom) + 1;
                }
            }
            addExpressions(initialExpressions, initialConditionEvent, initialGeneration);
        }
        
        void updateStepSpec(const StepSpecification newStepSpec) {
            const auto previousMaxGeneration = stepSpec_.maxGenerations;
            stepSpec_ = newStepSpec;
            if (newStepSpec.maxGenerations > previousMaxGeneration) {
                for (int expressionID = 0; expressionID < expressions_.size(); ++expressionID) {
                    if (expressions_[expressionID].generation == previousMaxGeneration) {
                        unindexedExpressions_.push_back(expressionID);
                    }
                }
            }
        }
        
        void indexNewExpressions(const std::function<bool()> shouldAbort) {
            // Atoms index must be updated first, because the matcher uses it to discover expressions.
            atomsIndex_.addExpressions(unindexedExpressions_);
            matcher_.addMatchesInvolvingExpressions(unindexedExpressions_, shouldAbort);
            unindexedExpressions_.clear();
        }
        
        bool willExceedAtomsLimit(const std::vector<std::vector<int>> explicitRuleInputs,
                                  const std::vector<std::vector<int>> explicitRuleOutputs) const {
            const int currentAtomsCount = atomsIndex_.atomsCount();
            
            std::unordered_map<Atom, int> addedExpressionsCountPerAtom;
            updateExpressionsCountsInvolvingAtoms(addedExpressionsCountPerAtom, explicitRuleInputs, -1);
            updateExpressionsCountsInvolvingAtoms(addedExpressionsCountPerAtom, explicitRuleOutputs, +1);
            
            int newAtomsCount = currentAtomsCount;
            for (const auto& atomAndAddedExpressionsCount : addedExpressionsCountPerAtom) {
                const Atom atom = atomAndAddedExpressionsCount.first;
                const int addedExpressionsCount = atomAndAddedExpressionsCount.second;
                const int currentExpressionsCount =
                    static_cast<int>(atomsIndex_.expressionsContainingAtom(atom).size());
                if (currentExpressionsCount == 0 && addedExpressionsCount > 0) {
                    ++newAtomsCount;
                }
                else if (currentExpressionsCount > 0 && currentExpressionsCount + addedExpressionsCount == 0) {
                    --newAtomsCount;
                }
            }
            
            return newAtomsCount > stepSpec_.maxFinalAtoms;
        }
        
        void updateExpressionsCountsInvolvingAtoms(std::unordered_map<Atom, int>& expressionsCountsPerAtom,
                                                  const std::vector<std::vector<int>>& deltaExpressions,
                                                  const int deltaCount) const {
            for (const auto& inputExpression : deltaExpressions) {
                std::unordered_set<Atom> expressionAtoms;
                for (const auto atom : inputExpression) {
                    expressionAtoms.insert(atom);
                }
                for (const auto atom : expressionAtoms) {
                    expressionsCountsPerAtom[atom] += deltaCount;
                }
            }
        }
        
        std::vector<AtomsVector> nameAnonymousAtoms(const std::vector<AtomsVector>& atomVectors) {
            std::unordered_map<Atom, Atom> names;
            std::vector<AtomsVector> result = atomVectors;
            for (auto& expression : result) {
                for (auto& atom : expression) {
                    if (atom < 0 && names.count(atom) == 0) {
                        names[atom] = nextAtom_++;
                    }
                    if (atom < 0) {
                        atom = names[atom];
                    }
                }
            }
            
            return result;
        }
        
        std::vector<ExpressionID> addExpressions(const std::vector<AtomsVector>& expressions,
                                                 const EventID creatorEvent,
                                                 const int generation) {
            const auto ids = assignExpressionIDs(expressions, creatorEvent, generation);
            
            // If generation is at least maxGeneration_, we will never use these expressions as inputs, so no need adding them to the index.
            if (generation < stepSpec_.maxGenerations) {
                for (const auto id : ids) {
                    unindexedExpressions_.push_back(id);
                }
            }
            return ids;
        }
        
        std::vector<ExpressionID> assignExpressionIDs(const std::vector<AtomsVector>& expressions,
                                                      const EventID creatorEvent,
                                                      const int generation) {
            std::vector<ExpressionID> ids;
            for (const auto& expression : expressions) {
                ids.push_back(nextExpressionID_);
                expressions_.insert(std::make_pair(nextExpressionID_++,
                                                   SetExpression{expression, creatorEvent, finalStateEvent, generation}));
            }
            return ids;
        }
        
        void assignDestroyerEvent(const std::vector<ExpressionID>& expressions, const EventID destroyerEvent) {
            for (const auto id : expressions) {
                expressions_.at(id).destroyerEvent = destroyerEvent;
            }
        }
    };
    
    Set::Set(const std::vector<Rule>& rules,
             const std::vector<AtomsVector>& initialExpressions) {
        implementation_ = std::make_shared<Implementation>(rules, initialExpressions);
    }
    
    int Set::replaceOnce(const std::function<bool()> shouldAbort) {
        return implementation_->replaceOnce(shouldAbort);
    }
    
    int Set::replace(const StepSpecification stepSpec, const std::function<bool()> shouldAbort) {
        return implementation_->replace(stepSpec, shouldAbort);
    }
    
    std::vector<SetExpression> Set::expressions() const {
        return implementation_->expressions();
    }
}
