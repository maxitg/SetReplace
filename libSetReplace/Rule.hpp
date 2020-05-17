#ifndef Rule_hpp
#define Rule_hpp

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

#endif /* Rule_hpp */
