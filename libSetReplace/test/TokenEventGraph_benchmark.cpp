// Standalone benchmark (not part of the test suite). Build the library in Release mode, then:
// c++ -std=c++17 -O3 -IlibSetReplace libSetReplace/test/TokenEventGraph_benchmark.cpp build/libSetReplace.a \
//   -pthread -o /tmp/ancestry-benchmark
// Usage: /tmp/ancestry-benchmark MODE ITERATIONS
// Modes: chain, diamonds (4 events/iteration), branches (2), parallel (2), untracked,
//        evolve-chain, evolve-fork, evolve-multiway (one event/iteration).
// Output: mode, iterations, events, tokens, construction/query seconds, peak process RSS bytes, checksum (TSV).
// Run each sample in a fresh process; compare identical event/token/query checksums across library versions.
// Timing excludes checksumming and destruction. getrusage's peak RSS includes the entire process, including
// checksumming. RSS measurement requires macOS or a Unix system that reports ru_maxrss in KiB (e.g. Linux).

#include <sys/resource.h>

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

uint64_t peakRSS() {
  rusage usage{};
  getrusage(RUSAGE_SELF, &usage);
#if defined(__APPLE__)
  return usage.ru_maxrss;
#else
  return static_cast<uint64_t>(usage.ru_maxrss) * 1024;
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

void report(const std::string& mode,
            const int64_t iterations,
            const size_t events,
            const size_t tokens,
            const Clock::duration duration,
            const uint64_t hash) {
  std::cout << mode << '\t' << iterations << '\t' << events << '\t' << tokens << '\t'
            << std::chrono::duration<double>(duration).count() << '\t' << peakRSS() << '\t' << hash << '\n';
}

void benchmarkGraph(const std::string& mode, const int64_t iterations) {
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
  report(mode, iterations, graph.eventsCount(), graph.tokenCount(), duration, hash);
}

void benchmarkEvolution(const std::string& mode, const int64_t iterations) {
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
  report(mode, iterations, system.events().size() - 1, tokens.size(), duration, hash);
}
}  // namespace

int main(const int argc, const char* const argv[]) {
  if (argc != 3) {
    std::cerr << "Usage: ancestry-benchmark MODE ITERATIONS\n";
    return 1;
  }
  try {
    const std::string mode(argv[1]);
    const auto iterations = std::stoll(argv[2]);
    if (iterations <= 0) throw std::invalid_argument("Iterations must be positive");
    if (mode.compare(0, 7, "evolve-") == 0) {
      benchmarkEvolution(mode, iterations);
    } else {
      benchmarkGraph(mode, iterations);
    }
  } catch (const std::exception& error) {
    std::cerr << error.what() << '\n';
    return 1;
  }
}
