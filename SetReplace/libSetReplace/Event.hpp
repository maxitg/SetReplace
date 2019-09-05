#ifndef Event_hpp
#define Event_hpp

#include <vector>

#include "IDTypes.hpp"

namespace SetReplace {
    /** @brief Substitution event that has already happened.
     */
    struct Event {
        /** @brief ID for the rule that this event corresponds to.
         */
        RuleID rule;
        
        /** @brief Expressions this event removed.
         */
        std::vector<ExpressionID> inputExpressions;
        
        /** @brief Expressions this event created.
         */
        std::vector<ExpressionID> outputExpressions;
    };
}

#endif /* Event_hpp */
