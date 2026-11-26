#include "TokenEventGraph.hpp"

#include <gtest/gtest.h>

#include <algorithm>
#include <limits>
#include <numeric>
#include <random>
#include <unordered_map>
#include <utility>
#include <vector>

#include "DestroyerChoices.hpp"

namespace SetReplace {
namespace {
using Choices = detail::DestroyerChoices;
using ExplicitChoices = std::unordered_map<TokenID, EventID>;

bool compatible(const ExplicitChoices& first, const ExplicitChoices& second) {
  for (const auto& tokenAndEvent : first) {
    const auto found = second.find(tokenAndEvent.first);
    if (found != second.end() && found->second != tokenAndEvent.second) return false;
  }
  return true;
}

// The original copied-map algorithm, kept as a small differential oracle. It deliberately retains the input-order
// behavior when an event's inputs are not spacelike, as well as the global Unknown fallback after a conflict.
class ExplicitHistory {
 public:
  explicit ExplicitHistory(const int initialTokens) : creators_(initialTokens, 0), choices_(1) {}

  void addEvent(const std::vector<TokenID>& inputs, const int outputCount) {
    const auto event = nextEvent_++;
    if (spacelike_) {
      ExplicitChoices choices;
      for (const auto input : inputs) {
        choices[input] = event;
        const auto& parent = choices_[creators_[input]];
        if (!compatible(choices, parent)) {
          spacelike_ = false;
          break;
        }
        choices.insert(parent.begin(), parent.end());
      }
      choices_.push_back(std::move(choices));
    }
    creators_.insert(creators_.end(), outputCount, event);
  }

  SeparationType separation(const TokenID first, const TokenID second) const {
    if (!spacelike_) return SeparationType::Unknown;
    if (first == second) return SeparationType::Identical;
    const auto& a = choices_[creators_[first]];
    const auto& b = choices_[creators_[second]];
    if (a.count(second) || b.count(first)) return SeparationType::Timelike;
    return compatible(a, b) ? SeparationType::Spacelike : SeparationType::Branchlike;
  }

