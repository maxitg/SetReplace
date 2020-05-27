#include "SetReplace.hpp"

// NOLINTNEXTLINE(build/c++11)
#include <chrono>  // <chrono> is banned in Chromium, so cpplint flags it https://stackoverflow.com/a/33653404/905496
#include <limits>
#include <random>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "Set.hpp"

mint getData(const mint* data, const mint& length, const mint& index) {
  if (index >= length || index < 0) {
    throw LIBRARY_FUNCTION_ERROR;
  } else {
    return data[index];
  }
}

namespace SetReplace {
// These are global variables that keep all sets returned to Wolfram Language until they are destroyed.
// Pointers are not returned directly for security reasons.
using SetID = int64_t;
std::unordered_map<SetID, Set> sets_;

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

std::vector<Rule> getRules(WolframLibraryData libData, MTensor rulesTensor) {
  const mint tensorLength = libData->MTensor_getFlattenedLength(rulesTensor);
  const mint* tensorData = libData->MTensor_getIntegerData(rulesTensor);
  mint readIndex = 0;
  const auto getRulesData = [&tensorData, &tensorLength, &readIndex]() -> mint {
    return getData(tensorData, tensorLength, readIndex++);
  };

  const mint rulesCount = getRulesData();
  std::vector<Rule> rules;
  rules.reserve(rulesCount);
  for (mint ruleIndex = 0; ruleIndex < rulesCount; ++ruleIndex) {
    if (getRulesData() != 2) {
      throw LIBRARY_FUNCTION_ERROR;
    } else {
      rules.emplace_back(
          Rule{getNextSet(tensorLength, tensorData, &readIndex), getNextSet(tensorLength, tensorData, &readIndex)});
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

MTensor putSet(const std::vector<SetExpression>& expressions, WolframLibraryData libData) {
  // creator event + destroyer events pointer + generation + atoms list pointer
  // add fake event at the end to specify the length of the last expression
  size_t tensorLength = 1 + 4 * (expressions.size() + 1);

  // Atoms are next, positions to which are referenced in each expression spec.
  // This is where the first atom will be located.
  size_t atomsPointer = tensorLength + 1;
  for (const auto& expression : expressions) {
    tensorLength += expression.atoms.size();
  }

  // Finally, destroyer events.
  // This is where the first list of destroyer events is located.
  size_t destroyerPointer = tensorLength + 1;
  for (const auto& expression : expressions) {
    tensorLength += expression.destroyerEvents.size();
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
    appendToTensor({static_cast<mint>(expression.creatorEvent),
                    static_cast<mint>(destroyerPointer),
                    static_cast<mint>(expression.generation),
                    static_cast<mint>(atomsPointer)});
    atomsPointer += expression.atoms.size();
    destroyerPointer += expression.destroyerEvents.size();
  }

  // Put fake event at the end so that the length of final expression can be determined on WL side.
  constexpr EventID fakeEvent = -3;
  constexpr Generation fakeGeneration = -1;
  appendToTensor({static_cast<mint>(fakeEvent),
                  static_cast<mint>(destroyerPointer),
                  static_cast<mint>(fakeGeneration),
                  static_cast<mint>(atomsPointer)});

  for (const auto& expression : expressions) {
    // Cannot do static_cast due to 32-bit Windows support
    appendToTensor(std::vector<mint>(expression.atoms.begin(), expression.atoms.end()));
  }

  for (const auto& expression : expressions) {
    appendToTensor(expression.destroyerEvents);
  }

  return output;
}

int setCreate(WolframLibraryData libData, mint argc, const MArgument* argv, MArgument result) {
  if (argc != 5) {
    return LIBRARY_FUNCTION_ERROR;
  }

  std::vector<Rule> rules;
  std::vector<AtomsVector> initialExpressions;
  Set::EventSelectionFunction eventSelectionFunction;
  Matcher::OrderingSpec orderingSpec;
  unsigned int randomSeed;
  try {
    rules = getRules(libData, MArgument_getMTensor(argv[0]));
    initialExpressions = getSet(libData, MArgument_getMTensor(argv[1]));
    eventSelectionFunction = static_cast<Set::EventSelectionFunction>(MArgument_getInteger(argv[2]));
    orderingSpec = getOrderingSpec(libData, MArgument_getMTensor(argv[3]));
    randomSeed = static_cast<unsigned int>(MArgument_getInteger(argv[4]));
  } catch (...) {
    return LIBRARY_FUNCTION_ERROR;
  }

  SetID thisSetID;
  do {
    std::mt19937_64 randomGenerator(std::chrono::system_clock::now().time_since_epoch().count());
    std::uniform_int_distribution<SetID> distribution(0, std::numeric_limits<SetID>::max());
    thisSetID = distribution(randomGenerator);
  } while (sets_.count(thisSetID) > 0);
  try {
    sets_.insert({thisSetID, Set(rules, initialExpressions, eventSelectionFunction, orderingSpec, randomSeed)});
  } catch (...) {
    return LIBRARY_FUNCTION_ERROR;
  }

  MArgument_setInteger(result, thisSetID);
  return LIBRARY_NO_ERROR;
}

int setDelete([[maybe_unused]] WolframLibraryData libData,
              mint argc,
              MArgument* argv,
              [[maybe_unused]] MArgument result) {
  if (argc != 1) {
    return LIBRARY_FUNCTION_ERROR;
  }
  const SetID setToDelete = MArgument_getInteger(argv[0]);

  const auto setToDeleteIterator = sets_.find(setToDelete);
  if (setToDeleteIterator != sets_.end()) {
    sets_.erase(setToDeleteIterator);
  } else {
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
    return setIDIterator->second;
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

  std::vector<SetExpression> expressions;
  try {
    expressions = setFromID(setID).expressions();
  } catch (...) {
    return LIBRARY_FUNCTION_ERROR;
  }

  MArgument_setMTensor(result, putSet(expressions, libData));

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

int eventRuleIDs(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result) {
  if (argc != 1) {
    return LIBRARY_FUNCTION_ERROR;
  }

  const SetID setID = MArgument_getInteger(argv[0]);

  try {
    const auto ruleIDs = setFromID(setID).eventRuleIDs();
    const mint dimensions[1] = {static_cast<mint>(ruleIDs.size() - 1)};
    MTensor output;
    libData->MTensor_new(MType_Integer, 1, dimensions, &output);

    mint writeIndex = 0;
    mint position[1];
    for (size_t event = 1; event < ruleIDs.size(); ++event) {
      position[0] = ++writeIndex;
      libData->MTensor_setInteger(output, position, static_cast<mint>(ruleIDs[event]) + 1);
    }

    MArgument_setMTensor(result, output);
  } catch (...) {
    return LIBRARY_FUNCTION_ERROR;
  }

  return LIBRARY_NO_ERROR;
}
}  // namespace SetReplace

EXTERN_C mint WolframLibrary_getVersion() { return WolframLibraryVersion; }

EXTERN_C int WolframLibrary_initialize([[maybe_unused]] WolframLibraryData libData) { return 0; }

EXTERN_C void WolframLibrary_uninitialize([[maybe_unused]] WolframLibraryData libData) { return; }

EXTERN_C int setCreate(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result) {
  return SetReplace::setCreate(libData, argc, argv, result);
}

EXTERN_C int setDelete(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result) {
  return SetReplace::setDelete(libData, argc, argv, result);
}

EXTERN_C int setReplace(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result) {
  return SetReplace::setReplace(libData, argc, argv, result);
}

EXTERN_C int setExpressions(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result) {
  return SetReplace::setExpressions(libData, argc, argv, result);
}

EXTERN_C int maxCompleteGeneration(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result) {
  return SetReplace::maxCompleteGeneration(libData, argc, argv, result);
}

EXTERN_C int terminationReason(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result) {
  return SetReplace::terminationReason(libData, argc, argv, result);
}

EXTERN_C int eventRuleIDs(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result) {
  return SetReplace::eventRuleIDs(libData, argc, argv, result);
}
