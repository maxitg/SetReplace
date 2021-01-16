#include "SetReplace.hpp"

// NOLINTNEXTLINE(build/c++11)
#include <chrono>  // <chrono> is banned in Chromium, so cpplint flags it https://stackoverflow.com/a/33653404/905496
#include <limits>
#include <memory>
#include <random>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "HypergraphRenderer.hpp"
#include "Set.hpp"

namespace SetReplace {
namespace {
// These are global variables that keep all sets returned to Wolfram Language until they are no longer referenced.
// Pointers are not returned directly for security reasons.
using SetID = mint;
// We use a pointer here because map key insertion (setManageInstance) is separate from map value insertion
// (setInitialize). Until the value is inserted, the set is nullptr.
std::unordered_map<SetID, std::unique_ptr<Set>> sets_;

/** @brief Either acquires or a releases a set, depending on the mode.
 */
void setManageInstance([[maybe_unused]] WolframLibraryData libData, mbool mode, mint id) {
  if (mode == 0) {
    sets_.emplace(id, nullptr);
  } else {
    sets_.erase(id);
  }
}

mint getData(const mint* data, const mint& length, const mint& index) {
  if (index >= length || index < 0) {
    throw LIBRARY_FUNCTION_ERROR;
  } else {
    return data[index];
  }
}

std::vector<AtomsVector> getNextSet(const mint& tensorLength, const mint* tensorData, mint* startReadIndex) {
  const auto getDataFunc = [&tensorData, &tensorLength, startReadIndex]() -> mint {
    return getData(tensorData, tensorLength, (*startReadIndex)++);
  };

  const mint setLength = getDataFunc();
  std::vector<AtomsVector> set(setLength);
  for (mint expressionIndex = 0; expressionIndex < setLength; ++expressionIndex) {
    const mint expressionLength = getDataFunc();
    auto& currentSet = set[expressionIndex];
    currentSet.reserve(expressionLength);
    for (mint atomIndex = 0; atomIndex < expressionLength; ++atomIndex) {
      currentSet.emplace_back(static_cast<Atom>(getDataFunc()));
    }
  }
  return set;
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
      rules.emplace_back(Rule{getNextSet(rulesTensorLength, rulesTensorData, &rulesReadIndex),
                              getNextSet(rulesTensorLength, rulesTensorData, &rulesReadIndex),
                              static_cast<EventSelectionFunction>(
                                  getData(selectionFunctionsTensorData, selectionFunctionsTensorLength, ruleIndex))});
    }
  }
  return rules;
}

std::vector<AtomsVector> getSet(WolframLibraryData libData, MTensor setTensor) {
  mint readIndex = 0;
  return getNextSet(
      libData->MTensor_getFlattenedLength(setTensor), libData->MTensor_getIntegerData(setTensor), &readIndex);
}

Matcher::OrderingSpec getOrderingSpec(WolframLibraryData libData, MTensor orderingSpecTensor) {
  mint tensorLength = libData->MTensor_getFlattenedLength(orderingSpecTensor);
  mint* tensorData = libData->MTensor_getIntegerData(orderingSpecTensor);
  Matcher::OrderingSpec result;
  result.reserve(tensorLength);
  for (mint i = 0; i < tensorLength; i += 2) {
    result.emplace_back(
        std::make_pair(static_cast<Matcher::OrderingFunction>(getData(tensorData, tensorLength, i)),
                       static_cast<Matcher::OrderingDirection>(getData(tensorData, tensorLength, i + 1))));
  }
  return result;
}

Set::StepSpecification getStepSpec(WolframLibraryData libData, MTensor stepsTensor) {
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

    return Set::StepSpecification{
        stepSpecElements[0], stepSpecElements[1], stepSpecElements[2], stepSpecElements[3], stepSpecElements[4]};
  }
}

