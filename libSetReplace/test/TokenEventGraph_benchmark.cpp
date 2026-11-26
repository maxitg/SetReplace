// Runs as part of profile_tests in CI. For standalone measurements, build the library in Release mode, then:
// benchmark_source=libSetReplace/test/TokenEventGraph_benchmark.cpp
// c++ -std=c++17 -O3 -IlibSetReplace "$benchmark_source" build/libSetReplace.a -pthread -o /tmp/ancestry-benchmark
// Usage: /tmp/ancestry-benchmark MODE ITERATIONS
// Modes: chain, diamonds (4 events/iteration), branches (2), parallel (2), untracked,
//        evolve-chain, evolve-fork, evolve-multiway (one event/iteration).
// Output: mode, iterations, events, tokens, construction/query seconds, peak process RSS bytes, checksum (TSV).
// Run each sample in a fresh process; compare identical event/token/query checksums across library versions.
// Timing excludes checksumming and destruction. getrusage's peak RSS includes the entire process, including
// checksumming. RSS is available on macOS/Linux (zero elsewhere). In profile_tests it is cumulative across cases;
// use standalone mode or one --gtest_filter case per fresh process to compare individual workloads' memory use.

#if defined(__APPLE__) || defined(__linux__)
#include <sys/resource.h>
#endif

#ifdef LIBSETREPLACE_BUILD_TESTING
#include <gtest/gtest.h>
#endif

#include <chrono>
#include <cstdint>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>
#include <vector>

#include "HypergraphSubstitutionSystem.hpp"
#include "TokenEventGraph.hpp"

namespace {
using SetReplace::Event;
using SetReplace::TokenEventGraph;
using SetReplace::TokenID;
using Clock = std::chrono::steady_clock;

struct Measurements {
  size_t events;
  size_t tokens;
  double seconds;
  uint64_t peakRSSBytes;
  uint64_t checksum;
};

uint64_t peakRSS() {
#if defined(__APPLE__) || defined(__linux__)
  rusage usage{};
  if (getrusage(RUSAGE_SELF, &usage) != 0) return 0;
#if defined(__APPLE__)
  return usage.ru_maxrss;
#else
  return static_cast<uint64_t>(usage.ru_maxrss) * 1024;
#endif
#else
  return 0;
#endif
}

void hashValue(uint64_t* hash, const uint64_t value) { *hash = (*hash ^ value) * uint64_t{1099511628211}; }

uint64_t hashEvents(const std::vector<Event>& events, uint64_t hash) {
  for (const auto& event : events) {
    hashValue(&hash, event.rule);
    hashValue(&hash, event.generation);
    hashValue(&hash, event.inputTokens.size());
    for (const auto input : event.inputTokens) hashValue(&hash, input);
    hashValue(&hash, event.outputTokens.size());
    for (const auto output : event.outputTokens) hashValue(&hash, output);
  }
  return hash;
}

Measurements measure(const size_t events, const size_t tokens, const Clock::duration duration, const uint64_t hash) {
  return {events, tokens, std::chrono::duration<double>(duration).count(), peakRSS(), hash};
}

Measurements benchmarkGraph(const std::string& mode, const int64_t iterations) {
  const auto start = Clock::now();
  TokenEventGraph graph(2,
                        mode == "untracked" ? TokenEventGraph::SeparationTrackingMethod::None
                                            : TokenEventGraph::SeparationTrackingMethod::DestroyerChoices);
  TokenID first = 0;
  TokenID second = 1;
  uint64_t hash = 0;
  for (int64_t i = 0; i < iterations; ++i) {
    if (mode == "chain" || mode == "untracked") {
      first = graph.addEvent(0, {first}, 1)[0];
      hashValue(&hash, static_cast<uint64_t>(graph.tokenSeparation(0, first)));
    } else if (mode == "diamonds") {
      const auto fork = graph.addEvent(0, {first}, 2);
      first = graph.addEvent(0, {fork[0]}, 1)[0];
      second = graph.addEvent(0, {fork[1]}, 1)[0];
      hashValue(&hash, static_cast<uint64_t>(graph.tokenSeparation(first, second)));
      first = graph.addEvent(0, {first, second}, 1)[0];
    } else if (mode == "branches") {
      second = graph.addEvent(0, {first}, 1)[0];
      first = graph.addEvent(0, {first}, 1)[0];
      hashValue(&hash, static_cast<uint64_t>(graph.tokenSeparation(first, second)));
    } else if (mode == "parallel") {
      first = graph.addEvent(0, {first}, 1)[0];
      second = graph.addEvent(0, {second}, 1)[0];
      hashValue(&hash, static_cast<uint64_t>(graph.tokenSeparation(first, second)));
    } else {
      throw std::invalid_argument("Unknown graph benchmark mode");
    }
  }
  const auto duration = Clock::now() - start;
  hash = hashEvents(graph.events(), hash);
  return measure(graph.eventsCount(), graph.tokenCount(), duration, hash);
}

Measurements benchmarkEvolution(const std::string& mode, const int64_t iterations) {
  using SetReplace::AtomsVector;
  using SetReplace::EventSelectionFunction;
  using SetReplace::HypergraphMatcher;
  using SetReplace::HypergraphSubstitutionSystem;
  using SetReplace::Rule;
  std::vector<Rule> rules;
  std::vector<AtomsVector> initial = {{1}};
  if (mode == "evolve-chain") {
    rules.push_back({{{-1}}, {{-2}}, EventSelectionFunction::Spacelike});
  } else if (mode == "evolve-fork") {
    rules.push_back({{{-1}}, {{-2}, {-3}}, EventSelectionFunction::Spacelike});
  } else if (mode == "evolve-multiway") {
    rules.push_back(
        {{{-1, -2}, {-2, -3}}, {{-2, -3}, {-2, -4}, {-3, -4}, {-2, -1}}, EventSelectionFunction::Spacelike});
    initial = {{1, 1}, {1, 1}};
  } else {
    throw std::invalid_argument("Unknown evolution benchmark mode");
  }
  const HypergraphMatcher::OrderingSpec ordering = {
      {HypergraphMatcher::OrderingFunction::SortedInputTokenIndices, HypergraphMatcher::OrderingDirection::Normal},
      {HypergraphMatcher::OrderingFunction::InputTokenIndices, HypergraphMatcher::OrderingDirection::Normal},
      {HypergraphMatcher::OrderingFunction::RuleIndex, HypergraphMatcher::OrderingDirection::Normal}};
  const auto start = Clock::now();
  HypergraphSubstitutionSystem system(
      rules, initial, std::numeric_limits<int64_t>::max(), ordering, HypergraphMatcher::EventDeduplication::None, 0);
  HypergraphSubstitutionSystem::StepSpecification steps;
  steps.maxEvents = iterations;
  system.replace(steps, []() { return false; });
  const auto duration = Clock::now() - start;
  const auto tokens = system.tokens();
  auto hash = hashEvents(system.events(), 0);
  for (const auto& token : tokens) {
    hashValue(&hash, token.size());
    for (const auto atom : token) hashValue(&hash, atom);
  }
  hashValue(&hash, static_cast<uint64_t>(system.terminationReason()));
  return measure(system.events().size() - 1, tokens.size(), duration, hash);
}

Measurements benchmark(const std::string& mode, const int64_t iterations) {
  return mode.compare(0, 7, "evolve-") == 0 ? benchmarkEvolution(mode, iterations) : benchmarkGraph(mode, iterations);
}
}  // namespace

