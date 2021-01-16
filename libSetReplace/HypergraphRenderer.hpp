#ifndef LIBSETREPLACE_HYPERGRAPHRENDERER_HPP_
#define LIBSETREPLACE_HYPERGRAPHRENDERER_HPP_

#include <string>

#include "Set.hpp"

namespace SetReplace {
/** @brief HypergraphRenderer is the class for high-performance rendering Set evolutions with Vulkan
 */
class HypergraphRenderer {
 public:
  /** @brief Type of the error occured during rendering.
   */
  enum class Error { Success };

  /** @brief Creates a renderer for the specific Set
   */
  HypergraphRenderer(const Set& set);

  Error renderEvolutionVideo(const std::string& filename, const std::pair<int, int>& size, const int fps);

 private:
  class Implementation;
  std::shared_ptr<Implementation> implementation_;
};
}  // namespace SetReplace

#endif  // LIBSETREPLACE_HYPERGRAPHRENDERER_HPP_
