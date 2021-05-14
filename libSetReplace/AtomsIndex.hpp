#ifndef LIBSETREPLACE_ATOMSINDEX_HPP_
#define LIBSETREPLACE_ATOMSINDEX_HPP_

#include <functional>
#include <memory>
#include <unordered_set>
#include <vector>

#include "IDTypes.hpp"

namespace SetReplace {
/** @brief AtomsIndex keeps references to tokens accessible by atoms, which is useful for matching.
 */
class AtomsIndex {
 public:
  /** @brief Creates an empty index.
   * @param getAtomsVector datasource function that returns the list of atoms for a requested token.
   */
  explicit AtomsIndex(const GetAtomsVectorFunc& getAtomsVector);

  /** @brief Removes tokens with specified IDs from the index.
   */
  void removeTokens(const std::vector<TokenID>& tokenIDs);

  /** @brief Adds tokens with specified IDs to the index.
   */
  void addTokens(const std::vector<TokenID>& tokenIDs);

  /** @brief Returns the list of tokens containing a specified atom.
   */
  std::unordered_set<TokenID> tokensContainingAtom(Atom atom) const;

 private:
  class Implementation;
  std::shared_ptr<Implementation> implementation_;
};
}  // namespace SetReplace

#endif  // LIBSETREPLACE_ATOMSINDEX_HPP_
