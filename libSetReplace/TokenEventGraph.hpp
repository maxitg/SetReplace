#ifndef LIBSETREPLACE_TOKENEVENTGRAPH_HPP_
#define LIBSETREPLACE_TOKENEVENTGRAPH_HPP_

#include <memory>
#include <vector>

#include "AtomsIndex.hpp"
#include "IDTypes.hpp"

namespace SetReplace {
/** @brief Match is a potential event that has not actualized yet.
 */
struct Match {
  /** @brief ID for the rule this match corresponds to.
   */
  RuleID rule;

  /** @brief Tokens matching the rule inputs.
   */
  std::vector<TokenID> inputTokens;
};

using MatchPtr = std::shared_ptr<const Match>;

/** @brief Event is an instantiated replacement that has taken place in the system.
 */
struct Event {
  /** @brief ID for the rule this event corresponds to.
   */
  const RuleID rule;

  /** @brief Tokens matching the rule inputs.
   */
  const std::vector<TokenID> inputTokens;

  /** @brief Tokens created from the rule outputs.
   */
  const std::vector<TokenID> outputTokens;

  /** @brief Layer of the causal graph this event belongs to.
   */
  const Generation generation;
};

/** @brief Type of separation between tokens.
 */
enum class SeparationType {
  Unknown,    // Lookup not possible (i.e., SeparationTrackingMethod is None)
  Identical,  // The token IDs requested are the same
  Timelike,   // One token causally depends on the another
  Spacelike,  // Tokens are compatible (created by an event)
  Branchlike  // Tokens are incompatible (created from the same expression)
};

using GetTokenSeparationFunc = std::function<SeparationType(const TokenID&, const TokenID&)>;

/** @brief TokenEventGraph keeps track of causal relationships between events and tokens.
 @details It does not care and does not know about atoms at all because they are only used for matching. Tokens are
 only identified by IDs.
 */
class TokenEventGraph {
 public:
  /** @brief Whether and what kind of separation (timelike, spacelike, branchlike) between tokens should be
   tracked.
   @details This tracking is in general expensive, so it should be disabled if not needed. It is however much faster to
   precompute it during evolution than compute it on demand. Only supported for spacelike systems.
   */
  enum class SeparationTrackingMethod {
    None,             // lookup impossible
    DestroyerChoices  // O(events * tokens) in memory and time, O(tokens) lookup
  };

  /** @brief Creates a new TokenEventGraph with a given number of initial tokens.
   */
  explicit TokenEventGraph(int initialTokenCount, SeparationTrackingMethod separationTrackingMethod);

  /** @brief Adds a new event, names its output tokens, and returns their IDs.
   */
  std::vector<TokenID> addEvent(RuleID ruleID, const std::vector<TokenID>& inputTokens, int outputTokenCount);

  /** @brief Yields a vector of all events throughout history.
   @details This includes the initial event, so the size of the result is one larger than eventsCount().
   */
  const std::vector<Event>& events() const;

  /** @brief Total number of events.
   */
  size_t eventsCount() const;

  /** @brief Yields a vector of IDs for all tokens in the causal graph.
   */
  std::vector<TokenID> allTokenIDs() const;

  /** @brief Total number of tokens.
   */
  size_t tokenCount() const;

  /** @brief Generation for a given token.
   * @details This is the same as the generation of its creator event.
   */
  Generation tokenGeneration(TokenID id) const;

  /** @brief Largest generation of any event.
   */
  Generation largestGeneration() const;

  /** @brief Computes the separation type between tokens (timelike, spacelike or branchlike).
   @details Fails if SeparationTrackingMethod is disabled.
   */
  SeparationType tokenSeparation(TokenID first, TokenID second) const;

  /** @brief Number of destroyer events per token.
   */
  uint64_t destroyerEventsCount(TokenID id) const;

 private:
  class Implementation;
  std::shared_ptr<Implementation> implementation_;
};
}  // namespace SetReplace

#endif  // LIBSETREPLACE_TOKENEVENTGRAPH_HPP_
