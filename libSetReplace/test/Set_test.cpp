#include "Set.hpp"

#include <gtest/gtest.h>

#include <iostream>

#include "IDTypes.hpp"
#include "Match.hpp"
#include "Rule.hpp"

namespace SetReplace {
TEST(SetReplace, createSetAndReplace) {
  // Negative atoms refer to patterns (useful for rules)
  std::vector<Rule> rules;
  auto a_rule = Rule({{{-1, -2}, {-2, -3}}, {{-1, -3}, {-4, -2}, {-1, -4}}});
  rules.push_back(a_rule);

  std::vector<AtomsVector> initialExpressions = {{1, 2}, {2, 3}};

  Matcher::OrderingSpec orderingSpec = {
      {Matcher::OrderingFunction::SortedExpressionIDs, Matcher::OrderingDirection::Normal},
      {Matcher::OrderingFunction::ReverseSortedExpressionIDs, Matcher::OrderingDirection::Normal},
      {Matcher::OrderingFunction::ExpressionIDs, Matcher::OrderingDirection::Normal},
      {Matcher::OrderingFunction::RuleIndex, Matcher::OrderingDirection::Normal}};
  unsigned int randomSeed = 0;
  auto a_set = Set(rules, initialExpressions, orderingSpec, randomSeed);

  auto shouldAbort = []() { return false; };
  Set::StepSpecification stepSpec;
  stepSpec.maxEvents = 10;
  stepSpec.maxGenerationsLocal = 100;
  stepSpec.maxFinalAtoms = 100000;
  stepSpec.maxFinalAtomDegree = 100000;
  stepSpec.maxFinalExpressions = 100000;
  EXPECT_TRUE(a_set.replace(stepSpec, shouldAbort));
}
}  // namespace SetReplace