 private:
  EventID nextEvent_ = 1;
  bool spacelike_ = true;
  std::vector<EventID> creators_;
  std::vector<ExplicitChoices> choices_;
};
}  // namespace

TEST(DestroyerChoices, persistenceAndConflictingUnions) {
  Choices choices;
  auto original = Choices::empty;
  for (TokenID token = 0; token < 1024; ++token) original = choices.set(original, token, token + 1);
  const auto changed = choices.set(original, 511, 2048);
  const auto extended = choices.set(original, 4096, 2049);
  EXPECT_EQ(choices.unite(original, original), original);
  EXPECT_EQ(choices.unite(original, Choices::empty), original);
  EXPECT_EQ(choices.unite(original, changed), Choices::incompatible);
  EXPECT_FALSE(choices.compatible(original, changed));
  EXPECT_FALSE(choices.contains(original, 4096));
  EXPECT_TRUE(choices.contains(extended, 4096));
  EXPECT_EQ(choices.unite(original, extended), extended);
  EXPECT_EQ(choices.unite(extended, original), extended);
  EXPECT_TRUE(choices.compatible(original, extended));
  EXPECT_TRUE(choices.compatible(extended, original));
  EXPECT_FALSE(choices.contains(Choices::empty, 0));
}

TEST(DestroyerChoices, sparseKeysAcrossAllTokenIDBits) {
  Choices choices;
  auto first = Choices::empty;
  auto second = Choices::empty;
  std::vector<TokenID> keys = {0, std::numeric_limits<TokenID>::max()};
  for (int bit = 0; bit < 63; ++bit) keys.push_back(TokenID{1} << bit);
  for (size_t index = 0; index < keys.size(); ++index) {
    first = choices.set(first, keys[index], static_cast<EventID>(index));
  }
  for (size_t index = keys.size(); index > 0; --index) {
    second = choices.set(second, keys[index - 1], static_cast<EventID>(index - 1));
  }
  EXPECT_TRUE(choices.compatible(first, second));
  EXPECT_NE(choices.unite(first, second), Choices::incompatible);
  for (const auto key : keys) EXPECT_TRUE(choices.contains(first, key));
  EXPECT_FALSE(choices.contains(first, 3));
  const auto changed = choices.set(second, TokenID{1} << 62, 999);
  EXPECT_FALSE(choices.compatible(first, changed));
  EXPECT_EQ(choices.unite(first, changed), Choices::incompatible);
}

TEST(DestroyerChoices, randomizedVersionsMatchExplicitMaps) {
  std::mt19937_64 random(1729);
  Choices choices;
  std::vector<std::pair<Choices::Root, ExplicitChoices>> versions = {{Choices::empty, {}}};
  std::vector<TokenID> keys = {0, 1, 2, 3, 4, 7, 8, 15, 16};
  for (int i = 0; i < 32; ++i) {
    keys.push_back(static_cast<TokenID>(random() & static_cast<uint64_t>(std::numeric_limits<TokenID>::max())));
  }
  for (int iteration = 0; iteration < 1000; ++iteration) {
    const auto first = versions[random() % versions.size()];
    const auto second = versions[random() % versions.size()];
    const bool expectedCompatibility = compatible(first.second, second.second);
    EXPECT_EQ(choices.compatible(first.first, second.first), expectedCompatibility);
    EXPECT_EQ(choices.compatible(second.first, first.first), expectedCompatibility);
    if (iteration % 3 == 0) {
      const auto merged = choices.unite(first.first, second.first);
      EXPECT_EQ(merged != Choices::incompatible, expectedCompatibility);
      if (expectedCompatibility) {
        auto expected = first.second;
        expected.insert(second.second.begin(), second.second.end());
        versions.push_back({merged, std::move(expected)});
      }
    } else {
      const auto key = keys[random() % keys.size()];
      const auto value = static_cast<EventID>(random() % 7);
      auto expected = first.second;
      expected[key] = value;
      versions.push_back({choices.set(first.first, key, value), std::move(expected)});
    }
    // Revisit old versions after mutations and arena growth, not just the newly created root.
    const auto& version = versions[random() % versions.size()];
    for (const auto key : keys) {
      const auto found = version.second.find(key);
      ASSERT_EQ(choices.contains(version.first, key), found != version.second.end());
      if (found != version.second.end()) {
        const auto correct = choices.set(Choices::empty, key, found->second);
        const auto incorrect = choices.set(Choices::empty, key, found->second + 1);
        EXPECT_TRUE(choices.compatible(version.first, correct));
        EXPECT_FALSE(choices.compatible(version.first, incorrect));
      }
    }
  }
}

TEST(TokenEventGraph, tracksChainForkJoinAndAlternativeDestroyers) {
  TokenEventGraph graph(2, TokenEventGraph::SeparationTrackingMethod::DestroyerChoices);
  EXPECT_EQ(graph.tokenSeparation(0, 0), SeparationType::Identical);
  EXPECT_EQ(graph.tokenSeparation(0, 1), SeparationType::Spacelike);
  const auto siblings = graph.addEvent(0, {0}, 2);
  const auto left = graph.addEvent(1, {siblings[0]}, 1)[0];
  const auto right = graph.addEvent(2, {siblings[1]}, 1)[0];
  EXPECT_EQ(graph.tokenSeparation(left, right), SeparationType::Spacelike);
  const auto joined = graph.addEvent(3, {left, right}, 1)[0];
  const auto alternative = graph.addEvent(4, {siblings[0]}, 1)[0];
  EXPECT_EQ(graph.tokenSeparation(left, alternative), SeparationType::Branchlike);
  EXPECT_EQ(graph.tokenSeparation(joined, alternative), SeparationType::Branchlike);
  EXPECT_EQ(graph.tokenSeparation(joined, right), SeparationType::Timelike);
  EXPECT_EQ(graph.tokenSeparation(joined, 0), SeparationType::Timelike);
  EXPECT_EQ(graph.tokenSeparation(joined, 1), SeparationType::Spacelike);
  EXPECT_EQ(graph.tokenSeparation(siblings[0], siblings[1]), SeparationType::Spacelike);
  EXPECT_EQ(graph.tokenGeneration(joined), 3);
  EXPECT_EQ(graph.destroyerEventsCount(siblings[0]), 2);
}

TEST(TokenEventGraph, incompatibleJoinDisablesAllSeparationQueries) {
  TokenEventGraph graph(2, TokenEventGraph::SeparationTrackingMethod::DestroyerChoices);
  const auto left = graph.addEvent(0, {0}, 1)[0];
  const auto right = graph.addEvent(0, {0}, 1)[0];
  const auto joined = graph.addEvent(0, {left, right}, 2);
  EXPECT_EQ(graph.tokenSeparation(0, 1), SeparationType::Unknown);
  EXPECT_EQ(graph.tokenSeparation(joined[0], joined[0]), SeparationType::Unknown);
  EXPECT_EQ(graph.tokenSeparation(joined[0], joined[1]), SeparationType::Unknown);
  const auto later = graph.addEvent(0, {joined[0]}, 1)[0];
  EXPECT_EQ(graph.tokenSeparation(later, 1), SeparationType::Unknown);
}

TEST(TokenEventGraph, disabledTrackingKeepsMetadata) {
  TokenEventGraph graph(2, TokenEventGraph::SeparationTrackingMethod::None);
  const auto output = graph.addEvent(4, {0, 1}, 1)[0];
  EXPECT_EQ(graph.tokenSeparation(0, 0), SeparationType::Unknown);
  EXPECT_EQ(graph.tokenSeparation(0, output), SeparationType::Unknown);
  EXPECT_EQ(graph.tokenGeneration(output), 1);
  EXPECT_EQ(graph.events().back().inputTokens, (std::vector<TokenID>{0, 1}));
  EXPECT_EQ(graph.events().back().rule, 4);
}

TEST(TokenEventGraph, randomSpacelikeHistoriesMatchExplicitMaps) {
  for (unsigned int seed = 0; seed < 12; ++seed) {
    SCOPED_TRACE(seed);
    std::mt19937 random(seed);
    TokenEventGraph graph(8, TokenEventGraph::SeparationTrackingMethod::DestroyerChoices);
    ExplicitHistory reference(8);
    for (int event = 0; event < 120; ++event) {
      std::vector<TokenID> candidates(graph.tokenCount());
      std::iota(candidates.begin(), candidates.end(), 0);
      std::shuffle(candidates.begin(), candidates.end(), random);
      std::vector<TokenID> inputs;
      const auto inputCount = random() % 4;
      for (const auto candidate : candidates) {
        if (inputs.size() == inputCount) break;
        if (std::all_of(inputs.begin(), inputs.end(), [&](const TokenID previous) {
              return reference.separation(candidate, previous) == SeparationType::Spacelike;
            })) {
          inputs.push_back(candidate);
        }
      }
      const auto outputCount = static_cast<int>(random() % 4);
      graph.addEvent(0, inputs, outputCount);
      reference.addEvent(inputs, outputCount);
    }
    for (TokenID first = 0; first < static_cast<TokenID>(graph.tokenCount()); ++first) {
      for (TokenID second = 0; second < static_cast<TokenID>(graph.tokenCount()); ++second) {
        ASSERT_EQ(graph.tokenSeparation(first, second), reference.separation(first, second)) << first << ", " << second;
      }
    }
  }
}

TEST(TokenEventGraph, arbitraryInputOrdersMatchExplicitMaps) {
  // Cover all ordered pairs after a small branching history, including identical, spacelike, timelike, and branchlike
  // inputs. This also checks that adding a non-spacelike event retains the original fallback behavior.
  for (TokenID first = 0; first < 7; ++first) {
    for (TokenID second = 0; second < 7; ++second) {
      TokenEventGraph graph(2, TokenEventGraph::SeparationTrackingMethod::DestroyerChoices);
      ExplicitHistory reference(2);
      for (const auto& inputs : std::vector<std::vector<TokenID>>{{0}, {2}, {2}, {1}, {3, 5}, {first, second}}) {
        graph.addEvent(0, inputs, 1);
        reference.addEvent(inputs, 1);
      }
      for (TokenID a = 0; a < static_cast<TokenID>(graph.tokenCount()); ++a) {
        for (TokenID b = 0; b < static_cast<TokenID>(graph.tokenCount()); ++b) {
          ASSERT_EQ(graph.tokenSeparation(a, b), reference.separation(a, b))
              << "inputs " << first << ", " << second << "; query " << a << ", " << b;
        }
      }
    }
  }
}
}  // namespace SetReplace
