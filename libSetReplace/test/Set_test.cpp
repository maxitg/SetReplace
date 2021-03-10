#include "Set.hpp"

#include <gtest/gtest.h>

#include <unordered_map>
#include <vector>

#include "Match.hpp"
#include "Rule.hpp"

namespace SetReplace {
Set testSet(const uint64_t maxDestroyerEvents, const EventSelectionFunction eventSelectionFunction) {
  // Negative atoms refer to patterns (useful for rules)
  std::vector<Rule> rules;
  auto aRule = Rule({{{-1}, {-1, -2}}, {{-2}}, eventSelectionFunction});
  rules.push_back(aRule);

  // make two "particles" {1} and {3} which will traverse the graph deleting edges in their path
  std::vector<AtomsVector> initialExpressions = {{1}, {1, 2}, {3}, {3, 4}, {2, 5}, {4, 5}, {5, 6}};

  Matcher::OrderingSpec orderingSpec = {
      {Matcher::OrderingFunction::SortedExpressionIDs, Matcher::OrderingDirection::Normal},
      {Matcher::OrderingFunction::ExpressionIDs, Matcher::OrderingDirection::Normal},
      {Matcher::OrderingFunction::RuleIndex, Matcher::OrderingDirection::Normal}};
  Matcher::EventDeduplication eventDeduplication = Matcher::EventDeduplication::None;
  unsigned int randomSeed = 0;
  return Set(rules, initialExpressions, maxDestroyerEvents, orderingSpec, eventDeduplication, randomSeed);
}

constexpr auto doNotAbort = []() { return false; };

constexpr int64_t max64int = std::numeric_limits<int64_t>::max();

TEST(Set, globalSpacelike) {
  // Singleway systems are always spacelike, so it's not necessary to specify a spacelike selection function
  Set aSet = testSet(1, EventSelectionFunction::All);
  Set::StepSpecification stepSpec;
  stepSpec.maxEvents = 2;
  EXPECT_EQ(aSet.replace(stepSpec, doNotAbort), 2);
  EXPECT_EQ(aSet.maxCompleteGeneration(doNotAbort), 1);
  EXPECT_EQ(aSet.terminationReason(), Set::TerminationReason::MaxEvents);
  EXPECT_EQ(aSet.expressions(), (std::vector<AtomsVector>{{1}, {1, 2}, {3}, {3, 4}, {2, 5}, {4, 5}, {5, 6}, {2}, {4}}));

  EXPECT_EQ(aSet.events()[2].generation, 1);
  EXPECT_EQ(aSet.events()[2].inputExpressions, (std::vector<ExpressionID>{2, 3}));
  EXPECT_EQ(aSet.events()[2].outputExpressions, (std::vector<ExpressionID>{8}));
  EXPECT_EQ(aSet.events()[2].rule, 0);

  EXPECT_EQ(aSet.replace(Set::StepSpecification(), doNotAbort), 3);
  // in the global spacelike case, only one of the {5}'s can make it to {6} because there is only one {5, 6} to use.
  EXPECT_EQ(aSet.expressions(),
            (std::vector<AtomsVector>{{1}, {1, 2}, {3}, {3, 4}, {2, 5}, {4, 5}, {5, 6}, {2}, {4}, {5}, {5}, {6}}));
}

TEST(Set, matchAllMultiway) {
  Set aSet = testSet(max64int, EventSelectionFunction::All);
  // Unlike the global spacelike case, the edge {5, 6} can now be used twice, so there is an extra event
  EXPECT_EQ(aSet.replace(Set::StepSpecification(), doNotAbort), 6);
  // and two {6}'s in the list of expressions
  EXPECT_EQ(aSet.expressions(),
            (std::vector<AtomsVector>{{1}, {1, 2}, {3}, {3, 4}, {2, 5}, {4, 5}, {5, 6}, {2}, {4}, {5}, {5}, {6}, {6}}));
}

Set testSetMaxDestroyerEvents(const uint64_t maxDestroyerEvents, const EventSelectionFunction eventSelectionFunction) {
  std::vector<Rule> rules;
  // {{1, 2}, {2, 3}} -> {{2, 3}, {2, 4}, {3, 4}, {2, 1}}
  auto aRule = Rule({{{-1, -2}, {-2, -3}}, {{-2, -3}, {-2, -4}, {-3, -4}, {-2, -1}}, eventSelectionFunction});
  rules.push_back(aRule);

  std::vector<AtomsVector> initialExpressions = {{1, 1}, {1, 1}};

  Matcher::OrderingSpec orderingSpec = {
      {Matcher::OrderingFunction::SortedExpressionIDs, Matcher::OrderingDirection::Normal},
      {Matcher::OrderingFunction::ExpressionIDs, Matcher::OrderingDirection::Normal},
      {Matcher::OrderingFunction::RuleIndex, Matcher::OrderingDirection::Normal}};
  Matcher::EventDeduplication eventDeduplication = Matcher::EventDeduplication::None;
  unsigned int randomSeed = 0;
  return Set(rules, initialExpressions, maxDestroyerEvents, orderingSpec, eventDeduplication, randomSeed);
}

TEST(Set, maxDestroyerEvents1) {
  Set aSetSpacelike = testSetMaxDestroyerEvents(1, EventSelectionFunction::Spacelike);
  Set aSetAll = testSetMaxDestroyerEvents(1, EventSelectionFunction::All);
  Set::StepSpecification stepSpec;
  stepSpec.maxEvents = 5;

  EXPECT_EQ(aSetSpacelike.replace(stepSpec, doNotAbort), aSetAll.replace(stepSpec, doNotAbort));

  EXPECT_EQ(aSetSpacelike.expressions(), aSetAll.expressions());
  for (int i = 0; i <= stepSpec.maxEvents; ++i) {
    EXPECT_EQ(aSetSpacelike.events()[i].inputExpressions, aSetAll.events()[i].inputExpressions);
    EXPECT_EQ(aSetSpacelike.events()[i].outputExpressions, aSetAll.events()[i].outputExpressions);
  }
}

std::unordered_map<ExpressionID, uint64_t> getDestroyerEventsCountMap(const std::vector<Event>& events) {
  std::unordered_map<ExpressionID, uint64_t> destroyerEventsCountMap;
  for (const auto& event : events) {
    for (const auto& id : event.inputExpressions) {
      destroyerEventsCountMap[id] += 1;
    }
  }
  return destroyerEventsCountMap;
}

TEST(Set, maxDestroyerEventsN) {
  Set::StepSpecification stepSpec;
  stepSpec.maxEvents = 50;

  for (int n = 0; n <= 20; ++n) {
    Set aSetSpacelike = testSetMaxDestroyerEvents(n, EventSelectionFunction::Spacelike);
    aSetSpacelike.replace(stepSpec, doNotAbort);

    const auto& destroyerEventsCountMap = getDestroyerEventsCountMap(aSetSpacelike.events());
    for (auto& iterator : destroyerEventsCountMap) {
      EXPECT_LT(iterator.second, n);
    }
  }
}

TEST(Set, maxDestroyerEventsMultiwaySpacelike) {
  Set aSet2 = testSetMaxDestroyerEvents(2, EventSelectionFunction::Spacelike);
  Set aSet3 = testSetMaxDestroyerEvents(3, EventSelectionFunction::Spacelike);
  Set::StepSpecification stepSpec;
  stepSpec.maxEvents = 5;

  EXPECT_EQ(aSet2.replace(stepSpec, doNotAbort), aSet3.replace(stepSpec, doNotAbort));

  EXPECT_EQ(aSet2.events()[5].inputExpressions, (std::vector<ExpressionID>{5, 3}));
  EXPECT_EQ(aSet2.events()[5].outputExpressions, (std::vector<ExpressionID>{18, 19, 20, 21}));

  EXPECT_EQ(aSet3.events()[5].inputExpressions, (std::vector<ExpressionID>{2, 5}));
  EXPECT_EQ(aSet3.events()[5].outputExpressions, (std::vector<ExpressionID>{18, 19, 20, 21}));
}

TEST(Set, replaceOnce) {
  Matcher::OrderingSpec orderingSpec = {
      {Matcher::OrderingFunction::SortedExpressionIDs, Matcher::OrderingDirection::Normal},
      {Matcher::OrderingFunction::ReverseSortedExpressionIDs, Matcher::OrderingDirection::Normal},
      {Matcher::OrderingFunction::ExpressionIDs, Matcher::OrderingDirection::Normal},
      {Matcher::OrderingFunction::RuleIndex, Matcher::OrderingDirection::Normal}};

  Set set({{{{-1}}, {{-1, -1}}}}, {{1}}, 1, orderingSpec, Matcher::EventDeduplication::None, 0);
  EXPECT_EQ(set.replaceOnce(doNotAbort), 1);
}
}  // namespace SetReplace
