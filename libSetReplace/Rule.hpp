#ifndef LIBSETREPLACE_RULE_HPP_
#define LIBSETREPLACE_RULE_HPP_

#include <vector>

#include "Expression.hpp"

namespace SetReplace {
/** @brief Substitution rule used in the evolution.
 */
struct Rule {
  const std::vector<AtomsVector> inputs;
  const std::vector<AtomsVector> outputs;
};
}  // namespace SetReplace

#endif  // LIBSETREPLACE_RULE_HPP_
