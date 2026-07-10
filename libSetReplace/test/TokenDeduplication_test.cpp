#include "TokenDeduplication.hpp"

#include <gtest/gtest.h>

#include <limits>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "HypergraphMatcher.hpp"
#include "HypergraphSubstitutionSystem.hpp"
#include "Rule.hpp"

namespace SetReplace {
constexpr auto doNotAbort = []() { return false; };

constexpr int64_t max64int = std::numeric_limits<int64_t>::max();

HypergraphMatcher::OrderingSpec standardOrderingSpec() {
  return {{HypergraphMatcher::OrderingFunction::SortedInputTokenIndices, HypergraphMatcher::OrderingDirection::Normal},
          {HypergraphMatcher::OrderingFunction::InputTokenIndices, HypergraphMatcher::OrderingDirection::Normal},
          {HypergraphMatcher::OrderingFunction::RuleIndex, HypergraphMatcher::OrderingDirection::Normal}};
}

// A chain of identical tokens {1} -> {1} -> ... should collapse into a single token with a self-loop event.
TEST(TokenDeduplication, identicalChainCollapsesToSelfLoop) {
  const std::vector<AtomsVector> tokens = {{1}, {1}, {1}, {1}};
  const std::vector<Event> events = {
      {initialConditionRule, {}, {0}, 0}, {0, {0}, {1}, 1}, {0, {1}, {2}, 2}, {0, {2}, {3}, 3}};

  const auto result = deduplicateTokens(tokens, events, 3, 0, doNotAbort);

  EXPECT_EQ(result.tokenClasses, (std::vector<TokenID>{0, 0, 0, 0}));
  EXPECT_EQ(result.eventClasses, (std::vector<EventID>{0, 1, 1, 1}));
  EXPECT_TRUE(result.atomClasses.empty());
}

// {{1, 2}} -> {{2, 3}} -> {{3, 4}} -> ... Consecutive tokens share an atom, so they cannot be identified (the shared
// atom would have to be renamed into another atom of the same token). Tokens two steps apart can be, so the
// evolution should collapse into a 2-cycle.
TEST(TokenDeduplication, slidingChainCollapsesToPeriodTwoCycle) {
  std::vector<Rule> rules = {Rule({{{-1, -2}}, {{-2, -3}}, EventSelectionFunction::All})};
  HypergraphSubstitutionSystem system(
      rules, {{1, 2}}, 1, standardOrderingSpec(), HypergraphMatcher::EventDeduplication::None, 0);
  HypergraphSubstitutionSystem::StepSpecification stepSpec;
  stepSpec.maxEvents = 6;
  EXPECT_EQ(system.replace(stepSpec, doNotAbort), 6);
  EXPECT_EQ(system.tokens(), (std::vector<AtomsVector>{{1, 2}, {2, 4}, {4, 5}, {5, 6}, {6, 7}, {7, 8}, {8, 9}}));

  const auto result = deduplicateTokens(system.tokens(), system.events(), 6, 2, doNotAbort);

  EXPECT_EQ(result.tokenClasses, (std::vector<TokenID>{0, 1, 0, 1, 0, 1, 0}));
  EXPECT_EQ(result.eventClasses, (std::vector<EventID>{0, 1, 2, 1, 2, 1, 2}));
  EXPECT_EQ(result.atomClasses, (std::unordered_map<Atom, Atom>{{4, 1}, {6, 1}, {8, 1}, {5, 2}, {7, 2}, {9, 2}}));
}

// Two multiway branches leading to tokens with identical contents and pasts that are deleted by the deduplication
// should merge those tokens even though they are branchlike separated. The events creating them stay separate.
TEST(TokenDeduplication, branchialMergeOfIdenticalTokens) {
  std::vector<Rule> rules = {Rule({{{-1, -2}, {-2, -3}}, {{-1, -3}}, EventSelectionFunction::Spacelike})};
  HypergraphSubstitutionSystem system(rules,
                                      {{1, 2}, {2, 3}, {3, 4}},
                                      max64int,
                                      standardOrderingSpec(),
                                      HypergraphMatcher::EventDeduplication::None,
                                      0);
  EXPECT_EQ(system.replace(HypergraphSubstitutionSystem::StepSpecification(), doNotAbort), 4);
  EXPECT_EQ(system.tokens(), (std::vector<AtomsVector>{{1, 2}, {2, 3}, {3, 4}, {1, 3}, {2, 4}, {1, 4}, {1, 4}}));

  const auto result = deduplicateTokens(system.tokens(), system.events(), 3, 4, doNotAbort);

  EXPECT_EQ(result.tokenClasses, (std::vector<TokenID>{0, 1, 2, 3, 4, 5, 5}));
  EXPECT_EQ(result.eventClasses, (std::vector<EventID>{0, 1, 2, 3, 4}));
  EXPECT_TRUE(result.atomClasses.empty());
}

// Deduplicating a periodic multiway evolution rolls each branch up into a fixed-size loop. In particular, the event
// horizon must not be glued directly to the initial condition (initial tokens have an extra destroyer event per
// branch, so their futures are genuinely different), which would produce loops growing with the number of
// generations.
TEST(TokenDeduplication, periodicBranchesCollapseToFixedSizeLoops) {
  std::vector<Rule> rules = {Rule({{{-1, -2}, {-2, -3}}, {{-1, -3}, {-2, -3}}, EventSelectionFunction::Spacelike})};
  HypergraphSubstitutionSystem system(
      rules, {{1, 2}, {2, 1}}, max64int, standardOrderingSpec(), HypergraphMatcher::EventDeduplication::None, 0);
  HypergraphSubstitutionSystem::StepSpecification stepSpec;
  stepSpec.maxGenerationsLocal = 4;
  EXPECT_EQ(system.replace(stepSpec, doNotAbort), 8);
  EXPECT_EQ(system.tokens(),
            (std::vector<AtomsVector>{{1, 2},
                                      {2, 1},
                                      {1, 1},
                                      {2, 1},
                                      {2, 2},
                                      {1, 2},
                                      {2, 1},
                                      {1, 1},
                                      {1, 2},
                                      {2, 2},
                                      {2, 1},
                                      {1, 1},
                                      {1, 2},
                                      {2, 2},
                                      {2, 1},
                                      {1, 1},
                                      {1, 2},
                                      {2, 2}}));

  const auto result = deduplicateTokens(system.tokens(), system.events(), 4, 2, doNotAbort);

  EXPECT_EQ(result.tokenClasses, (std::vector<TokenID>{0, 1, 2, 3, 4, 5, 3, 2, 5, 4, 3, 2, 5, 4, 3, 2, 5, 4}));
  EXPECT_EQ(result.eventClasses, (std::vector<EventID>{0, 1, 2, 3, 4, 3, 4, 3, 4}));
  EXPECT_TRUE(result.atomClasses.empty());
}

// An identity rule on a triangle recreates the same tokens forever, so the deduplicated multihistory must be the same
// fixed-size object regardless of how many generations are evolved. In particular, tokens re-consumed by later
// sibling-branch events (whose counterparts for their copies are beyond the horizon) must still merge with their
// copies.
TEST(TokenDeduplication, identityRuleQuotientIsGenerationIndependent) {
  for (Generation generations = 1; generations <= 3; ++generations) {
    std::vector<Rule> rules = {Rule({{{-1, -2}, {-2, -3}}, {{-1, -2}, {-2, -3}}, EventSelectionFunction::Spacelike})};
    HypergraphSubstitutionSystem system(rules,
                                        {{1, 2}, {2, 3}, {3, 1}},
                                        max64int,
                                        standardOrderingSpec(),
                                        HypergraphMatcher::EventDeduplication::None,
                                        0);
    HypergraphSubstitutionSystem::StepSpecification stepSpec;
    stepSpec.maxGenerationsLocal = generations;
    system.replace(stepSpec, doNotAbort);

    const auto result = deduplicateTokens(system.tokens(), system.events(), generations, 3, doNotAbort);

    const std::unordered_set<TokenID> tokenClasses(result.tokenClasses.begin(), result.tokenClasses.end());
    const std::unordered_set<EventID> eventClasses(result.eventClasses.begin(), result.eventClasses.end());
    EXPECT_EQ(tokenClasses.size(), 3);
    EXPECT_EQ(eventClasses.size(), 4);  // including the initial event
    EXPECT_TRUE(result.atomClasses.empty());
  }
}

// When several destroyer events of the same generation use a token at the same input index, the correct
// correspondence cannot be determined locally. The trial enumerates the possible alignments, so the merge succeeds
// even though the heuristic order pairs the events incorrectly at first (the copy's destroyers are created in the
// opposite order, and the sorting key cannot see the difference between the partners).
TEST(TokenDeduplication, ambiguousDestroyerAlignmentIsSearched) {
  const std::vector<AtomsVector> tokens = {
      {1}, {2, 2}, {3, 4}, {5, 5}, {6, 7}, {1}, {20, 20}, {30, 40}, {60, 70}, {50, 50}, {1}, {80, 80}, {90, 91}};
  const std::vector<Event> events = {{initialConditionRule, {}, {0, 1, 2}, 0},
                                     {0, {0, 1}, {3}, 1},           // consumes X with the repeated-atom partner
                                     {0, {0, 2}, {4}, 1},           // consumes X with the distinct-atom partner
                                     {1, {0, 1, 2}, {5, 6, 7}, 1},  // copies the entire state
                                     // the copy's destroyers are created in the opposite order
                                     {0, {5, 7}, {8}, 2},
                                     {0, {5, 6}, {9}, 2},
                                     {1, {5, 6, 7}, {10, 11, 12}, 2}};

  const auto result = deduplicateTokens(tokens, events, 2, 0, doNotAbort);

  EXPECT_EQ(result.tokenClasses, (std::vector<TokenID>{0, 1, 2, 3, 4, 0, 1, 2, 4, 3, 0, 1, 2}));
  EXPECT_EQ(result.eventClasses, (std::vector<EventID>{0, 1, 2, 3, 2, 1, 3}));
  EXPECT_EQ(result.atomClasses,
            (std::unordered_map<Atom, Atom>{
                {20, 2}, {80, 2}, {30, 3}, {90, 3}, {40, 4}, {91, 4}, {50, 5}, {60, 6}, {70, 7}}));
}

// Two independent chains with different atoms evolve identically, but their atoms are spacelike separated, so the
// chains must not be merged with each other. Each chain still collapses into its own self-loop.
TEST(TokenDeduplication, spacelikeAtomsPreventMerging) {
  const std::vector<AtomsVector> tokens = {{1}, {2}, {1}, {2}};
  const std::vector<Event> events = {{initialConditionRule, {}, {0, 1}, 0}, {0, {0}, {2}, 1}, {0, {1}, {3}, 1}};

  const auto result = deduplicateTokens(tokens, events, 1, 0, doNotAbort);

  EXPECT_EQ(result.tokenClasses, (std::vector<TokenID>{0, 1, 0, 1}));
  EXPECT_EQ(result.eventClasses, (std::vector<EventID>{0, 1, 2}));
  EXPECT_TRUE(result.atomClasses.empty());
}

// Explicitly named atoms are never identified with each other, even if they are independent. Without naming, the
// same merge succeeds.
TEST(TokenDeduplication, namedAtomsPreventIdentification) {
  const std::vector<AtomsVector> tokens = {{1}, {2}, {3}};
  const std::vector<Event> events = {{initialConditionRule, {}, {0}, 0}, {0, {0}, {1}, 1}, {0, {1}, {2}, 2}};

  const auto unrestricted = deduplicateTokens(tokens, events, 1, 0, doNotAbort);
  EXPECT_EQ(unrestricted.tokenClasses, (std::vector<TokenID>{0, 0, 0}));
  EXPECT_EQ(unrestricted.eventClasses, (std::vector<EventID>{0, 1, 1}));
  EXPECT_EQ(unrestricted.atomClasses, (std::unordered_map<Atom, Atom>{{2, 1}, {3, 1}}));

  // With atoms 1 and 2 named, tokens {1} and {2} can no longer be identified, but {3} (created) can still be
  // identified with {1}.
  const auto restricted = deduplicateTokens(tokens, events, 1, 2, doNotAbort);
  EXPECT_EQ(restricted.tokenClasses, (std::vector<TokenID>{0, 1, 0}));
  EXPECT_EQ(restricted.eventClasses, (std::vector<EventID>{0, 1, 2}));
  EXPECT_EQ(restricted.atomClasses, (std::unordered_map<Atom, Atom>{{3, 1}}));
}

// Outputs of the same event are spacelike separated (they coexist in states), so they are never identified even if
// their contents are identical: states are multisets, and the number of identical tokens matters for matching.
TEST(TokenDeduplication, outputsOfSameEventDoNotMerge) {
  const std::vector<AtomsVector> identicalOutputs = {{1}, {1}, {1}};
  const std::vector<AtomsVector> distinctOutputs = {{1}, {2}, {3}};
  const std::vector<Event> events = {{initialConditionRule, {}, {0}, 0}, {0, {0}, {1, 2}, 1}};

  for (const auto& tokens : {identicalOutputs, distinctOutputs}) {
    const auto result = deduplicateTokens(tokens, events, 2, 0, doNotAbort);

    EXPECT_EQ(result.tokenClasses, (std::vector<TokenID>{0, 1, 2}));
    EXPECT_EQ(result.eventClasses, (std::vector<EventID>{0, 1}));
    EXPECT_TRUE(result.atomClasses.empty());
  }
}

// Two identical spacelike tokens in the initial condition stay separate (a two-input rule can match them, which
// would be impossible with a single token). Corresponding outputs of the two event orderings are branchlike, so they
// do merge.
TEST(TokenDeduplication, spacelikeInitialTokensDoNotMerge) {
  std::vector<Rule> rules = {Rule(
      {{{-1, -2, -3}, {-4, -2, -5}}, {{-1, -1, -4}, {-3, -2, -1}, {-6, -2, -5}}, EventSelectionFunction::Spacelike})};
  HypergraphSubstitutionSystem system(
      rules, {{1, 1, 1}, {1, 1, 1}}, max64int, standardOrderingSpec(), HypergraphMatcher::EventDeduplication::None, 0);
  HypergraphSubstitutionSystem::StepSpecification stepSpec;
  stepSpec.maxEvents = 2;
  EXPECT_EQ(system.replace(stepSpec, doNotAbort), 2);
  EXPECT_EQ(system.tokens(),
            (std::vector<AtomsVector>{
                {1, 1, 1}, {1, 1, 1}, {1, 1, 1}, {1, 1, 1}, {3, 1, 1}, {1, 1, 1}, {1, 1, 1}, {4, 1, 1}}));

  // The evolution is truncated mid-generation, so no generations are complete, and merges beyond the coexistence,
  // independence and content conditions are speculative.
  const auto result = deduplicateTokens(system.tokens(), system.events(), 0, 1, doNotAbort);

  EXPECT_EQ(result.tokenClasses[0], 0);
  EXPECT_EQ(result.tokenClasses[1], 1);  // not merged with token 0 despite identical contents
  EXPECT_EQ(result.eventClasses, (std::vector<EventID>{0, 1, 2}));  // the two orderings consume coexisting tokens
  EXPECT_EQ(result.atomClasses, (std::unordered_map<Atom, Atom>{{4, 3}}));
}

// Tokens at the horizon (with incompletely known futures) do not constrain merges, but they should merge into classes
// themselves when the rest of the structure matches.
TEST(TokenDeduplication, horizonTokensMergeOptimistically) {
  const std::vector<AtomsVector> tokens = {{1}, {1}, {1}};
  const std::vector<Event> events = {{initialConditionRule, {}, {0}, 0}, {0, {0}, {1}, 1}, {0, {1}, {2}, 2}};

  // With the horizon at generation 1, the future of token 1 is already incompletely known, but the chain should still
  // collapse.
  const auto result = deduplicateTokens(tokens, events, 1, 0, doNotAbort);

  EXPECT_EQ(result.tokenClasses, (std::vector<TokenID>{0, 0, 0}));
  EXPECT_EQ(result.eventClasses, (std::vector<EventID>{0, 1, 1}));
  EXPECT_TRUE(result.atomClasses.empty());
}

// If the futures are completely known and differ, tokens must not merge even if their contents are identical.
TEST(TokenDeduplication, differentFuturesPreventMerging) {
  // Token 1 is destroyed, token 2 is not, and the evolution is complete.
  const std::vector<AtomsVector> tokens = {{1}, {1}, {1}};
  const std::vector<Event> events = {{initialConditionRule, {}, {0}, 0}, {0, {0}, {1, 2}, 1}, {0, {1}, {}, 2}};

  const auto result = deduplicateTokens(tokens, events, 3, 0, doNotAbort);

  EXPECT_EQ(result.tokenClasses, (std::vector<TokenID>{0, 1, 2}));
  EXPECT_EQ(result.eventClasses, (std::vector<EventID>{0, 1, 2}));
  EXPECT_TRUE(result.atomClasses.empty());
}

TEST(TokenDeduplication, abortThrows) {
  const std::vector<AtomsVector> tokens = {{1}, {1}};
  const std::vector<Event> events = {{initialConditionRule, {}, {0}, 0}, {0, {0}, {1}, 1}};

  EXPECT_THROW(deduplicateTokens(tokens, events, 2, 0, []() { return true; }), TokenDeduplicationError);
}

TEST(TokenDeduplication, inconsistentInputThrows) {
  // Event input refers to a nonexistent token.
  const std::vector<AtomsVector> tokens = {{1}};
  const std::vector<Event> events = {{initialConditionRule, {}, {0}, 0}, {0, {5}, {}, 1}};

  EXPECT_THROW(deduplicateTokens(tokens, events, 2, 0, doNotAbort), TokenDeduplicationError);
}
}  // namespace SetReplace
