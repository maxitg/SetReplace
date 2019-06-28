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
        
        std::vector<Rule> rules(getRulesData());
        for (int ruleIndex = 0; ruleIndex < rules.size(); ++ruleIndex) {
            if (getRulesData() != 2) {
                throw LIBRARY_FUNCTION_ERROR;
            } else {
                const std::vector<std::vector<Expression>*> setsToRead =
                {&rules[ruleIndex].inputs, &rules[ruleIndex].outputs};
                
                for (auto& set : setsToRead) {
                    set->resize(getRulesData());
                    for (int expressionIndex = 0; expressionIndex < set->size(); ++expressionIndex) {
                        (*set)[expressionIndex].resize(getRulesData());
                        for (int atomIndex = 0; atomIndex < (*set)[expressionIndex].size(); ++atomIndex) {
                            (*set)[expressionIndex][atomIndex] = (int)getRulesData();
                        }
                    }
                }
            }
        }
        return rules;
    }
    
    std::vector<Expression> getSet(WolframLibraryData libData, MTensor& setTensor) {
        mint tensorLength = libData->MTensor_getFlattenedLength(setTensor);
        mint* tensorData = libData->MTensor_getIntegerData(setTensor);
        int readIndex = 0;
        const auto getSetData = [&tensorData, &tensorLength, &readIndex]() -> mint {
            return getData(tensorData, tensorLength, readIndex++);
        };
        
        std::vector<Expression> set(getSetData());
        for (int expressionIndex = 0; expressionIndex < set.size(); ++expressionIndex) {
            set[expressionIndex].resize(getSetData());
            for (int atomIndex = 0; atomIndex < set[expressionIndex].size(); ++atomIndex) {
                set[expressionIndex][atomIndex] = (int)getSetData();
            }
        }
        return set;
    }
    
    MTensor putSet(const std::vector<Expression>& expressions, WolframLibraryData libData) {
        int tensorLength = 1 + (int)expressions.size();
        for (int i = 0; i < expressions.size(); ++i) {
            tensorLength += expressions[i].size();
        }
        
        mint dimensions[1] = {tensorLength};
        MTensor output;
        libData->MTensor_new(MType_Integer, 1, dimensions, &output);
        
        int writeIndex = 0;
        mint position[1];
        position[0] = ++writeIndex;
        libData->MTensor_setInteger(output, position, expressions.size());
        for (int expressionIndex = 0; expressionIndex < expressions.size(); ++expressionIndex) {
            position[0] = ++writeIndex;
            libData->MTensor_setInteger(output, position, expressions[expressionIndex].size());
            for (int atomIndex = 0; atomIndex < expressions[expressionIndex].size(); ++atomIndex) {
                position[0] = ++writeIndex;
                libData->MTensor_setInteger(output, position, expressions[expressionIndex][atomIndex]);
            }
        }
        
        return output;
    }
    
    MTensor putSets(const std::vector<std::vector<Expression>>& sets, WolframLibraryData libData) {
        int tensorLength = 1 + (int)sets.size();
        for (const auto& set : sets) {
            tensorLength += (int)set.size();
            for (const auto& expression : set) {
                tensorLength += (int)expression.size();
            }
        }
        
        mint dimensions[1] = {tensorLength};
        MTensor output;
        libData->MTensor_new(MType_Integer, 1, dimensions, &output);
        
        int writeIndex = 0;
        mint position[1];
        position[0] = ++writeIndex;
        libData->MTensor_setInteger(output, position, sets.size());
        for (int setIndex = 0; setIndex < sets.size(); ++setIndex) {
            position[0] = ++writeIndex;
            libData->MTensor_setInteger(output, position, sets[setIndex].size());
            for (int expressionIndex = 0; expressionIndex < sets[setIndex].size(); expressionIndex++) {
                position[0] = ++writeIndex;
                libData->MTensor_setInteger(output, position, sets[setIndex][expressionIndex].size());
                for (int atomIndex = 0; atomIndex < sets[setIndex][expressionIndex].size(); atomIndex++) {
                    position[0] = ++writeIndex;
                    libData->MTensor_setInteger(output, position, sets[setIndex][expressionIndex][atomIndex]);
                }
            }
        }
        
        return output;
    }
    
    const auto abortCheckFunction(WolframLibraryData libData) {
        return [libData]() {
            return static_cast<bool>(libData->AbortQ());
        };
    }
    
    int setReplace(WolframLibraryData libData, mint argc, MArgument *argv, MArgument result) {
        if (argc != 3) {
            return LIBRARY_FUNCTION_ERROR;
        }
        
        std::vector<Rule> rules;
        std::vector<Expression> initialExpressions;
        int steps;
        try {
            rules = getRules(libData, MArgument_getMTensor(argv[0]));
            initialExpressions = getSet(libData, MArgument_getMTensor(argv[1]));
            steps = (int)MArgument_getInteger(argv[2]);
        } catch (...) {
            return LIBRARY_FUNCTION_ERROR;
        }
        
        try {
            Set set(rules, initialExpressions, abortCheckFunction(libData));
            set.replace(steps);
            const auto expressions = set.expressions();
            MArgument_setMTensor(result, putSet(expressions, libData));
        } catch (...) {
            return LIBRARY_FUNCTION_ERROR;
        }
        
        return LIBRARY_NO_ERROR;
    }
    
    int setCases(WolframLibraryData libData, mint argc, MArgument *argv, MArgument result) {
        if (argc != 2) {
            return LIBRARY_FUNCTION_ERROR;
        }
        
        std::vector<Expression> pattern;
        std::vector<Expression> initialExpressions;
        try {
            pattern = getSet(libData, MArgument_getMTensor(argv[0]));
            initialExpressions = getSet(libData, MArgument_getMTensor(argv[1]));
        } catch (...) {
            return LIBRARY_FUNCTION_ERROR;
        }
        
        try {
            const Set set({{pattern, {}}}, initialExpressions, abortCheckFunction(libData));
            const auto matches = set.matches();
            std::vector<std::vector<Expression>> matchedSets;
            matchedSets.reserve(matches.size());
            for (const auto& match : matches) {
                matchedSets.push_back(match.second);
            }
            MArgument_setMTensor(result, putSets(matchedSets, libData));
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

EXTERN_C int setCases(WolframLibraryData libData, mint argc, MArgument *argv, MArgument result) {
    return SetReplace::setCases(libData, argc, argv, result);
}
