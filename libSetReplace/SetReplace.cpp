#include <chrono>
#include <random>
#include <string>
#include <unordered_map>

#include "SetReplace.hpp"

#include "Set.hpp"

mint getData(mint* data, mint length, mint index) {
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

    std::vector<Rule> getRules(WolframLibraryData libData, MTensor& rulesTensor) {
        mint tensorLength = libData->MTensor_getFlattenedLength(rulesTensor);
        mint* tensorData = libData->MTensor_getIntegerData(rulesTensor);
        mint readIndex = 0;
        const auto getRulesData = [&tensorData, &tensorLength, &readIndex]() -> mint {
            return getData(tensorData, tensorLength, readIndex++);
        };
        
        const mint rulesCount = getRulesData();
        std::vector<Rule> rules;
        for (mint ruleIndex = 0; ruleIndex < rulesCount; ++ruleIndex) {
            if (getRulesData() != 2) {
                throw LIBRARY_FUNCTION_ERROR;
            } else {
                std::vector<std::vector<AtomsVector>> ruleInputsAndOutputs(2);
                
                for (auto& set : ruleInputsAndOutputs) {
                    const mint setLength = getRulesData();
                    for (mint expressionIndex = 0; expressionIndex < setLength; ++expressionIndex) {
                        const mint expressionLength = getRulesData();
                        set.push_back(AtomsVector());
                        for (mint atomIndex = 0; atomIndex < expressionLength; ++atomIndex) {
                            set[expressionIndex].push_back(static_cast<Atom>(getRulesData()));
                        }
                    }
                }
                rules.push_back(Rule{ruleInputsAndOutputs[0], ruleInputsAndOutputs[1]});
            }
        }
        return rules;
    }
    
    std::vector<AtomsVector> getSet(WolframLibraryData libData, MTensor& setTensor) {
        mint tensorLength = libData->MTensor_getFlattenedLength(setTensor);
        mint* tensorData = libData->MTensor_getIntegerData(setTensor);
        mint readIndex = 0;
        const auto getSetData = [&tensorData, &tensorLength, &readIndex]() -> mint {
            return getData(tensorData, tensorLength, readIndex++);
        };
        
        const mint setLength = getSetData();
        std::vector<AtomsVector> set;
        for (mint expressionIndex = 0; expressionIndex < setLength; ++expressionIndex) {
            const mint expressionLength = getSetData();
            set.push_back(AtomsVector());
            for (mint atomIndex = 0; atomIndex < expressionLength; ++atomIndex) {
                set[expressionIndex].push_back(static_cast<Atom>(getSetData()));
            }
        }
        return set;
    }

    Matcher::OrderingSpec getOrderingSpec(WolframLibraryData libData, MTensor& orderingSpecTensor) {
        mint tensorLength = libData->MTensor_getFlattenedLength(orderingSpecTensor);
        mint* tensorData = libData->MTensor_getIntegerData(orderingSpecTensor);
        Matcher::OrderingSpec result;
        for (mint i = 0; i < tensorLength; i += 2) {
            result.push_back({
                static_cast<Matcher::OrderingFunction>(getData(tensorData, tensorLength, i)),
                static_cast<Matcher::OrderingDirection>(getData(tensorData, tensorLength, i + 1))});
        }
        return result;
    }
    
    Set::StepSpecification getStepSpec(WolframLibraryData libData, MTensor& stepsTensor) {
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
            Set::StepSpecification result;
            result.maxEvents = stepSpecElements[0];
            result.maxGenerationsLocal = stepSpecElements[1];
            result.maxFinalAtoms = stepSpecElements[2];
            result.maxFinalAtomDegree = stepSpecElements[3];
            result.maxFinalExpressions = stepSpecElements[4];
            
            return result;
        }
    }
    
    MTensor putSet(const std::vector<SetExpression>& expressions, WolframLibraryData libData) {
        // creator + destroyer events + generation + atoms count
        // add fake event at the end to specify the length of the last expression
        size_t tensorLength = 1 + 4 * (expressions.size() + 1);
        
        // The rest of the result are the atoms, positions to which are referenced in each expression spec.
        // This is where the first atom will be located.
        size_t atomsPointer = tensorLength + 1;
        
        for (size_t i = 0; i < expressions.size(); ++i) {
            tensorLength += expressions[i].atoms.size();
        }
        
        mint dimensions[1] = {static_cast<mint>(tensorLength)};
        MTensor output;
        libData->MTensor_new(MType_Integer, 1, dimensions, &output);
        
        mint writeIndex = 0;
        mint position[1];
        const auto appendToTensor = [libData, &writeIndex, &position, &output](const std::vector<mint> numbers) {
            for (const auto number : numbers) {
                position[0] = ++writeIndex;
                libData->MTensor_setInteger(output, position, number);
            }
        };
        
        appendToTensor({static_cast<mint>(expressions.size())});
        for (size_t expressionIndex = 0; expressionIndex < expressions.size(); ++expressionIndex) {
            appendToTensor({
                expressions[expressionIndex].creatorEvent,
                expressions[expressionIndex].destroyerEvent,
                expressions[expressionIndex].generation,
                static_cast<mint>(atomsPointer)});
            atomsPointer += expressions[expressionIndex].atoms.size();
        }
        
        // Put fake event at the end so that the length of final expression can be determined on WL side.
        constexpr EventID fakeEvent = -3;
        constexpr Generation fakeGeneration = -1;
        appendToTensor({fakeEvent, fakeEvent, fakeGeneration, static_cast<mint>(atomsPointer)});
        
        for (size_t expressionIndex = 0; expressionIndex < expressions.size(); ++expressionIndex) {
            appendToTensor(expressions[expressionIndex].atoms);
        }
        
        return output;
    }

    int setCreate(WolframLibraryData libData, mint argc, MArgument *argv, MArgument result) {
        if (argc != 4) {
            return LIBRARY_FUNCTION_ERROR;
        }
        
        std::vector<Rule> rules;
        std::vector<AtomsVector> initialExpressions;
        Matcher::OrderingSpec orderingSpec;
        unsigned int randomSeed;
        try {
            rules = getRules(libData, MArgument_getMTensor(argv[0]));
            initialExpressions = getSet(libData, MArgument_getMTensor(argv[1]));
            orderingSpec = getOrderingSpec(libData, MArgument_getMTensor(argv[2]));
            randomSeed = static_cast<unsigned int>(MArgument_getInteger(argv[3]));
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
            sets_.insert({thisSetID, Set(rules, initialExpressions, orderingSpec, randomSeed)});
        } catch (...) {
            return LIBRARY_FUNCTION_ERROR;
        }
        
        MArgument_setInteger(result, thisSetID);
        return LIBRARY_NO_ERROR;
    }

    int setDelete(WolframLibraryData libData, mint argc, MArgument *argv, MArgument result) {
        if (argc != 1) {
            return LIBRARY_FUNCTION_ERROR;
        }
        const SetID setToDelete = MArgument_getInteger(argv[0]);
        if (sets_.count(setToDelete)) {
            sets_.erase(setToDelete);
        } else {
            return LIBRARY_FUNCTION_ERROR;
        }
        return LIBRARY_NO_ERROR;
    }
    
    const std::function<bool()> shouldAbort(WolframLibraryData& libData) {
        return [&libData]() {
            return static_cast<bool>(libData->AbortQ());
        };
    }

    Set& setFromID(const SetID id) {
        if (sets_.count(id)) {
            return sets_.at(id);
        } else {
            throw LIBRARY_FUNCTION_ERROR;
        }
    }

    int setReplace(WolframLibraryData libData, mint argc, MArgument *argv, MArgument result) {
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

    int setExpressions(WolframLibraryData libData, mint argc, MArgument *argv, MArgument result) {
        if (argc != 1) {
            return LIBRARY_FUNCTION_ERROR;
        }
        
        const SetID setID = MArgument_getInteger(argv[0]);;
        
        std::vector<SetExpression> expressions;
        try {
            expressions = setFromID(setID).expressions();
        } catch (...) {
            return LIBRARY_FUNCTION_ERROR;
        }
        
        MArgument_setMTensor(result, putSet(expressions, libData));
        
        return LIBRARY_NO_ERROR;
    }

    int maxCompleteGeneration(WolframLibraryData libData, mint argc, MArgument *argv, MArgument result) {
        if (argc != 1) {
            return LIBRARY_FUNCTION_ERROR;
        }
        
        const SetID setID = MArgument_getInteger(argv[0]);;
        
        Generation maxCompleteGeneration;
        try {
            maxCompleteGeneration = setFromID(setID).maxCompleteGeneration(shouldAbort(libData));
        } catch (...) {
            return LIBRARY_FUNCTION_ERROR;
        }
        
        MArgument_setInteger(result, maxCompleteGeneration);
        
        return LIBRARY_NO_ERROR;
    }

    int terminationReason(WolframLibraryData libData, mint argc, MArgument *argv, MArgument result) {
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
        
        MArgument_setInteger(result, (int)terminationReason);

        return LIBRARY_NO_ERROR;
    }

    int eventRuleIDs(WolframLibraryData libData, mint argc, MArgument *argv, MArgument result) {
        if (argc != 1) {
            return LIBRARY_FUNCTION_ERROR;
        }
        
        const SetID setID = MArgument_getInteger(argv[0]);
        
        try {
            const auto ruleIDs = setFromID(setID).eventRuleIDs();
            mint dimensions[1] = {static_cast<mint>(ruleIDs.size() - 1)};
            MTensor output;
            libData->MTensor_new(MType_Integer, 1, dimensions, &output);
            
            mint writeIndex = 0;
            mint position[1];
            for (size_t event = 1; event < ruleIDs.size(); ++event) {
                position[0] = ++writeIndex;
                libData->MTensor_setInteger(output, position, ruleIDs[event] + 1);
            }
            
            MArgument_setMTensor(result, output);
        } catch (...) {
            return LIBRARY_FUNCTION_ERROR;
        }
        
        return LIBRARY_NO_ERROR;
    }
}

