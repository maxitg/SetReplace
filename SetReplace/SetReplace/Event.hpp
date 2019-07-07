#ifndef Match_hpp
#define Match_hpp

#include <optional>
#include <vector>

#include "Rule.hpp"

namespace SetReplace {
    using ExpressionID = int;
    
    struct Expression;
    struct Event {
        /** @brief Order in which the march was created.
         * @details Note, this is not the same as the order in which events are evaluated (which corresponds to creating outputs).
         */
        int id;
        
        /** @brief Rule governing this event.
         */
        std::vector<Rule>::const_iterator rule;
        
        /** @brief Pointer to the vector of all expressions in the set.
         */
        std::vector<Expression>* setExpressions;
        
        /** @brief Expression iterators the rule input matches to.
         */
        std::vector<ExpressionID> inputs;
        
        /** @brief Expression iterators to the rule output. No value if the event is not created yet.
         */
        std::optional<std::vector<ExpressionID>> outputs;
        
        /** @brief Compares events according to evaluation order.
         * @details Events evaluated earlier are smaller.
         */
        bool operator<(const Event& other) const;
        
        /** @brief Yields true if the event has been actually created, and its output exists in the expressions set.
         */
        bool actualized() const;
        
        /** @brief Yields true if evaluating this event would create a new branch in the multiway system, and false otherwise.
         */
        bool wouldBranch() const;
        
        /** @brief Generation of the expressions created by this event.
         */
        int generation() const;
    };
}

#endif /* Match_hpp */
