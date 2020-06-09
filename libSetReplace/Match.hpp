#ifndef LIBSETREPLACE_MATCH_HPP_
#define LIBSETREPLACE_MATCH_HPP_

#include <memory>
#include <set>
#include <utility>
#include <vector>

#include "Expression.hpp"
#include "IDTypes.hpp"
#include "Rule.hpp"

namespace SetReplace {
/** @brief Match is a potential event that has not actualized yet.
 */
struct Match {
  /** @brief ID for the rule this match corresponds to.
   */
  RuleID rule;

  /** @brief Expression matching the rule inputs.
   */
  std::vector<ExpressionID> inputExpressions;
};

using MatchPtr = std::shared_ptr<const Match>;

/** @brief Matcher takes rules, atoms index, and a list of expressions, and returns all possible matches.
 * @details This contains the lowest-level code, and the main functionality of the library. Uses atomsIndex to discover
 * expressions, thus if an expression is absent from the atomsIndex, it would not appear in any matches.
 */
class Matcher {
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
    SortedExpressionIDs = First,
    ReverseSortedExpressionIDs = 1,
    ExpressionIDs = 2,
    RuleIndex = 3,
    Last = 4
  };

  /** @brief Whether to sort in normal or reverse order.
   *
   * If adding additional values, preserve First and Last, as these are used for valid enum checking.
   */
  enum class OrderingDirection { First = 0, Normal = First, Reverse = 1, Last = 2 };

  /** @brief Full specification for the sequence of ordering functions.
   */
  using OrderingSpec = std::vector<std::pair<OrderingFunction, OrderingDirection>>;

  /** @brief Creates a new matcher object.
   * @details This is an O(1) operation, does not do any matching yet.
   */
  Matcher(const std::vector<Rule>& rules,
          AtomsIndex* atomsIndex,
          const std::function<AtomsVector(ExpressionID)>& getAtomsVector,
          const OrderingSpec& orderingSpec,
          unsigned int randomSeed = 0);

  /** @brief Finds and adds to the index all matches involving specified expressions.
   * @details Calls shouldAbort() frequently, and throws Error::Aborted if that returns true. Otherwise might take
   * significant time to evaluate depending on the system.
   */
  void addMatchesInvolvingExpressions(const std::vector<ExpressionID>& expressionIDs,
                                      const std::function<bool()>& shouldAbort);

  /** @brief Removes matches containing specified expression IDs from the index.
   */
  void removeMatchesInvolvingExpressions(const std::vector<ExpressionID>& expressionIDs);

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

  /** @brief Replaces patterns in atomsToReplace with explicit atoms.
   * @param inputPatterns patterns corresponding to patternMatches.
   * @param patternMatches explicit atoms corresponding to patterns in inputPatterns.
   * @param atomsToReplace patterns, which would be replaced the same way as inputPatterns are matched to
   * patternMatches.
   */
  static bool substituteMissingAtomsIfPossible(const std::vector<AtomsVector>& inputPatterns,
                                               const std::vector<AtomsVector>& patternMatches,
                                               std::vector<AtomsVector>* atomsToReplace);

  /** @brief Returns the set of expression IDs matched in any match. */
  std::vector<MatchPtr> allMatches() const;

 private:
  class Implementation;
  std::shared_ptr<Implementation> implementation_;
};
}  // namespace SetReplace

#endif  // LIBSETREPLACE_MATCH_HPP_