EXTERN_C mint WolframLibrary_getVersion() {
    return WolframLibraryVersion;
}

EXTERN_C int WolframLibrary_initialize(WolframLibraryData libData) {
    return 0;
}

EXTERN_C void WolframLibrary_uninitialize(WolframLibraryData libData) {
    return;
}

EXTERN_C int setCreate(WolframLibraryData libData, mint argc, MArgument *argv, MArgument result) {
    return SetReplace::setCreate(libData, argc, argv, result);
}

EXTERN_C int setDelete(WolframLibraryData libData, mint argc, MArgument *argv, MArgument result) {
    return SetReplace::setDelete(libData, argc, argv, result);
}

EXTERN_C int setReplace(WolframLibraryData libData, mint argc, MArgument *argv, MArgument result) {
    return SetReplace::setReplace(libData, argc, argv, result);
}

EXTERN_C int setExpressions(WolframLibraryData libData, mint argc, MArgument *argv, MArgument result) {
    return SetReplace::setExpressions(libData, argc, argv, result);
}

EXTERN_C int maxCompleteGeneration(WolframLibraryData libData, mint argc, MArgument *argv, MArgument result) {
    return SetReplace::maxCompleteGeneration(libData, argc, argv, result);
}

EXTERN_C int terminationReason(WolframLibraryData libData, mint argc, MArgument *argv, MArgument result) {
    return SetReplace::terminationReason(libData, argc, argv, result);
}

EXTERN_C int eventRuleIDs(WolframLibraryData libData, mint argc, MArgument *argv, MArgument result) {
    return SetReplace::eventRuleIDs(libData, argc, argv, result);
}
