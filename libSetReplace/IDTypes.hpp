#ifndef LIBSETREPLACE_IDTYPES_HPP_
#define LIBSETREPLACE_IDTYPES_HPP_

#include <cstdint>
#include <vector>

namespace SetReplace {
/** @brief Identifiers for tokens, which are the elements of the multiset in the multiset system, and contain ordered
 * sequences of atoms, e.g., hyperedges in the hypergraph system.
 */
using TokenID = int64_t;

/** @brief Identifiers for atoms, which are the elements of tokens, e.g., vertices in the hypergraph in the hypergraph
 * system.
 * @details Positive IDs refer to specific atoms, negative IDs refer to patterns (as, for instance, can be used in the
 * rules).
 */
using Atom = int64_t;

/** @brief List of atoms without references to events, as can be used in, e.g., rule specification. Corresponds to
 * contents of tokens in the hypergraph system.
 */
using AtomsVector = std::vector<Atom>;

/** @brief Function type used to get a token's corresponding AtomsVector.
 */
using GetAtomsVectorFunc = std::function<const AtomsVector&(const TokenID&)>;

/** @brief Identifiers for rules, which stay the same for the entire evolution of the system.
 */
using RuleID = int;
constexpr RuleID initialConditionRule = -1;

/** @brief Identifiers for substitution events, later events have larger IDs.
 */
using EventID = int64_t;
constexpr EventID initialConditionEvent = 0;

/** @brief Layer this token belongs to in the causal graph.
 * @details Specifically, if the largest generation of tokens in the event inputs is n, the generation of its
 * outputs will be n + 1.
 */
using Generation = int64_t;
constexpr Generation initialGeneration = 0;
}  // namespace SetReplace

#endif  // LIBSETREPLACE_IDTYPES_HPP_
