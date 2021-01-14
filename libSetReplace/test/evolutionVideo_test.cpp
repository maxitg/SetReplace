#include <gtest/gtest.h>

#include "HypergraphRenderer.hpp"
#include "Set.hpp"

namespace SetReplace {

constexpr auto doNotAbort = []() { return false; };

// Tests whether CPU parallelism is reported as unavailable in the correct cases.
TEST(evolutionVideo, FileIsProduced) {
  const std::vector<Rule> rules = {Rule({{{-1}, {-1, -2}}, {{-2}}, EventSelectionFunction::All})};
  const std::vector<AtomsVector> initialExpressions = {{1}, {1, 2}, {3}, {3, 4}, {2, 5}, {4, 5}, {5, 6}};
  const Matcher::OrderingSpec orderingSpec = {
      {Matcher::OrderingFunction::SortedExpressionIDs, Matcher::OrderingDirection::Normal},
      {Matcher::OrderingFunction::ReverseSortedExpressionIDs, Matcher::OrderingDirection::Normal},
      {Matcher::OrderingFunction::ExpressionIDs, Matcher::OrderingDirection::Normal},
      {Matcher::OrderingFunction::RuleIndex, Matcher::OrderingDirection::Normal}};
  constexpr auto eventDeduplication = Matcher::EventDeduplication::None;
  constexpr unsigned int randomSeed = 0;
  Set set(rules, initialExpressions, Set::SystemType::Multiway, orderingSpec, eventDeduplication, randomSeed);
  HypergraphRenderer renderer(set);
  renderer.renderEvolutionVideo(
      "/private/var/folders/f_/klrm3n7d4_989wy4dxx9_l9c0000gn/T/SetReplace/evolutionVideo/video.mp4", doNotAbort);
}

}  // namespace SetReplace