MTensor putSet(const std::vector<AtomsVector>& expressions, WolframLibraryData libData) {
  // count + atoms list pointer for each expression + an extra pointer at the end to the element one past the end
  size_t tensorLength = 1 + (expressions.size() + 1);

  // Atoms are next, positions to which are referenced in each expression spec.
  // This is where the first atom will be located.
  size_t atomsPointer = tensorLength + 1;
  for (const auto& expression : expressions) {
    tensorLength += expression.size();
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

  appendToTensor({static_cast<mint>(expressions.size())});
  for (const auto& expression : expressions) {
    appendToTensor({static_cast<mint>(atomsPointer)});
    atomsPointer += expression.size();
  }
  appendToTensor({static_cast<mint>(atomsPointer)});

  for (const auto& expression : expressions) {
    // Cannot do static_cast due to 32-bit Windows support
    appendToTensor(std::vector<mint>(expression.begin(), expression.end()));
  }

  return output;
}

MTensor putEvents(const std::vector<Event>& events, WolframLibraryData libData) {
  // ruleID + input expressions pointer + output expressions pointer + generation
  // add fake rule ID and generation at the end to specify the length of the last expression
  size_t tensorLength = 1 + 4 * (events.size() + 1);

  size_t inputsPointer = tensorLength + 1;
  size_t outputsPointer = tensorLength + 1;
  for (const auto& event : events) {
    tensorLength += event.inputExpressions.size() + event.outputExpressions.size();
    outputsPointer += event.inputExpressions.size();
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
    inputsPointer += event.inputExpressions.size();
    outputsPointer += event.outputExpressions.size();
  }

  // Put fake event at the end so that the length of final expression can be determined on WL side.
  constexpr ExpressionID fakeRule = -2;
  constexpr Generation fakeGeneration = -1;
  appendToTensor({static_cast<mint>(fakeRule),
                  static_cast<mint>(inputsPointer),
                  static_cast<mint>(outputsPointer),
                  static_cast<mint>(fakeGeneration)});

  for (const auto& event : events) {
    // Cannot do static_cast due to 32-bit Windows support
    appendToTensor(std::vector<mint>(event.inputExpressions.begin(), event.inputExpressions.end()));
    outputsPointer += event.inputExpressions.size();
  }

  for (const auto& event : events) {
    // Cannot do static_cast due to 32-bit Windows support
    appendToTensor(std::vector<mint>(event.outputExpressions.begin(), event.outputExpressions.end()));
  }

  return output;
}

int setInitialize(WolframLibraryData libData, mint argc, const MArgument* argv, [[maybe_unused]] MArgument result) {
  if (argc != 8) {
    return LIBRARY_FUNCTION_ERROR;
  }

  SetID thisSetID;
  std::vector<Rule> rules;
  std::vector<AtomsVector> initialExpressions;
  Set::SystemType systemType;
  Matcher::OrderingSpec orderingSpec;
  Matcher::EventDeduplication eventDeduplication;
  unsigned int randomSeed;
  try {
    thisSetID = MArgument_getInteger(argv[0]);
    rules = getRules(libData, MArgument_getMTensor(argv[1]), MArgument_getMTensor(argv[2]));
    initialExpressions = getSet(libData, MArgument_getMTensor(argv[3]));
    systemType = static_cast<Set::SystemType>(MArgument_getInteger(argv[4]));
    orderingSpec = getOrderingSpec(libData, MArgument_getMTensor(argv[5]));
    eventDeduplication = static_cast<Matcher::EventDeduplication>(MArgument_getInteger(argv[6]));
    randomSeed = static_cast<unsigned int>(MArgument_getInteger(argv[7]));
  } catch (...) {
    return LIBRARY_FUNCTION_ERROR;
  }

  try {
    sets_[thisSetID] =
        std::make_unique<Set>(rules, initialExpressions, systemType, orderingSpec, eventDeduplication, randomSeed);
  } catch (...) {
    return LIBRARY_FUNCTION_ERROR;
  }

  return LIBRARY_NO_ERROR;
}

std::function<bool()> shouldAbort(WolframLibraryData libData) {
  return [libData]() { return static_cast<bool>(libData->AbortQ()); };
}

Set& setFromID(const SetID id) {
  const auto setIDIterator = sets_.find(id);
  if (setIDIterator != sets_.end()) {
    return *setIDIterator->second;
  } else {
    throw LIBRARY_FUNCTION_ERROR;
  }
}

int setReplace(WolframLibraryData libData, mint argc, MArgument* argv, [[maybe_unused]] MArgument result) {
  if (argc != 2) {
    return LIBRARY_FUNCTION_ERROR;
  }

  const SetID setID = MArgument_getInteger(argv[0]);
  Set::StepSpecification stepSpec;
  try {
    stepSpec = getStepSpec(libData, MArgument_getMTensor(argv[1]));
  } catch (...) {
    return LIBRARY_FUNCTION_ERROR;
  }

  try {
    setFromID(setID).replace(stepSpec, shouldAbort(libData));
  } catch (...) {
    return LIBRARY_FUNCTION_ERROR;
  }

  return LIBRARY_NO_ERROR;
}

int setExpressions(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result) {
  if (argc != 1) {
    return LIBRARY_FUNCTION_ERROR;
  }

  const SetID setID = MArgument_getInteger(argv[0]);

  std::vector<AtomsVector> expressions;
  try {
    expressions = setFromID(setID).expressions();
  } catch (...) {
    return LIBRARY_FUNCTION_ERROR;
  }

  MArgument_setMTensor(result, putSet(expressions, libData));

  return LIBRARY_NO_ERROR;
}

int setEvents(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result) {
  if (argc != 1) {
    return LIBRARY_FUNCTION_ERROR;
  }

  const SetID setID = MArgument_getInteger(argv[0]);

  try {
    const auto& events = setFromID(setID).events();
    MArgument_setMTensor(result, putEvents(events, libData));
  } catch (...) {
    return LIBRARY_FUNCTION_ERROR;
  }

  return LIBRARY_NO_ERROR;
}

int maxCompleteGeneration(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result) {
  if (argc != 1) {
    return LIBRARY_FUNCTION_ERROR;
  }

  const SetID setID = MArgument_getInteger(argv[0]);

  Generation maxCompleteGeneration;
  try {
    maxCompleteGeneration = setFromID(setID).maxCompleteGeneration(shouldAbort(libData));
  } catch (...) {
    return LIBRARY_FUNCTION_ERROR;
  }

  MArgument_setInteger(result, maxCompleteGeneration);

  return LIBRARY_NO_ERROR;
}

int terminationReason([[maybe_unused]] WolframLibraryData, mint argc, MArgument* argv, MArgument result) {
  if (argc != 1) {
    return LIBRARY_FUNCTION_ERROR;
  }

  const SetID setID = MArgument_getInteger(argv[0]);

  Set::TerminationReason terminationReason;
  try {
    terminationReason = setFromID(setID).terminationReason();
  } catch (...) {
    return LIBRARY_FUNCTION_ERROR;
  }

  MArgument_setInteger(result, static_cast<int>(terminationReason));

  return LIBRARY_NO_ERROR;
}

std::string getString(WolframLibraryData libData, MTensor charsTensor) {
  mint stringLength = libData->MTensor_getFlattenedLength(charsTensor);
  mint* tensorData = libData->MTensor_getIntegerData(charsTensor);
  std::string result;
  result.reserve(stringLength);
  for (mint i = 0; i < stringLength; ++i) {
    result.push_back(static_cast<char>(getData(tensorData, stringLength, i)));
  }
  return result;
}

int renderEvolutionVideo(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result) {
  if (argc != 5) {
    return LIBRARY_FUNCTION_ERROR;
  }

  const SetID setID = MArgument_getInteger(argv[0]);
  const std::string filename = getString(libData, MArgument_getMTensor(argv[1]));
  const int width = static_cast<int>(MArgument_getInteger(argv[2]));
  const int height = static_cast<int>(MArgument_getInteger(argv[3]));
  const int fps = static_cast<int>(MArgument_getInteger(argv[4]));

  HypergraphRenderer::Error errorCode;
  try {
    HypergraphRenderer renderer(setFromID(setID));
    errorCode = renderer.renderEvolutionVideo(filename, {width, height}, fps);
  } catch (...) {
    return LIBRARY_FUNCTION_ERROR;
  }

  return static_cast<int>(errorCode);
}
}  // namespace
}  // namespace SetReplace

