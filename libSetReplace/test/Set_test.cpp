#include "Set.hpp"

#include <vector>

#include <gtest/gtest.h>

#include "Match.hpp"
#include "Rule.hpp"

namespace SetReplace {
Set testSet(const Set::EventSelectionFunction eventSelectionFunction) {
  // Negative atoms refer to patterns (useful for rules)
  std::vector<Rule> rules;
  auto aRule = Rule({{{-1}, {-1, -2}}, {{-2}}});
  rules.push_back(aRule);

  // make two "particles" {1} and {3} which will traverse the graph deleting edges in their path
  std::vector<AtomsVector> initialExpressions = {{1}, {1, 2}, {3}, {3, 4}, {2, 5}, {4, 5}, {5, 6}};

  Matcher::OrderingSpec orderingSpec = {
    {Matcher::OrderingFunction::SortedExpressionIDs, Matcher::OrderingDirection::Normal},
    {Matcher::OrderingFunction::ReverseSortedExpressionIDs, Matcher::OrderingDirection::Normal},
    {Matcher::OrderingFunction::ExpressionIDs, Matcher::OrderingDirection::Normal},
    {Matcher::OrderingFunction::RuleIndex, Matcher::OrderingDirection::Normal}};
  unsigned int randomSeed = 0;
  return Set(rules, initialExpressions, eventSelectionFunction, orderingSpec, randomSeed);
}

constexpr auto doNotAbort = []() { return false; };

TEST(Set, globalSpacelike) {
  Set aSet = testSet(Set::EventSelectionFunction::GlobalSpacelike);
  Set::StepSpecification stepSpec;
  stepSpec.maxEvents = 2;
  EXPECT_EQ(aSet.replace(stepSpec, doNotAbort), 2);
  EXPECT_EQ(aSet.maxCompleteGeneration(doNotAbort), 1);
  EXPECT_EQ(aSet.terminationReason(), Set::TerminationReason::MaxEvents);
  EXPECT_EQ(aSet.expressions(), (std::vector<AtomsVector>{{1}, {1, 2}, {3}, {3, 4}, {2, 5}, {4, 5}, {5, 6}, {2}, {4}}));

  EXPECT_EQ(aSet.events()[1].generation, 1);
  EXPECT_EQ(aSet.events()[1].inputExpressions, (std::vector<ExpressionID>{2, 3}));
  EXPECT_EQ(aSet.events()[1].outputExpressions, (std::vector<ExpressionID>{8}));
  EXPECT_EQ(aSet.events()[1].rule, 0);

  EXPECT_EQ(aSet.replace(Set::StepSpecification(), doNotAbort), 3);
  // in the global spacelike case, only one of the {5}'s can make it to {6} because there is only one {5, 6} to use.
  EXPECT_EQ(aSet.expressions(), (std::vector<AtomsVector>{{1}, {1, 2}, {3}, {3, 4}, {2, 5}, {4, 5}, {5, 6}, {2}, {4}, {5}, {5}, {6}}));}

TEST(Set, matchAllMultiway) {
  Set aSet = testSet(Set::EventSelectionFunction::None);
  // Unlike the global spacelike case, the edge {5, 6} can now be used twice, so there is an extra event
  EXPECT_EQ(aSet.replace(Set::StepSpecification(), doNotAbort), 6);
  // and two {6}'s in the list of expressions
  EXPECT_EQ(aSet.expressions(), (std::vector<AtomsVector>{{1}, {1, 2}, {3}, {3, 4}, {2, 5}, {4, 5}, {5, 6}, {2}, {4}, {5}, {5}, {6}, {6}}));
}
}  // namespace SetReplace
