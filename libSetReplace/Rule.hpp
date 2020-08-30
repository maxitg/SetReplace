#ifndef LIBSETREPLACE_RULE_HPP_
#define LIBSETREPLACE_RULE_HPP_

#include <vector>

#include "Expression.hpp"

namespace SetReplace {
/** @brief What kind of expression types the rule should match.
 */
enum class EventSelectionFunction {
  All = 0,       // match all events matching the input pattern
  Spacelike = 1  // only match spacelike groups of events
};

/** @brief Substitution rule used in the evolution.
 */
struct Rule {
  const std::vector<AtomsVector> inputs;
  const std::vector<AtomsVector> outputs;
  const EventSelectionFunction eventSelectionFunction;
};
}  // namespace SetReplace

#endif  // LIBSETREPLACE_RULE_HPP_
