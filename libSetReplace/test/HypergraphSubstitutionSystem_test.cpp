#include "HypergraphSubstitutionSystem.hpp"

#include <gtest/gtest.h>

#include <unordered_map>
#include <vector>

#include "HypergraphMatcher.hpp"
#include "Rule.hpp"

namespace SetReplace {
HypergraphSubstitutionSystem testSystem(const uint64_t maxDestroyerEvents,
                                        const EventSelectionFunction eventSelectionFunction) {
  // Negative atoms refer to patterns (useful for rules)
  std::vector<Rule> rules;
  auto aRule = Rule({{{-1}, {-1, -2}}, {{-2}}, eventSelectionFunction});
  rules.push_back(aRule);

  // make two "particles" {1} and {3} which will traverse the graph deleting edges in their path
  std::vector<AtomsVector> initialTokens = {{1}, {1, 2}, {3}, {3, 4}, {2, 5}, {4, 5}, {5, 6}};

  HypergraphMatcher::OrderingSpec orderingSpec = {
      {HypergraphMatcher::OrderingFunction::SortedInputTokenIndices, HypergraphMatcher::OrderingDirection::Normal},
      {HypergraphMatcher::OrderingFunction::InputTokenIndices, HypergraphMatcher::OrderingDirection::Normal},
      {HypergraphMatcher::OrderingFunction::RuleIndex, HypergraphMatcher::OrderingDirection::Normal}};
  HypergraphMatcher::EventDeduplication eventDeduplication = HypergraphMatcher::EventDeduplication::None;
  unsigned int randomSeed = 0;
  return HypergraphSubstitutionSystem(
      rules, initialTokens, maxDestroyerEvents, orderingSpec, eventDeduplication, randomSeed);
}

constexpr auto doNotAbort = []() { return false; };

constexpr int64_t max64int = std::numeric_limits<int64_t>::max();

TEST(HypergraphSubstitutionSystem, globalSpacelike) {
  // Singleway systems are always spacelike, so it's not necessary to specify a spacelike selection function
  HypergraphSubstitutionSystem aSystem = testSystem(1, EventSelectionFunction::All);
  HypergraphSubstitutionSystem::StepSpecification stepSpec;
  stepSpec.maxEvents = 2;
  EXPECT_EQ(aSystem.replace(stepSpec, doNotAbort), 2);
  EXPECT_EQ(aSystem.maxCompleteGeneration(doNotAbort), 1);
  EXPECT_EQ(aSystem.terminationReason(), HypergraphSubstitutionSystem::TerminationReason::MaxEvents);
  EXPECT_EQ(aSystem.tokens(), (std::vector<AtomsVector>{{1}, {1, 2}, {3}, {3, 4}, {2, 5}, {4, 5}, {5, 6}, {2}, {4}}));

  EXPECT_EQ(aSystem.events()[2].generation, 1);
  EXPECT_EQ(aSystem.events()[2].inputTokens, (std::vector<TokenID>{2, 3}));
  EXPECT_EQ(aSystem.events()[2].outputTokens, (std::vector<TokenID>{8}));
  EXPECT_EQ(aSystem.events()[2].rule, 0);

  EXPECT_EQ(aSystem.replace(HypergraphSubstitutionSystem::StepSpecification(), doNotAbort), 3);
  // in the global spacelike case, only one of the {5}'s can make it to {6} because there is only one {5, 6} to use.
  EXPECT_EQ(aSystem.tokens(),
            (std::vector<AtomsVector>{{1}, {1, 2}, {3}, {3, 4}, {2, 5}, {4, 5}, {5, 6}, {2}, {4}, {5}, {5}, {6}}));
}

TEST(HypergraphSubstitutionSystem, matchAllMultiway) {
  HypergraphSubstitutionSystem aSystem = testSystem(max64int, EventSelectionFunction::All);
  // Unlike the global spacelike case, the token {5, 6} can now be used twice, so there is an extra event
  EXPECT_EQ(aSystem.replace(HypergraphSubstitutionSystem::StepSpecification(), doNotAbort), 6);
  // and two {6}'s in the list of tokens
  EXPECT_EQ(aSystem.tokens(),
            (std::vector<AtomsVector>{{1}, {1, 2}, {3}, {3, 4}, {2, 5}, {4, 5}, {5, 6}, {2}, {4}, {5}, {5}, {6}, {6}}));
}

HypergraphSubstitutionSystem testSystemMaxDestroyerEvents(const uint64_t maxDestroyerEvents,
                                                          const EventSelectionFunction eventSelectionFunction) {
  std::vector<Rule> rules;
  // {{1, 2}, {2, 3}} -> {{2, 3}, {2, 4}, {3, 4}, {2, 1}}
  auto aRule = Rule({{{-1, -2}, {-2, -3}}, {{-2, -3}, {-2, -4}, {-3, -4}, {-2, -1}}, eventSelectionFunction});
  rules.push_back(aRule);

  std::vector<AtomsVector> initialTokens = {{1, 1}, {1, 1}};

  HypergraphMatcher::OrderingSpec orderingSpec = {
      {HypergraphMatcher::OrderingFunction::SortedInputTokenIndices, HypergraphMatcher::OrderingDirection::Normal},
      {HypergraphMatcher::OrderingFunction::InputTokenIndices, HypergraphMatcher::OrderingDirection::Normal},
      {HypergraphMatcher::OrderingFunction::RuleIndex, HypergraphMatcher::OrderingDirection::Normal}};
  HypergraphMatcher::EventDeduplication eventDeduplication = HypergraphMatcher::EventDeduplication::None;
  unsigned int randomSeed = 0;
  return HypergraphSubstitutionSystem(
      rules, initialTokens, maxDestroyerEvents, orderingSpec, eventDeduplication, randomSeed);
}

TEST(HypergraphSubstitutionSystem, maxDestroyerEvents1) {
  HypergraphSubstitutionSystem aSpacelikeSystem = testSystemMaxDestroyerEvents(1, EventSelectionFunction::Spacelike);
  HypergraphSubstitutionSystem anAllSystem = testSystemMaxDestroyerEvents(1, EventSelectionFunction::All);
  HypergraphSubstitutionSystem::StepSpecification stepSpec;
  stepSpec.maxEvents = 5;

  EXPECT_EQ(aSpacelikeSystem.replace(stepSpec, doNotAbort), anAllSystem.replace(stepSpec, doNotAbort));

  EXPECT_EQ(aSpacelikeSystem.tokens(), anAllSystem.tokens());
  for (int i = 0; i <= stepSpec.maxEvents; ++i) {
    EXPECT_EQ(aSpacelikeSystem.events()[i].inputTokens, anAllSystem.events()[i].inputTokens);
    EXPECT_EQ(aSpacelikeSystem.events()[i].outputTokens, anAllSystem.events()[i].outputTokens);
  }
}

std::unordered_map<TokenID, uint64_t> getDestroyerEventsCountMap(const std::vector<Event>& events) {
  std::unordered_map<TokenID, uint64_t> destroyerEventsCountMap;
  for (const auto& event : events) {
    for (const auto& id : event.inputTokens) {
      destroyerEventsCountMap[id] += 1;
    }
  }
  return destroyerEventsCountMap;
}

TEST(HypergraphSubstitutionSystem, maxDestroyerEventsN) {
  HypergraphSubstitutionSystem::StepSpecification stepSpec;
  stepSpec.maxEvents = 50;

  for (int n = 0; n <= 20; ++n) {
    HypergraphSubstitutionSystem aSpacelikeSystem = testSystemMaxDestroyerEvents(n, EventSelectionFunction::Spacelike);
    aSpacelikeSystem.replace(stepSpec, doNotAbort);

    const auto& destroyerEventsCountMap = getDestroyerEventsCountMap(aSpacelikeSystem.events());
    for (auto& iterator : destroyerEventsCountMap) {
      EXPECT_LE(iterator.second, n);
    }
  }
}

TEST(HypergraphSubstitutionSystem, maxDestroyerEventsMultiwaySpacelike) {
  HypergraphSubstitutionSystem aSystem2 = testSystemMaxDestroyerEvents(2, EventSelectionFunction::Spacelike);
  HypergraphSubstitutionSystem aSystem3 = testSystemMaxDestroyerEvents(3, EventSelectionFunction::Spacelike);
  HypergraphSubstitutionSystem::StepSpecification stepSpec;
  stepSpec.maxEvents = 5;

  EXPECT_EQ(aSystem2.replace(stepSpec, doNotAbort), aSystem3.replace(stepSpec, doNotAbort));

  EXPECT_EQ(aSystem2.events()[5].inputTokens, (std::vector<TokenID>{5, 3}));
  EXPECT_EQ(aSystem2.events()[5].outputTokens, (std::vector<TokenID>{18, 19, 20, 21}));

  EXPECT_EQ(aSystem3.events()[5].inputTokens, (std::vector<TokenID>{2, 5}));
  EXPECT_EQ(aSystem3.events()[5].outputTokens, (std::vector<TokenID>{18, 19, 20, 21}));
}

TEST(HypergraphSubstitutionSystem, replaceOnce) {
  HypergraphMatcher::OrderingSpec orderingSpec = {
      {HypergraphMatcher::OrderingFunction::SortedInputTokenIndices, HypergraphMatcher::OrderingDirection::Normal},
      {HypergraphMatcher::OrderingFunction::ReverseSortedInputTokenIndices,
       HypergraphMatcher::OrderingDirection::Normal},
      {HypergraphMatcher::OrderingFunction::InputTokenIndices, HypergraphMatcher::OrderingDirection::Normal},
      {HypergraphMatcher::OrderingFunction::RuleIndex, HypergraphMatcher::OrderingDirection::Normal}};

  HypergraphSubstitutionSystem system(
      {{{{-1}}, {{-1, -1}}}}, {{1}}, 1, orderingSpec, HypergraphMatcher::EventDeduplication::None, 0);
  EXPECT_EQ(system.replaceOnce(doNotAbort), 1);
}

TEST(HypergraphSubstitutionSystem, multiruleSeeding) {
  std::array<int, 2> replacedTokenCounts = {0, 0};
  constexpr int trialCount = 100;
  for (int i = 0; i < trialCount; ++i) {
    HypergraphSubstitutionSystem system(
        {{{{1, 2}}, {}}, {{{2, 3}}, {}}}, {{1, 2}, {2, 3}}, 1, {}, HypergraphMatcher::EventDeduplication::None, 123);
    system.replaceOnce(doNotAbort);
    ++replacedTokenCounts[system.events()[1].inputTokens[0]];
  }
  EXPECT_EQ(std::max(replacedTokenCounts[0], replacedTokenCounts[1]), trialCount);
}
}  // namespace SetReplace
