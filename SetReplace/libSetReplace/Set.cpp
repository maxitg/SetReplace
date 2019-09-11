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
        
        // Events will never be created with inputs of this generation.
        const Generation maxGeneration_;
        
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
        
    public:
        Implementation(const std::vector<Rule>& rules,
                       const std::vector<AtomsVector>& initialExpressions,
                       const std::function<bool()> shouldAbort,
                       const Generation maxGeneration) :
            Implementation(rules, initialExpressions, shouldAbort, maxGeneration, [this](const int expressionID) {
                return expressions_.at(expressionID).atoms;
            }) {}
        
        int replaceOnce() {
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
        
        int replace(const int substitutionCount) {
            int count = 0;
            for (int i = 0; i < substitutionCount; ++i) {
                if (replaceOnce()) {
                    ++count;
                } else {
                    return count;
                }
            }
            return count;
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
                       const std::function<bool()> shouldAbort,
                       const Generation maxGeneration,
                       const std::function<AtomsVector(ExpressionID)>& getAtomsVector) :
        rules_(rules),
        maxGeneration_(maxGeneration),
        atomsIndex_(getAtomsVector),
        matcher_(rules_, atomsIndex_, getAtomsVector, shouldAbort) {
            for (const auto& expression : initialExpressions) {
                for (const auto& atom : expression) {
                    if (atom <= 0) throw Error::NonPositiveAtoms;
                    nextAtom_ = std::max(nextAtom_ - 1, atom) + 1;
                }
            }
            addExpressions(initialExpressions, initialConditionEvent, initialGeneration);
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
            if (generation < maxGeneration_) {
                // Atoms index must be updated first, because the matcher uses it to discover expressions.
                atomsIndex_.addExpressions(ids);
                matcher_.addMatchesInvolvingExpressions(ids);
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
             const std::vector<AtomsVector>& initialExpressions,
             const std::function<bool()> shouldAbort,
             const Generation maxGeneration) {
        implementation_ = std::make_shared<Implementation>(rules, initialExpressions, shouldAbort, maxGeneration);
    }
    
    int Set::replaceOnce() {
        return implementation_->replaceOnce();
    }
    
    int Set::replace(const int substitutionCount) {
        return implementation_->replace(substitutionCount);
    }
    
    std::vector<SetExpression> Set::expressions() const {
        return implementation_->expressions();
    }
}
