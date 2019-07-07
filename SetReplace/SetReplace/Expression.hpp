#ifndef Expression_hpp
#define Expression_hpp

#include <set>
#include <unordered_set>
#include <vector>

#include "Event.hpp"

namespace SetReplace {    
    /** @brief Minimal number of replacements needed to reach this expression starting from initial conditions.
     * @details Equivalent as the depth of causal network at the creation event for this expression.
     */
    using Generation = int;
    
    /** @brief Identifier of the branch of the multiway system to which the expression belongs to.
     */
    using Branch = int; /* might be a reference to a branch struct later */
    
    struct Expression {
        /** @brief Index in the order the expression was created.
         */
        int id;
        
        /** @brief Vector of atoms constituting the expression.
         * @details All atoms in the list must be global references, and thus non-negative.
         */
        AtomsVector atoms;
        
        /** @brief Generation this expression belongs to.
         * @details Must be non-negative, where 0 refers to initial condition.
         */
        Generation generation;
                
        /** @brief Event that created this expression.
         */
        std::set<Event>::const_iterator precedingEvent;
        
        struct SetIteratorHash { size_t operator()(std::set<Event>::const_iterator) const; };
        /** @brief Events which have this expression as an input.
         * @details These events are not necessarily evaluated yet, and could just be references to potential matches.
         */
        std::unordered_set<std::set<Event>::const_iterator, SetIteratorHash> succedingEvents;
        
        bool isInTheFutureOf(const Expression& other) const;
    };
}

#endif /* Expression_hpp */
