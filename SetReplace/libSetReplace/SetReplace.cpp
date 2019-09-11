#include <chrono>
#include <string>

#include "SetReplace.hpp"

#include "Set.hpp"

mint getData(mint* data, mint length, mint index) {
    if (index >= length) {
        throw LIBRARY_FUNCTION_ERROR;
    } else {
        return data[index];
    }
}

namespace SetReplace {
    std::vector<Rule> getRules(WolframLibraryData libData, MTensor& rulesTensor) {
        mint tensorLength = libData->MTensor_getFlattenedLength(rulesTensor);
        mint* tensorData = libData->MTensor_getIntegerData(rulesTensor);
        int readIndex = 0;
        const auto getRulesData = [&tensorData, &tensorLength, &readIndex]() -> mint {
            return getData(tensorData, tensorLength, readIndex++);
        };
        
        const int rulesCount = static_cast<int>(getRulesData());
        std::vector<Rule> rules;
        for (int ruleIndex = 0; ruleIndex < rulesCount; ++ruleIndex) {
            if (getRulesData() != 2) {
                throw LIBRARY_FUNCTION_ERROR;
            } else {
                std::vector<std::vector<AtomsVector>> ruleInputsAndOutputs(2);
                
                for (auto& set : ruleInputsAndOutputs) {
                    set.resize(getRulesData());
                    for (int expressionIndex = 0; expressionIndex < set.size(); ++expressionIndex) {
                        set[expressionIndex].resize(getRulesData());
                        for (int atomIndex = 0; atomIndex < set[expressionIndex].size(); ++atomIndex) {
                            set[expressionIndex][atomIndex] = (int)getRulesData();
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
        int readIndex = 0;
        const auto getSetData = [&tensorData, &tensorLength, &readIndex]() -> mint {
            return getData(tensorData, tensorLength, readIndex++);
        };
        
        std::vector<AtomsVector> set(getSetData());
        for (int expressionIndex = 0; expressionIndex < set.size(); ++expressionIndex) {
            set[expressionIndex].resize(getSetData());
            for (int atomIndex = 0; atomIndex < set[expressionIndex].size(); ++atomIndex) {
                set[expressionIndex][atomIndex] = (int)getSetData();
            }
        }
        return set;
    }
    
    std::pair<int, Generation> getGenerationsAndSteps(WolframLibraryData libData, MTensor& stepsTensor) {
        mint tensorLength = libData->MTensor_getFlattenedLength(stepsTensor);
        if (tensorLength != 2) {
            throw LIBRARY_DIMENSION_ERROR;
        } else {
            mint* tensorData = libData->MTensor_getIntegerData(stepsTensor);
            return {getData(tensorData, 2, 0), getData(tensorData, 2, 1)};
        }
    }
    
    MTensor putSet(const std::vector<SetExpression>& expressions, WolframLibraryData libData) {
        // creator + destroyer events + generation + atoms count
        // add fake event at the end to specify the length of the last expression
        int tensorLength = 1 + 4 * (static_cast<int>(expressions.size()) + 1);
        
        // The rest of the result are the atoms, positions to which are referenced in each expression spec.
        // This is where the first atom will be located.
        int atomsPointer = tensorLength + 1;
        
        for (int i = 0; i < expressions.size(); ++i) {
            tensorLength += expressions[i].atoms.size();
        }
        
        mint dimensions[1] = {tensorLength};
        MTensor output;
        libData->MTensor_new(MType_Integer, 1, dimensions, &output);
        
        int writeIndex = 0;
        mint position[1];
        const auto appendToTensor = [libData, &writeIndex, &position, &output](const std::vector<int> numbers) {
            for (const auto number : numbers) {
                position[0] = ++writeIndex;
                libData->MTensor_setInteger(output, position, number);
            }
        };
        
        appendToTensor({static_cast<int>(expressions.size())});
        for (int expressionIndex = 0; expressionIndex < expressions.size(); ++expressionIndex) {
            appendToTensor({
                expressions[expressionIndex].creatorEvent,
                expressions[expressionIndex].destroyerEvent,
                expressions[expressionIndex].generation,
                atomsPointer});
            atomsPointer += expressions[expressionIndex].atoms.size();
        }
        
        // Put fake event at the end so that the length of final expression can be determined on WL side.
        constexpr EventID fakeEvent = -3;
        constexpr Generation fakeGeneration = -1;
        appendToTensor({fakeEvent, fakeEvent, fakeGeneration, atomsPointer});
        
        for (int expressionIndex = 0; expressionIndex < expressions.size(); ++expressionIndex) {
            appendToTensor(expressions[expressionIndex].atoms);
        }
        
        return output;
    }
    
    int setReplace(WolframLibraryData libData, mint argc, MArgument *argv, MArgument result) {
        if (argc != 3) {
            return LIBRARY_FUNCTION_ERROR;
        }
        
        std::vector<Rule> rules;
        std::vector<AtomsVector> initialExpressions;
        std::pair<Generation, int> generationsAndSteps;
        try {
            rules = getRules(libData, MArgument_getMTensor(argv[0]));
            initialExpressions = getSet(libData, MArgument_getMTensor(argv[1]));
            generationsAndSteps = getGenerationsAndSteps(libData, MArgument_getMTensor(argv[2]));
        } catch (...) {
            return LIBRARY_FUNCTION_ERROR;
        }
        
        const auto shouldAbort = [&libData]() {
            return static_cast<bool>(libData->AbortQ());
        };
        try {
            Set set(rules, initialExpressions, shouldAbort, generationsAndSteps.first);
            set.replace(generationsAndSteps.second);
            const auto expressions = set.expressions();
            MArgument_setMTensor(result, putSet(expressions, libData));
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

EXTERN_C int setReplace(WolframLibraryData libData, mint argc, MArgument *argv, MArgument result) {
    return SetReplace::setReplace(libData, argc, argv, result);
}
