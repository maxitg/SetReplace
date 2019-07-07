#include "Event.hpp"
#include "Set.hpp"

#include <algorithm>
#include <set>
#include <string>
#include <unordered_map>
#include <unordered_set>

namespace SetReplace {
    class Set::Implementation {
    private:
        // Function to call to check if Wolfram Language abort is in progress.
        const std::function<bool()> shouldAbort_;
        
        int nextAtom_ = 0;
        const std::vector<Rule> rules_;
        std::vector<Expression> expressions_;
        int nextEventID_ = 0;
        std::set<Event> events_;
        
        // Will become false if there are multiple future events possible for a single expression.
        bool isConfluent_ = true;
        
        std::unordered_map<Atom, std::unordered_set<ExpressionID>> atomsIndex_;
        
    public:
        Implementation(const std::vector<Rule>& rules,
                       const std::vector<AtomsVector>& initialExpressions,
                       const std::function<bool()> shouldAbort) :
        rules_(rules),
        shouldAbort_(shouldAbort) {
            for (const auto& atoms : initialExpressions) {
                for (const Atom atom : atoms) {
                    nextAtom_ = std::max(nextAtom_ - 1, atom) + 1;
                }
            }
            addExpressions(initialExpressions, events_.end());
        }
        
        int createEvents(const int count) {
            int actualCount = 0;
            for (int i = 0; i < count && futureEventsExist(); ++i) {
                actualCount += createEvent();
            }
            return actualCount;
        }
        
        int replaceUptoGeneration(const int maxGeneration) {
            while (createEvent(maxGeneration));
            if (!expressions_.empty()) {
                return (expressions_.end() - 1)->generation;
            } else {
                return 0;
            }
        }
        
        const std::vector<Expression>& expressions() const {
            return expressions_;
        }
        
        const std::set<Event>& events() const {
            return events_;
        }
        
        bool isConfluent() const {
            return isConfluent_;
        }
        
    private:
        bool addExpressions(const std::vector<AtomsVector>& atomVectors,
                            std::set<Event>::const_iterator preceedingEvent,
                            const int maxGeneration = std::numeric_limits<int>::max()) {
            const auto indices = addToExpressionsVector(atomVectors, preceedingEvent, maxGeneration);
            if (indices.has_value()) {
                addToAtomsIndex(*indices);
                addMatches(*indices);
                return true;
            }
            return false;
        }
        
        std::optional<std::vector<size_t>> addToExpressionsVector(
                                                const std::vector<AtomsVector>& atomsVectors,
                                                const std::set<Event>::const_iterator preceedingEvent,
                                                const int maxGeneration) {
            int generation = 0;
            Event newEvent;
            if (preceedingEvent != events_.end()) {
                generation = preceedingEvent->generation();
                
                newEvent = *preceedingEvent;
                newEvent.outputs = std::make_optional<std::vector<ExpressionID>>();
            }
            if (generation > maxGeneration) {
                return std::nullopt;
            }
            
            std::vector<size_t> indices;
            for (const auto& atomsVector : atomsVectors) {
                indices.push_back(expressions_.size());
                Expression newExpression;
                newExpression.atoms = atomsVector;
                newExpression.generation = generation;
                newExpression.id = static_cast<int>(expressions_.size());
                if (preceedingEvent == events_.end()) {
                    newExpression.precedingEvent = events_.end();
                }
                expressions_.push_back(newExpression);
                if (preceedingEvent != events_.end()) {
                    newEvent.outputs->push_back(newExpression.id);
                }
            }
            
            if (preceedingEvent != events_.end()) {
                const auto newEventIt = events_.insert(newEvent).first;
                for (const auto expressionID : *newEvent.outputs) {
                    expressions_[expressionID].precedingEvent = newEventIt;
                }
                
                const auto expressionsBeforePreceedingEvent = preceedingEvent->inputs;
                for (const auto pastExpressionID : expressionsBeforePreceedingEvent) {
                    expressions_[pastExpressionID].succedingEvents.erase(preceedingEvent);
                    expressions_[pastExpressionID].succedingEvents.insert(newEventIt);
                }
                
                events_.erase(preceedingEvent);
            }
            
            return std::make_optional(indices);
        }
        
        void addToAtomsIndex(const std::vector<size_t>& indices) {
            for (const auto index : indices) {
                for (const auto atom : expressions_[index].atoms) {
                    atomsIndex_[atom].insert(index);
                }
            }
        }
        
