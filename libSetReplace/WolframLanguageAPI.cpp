#include "WolframLanguageAPI.hpp"

// NOLINTNEXTLINE(build/c++11)
#include <chrono>  // <chrono> is banned in Chromium, so cpplint flags it https://stackoverflow.com/a/33653404/905496
#include <limits>
#include <memory>
#include <random>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "HypergraphSubstitutionSystem.hpp"

namespace SetReplace {
namespace {
// These are global variables that keep all systems returned to Wolfram Language until they are no longer referenced.
// Pointers are not returned directly for security reasons.
using SystemID = mint;
// We use a pointer here because map key insertion (hypergraphManageInstance) is separate from map value insertion
// (hypergraphInitialize). Until the value is inserted, the set is nullptr.
std::unordered_map<SystemID, std::unique_ptr<HypergraphSubstitutionSystem>> hypergraphSubstitutionSystems_;

/** @brief Either acquires or a releases a set, depending on the mode.
 */
void hypergraphSubstitutionSystemManageInstance([[maybe_unused]] WolframLibraryData libData, mbool mode, mint id) {
  if (mode == 0) {
    hypergraphSubstitutionSystems_.emplace(id, nullptr);
  } else {
    hypergraphSubstitutionSystems_.erase(id);
  }
}

mint getData(const mint* data, const mint& length, const mint& index) {
  if (index >= length || index < 0) {
    throw LIBRARY_FUNCTION_ERROR;
  } else {
    return data[index];
  }
}

std::vector<AtomsVector> getNextHypergraph(const mint& tensorLength, const mint* tensorData, mint* startReadIndex) {
  const auto getDataFunc = [&tensorData, &tensorLength, startReadIndex]() -> mint {
    return getData(tensorData, tensorLength, (*startReadIndex)++);
  };

  const mint hypergraphLength = getDataFunc();
  std::vector<AtomsVector> atomVectors(hypergraphLength);
  for (mint tokenIndex = 0; tokenIndex < hypergraphLength; ++tokenIndex) {
    const mint tokenLength = getDataFunc();
    auto& currentToken = atomVectors[tokenIndex];
    currentToken.reserve(tokenLength);
    for (mint atomIndex = 0; atomIndex < tokenLength; ++atomIndex) {
      currentToken.emplace_back(static_cast<Atom>(getDataFunc()));
    }
  }
  return atomVectors;
}

std::vector<Rule> getRules(WolframLibraryData libData, MTensor rulesTensor, MTensor selectionFunctionsTensor) {
  const mint rulesTensorLength = libData->MTensor_getFlattenedLength(rulesTensor);
  const mint* rulesTensorData = libData->MTensor_getIntegerData(rulesTensor);
  const mint selectionFunctionsTensorLength = libData->MTensor_getFlattenedLength(selectionFunctionsTensor);
  const mint* selectionFunctionsTensorData = libData->MTensor_getIntegerData(selectionFunctionsTensor);
  mint rulesReadIndex = 0;
  const auto getRulesData = [&rulesTensorData, &rulesTensorLength, &rulesReadIndex]() -> mint {
    return getData(rulesTensorData, rulesTensorLength, rulesReadIndex++);
  };

  const mint rulesCount = getRulesData();
  if (rulesCount != selectionFunctionsTensorLength) {
    throw LIBRARY_FUNCTION_ERROR;
  }
  std::vector<Rule> rules;
  rules.reserve(rulesCount);
  for (mint ruleIndex = 0; ruleIndex < rulesCount; ++ruleIndex) {
    if (getRulesData() != 2) {
      throw LIBRARY_FUNCTION_ERROR;
    } else {
      rules.emplace_back(Rule{getNextHypergraph(rulesTensorLength, rulesTensorData, &rulesReadIndex),
                              getNextHypergraph(rulesTensorLength, rulesTensorData, &rulesReadIndex),
                              static_cast<EventSelectionFunction>(
                                  getData(selectionFunctionsTensorData, selectionFunctionsTensorLength, ruleIndex))});
    }
  }
  return rules;
}

std::vector<AtomsVector> getHypergraph(WolframLibraryData libData, MTensor setTensor) {
  mint readIndex = 0;
  return getNextHypergraph(
      libData->MTensor_getFlattenedLength(setTensor), libData->MTensor_getIntegerData(setTensor), &readIndex);
}

HypergraphMatcher::OrderingSpec getOrderingSpec(WolframLibraryData libData, MTensor orderingSpecTensor) {
  mint tensorLength = libData->MTensor_getFlattenedLength(orderingSpecTensor);
  mint* tensorData = libData->MTensor_getIntegerData(orderingSpecTensor);
  HypergraphMatcher::OrderingSpec result;
  result.reserve(tensorLength);
  for (mint i = 0; i < tensorLength; i += 2) {
    result.emplace_back(
        std::make_pair(static_cast<HypergraphMatcher::OrderingFunction>(getData(tensorData, tensorLength, i)),
                       static_cast<HypergraphMatcher::OrderingDirection>(getData(tensorData, tensorLength, i + 1))));
  }
  return result;
}

HypergraphSubstitutionSystem::StepSpecification getStepSpec(WolframLibraryData libData, MTensor stepsTensor) {
  mint tensorLength = libData->MTensor_getFlattenedLength(stepsTensor);
  constexpr mint specLength = 5;
  if (tensorLength != specLength) {
    throw LIBRARY_FUNCTION_ERROR;
  } else {
    mint* tensorData = libData->MTensor_getIntegerData(stepsTensor);
    std::vector<int64_t> stepSpecElements(specLength);
    for (mint k = 0; k < specLength; ++k) {
      stepSpecElements[k] = static_cast<int64_t>(getData(tensorData, specLength, k));
      if (stepSpecElements[k] < 0) throw LIBRARY_FUNCTION_ERROR;
    }

    return HypergraphSubstitutionSystem::StepSpecification{
        stepSpecElements[0], stepSpecElements[1], stepSpecElements[2], stepSpecElements[3], stepSpecElements[4]};
  }
}

MTensor putHypergraph(const std::vector<AtomsVector>& tokens, WolframLibraryData libData) {
  // count + atoms list pointer for each token + an extra pointer at the end to the element one past the end
  size_t tensorLength = 1 + (tokens.size() + 1);

  // Atoms are next, positions to which are referenced in each token spec.
  // This is where the first atom will be located.
  size_t atomsPointer = tensorLength + 1;
  for (const auto& token : tokens) {
    tensorLength += token.size();
  }

  const mint dimensions[1] = {static_cast<mint>(tensorLength)};
  MTensor output;
  libData->MTensor_new(MType_Integer, 1, dimensions, &output);

  mint writeIndex = 0;
  mint position[1];
  const auto appendToTensor = [libData, &writeIndex, &position, &output](const std::vector<mint>& numbers) {
    for (const auto number : numbers) {
      position[0] = ++writeIndex;
      libData->MTensor_setInteger(output, position, number);
    }
  };

  appendToTensor({static_cast<mint>(tokens.size())});
  for (const auto& token : tokens) {
    appendToTensor({static_cast<mint>(atomsPointer)});
    atomsPointer += token.size();
  }
  appendToTensor({static_cast<mint>(atomsPointer)});

  for (const auto& token : tokens) {
    // Cannot do static_cast due to 32-bit Windows support
    appendToTensor(std::vector<mint>(token.begin(), token.end()));
  }

  return output;
}

MTensor putEvents(const std::vector<Event>& events, WolframLibraryData libData) {
  // ruleID + input tokens pointer + output tokens pointer + generation
  // add fake rule ID and generation at the end to specify the length of the last token
  size_t tensorLength = 1 + 4 * (events.size() + 1);

  size_t inputsPointer = tensorLength + 1;
  size_t outputsPointer = tensorLength + 1;
  for (const auto& event : events) {
    tensorLength += event.inputTokens.size() + event.outputTokens.size();
    outputsPointer += event.inputTokens.size();
  }

  const mint dimensions[1] = {static_cast<mint>(tensorLength)};
  MTensor output;
  libData->MTensor_new(MType_Integer, 1, dimensions, &output);

  mint writeIndex = 0;
  mint position[1];
  const auto appendToTensor = [libData, &writeIndex, &position, &output](const std::vector<mint>& numbers) {
    for (const auto number : numbers) {
      position[0] = ++writeIndex;
      libData->MTensor_setInteger(output, position, number);
    }
  };

  appendToTensor({static_cast<mint>(events.size())});
  for (const auto& event : events) {
    appendToTensor({static_cast<mint>(event.rule),
                    static_cast<mint>(inputsPointer),
                    static_cast<mint>(outputsPointer),
                    static_cast<mint>(event.generation)});
    inputsPointer += event.inputTokens.size();
    outputsPointer += event.outputTokens.size();
  }

  // Put fake event at the end so that the length of final token can be determined on WL side.
  constexpr TokenID fakeRule = -2;
  constexpr Generation fakeGeneration = -1;
  appendToTensor({static_cast<mint>(fakeRule),
                  static_cast<mint>(inputsPointer),
                  static_cast<mint>(outputsPointer),
                  static_cast<mint>(fakeGeneration)});

  for (const auto& event : events) {
    // Cannot do static_cast due to 32-bit Windows support
    appendToTensor(std::vector<mint>(event.inputTokens.begin(), event.inputTokens.end()));
    outputsPointer += event.inputTokens.size();
  }

  for (const auto& event : events) {
    // Cannot do static_cast due to 32-bit Windows support
    appendToTensor(std::vector<mint>(event.outputTokens.begin(), event.outputTokens.end()));
  }

  return output;
}

int hypergraphSubstitutionSystemInitialize(WolframLibraryData libData,
                                           mint argc,
                                           const MArgument* argv,
                                           [[maybe_unused]] MArgument result) {
  if (argc != 8) {
    return LIBRARY_FUNCTION_ERROR;
  }

  SystemID thisSystemID;
  std::vector<Rule> rules;
  std::vector<AtomsVector> initialTokens;
  uint64_t maxDestroyerEvents;
  HypergraphMatcher::OrderingSpec orderingSpec;
  HypergraphMatcher::EventDeduplication eventDeduplication;
  unsigned int randomSeed;
  try {
    thisSystemID = MArgument_getInteger(argv[0]);
    rules = getRules(libData, MArgument_getMTensor(argv[1]), MArgument_getMTensor(argv[2]));
    initialTokens = getHypergraph(libData, MArgument_getMTensor(argv[3]));
    maxDestroyerEvents = MArgument_getInteger(argv[4]);
    orderingSpec = getOrderingSpec(libData, MArgument_getMTensor(argv[5]));
    eventDeduplication = static_cast<HypergraphMatcher::EventDeduplication>(MArgument_getInteger(argv[6]));
    randomSeed = static_cast<unsigned int>(MArgument_getInteger(argv[7]));
  } catch (...) {
    return LIBRARY_FUNCTION_ERROR;
  }

  try {
    hypergraphSubstitutionSystems_[thisSystemID] = std::make_unique<HypergraphSubstitutionSystem>(
        rules, initialTokens, maxDestroyerEvents, orderingSpec, eventDeduplication, randomSeed);
  } catch (...) {
    return LIBRARY_FUNCTION_ERROR;
  }

  return LIBRARY_NO_ERROR;
}

std::function<bool()> shouldAbort(WolframLibraryData libData) {
  return [libData]() { return static_cast<bool>(libData->AbortQ()); };
}

HypergraphSubstitutionSystem& hypergraphSubstitutionSystemFromID(const SystemID id) {
  const auto setIDIterator = hypergraphSubstitutionSystems_.find(id);
  if (setIDIterator != hypergraphSubstitutionSystems_.end()) {
    return *setIDIterator->second;
  } else {
    throw LIBRARY_FUNCTION_ERROR;
  }
}

int hypergraphSubstitutionSystemReplace(WolframLibraryData libData,
                                        mint argc,
                                        MArgument* argv,
                                        [[maybe_unused]] MArgument result) {
  if (argc != 2) {
    return LIBRARY_FUNCTION_ERROR;
  }

  const SystemID systemID = MArgument_getInteger(argv[0]);
  HypergraphSubstitutionSystem::StepSpecification stepSpec;
  try {
    stepSpec = getStepSpec(libData, MArgument_getMTensor(argv[1]));
  } catch (...) {
    return LIBRARY_FUNCTION_ERROR;
  }

  try {
    hypergraphSubstitutionSystemFromID(systemID).replace(stepSpec, shouldAbort(libData));
  } catch (...) {
    return LIBRARY_FUNCTION_ERROR;
  }

  return LIBRARY_NO_ERROR;
}

int hypergraphSubstitutionSystemTokens(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result) {
  if (argc != 1) {
    return LIBRARY_FUNCTION_ERROR;
  }

  const SystemID systemID = MArgument_getInteger(argv[0]);

  std::vector<AtomsVector> tokens;
  try {
    tokens = hypergraphSubstitutionSystemFromID(systemID).tokens();
  } catch (...) {
    return LIBRARY_FUNCTION_ERROR;
  }

  MArgument_setMTensor(result, putHypergraph(tokens, libData));

  return LIBRARY_NO_ERROR;
}

int hypergraphSubstitutionSystemEvents(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result) {
  if (argc != 1) {
    return LIBRARY_FUNCTION_ERROR;
  }

  const SystemID systemID = MArgument_getInteger(argv[0]);

  try {
    const auto& events = hypergraphSubstitutionSystemFromID(systemID).events();
    MArgument_setMTensor(result, putEvents(events, libData));
  } catch (...) {
    return LIBRARY_FUNCTION_ERROR;
  }

  return LIBRARY_NO_ERROR;
}

int hypergraphSubstitutionSystemMaxCompleteGeneration(WolframLibraryData libData,
                                                      mint argc,
                                                      MArgument* argv,
                                                      MArgument result) {
  if (argc != 1) {
    return LIBRARY_FUNCTION_ERROR;
  }

  const SystemID systemID = MArgument_getInteger(argv[0]);

  Generation maxCompleteGeneration;
  try {
    maxCompleteGeneration = hypergraphSubstitutionSystemFromID(systemID).maxCompleteGeneration(shouldAbort(libData));
  } catch (...) {
    return LIBRARY_FUNCTION_ERROR;
  }

  MArgument_setInteger(result, maxCompleteGeneration);

  return LIBRARY_NO_ERROR;
}

int hypergraphSubstitutionSystemTerminationReason([[maybe_unused]] WolframLibraryData,
                                                  mint argc,
                                                  MArgument* argv,
                                                  MArgument result) {
  if (argc != 1) {
    return LIBRARY_FUNCTION_ERROR;
  }

  const SystemID systemID = MArgument_getInteger(argv[0]);

  HypergraphSubstitutionSystem::TerminationReason terminationReason;
  try {
    terminationReason = hypergraphSubstitutionSystemFromID(systemID).terminationReason();
  } catch (...) {
    return LIBRARY_FUNCTION_ERROR;
  }

  MArgument_setInteger(result, static_cast<int>(terminationReason));

  return LIBRARY_NO_ERROR;
}
}  // namespace
}  // namespace SetReplace