EXTERN_C mint WolframLibrary_getVersion() { return WolframLibraryVersion; }

EXTERN_C int WolframLibrary_initialize(WolframLibraryData libData) {
  return (*libData->registerLibraryExpressionManager)("SetReplace", SetReplace::setManageInstance);
}

EXTERN_C void WolframLibrary_uninitialize(WolframLibraryData libData) {
  (*libData->unregisterLibraryExpressionManager)("SetReplace");
}

EXTERN_C int setInitialize(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result) {
  return SetReplace::setInitialize(libData, argc, argv, result);
}

EXTERN_C int setReplace(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result) {
  return SetReplace::setReplace(libData, argc, argv, result);
}

EXTERN_C int setExpressions(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result) {
  return SetReplace::setExpressions(libData, argc, argv, result);
}

EXTERN_C int setEvents(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result) {
  return SetReplace::setEvents(libData, argc, argv, result);
}

EXTERN_C int maxCompleteGeneration(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result) {
  return SetReplace::maxCompleteGeneration(libData, argc, argv, result);
}

EXTERN_C int terminationReason(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result) {
  return SetReplace::terminationReason(libData, argc, argv, result);
}

EXTERN_C int renderEvolutionVideo(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result) {
  return SetReplace::renderEvolutionVideo(libData, argc, argv, result);
}