        void addMatches(const std::vector<size_t>& expressionIDs) {
            for (int ruleID = 0; ruleID < rules_.size(); ++ruleID) {
                addMatches(expressionIDs, ruleID);
            }
        }
        
        void addMatches(const std::vector<size_t>& expressionIDs, const int ruleID) {
            for (int ruleInputIndex = 0; ruleInputIndex < rules_[ruleID].inputs.size(); ++ruleInputIndex) {
                std::vector<int> emptyMatch(rules_[ruleID].inputs.size(), -1);
                addMatches(emptyMatch, ruleID, rules_[ruleID].inputs, ruleInputIndex, expressionIDs);
            }
        }
        
        void addMatches(const std::vector<int>& currentMatch,
                        const int ruleID,
                        const std::vector<AtomsVector>& inputs,
                        const int nextInputID,
                        const std::vector<size_t>& potentialExpressionIDs) {
            for (const auto expressionID : potentialExpressionIDs) {
                if (expressionUnused(currentMatch, expressionID)) {
                    addMatches(currentMatch, ruleID, inputs, nextInputID, expressionID);
                }
            }
        }
        
        static bool expressionUnused(const std::vector<int>& match, const size_t expressionID) {
            for (int id = 0; id < match.size(); ++id) {
                if (match[id] == expressionID) return false;
            }
            return true;
        }
        
        void addMatches(const std::vector<int>& currentMatch,
                        const int ruleID,
                        const std::vector<AtomsVector>& inputs,
                        const int nextInputID,
                        const size_t expressionID) {
            const auto& input = inputs[nextInputID];
            const auto& expressionAtoms = expressions_[expressionID].atoms;
            if (input.size() != expressionAtoms.size()) return;
            
            std::vector<int> newCurrentMatch = currentMatch;
            newCurrentMatch[nextInputID] = static_cast<int>(expressionID);
            
            auto newInputs = inputs;
            if (replaceExplicit({input}, {expressionAtoms}, newInputs)) {
                addMatches(newCurrentMatch, ruleID, newInputs);
            }
        }
        
