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
        StepSpecification stepSpec_;
        TerminationReason terminationReason_ = TerminationReason::NotTerminated;
                
        std::unordered_map<ExpressionIndex, SetExpression> expressions_;
        std::vector<RuleIndex> eventRuleIndices_ = {-1};
        
        Atom nextAtom_ = 1;
        ExpressionIndex nextExpressionIndex_ = 0;
        
        int destroyedExpressionsCount_ = 0;
        
        // In another words, expressions counts by atom.
        // Note, we cannot use atomsIndex_, because it does not keep last generation expressions.
        std::unordered_map<Atom, int> atomDegrees_;
        
        // Largest generation produced so far.
        // Note, this is not the same as max of generations of all expressions,
        // because there might exist an event that deletes expressions, but does not create any new ones.
        Generation largestGeneration_ = 0;
        
        AtomsIndex atomsIndex_;
        
        Matcher matcher_;
        
        std::vector<ExpressionIndex> unindexedExpressions_;
        
    public:
        Implementation(const std::vector<Rule>& rules,
                       const std::vector<AtomsVector>& initialExpressions,
                       const Matcher::EvaluationType evaluationType,
                       const unsigned int randomSeed) :
            Implementation(rules,
                           initialExpressions,
                           evaluationType,
                           randomSeed,
                           [this](const int expressionIndex) {
                                return expressions_.at(expressionIndex).atoms;
                           }) {}
        
        int replaceOnce(const std::function<bool()> shouldAbort) {
            terminationReason_ = TerminationReason::NotTerminated;

            if (eventRuleIndices_.size() > stepSpec_.maxEvents) {
                terminationReason_ = TerminationReason::MaxEvents;
                return 0;
            }
            
            indexNewExpressions([this, &shouldAbort](){
                const bool isAborted = shouldAbort();
                if (isAborted) terminationReason_ = TerminationReason::Aborted;
                return isAborted;
            });
            if (matcher_.matchCount() == 0) {
                if (largestGeneration_ == stepSpec_.maxGenerationsLocal) {
                    terminationReason_ = TerminationReason::MaxGenerationsLocal;
                } else {
                    terminationReason_ = TerminationReason::FixedPoint;
                }
                return 0;
            }
            Match match = matcher_.nextMatch();
            
            const auto& ruleInputs = rules_[match.rule].inputs;
            std::vector<AtomsVector> inputExpressions;
            for (const auto& expressionIndex : match.inputExpressions) {
                inputExpressions.push_back(expressions_.at(expressionIndex).atoms);
            }
            
            auto explicitRuleInputs = ruleInputs;
            Matcher::substituteMissingAtomsIfPossible(ruleInputs, inputExpressions, explicitRuleInputs);
            
            // Identify output atoms that appear in the input, that still leaves newly created atoms as patterns.
            auto explicitRuleOutputs = rules_[match.rule].outputs;
            Matcher::substituteMissingAtomsIfPossible(ruleInputs, inputExpressions, explicitRuleOutputs);
            
            for (const auto function : {&Implementation::willExceedAtomLimits,
                                        &Implementation::willExceedExpressionsLimit}) {
                const auto willExceedAtomLimitsStatus = (this->*function)(explicitRuleInputs, explicitRuleOutputs);
                if (willExceedAtomLimitsStatus != TerminationReason::NotTerminated) {
                    terminationReason_ = willExceedAtomLimitsStatus;
                    return 0;
                }
            }
            
            std::vector<ExpressionID> inputExpressionIDs;
            for (const auto expressionIndex : match.inputExpressions) {
                inputExpressionIDs.push_back(expressions_[expressionIndex].id);
            }
            
            // At this point, we are committed to modifying the set.
            
            // Name newly created atoms as well, now all atoms in the output are explicitly named.
            const auto namedRuleOutputs = nameAnonymousRuleOutputs(inputExpressionIDs, explicitRuleOutputs, match.rule);
            
            matcher_.removeMatchesInvolvingExpressions(match.inputExpressions);
            atomsIndex_.removeExpressions(match.inputExpressions);
            
            int outputGeneration = 0;
            for (const auto& inputExpression : match.inputExpressions) {
                outputGeneration = std::max(outputGeneration, expressions_[inputExpression].generation + 1);
            }
            largestGeneration_ = std::max(largestGeneration_, outputGeneration);
            
            const EventIndex eventIndex = static_cast<int>(eventRuleIndices_.size());
            addExpressions(inputExpressionIDs, namedRuleOutputs, eventIndex, outputGeneration);
            assignDestroyerEvent(match.inputExpressions, eventIndex);
            eventRuleIndices_.push_back(match.rule);
            
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
            std::vector<std::pair<ExpressionIndex, SetExpression>> indicesAndExpressions;
            indicesAndExpressions.reserve(expressions_.size());
            for (const auto& indexAndExpression : expressions_) {
                indicesAndExpressions.push_back(indexAndExpression);
            }
            std::sort(indicesAndExpressions.begin(), indicesAndExpressions.end(), [](const auto& a, const auto& b) {
                return a.first < b.first;
            });
            std::vector<SetExpression> result;
            result.reserve(indicesAndExpressions.size());
            for (const auto& indexAndExpression : indicesAndExpressions) {
                result.push_back(indexAndExpression.second);
            }
            return result;
        }
        
        Generation maxCompleteGeneration(const std::function<bool()> shouldAbort) {
            indexNewExpressions(shouldAbort);
            return std::min(smallestGeneration(matcher_.allMatches()), largestGeneration_);
        }
        
        TerminationReason terminationReason() const {
            return terminationReason_;
        }
        
        const std::vector<RuleIndex>& eventRuleIndices() const {
            return eventRuleIndices_;
        }

    private:
        Implementation(const std::vector<Rule>& rules,
                       const std::vector<AtomsVector>& initialExpressions,
                       const Matcher::EvaluationType evaluationType,
                       const unsigned int randomSeed,
                       const std::function<AtomsVector(ExpressionIndex)>& getAtomsVector) :
        rules_(rules),
        atomsIndex_(getAtomsVector),
        matcher_(rules_, atomsIndex_, getAtomsVector, evaluationType, randomSeed) {
            for (const auto& expression : initialExpressions) {
                for (const auto& atom : expression) {
                    if (atom <= 0) throw Error::NonPositiveAtoms;
                    nextAtom_ = std::max(nextAtom_ - 1, atom) + 1;
                }
            }
            addExpressions({}, initialExpressions, initialConditionEvent, initialGeneration);
        }
        
        void updateStepSpec(const StepSpecification newStepSpec) {
            const auto previousMaxGeneration = stepSpec_.maxGenerationsLocal;
            stepSpec_ = newStepSpec;
            if (newStepSpec.maxGenerationsLocal > previousMaxGeneration) {
                for (int expressionIndex = 0; expressionIndex < expressions_.size(); ++expressionIndex) {
                    if (expressions_[expressionIndex].generation == previousMaxGeneration) {
                        unindexedExpressions_.push_back(expressionIndex);
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
        
        TerminationReason willExceedAtomLimits(const std::vector<std::vector<Atom>> explicitRuleInputs,
                                               const std::vector<std::vector<Atom>> explicitRuleOutputs) const {
            const int currentAtomsCount = static_cast<int>(atomDegrees_.size());
            
            std::unordered_map<Atom, int> atomDegreeDeltas;
            updateAtomDegrees(atomDegreeDeltas, explicitRuleInputs, -1, false);
            updateAtomDegrees(atomDegreeDeltas, explicitRuleOutputs, +1, false);
            
            int newAtomsCount = currentAtomsCount;
            for (const auto& atomAndDegreeDelta : atomDegreeDeltas) {
                const Atom atom = atomAndDegreeDelta.first;
                const int degreeDelta = atomAndDegreeDelta.second;
                const int currentDegree = atomDegrees_.count(atom) ? static_cast<int>(atomDegrees_.at(atom)) : 0;
                if (currentDegree == 0 && degreeDelta > 0) {
                    ++newAtomsCount;
                }
                else if (currentDegree > 0 && currentDegree + degreeDelta == 0) {
                    --newAtomsCount;
                }
                
                // Check atom degree.
                if (currentDegree + degreeDelta > stepSpec_.maxFinalAtomDegree) {
                    return TerminationReason::MaxFinalAtomDegree;
                }
            }
            
            if (newAtomsCount > stepSpec_.maxFinalAtoms) {
                return TerminationReason::MaxFinalAtoms;
            } else {
                return TerminationReason::NotTerminated;
            }
        }
        
        static void updateAtomDegrees(std::unordered_map<Atom, int>& atomDegrees,
                                      const std::vector<AtomsVector>& deltaExpressions,
                                      const int deltaCount,
                                      bool deleteIfZero = true) {
            for (const auto& expression : deltaExpressions) {
                std::unordered_set<Atom> expressionAtoms;
                for (const auto atom : expression) {
                    expressionAtoms.insert(atom);
                }
                for (const auto atom : expressionAtoms) {
                    atomDegrees[atom] += deltaCount;
                    if (deleteIfZero && atomDegrees[atom] == 0) {
                        atomDegrees.erase(atom);
                    }
                }
            }
        }
        
        TerminationReason willExceedExpressionsLimit(const std::vector<std::vector<Atom>> explicitRuleInputs,
                                                     const std::vector<std::vector<Atom>> explicitRuleOutputs) const {
            const int currentExpressionsCount = nextExpressionIndex_ - destroyedExpressionsCount_;
            const int newExpressionsCount = currentExpressionsCount
                                            - static_cast<int>(explicitRuleInputs.size())
                                            + static_cast<int>(explicitRuleOutputs.size());
            if (newExpressionsCount > stepSpec_.maxFinalExpressions) {
                return TerminationReason::MaxFinalExpressions;
            } else {
                return TerminationReason::NotTerminated;
            }
        }
        
        std::vector<AtomsVector> nameAnonymousRuleOutputs(const std::vector<ExpressionID>& inputs,
                                                          const std::vector<AtomsVector>& outputs,
                                                          const RuleIndex ruleIndex) {
            std::unordered_map<Atom, Atom> names;
            std::vector<AtomsVector> result = outputs;
            for (auto& expression : result) {
                for (auto& atom : expression) {
                    if (atom < 0 && names.count(atom) == 0) {
                        names[atom] = newAtom(inputs, (int)names.size(), ruleIndex);
                    }
                    if (atom < 0) {
                        atom = names[atom];
                    }
                }
            }
            
            return result;
        }
        
        Atom newAtom(const std::vector<ExpressionID>& inputs, const int newAtomIndex, const RuleIndex ruleIndex) {
            return newName(inputs, ElementType::Atom, newAtomIndex, ruleIndex);
        }
        
        ExpressionID newExpressionID(const std::vector<ExpressionID>& inputs,
                                     const int newExpressionIndex,
                                     const RuleIndex ruleIndex) {
            return newName(inputs, ElementType::Expression, newExpressionIndex, ruleIndex);
        }
        
        enum class ElementType{Atom, Expression};
        HashValue newName(const std::vector<ExpressionID>& inputs,
                          const ElementType type,
                          const int elementIndex,
                          const RuleIndex ruleIndex) {
            std::vector<HashValue> arrayToHash = {(HashValue)type, elementIndex, ruleIndex, inputs.size()};
            for (const auto& input : inputs) {
                arrayToHash.push_back(input);
            }
            return hash(arrayToHash);
        }
        
        HashValue hash(const std::vector<HashValue>& values) {
            std::hash<HashValue> hasher;
            HashValue result = 0;
            for (const auto& value : values)
            {
                result = result * 31 + hasher(value);
            }
            return result;
        }
        
        std::vector<ExpressionIndex> addExpressions(const std::vector<ExpressionID>& ruleInputs,
                                                    const std::vector<AtomsVector>& expressions,
                                                    const EventIndex creatorEvent,
                                                    const int generation) {
            const auto indices = assignExpressionIndicesAndIDs(ruleInputs, expressions, creatorEvent, generation);
            
            // If generation is at least maxGeneration_, we will never use these expressions as inputs, so no need adding them to the index.
            if (generation < stepSpec_.maxGenerationsLocal) {
                for (const auto index : indices) {
                    unindexedExpressions_.push_back(index);
                }
            }
            
            updateAtomDegrees(atomDegrees_, expressions, +1);
            return indices;
        }
        
        std::vector<ExpressionIndex> assignExpressionIndicesAndIDs(const std::vector<ExpressionID>& ruleInputs,
                                                                   const std::vector<AtomsVector>& expressions,
                                                                   const EventIndex creatorEvent,
                                                                   const int generation) {
            std::vector<ExpressionIndex> indices;
            for (int expressionIdx = 0; expressionIdx < expressions.size(); ++expressionIdx) {
                indices.push_back(nextExpressionIndex_);
                const ExpressionID id = newExpressionID(ruleInputs, expressionIdx, eventRuleIndices_[creatorEvent]);
                const auto setExpression =
                        SetExpression{id, expressions[expressionIdx], creatorEvent, finalStateEvent, generation};
                expressions_.insert(std::make_pair(nextExpressionIndex_++, setExpression));
            }
            return indices;
        }
        
        void assignDestroyerEvent(const std::vector<ExpressionIndex>& expressions, const EventIndex destroyerEvent) {
            for (const auto index : expressions) {
                if (expressions_.at(index).destroyerEvent == finalStateEvent) {
                    ++destroyedExpressionsCount_;
                }
                expressions_.at(index).destroyerEvent = destroyerEvent;
            }
            updateAtomDegrees(atomDegrees_, expressions, -1);
        }
        
        void updateAtomDegrees(std::unordered_map<Atom, int>& atomDegrees,
                               const std::vector<ExpressionIndex>& deltaExpressionIndices,
                               const int deltaCount) const {
            std::vector<AtomsVector> expressions;
            for (const auto index : deltaExpressionIndices) {
                expressions.push_back(expressions_.at(index).atoms);
            }
            updateAtomDegrees(atomDegrees, expressions, deltaCount);
        }
        
        Generation smallestGeneration(const std::set<Match>& matches) const {
            Generation smallestSoFar = std::numeric_limits<Generation>::max();
            for (const auto& match : matches) {
                Generation largestForTheMatch = 0;
                for (const ExpressionIndex index : match.inputExpressions) {
                    largestForTheMatch = std::max(largestForTheMatch, expressions_.at(index).generation);
                }
                smallestSoFar = std::min(smallestSoFar, largestForTheMatch);
            }
            return smallestSoFar;
        }
    };
    
    Set::Set(const std::vector<Rule>& rules,
             const std::vector<AtomsVector>& initialExpressions,
             const Matcher::EvaluationType evaluationType,
             const unsigned int randomSeed) {
        implementation_ = std::make_shared<Implementation>(rules, initialExpressions, evaluationType, randomSeed);
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
    
    Generation Set::maxCompleteGeneration(const std::function<bool()> shouldAbort) {
        return implementation_->maxCompleteGeneration(shouldAbort);
    }

    Set::TerminationReason Set::terminationReason() const {
        return implementation_->terminationReason();
    }

    const std::vector<RuleIndex>& Set::eventRuleIndices() const {
        return implementation_->eventRuleIndices();
    }
}
