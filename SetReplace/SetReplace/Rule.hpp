#ifndef Rule_hpp
#define Rule_hpp

#include <vector>

namespace SetReplace {
    /** @brief Atoms are represented by integers.
     * @details Negative atoms represent unfilled pattern slots, non-negative are global references to existing atoms.
     */
    using Atom = int;
    
    /** @brief Vector of atoms constituting a single expression in a set.
     */
    using AtomsVector = std::vector<Atom>;
    
    /** @brief One of the rules that are used to generate events.
     * @details Rule consists of two sets: an input pattern that is matched to a subset of expressions that would be removed, and the output that are newly created expressions.
     */
    struct Rule {
        /** @brief Index of the rule in the list of rules.
         * @details In some cases controls precedence of rule applications.
         */
        int id;
        
        /** @brief Represents a set of patterns that are matched to a subset.
         * @details Non-negative atoms are global references, negative atoms are consistently matched with any atoms in the set.
         */
        std::vector<AtomsVector> inputs;
        
        /** @brief Represents a set of expressions that would be added after the event.
         * @details Non-negative atoms would be added as-is. Negative atoms that appear in inputs would be matched with corresponding existing expressions. Negative atoms that do not appear in inputs would be newly created and assigned new positive IDs.
         */
        std::vector<AtomsVector> outputs;
    };
}

#endif /* Rule_hpp */