EXTERN_C mint WolframLibrary_getVersion() { return WolframLibraryVersion; }

EXTERN_C int WolframLibrary_initialize(WolframLibraryData libData) {
  return (*libData->registerLibraryExpressionManager)("SetReplace",
                                                      SetReplace::hypergraphSubstitutionSystemManageInstance);
}

EXTERN_C void WolframLibrary_uninitialize(WolframLibraryData libData) {
  (*libData->unregisterLibraryExpressionManager)("SetReplace");
}

EXTERN_C int hypergraphSubstitutionSystemInitialize(WolframLibraryData libData,
                                                    mint argc,
                                                    MArgument* argv,
                                                    MArgument result) {
  return SetReplace::hypergraphSubstitutionSystemInitialize(libData, argc, argv, result);
}

EXTERN_C int hypergraphSubstitutionSystemReplace(WolframLibraryData libData,
                                                 mint argc,
                                                 MArgument* argv,
                                                 MArgument result) {
  return SetReplace::hypergraphSubstitutionSystemReplace(libData, argc, argv, result);
}

EXTERN_C int hypergraphSubstitutionSystemTokens(WolframLibraryData libData,
                                                mint argc,
                                                MArgument* argv,
                                                MArgument result) {
  return SetReplace::hypergraphSubstitutionSystemTokens(libData, argc, argv, result);
}

EXTERN_C int hypergraphSubstitutionSystemEvents(WolframLibraryData libData,
                                                mint argc,
                                                MArgument* argv,
                                                MArgument result) {
  return SetReplace::hypergraphSubstitutionSystemEvents(libData, argc, argv, result);
}

EXTERN_C int hypergraphSubstitutionSystemMaxCompleteGeneration(WolframLibraryData libData,
                                                               mint argc,
                                                               MArgument* argv,
                                                               MArgument result) {
  return SetReplace::hypergraphSubstitutionSystemMaxCompleteGeneration(libData, argc, argv, result);
}

EXTERN_C int hypergraphSubstitutionSystemTerminationReason(WolframLibraryData libData,
                                                           mint argc,
                                                           MArgument* argv,
                                                           MArgument result) {
  return SetReplace::hypergraphSubstitutionSystemTerminationReason(libData, argc, argv, result);
}
