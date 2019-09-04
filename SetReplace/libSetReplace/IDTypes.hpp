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
    constexpr EventID initialConditionEvent = 0;
    constexpr EventID finalStateEvent = -1;
    
    /** @brief Layer this expression belongs to in the causal network.
     * @details Specifically, if the largest generation of expressions in the event inputs is n, the generation of its outputs will be n + 1.
     */
    using Generation = int;
    constexpr Generation initialGeneration = 0;
}

#endif /* IDTypes_h */
