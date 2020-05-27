#ifndef LIBSETREPLACE_EXPRESSION_HPP_
#define LIBSETREPLACE_EXPRESSION_HPP_

#include <functional>
#include <memory>
#include <unordered_set>
#include <vector>

#include "IDTypes.hpp"

namespace SetReplace {
/** @brief List of atoms without references to events, as can be used in, i.e., rule specification.
 */
using AtomsVector = std::vector<Atom>;

/** @brief Expression, as a part of the set, i.e., (hyper)edges in the graph.
 */
struct SetExpression {
  /** @brief Ordered list of atoms the expression contains.
   */
  AtomsVector atoms;

  /** @brief Substitution event that has this expression as part of its output.
   */
  EventID creatorEvent;

  /** @brief Substitution events that have this expression as part of their inputs.
   */
  std::vector<EventID> destroyerEvents = {};

  /** @brief Layer of the causal network this expression belongs to.
   */
  Generation generation;
};

/** @brief AtomsIndex keeps references to set expressions accessible by atoms, which is useful for matching.
 */
class AtomsIndex {
 public:
  /** @brief Creates an empty index.
   * @param getAtomsVector datasource function that returns the list of atoms for a requested expression.
   */
  explicit AtomsIndex(const std::function<AtomsVector(ExpressionID)>& getAtomsVector);

  /** @brief Removes expressions with specified IDs from the index.
   */
  void removeExpressions(const std::vector<ExpressionID>& expressionIDs);

  /** @brief Adds expressions with specified IDs to the index.
   */
  void addExpressions(const std::vector<ExpressionID>& expressionIDs);

  /** @brief Returns the list of expressions containing a specified atom.
   */
  std::unordered_set<ExpressionID> expressionsContainingAtom(Atom atom) const;

 private:
  class Implementation;
  std::shared_ptr<Implementation> implementation_;
};
}  // namespace SetReplace

#endif  // LIBSETREPLACE_EXPRESSION_HPP_
