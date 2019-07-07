#include "Event.hpp"
#include "Expression.hpp"

#include <algorithm>
#include <vector>

namespace SetReplace {
    namespace {
        int compareVectors(const std::vector<ExpressionID>& first,
                           const std::vector<ExpressionID>& second) {
            for (int i = 0; i < std::min(first.size(), second.size()); ++i) {
                if (first[i] < second[i]) return -1;
                else if (first[i] > second[i]) return +1;
            }
            
            if (first.size() < second.size()) return -1;
            else if (first.size() > second.size()) return 1;
            else return 0;
        }
        
        int compareSortedIDs(const Event& first, const Event& second, const bool reverseOrder) {
            std::vector<std::vector<ExpressionID>> inputs;
            for (auto& originalInputs : {first.inputs, second.inputs}) {
                inputs.push_back(originalInputs);
                const auto last = inputs.end() - 1;
                std::sort(last->begin(), last->end());
                if (reverseOrder) {
                    std::reverse(last->begin(), last->end());
                }
            }
            
            return compareVectors(inputs[0], inputs[1]);
        }
        
        int compareUnsortedIDs(const Event& first, const Event& second) {
            return compareVectors(first.inputs, second.inputs);
        }
    }
    
    bool Event::operator<(const Event& other) const {
        //TODO(maxitg): First, check equality, i.e., are the input expressions exactly the same, or if they are in different orders, check if the symmetry is nevertheless preserved.
        
        // Put actualized events at the end. This must be the first sorting parameter, otherwise Set will stop evaluating.
        if (this->actualized() != other.actualized()) {
            return this->actualized() < other.actualized();
        }
        
        // First find matches with oldest newest IDs,
        // note this will automatically make events in smallest generations smaller.
        int comparison = compareSortedIDs(*this, other, true);
        if (comparison != 0) return comparison < 0;
        
        // Then, use smaller permutation
        comparison = compareUnsortedIDs(*this, other);
        if (comparison != 0) return comparison < 0;
        
        // Finally, if matches are exactly the same, use the rule with smaller ID
        return rule < other.rule;
    }
    
    bool Event::actualized() const {
        return this->outputs.has_value();
    }
    
    bool Event::wouldBranch() const {
        for (const auto& inputID : inputs) {
            const auto& expression = setExpressions->at(inputID);
            const auto& futureEvents = expression.succedingEvents;
            for (const auto& event : futureEvents) {
                if (event->actualized()) {
                    return true;
                }
            }
        }
        return false;
    }
    
    int Event::generation() const {
        int generation = 0;
        for (const auto& expression : inputs) {
            generation = std::max(generation, setExpressions->at(expression).generation + 1);
        }
        return generation;
    }
}