        static bool replaceExplicit(const std::vector<AtomsVector> patterns,
                                    const std::vector<AtomsVector> patternMatches,
                                    std::vector<AtomsVector>& expressions) {
            if (patterns.size() != patternMatches.size()) return false;
            
            std::unordered_map<Atom, Atom> match;
            for (int i = 0; i < patterns.size(); ++i) {
                const auto& pattern = patterns[i];
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
            
            for (int i = 0; i < expressions.size(); ++i) {
                for (int j = 0; j < expressions[i].size(); ++j) {
                    if (match.count(expressions[i][j])) {
                        expressions[i][j] = match[expressions[i][j]];
                    }
                }
            }
            return true;
        }
        
        void addMatches(const std::vector<int>& currentMatch,
                        const int ruleID,
                        const std::vector<AtomsVector>& inputs) {
            // check if we need to abort, this is the code that is called frequently during matching
            if (shouldAbort_()) {
                throw Error::Aborted;
            }
            if (matchComplete(currentMatch)) {
                createEvent(currentMatch, ruleID);
                return;
            }
            
            int nextInputID = -1;
            std::vector<size_t> potentialExpressionIDs;
            bool anonymousAtomsPresent = false;
            
            for (int i = 0; i < inputs.size(); ++i) {
                if (currentMatch[i] != -1) continue;
                
                std::unordered_set<Atom> requiredAtoms;
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
                
                std::unordered_map<size_t, int> requiredAtomsCounts;
                for (const auto atom : requiredAtoms) {
                    for (const auto& expressionID : atomsIndex_[atom]) {
                        requiredAtomsCounts[expressionID]++;
                    }
                }
                
                std::vector<size_t> candidateExpressionIDs;
                for (const auto& expressionCount : requiredAtomsCounts) {
                    if (expressionCount.second == requiredAtoms.size() &&
                            areCausallyIndependent(currentMatch, expressionCount.first)) {
                        candidateExpressionIDs.push_back(expressionCount.first);
                    }
                }
                
                if (nextInputID == -1 || candidateExpressionIDs.size() < potentialExpressionIDs.size()) {
                    potentialExpressionIDs = candidateExpressionIDs;
                    nextInputID = i;
                }
            }
            
            if (nextInputID == -1 && anonymousAtomsPresent) {
                throw std::string("Inputs of rule ") + std::to_string(ruleID) + std::string(" are not connected.");
            } else if (nextInputID == -1) {
                return;
            }
            
            addMatches(currentMatch, ruleID, inputs, nextInputID, potentialExpressionIDs);
        }
        
        // check that all expression IDs in the match refer to global expressions (i.e., are non-negative)
        static bool matchComplete(const std::vector<int>& match) {
            for (int i = 0; i < match.size(); ++i) {
                if (match[i] < 0) return false;
            }
            return true;
        }
        
        void createEvent(const std::vector<int>& currentMatch, const int ruleID) {
            Event newEvent;
            newEvent.setExpressions = &expressions_;
            newEvent.id = nextEventID_++;
            newEvent.inputs.reserve(currentMatch.size());
            for (const int expressionID : currentMatch) {
                newEvent.inputs.push_back(expressionID);
            }
            newEvent.rule = rules_.begin() + ruleID;
            
            const auto eventIteratorSuccess = events_.insert(newEvent);
            const auto eventIterator = eventIteratorSuccess.first;
            const auto success = eventIteratorSuccess.second;
            if (success) {
                for (const auto expressionID : currentMatch) {
                    const auto expressionIterator = expressions_.begin() + expressionID;
                    expressionIterator->succedingEvents.insert(eventIterator);
                    if (expressionIterator->succedingEvents.size() > 1) {
                        isConfluent_ = false;
                    }
                }
            } else {
                --nextEventID_;
            }
        }
        
        bool areCausallyIndependent(const std::vector<int>& firstIDs, const size_t secondID) const {
            for (const int firstID : firstIDs) {
                if (firstID >= 0 && !areCausallyIndependent(static_cast<size_t>(firstID), secondID)) {
                    return false;
                }
            }
            return true;
        }
        
        bool areCausallyIndependent(const size_t firstID, const size_t secondID) const {
            return !expressions_[firstID].isInTheFutureOf(expressions_[secondID]) &&
                !expressions_[secondID].isInTheFutureOf(expressions_[firstID]);
        }
        
        bool futureEventsExist() const {
            return !events_.empty() && !events_.begin()->actualized();
        }
        
        // Create event but only if new expressions have generations no larger than maxGeneration
        int createEvent(int maxGeneration = std::numeric_limits<int>::max()) {
            if (!futureEventsExist()) {
                return 0;
            }
            auto match = events_.begin();
            while (match->wouldBranch()) {
                // Disallow branching
                // TODO(maxitg): It should be a multiway system instead of this
                match++;
                if (match == events_.end()) {
                    return 0;
                }
            }
            
            const auto& ruleInputs = match->rule->inputs;
            std::vector<AtomsVector> inputAtomsVectors;
            for (const auto& inputExpression : match->inputs) {
                inputAtomsVectors.push_back(expressions_[inputExpression].atoms);
            }
            
            auto explicitRuleInputs = ruleInputs;
            replaceExplicit(ruleInputs, inputAtomsVectors, explicitRuleInputs);
            auto explicitRuleOutputs = match->rule->outputs;
            replaceExplicit(ruleInputs, inputAtomsVectors, explicitRuleOutputs);
            const auto namedRuleOutputs = nameAnonymousAtoms(explicitRuleOutputs);
            
            return addExpressions(namedRuleOutputs, match, maxGeneration);
        }
        
        std::vector<AtomsVector> nameAnonymousAtoms(const std::vector<AtomsVector>& expressions) {
            std::unordered_map<Atom, Atom> names;
            std::vector<AtomsVector> result = expressions;
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
    };
    
    Set::Set(const std::vector<Rule>& rules,
             const std::vector<AtomsVector>& initialExpressions,
             const std::function<bool()> shouldAbort) {
        implementation_ = std::make_shared<Implementation>(rules, initialExpressions, shouldAbort);
    }
    
    int Set::createEvents(const int count) {
        return implementation_->createEvents(count);
    }
    
    int Set::replaceUptoGeneration(const int maxGeneration) {
        return implementation_->replaceUptoGeneration(maxGeneration);
    }
    
    const std::vector<Expression>& Set::expressions() const {
        return implementation_->expressions();
    }
    
    const std::set<Event>& Set::events() const {
        return implementation_->events();
    }
    
    bool Set::isConfluent() const {
        return implementation_->isConfluent();
    }
}
