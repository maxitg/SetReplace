#include "HypergraphRenderer.hpp"

#include <fstream>

namespace SetReplace {
class HypergraphRenderer::Implementation {
 private:
  const Set& set_;

 public:
  Implementation(const Set& set) : set_(set) {}

  Error renderEvolutionVideo(const std::string& filename, const std::pair<int, int>& size, const int fps) {
    std::ofstream out(filename);
    out << size.first << " " << size.second << " " << fps << std::endl;
    out.close();
    return Error::Success;
  }
};

HypergraphRenderer::HypergraphRenderer(const Set& set) : implementation_(std::make_shared<Implementation>(set)) {}

HypergraphRenderer::Error HypergraphRenderer::renderEvolutionVideo(const std::string& filename,
                                                                   const std::pair<int, int>& size,
                                                                   const int fps) {
  return implementation_->renderEvolutionVideo(filename, size, fps);
}
}  // namespace SetReplace
