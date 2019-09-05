#ifndef IDTypes_h
#define IDTypes_h

namespace SetReplace {
    /** @brief Identifiers for atoms, which are the elements of expressions, i.e., vertices in the graph.
     * @details Positive IDs refer to specific atoms, negative IDs refer to patterns (as, for instance, can be used in the rules).
     */
    using Atom = int;
    
    /** @brief Identifiers for rules, which stay the same for the entire evolution of the system.
     */
    using RuleID = int;
    
    /** @brief Identifiers for expressions, which are the elements of the set, and contain ordered sequences of atoms, i.e., (hyper)edges in the graph.
     */
    using ExpressionID = int;
    
    /** @brief Identifiers for substitution events, later events have larger IDs.
     */
    using EventID = int;
    constexpr EventID initialConditionEvent = -1;
    constexpr EventID finalStateEvent = -2;
}

#endif /* IDTypes_h */
