#ifndef LIBSETREPLACE_HYPERGRAPH_RENDERER_HPP_
#define LIBSETREPLACE_HYPERGRAPH_RENDERER_HPP_

#include "Set.hpp"

namespace SetReplace {
/** @brief HypergraphRenderer renders videos of Set evolution.
 */
class HypergraphRenderer {
 public:
  HypergraphRenderer(const Set& set);

  bool renderEvolutionVideo(const std::string& filename, const std::function<bool()>& shouldAbort);

 private:
  class Implementation;
  std::shared_ptr<Implementation> implementation_;
};
}  // namespace SetReplace

#endif  // LIBSETREPLACE_HYPERGRAPH_RENDERER_HPP_
