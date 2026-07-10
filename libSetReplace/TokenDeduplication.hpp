#ifndef LIBSETREPLACE_TOKENDEDUPLICATION_HPP_
#define LIBSETREPLACE_TOKENDEDUPLICATION_HPP_

#include <functional>
#include <unordered_map>
#include <vector>

#include "IDTypes.hpp"
#include "TokenEventGraph.hpp"

namespace SetReplace {
/** @brief Equivalence classes of tokens, events and atoms produced by token deduplication.
 * @details Each class is named by its smallest member ID. A token-event graph quotiented by these classes is a
 * compressed presentation of the original multihistory: tokens (and events) that are guaranteed to have isomorphic
 * futures are collapsed into a single vertex. In particular, periodic evolutions produce cycles in the quotient.
 */
struct TokenDeduplicationResult {
  /** @brief Class representative (smallest equivalent token ID) for each token.
   */
  std::vector<TokenID> tokenClasses;

  /** @brief Class representative for each event, including the initial event at index 0.
   */
  std::vector<EventID> eventClasses;

  /** @brief Class representative for each atom that required renaming. Atoms not present are their own
   * representatives.
   */
  std::unordered_map<Atom, Atom> atomClasses;
};

/** @brief Errors that can occur during deduplication.
 */
enum class TokenDeduplicationError {
  Aborted,             // shouldAbort() returned true
  InconsistentInput,   // tokens/events do not describe a valid token-event graph
  InconsistentClasses  // internal consistency check of the computed classes failed (a bug if it ever happens)
};

/** @brief Computes equivalence classes of tokens that can be deduplicated without changing possible evolution.
 * @details Two tokens are merged if the multihistories obtained by deleting their causal pasts are isomorphic with an
 * isomorphism mapping one token to the other, the tokens can never coexist in a single state (i.e., they are not
 * spacelike separated: states are multisets, so the number of identical tokens matters for matching), and any atom
 * renamings the isomorphism performs only involve independent atoms (atoms that never co-occur in a spacelike set of
 * tokens). Both conditions are two facets of the same requirement: every state must map injectively into the
 * quotient. Instead of pairwise isomorphism checks, the implementation incrementally constructs the correspondence
 * and merges entire orbits, so time-translation symmetries of periodic evolutions collapse into cycles.
 * @param tokens contents (atom vectors) for every token ID, as returned by HypergraphSubstitutionSystem::tokens().
 * @param events all events including the initial event at index 0, as returned by
 * HypergraphSubstitutionSystem::events().
 * @param completeGenerations events of this generation or smaller are assumed to be completely evolved. The
 * correspondence between merged tokens is verified exactly within these generations. Parts of the correspondence
 * beyond them cannot be verified, but (for multiway systems) are determined by the verified parts, since the future
 * of a multihistory is a function of its tokens. Pass a value at least as large as the largest generation for
 * evolutions that terminated on their own.
 * @param largestNamedAtom atoms up to this value are explicitly named (e.g., they occur in the initial condition or
 * are referenced by the rules, so they are distinguishable by the evolution). Two distinct named atoms are never
 * identified with each other. A named atom can still be identified with created (unnamed) atoms, in which case it
 * becomes the class representative (named atoms are expected to be smaller than all unnamed ones).
 * @param shouldAbort function that returns true if the computation should be aborted (throws
 * TokenDeduplicationError::Aborted).
 */
TokenDeduplicationResult deduplicateTokens(const std::vector<AtomsVector>& tokens,
                                           const std::vector<Event>& events,
                                           Generation completeGenerations,
                                           Atom largestNamedAtom,
                                           const std::function<bool()>& shouldAbort);
}  // namespace SetReplace

#endif  // LIBSETREPLACE_TOKENDEDUPLICATION_HPP_
