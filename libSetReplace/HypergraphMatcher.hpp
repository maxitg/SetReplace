#ifndef LIBSETREPLACE_HYPERGRAPHMATCHER_HPP_
#define LIBSETREPLACE_HYPERGRAPHMATCHER_HPP_

#include <memory>
#include <set>
#include <utility>
#include <vector>

#include "AtomsIndex.hpp"
#include "IDTypes.hpp"
#include "Rule.hpp"
#include "TokenEventGraph.hpp"

namespace SetReplace {
/** @brief HypergraphMatcher takes rules, atoms index, and a list of tokens, and returns all possible matches.
 * @details This contains the lowest-level code, and the main functionality of the library. Uses atomsIndex to discover
 * tokens, thus if an token is absent from the atomsIndex, it would not appear in any matches.
 */
class HypergraphMatcher {
 public:
  /** @brief Type of the error occurred during evaluation.
   */
  enum Error { None, Aborted, DisconnectedInputs, NoMatches, InvalidOrderingFunction, InvalidOrderingDirection };

  /** @brief All possible functions available to sort matches. Random is the default that is always applied last.
   *
   * If adding additional values, preserve First and Last, as these are used for valid enum checking.
   */
  enum class OrderingFunction {
    First = 0,
    SortedInputTokenIndices = First,
    ReverseSortedInputTokenIndices = 1,
    InputTokenIndices = 2,
    RuleIndex = 3,
    Any = 4,
    Last = 5
  };

  /** @brief Whether to sort in normal or reverse order.
   *
   * If adding additional values, preserve First and Last, as these are used for valid enum checking.
   */
  enum class OrderingDirection { First = 0, Normal = First, Reverse = 1, Last = 2 };

  /** @brief Full specification for the sequence of ordering functions.
   */
  using OrderingSpec = std::vector<std::pair<OrderingFunction, OrderingDirection>>;

  enum class EventDeduplication { None = 0, SameInputSetIsomorphicOutputs = 1 };

  /** @brief Creates a new matcher object.
   * @details This is an O(1) operation, does not do any matching yet.
   */
  HypergraphMatcher(const std::vector<Rule>& rules,
                    AtomsIndex* atomsIndex,
                    const GetAtomsVectorFunc& getAtomsVector,
                    const GetTokenSeparationFunc& getTokenSeparation,
                    const OrderingSpec& orderingSpec,
                    const EventDeduplication& eventDeduplication,
                    unsigned int randomSeed = 0);

  /** @brief Finds and adds to the index all matches involving specified tokens.
   * @details Calls shouldAbort() frequently, and throws Error::Aborted if that returns true. Otherwise might take
   * significant time to evaluate depending on the system.
   */
  void addMatchesInvolvingTokens(const std::vector<TokenID>& tokenIDs, const std::function<bool()>& shouldAbort);

  /** @brief Removes matches containing specified token IDs from the index.
   */
  void removeMatchesInvolvingTokens(const std::vector<TokenID>& tokenIDs);

  /** @brief Removes a single match from the index.
   */
  void deleteMatch(const MatchPtr matchPtr);

  /** @brief Yields true if there are no matches left.
   */
  bool empty() const;

  /** @brief Returns the match that should be substituted next.
   * @details Throws Error::NoMatches if there are no matches.
   */
  MatchPtr nextMatch() const;

  /** @brief Returns the set of token IDs matched in any match. */
  std::vector<MatchPtr> allMatches() const;

  /** @brief Yields the explicit atom vectors of the input tokens of a particular match.
   */
  std::vector<AtomsVector> matchInputAtomsVectors(const MatchPtr& match) const;

  /** @brief Yields the explicit atom vectors of the output tokens of a particular match.
   * @details Newly created atoms are left as patterns.
   */
  std::vector<AtomsVector> matchOutputAtomsVectors(const MatchPtr& match) const;

 private:
  class Implementation;
  std::shared_ptr<Implementation> implementation_;
};
}  // namespace SetReplace

#endif  // LIBSETREPLACE_HYPERGRAPHMATCHER_HPP_