#ifdef LIBSETREPLACE_BUILD_TESTING
namespace {
// GTest records each case's duration in CI's XML reports. Keep the isolated construction/query timing too, along
// with process RSS and a behavior checksum. Avoid machine-specific timing assertions; performanceTest.wls compares
// the full evaluator against master. The expected checksums were measured with the original copied-map algorithm.
void checkBenchmark(const std::string& mode,
                    const int64_t iterations,
                    const size_t expectedEvents,
                    const size_t expectedTokens,
                    const uint64_t expectedChecksum) {
  SCOPED_TRACE(mode);
  const auto result = benchmark(mode, iterations);
  EXPECT_EQ(result.events, expectedEvents);
  EXPECT_EQ(result.tokens, expectedTokens);
  EXPECT_EQ(result.checksum, expectedChecksum);
  testing::Test::RecordProperty("construction_query_seconds", std::to_string(result.seconds));
  testing::Test::RecordProperty("peak_process_rss_bytes", std::to_string(result.peakRSSBytes));
  testing::Test::RecordProperty("checksum", std::to_string(result.checksum));
}
}  // namespace

TEST(AncestryPerformance, chain) { checkBenchmark("chain", 4000, 4000, 4002, 654487408303846705ULL); }

TEST(AncestryPerformance, diamonds) { checkBenchmark("diamonds", 1000, 4000, 5002, 9085257540886909697ULL); }

TEST(AncestryPerformance, branches) { checkBenchmark("branches", 2000, 4000, 4002, 11627404273712141834ULL); }

TEST(AncestryPerformance, parallel) { checkBenchmark("parallel", 2000, 4000, 4002, 12254675947120317018ULL); }

TEST(AncestryPerformance, untracked) { checkBenchmark("untracked", 100000, 100000, 100002, 5110053651328976625ULL); }

TEST(AncestryPerformance, evolutionChain) { checkBenchmark("evolve-chain", 4000, 4000, 4001, 3833631918176426673ULL); }

TEST(AncestryPerformance, evolutionFork) { checkBenchmark("evolve-fork", 8000, 8000, 16001, 11057497004757859415ULL); }

TEST(AncestryPerformance, evolutionMultiway) {
  checkBenchmark("evolve-multiway", 500, 500, 2002, 7695608088689429497ULL);
}
#else
int main(const int argc, const char* const argv[]) {
  if (argc != 3) {
    std::cerr << "Usage: ancestry-benchmark MODE ITERATIONS\n";
    return 1;
  }
  try {
    const std::string mode(argv[1]);
    const auto iterations = std::stoll(argv[2]);
    if (iterations <= 0) throw std::invalid_argument("Iterations must be positive");
    const auto result = benchmark(mode, iterations);
    std::cout << mode << '\t' << iterations << '\t' << result.events << '\t' << result.tokens << '\t' << result.seconds
              << '\t' << result.peakRSSBytes << '\t' << result.checksum << '\n';
  } catch (const std::exception& error) {
    std::cerr << error.what() << '\n';
    return 1;
  }
}
#endif
