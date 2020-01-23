#ifndef IDTypes_h
#define IDTypes_h

namespace SetReplace {
    /** @brief Type used for the output of the hash function used to name atoms and expressions.
     */
    using HashValue = __int128;

    /** @brief Identifiers for atoms, which are the elements of expressions, i.e., vertices in the graph.
     * @details Positive IDs refer to specific atoms, negative IDs refer to patterns (as, for instance, can be used in the rules).
     */
    using Atom = HashValue;
    
    /** @brief Identifiers for rules, which stay the same for the entire evolution of the system.
     */
    using RuleIndex = int;
    
    /** @brief Indices for expressions, which are the elements of the set, and contain ordered sequences of atoms, i.e., (hyper)edges in the graph.
     * @details Used in particular to determine the ages of expressions.
     */
    using ExpressionIndex = int;

    /** @brief Unique local identifier for an expression computed by hashing expressions used to produce it.
     * @details Is not affected by the age of expressions, and the evaluation order. I.e., evaluating two independent events in a different order would produce
     *          identical expression IDs.
     */
    using ExpressionID = HashValue;
    
    /** @brief Identifiers for substitution events, later events have larger IDs.
     */
    using EventIndex = int;
    constexpr EventIndex initialConditionEvent = 0;
    constexpr EventIndex finalStateEvent = -1;
    
    /** @brief Layer this expression belongs to in the causal network.
     * @details Specifically, if the largest generation of expressions in the event inputs is n, the generation of its outputs will be n + 1.
     */
    using Generation = int;
    constexpr Generation initialGeneration = 0;
}

#endif /* IDTypes_h */
