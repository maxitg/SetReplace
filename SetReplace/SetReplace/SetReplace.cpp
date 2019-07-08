#include <chrono>
#include <string>

#include "SetReplace.hpp"

#include "Set.hpp"

namespace SetReplace {
    std::vector<AtomsVector> getSet(mint* expressionLengthsData,
                                    mint* atomsData,
                                    const int beginIndex,
                                    const int endIndex) {
        std::vector<AtomsVector> result;
        result.reserve(endIndex - beginIndex);
        for (int expressionPosition = beginIndex; expressionPosition < endIndex; ++expressionPosition) {
            AtomsVector expression;
            expression.reserve(expressionLengthsData[expressionPosition + 1] -
                               expressionLengthsData[expressionPosition]);
            for (int atomPosition = static_cast<int>(expressionLengthsData[expressionPosition]);
                 atomPosition < expressionLengthsData[expressionPosition + 1];
                 ++atomPosition) {
                expression.push_back(static_cast<int>(atomsData[atomPosition]));
            }
            result.emplace_back(expression);
        }
        return result;
    }
    
    std::vector<Rule> getRules(WolframLibraryData libData,
                               MTensor ruleLengths,
                               MTensor ruleExpressionLengths,
                               MTensor ruleAtoms) {
        mint ruleLengthsLength = libData->MTensor_getFlattenedLength(ruleLengths);
        mint* ruleLengthsData = libData->MTensor_getIntegerData(ruleLengths);
        mint* ruleExpressionLengthsData = libData->MTensor_getIntegerData(ruleExpressionLengths);
        mint* ruleAtomsData = libData->MTensor_getIntegerData(ruleAtoms);
        
        std::vector<Rule> rules((ruleLengthsLength - 1) / 2);
        for (int rulePartIdx = 0; rulePartIdx < 2 * rules.size();) {
            rules[rulePartIdx / 2].id = rulePartIdx / 2;
            for (const auto set : {&rules[rulePartIdx / 2].inputs, &rules[rulePartIdx / 2].outputs}) {
                *set = getSet(ruleExpressionLengthsData,
                              ruleAtomsData,
                              static_cast<int>(ruleLengthsData[rulePartIdx]),
                              static_cast<int>(ruleLengthsData[rulePartIdx + 1]));
                ++rulePartIdx;
            }
        }
        
        return rules;
    }
    
    std::vector<AtomsVector> getSet(WolframLibraryData libData,
                                    MTensor expressionLengths,
                                    MTensor setAtoms) {
        mint expressionLengthsLength = libData->MTensor_getFlattenedLength(expressionLengths);
        mint* expressionLengthsData = libData->MTensor_getIntegerData(expressionLengths);
        mint* setAtomsData = libData->MTensor_getIntegerData(setAtoms);
        return getSet(expressionLengthsData,
                      setAtomsData,
                      0,
                      static_cast<int>(expressionLengthsLength) - 1);
    }
    
    enum class StepType { Events, Generations };
    
    struct EvaluationMode {
        StepType stepType;
        bool detectConfluence;
    };
    
    std::pair<EvaluationMode, int> getSteps(WolframLibraryData libData, MTensor stepData) {
        mint length = libData->MTensor_getFlattenedLength(stepData);
        if (length != 3) {
            throw LIBRARY_DIMENSION_ERROR;
        }
        mint* data = libData->MTensor_getIntegerData(stepData);
        
        EvaluationMode mode;
        if (data[0] == 0) {
            mode.stepType = StepType::Events;
        } else if (data[0] == 1) {
            mode.stepType = StepType::Generations;
        } else {
            throw LIBRARY_NUMERICAL_ERROR;
        }
        
        if (data[1] == 0) {
            mode.detectConfluence = false;
        } else if (data[1] == 1) {
            mode.detectConfluence = true;
        } else {
            throw LIBRARY_NUMERICAL_ERROR;
        }
        
        int steps = static_cast<int>(data[2]);
        return {mode, steps};
    }
    
    MTensor putSet(const std::vector<Expression>& expressions,
                   const std::set<Event>& events,
                   const bool isConfluent,
                   WolframLibraryData libData) {
        std::vector<int> result;
        
        std::vector<const Event*> eventsVector;
        eventsVector.resize(events.size());
        for (const auto& event : events) {
            eventsVector[event.id] = &event;
        }
        
        result.push_back(static_cast<int>(expressions.size()));
        result.push_back(static_cast<int>(eventsVector.size()));
        result.push_back(isConfluent);
        
        constexpr int expressionMetadataSize = 6;
        constexpr int eventMetadataSize = 5;
        
        int recordPosition = static_cast<int>(expressions.size() * expressionMetadataSize +
                                              eventsVector.size() * eventMetadataSize) + 3;
        for (const auto& expression : expressions) {
            result.push_back(static_cast<int>(recordPosition));
            recordPosition += expression.atoms.size();
            result.push_back(static_cast<int>(recordPosition));
            result.push_back(expression.generation);
            if (expression.precedingEvent == events.end()) {
                result.push_back(-1);
            } else {
                result.push_back(expression.precedingEvent->id);
            }
            result.push_back(static_cast<int>(recordPosition));
            recordPosition += expression.succedingEvents.size();
            result.push_back(static_cast<int>(recordPosition));
        }
        for (const auto& event : eventsVector) {
            result.push_back(event->rule->id);
            result.push_back(event->actualized());
            result.push_back(recordPosition);
            recordPosition += event->rule->inputs.size();
            result.push_back(recordPosition);
            if (event->actualized()) {
                recordPosition += event->rule->outputs.size();
            }
            result.push_back(recordPosition);
        }
        for (const auto& expression : expressions) {
            for (const auto& atom : expression.atoms) {
                result.push_back(atom);
            }
            for (const auto& event : expression.succedingEvents) {
                result.push_back(event->id);
            }
        }
        for (const auto& event : eventsVector) {
            for (const auto& expression : event->inputs) {
                result.push_back(expression);
            }
            if (event->actualized()) {
                for (const auto& expression : *event->outputs) {
                    result.push_back(expression);
                }
            }
        }
        
        MTensor output;
        mint dimensions[1] = {static_cast<mint>(result.size())};
        libData->MTensor_new(MType_Integer, 1, dimensions, &output);
        for (int i = 0; i < result.size(); ++i) {
            dimensions[0] = i + 1;
            libData->MTensor_setInteger(output, dimensions, result[i]);
        }
        return output;
    }
    
    int setReplace(WolframLibraryData libData, mint argc, MArgument *argv, MArgument result) {
        if (argc != 6) {
            return LIBRARY_FUNCTION_ERROR;
        }
        
        std::vector<Rule> rules;
        std::vector<AtomsVector> initialExpressions;
        EvaluationMode mode;
        int count;
        try {
            rules = getRules(libData,
                             MArgument_getMTensor(argv[0]),
                             MArgument_getMTensor(argv[1]),
                             MArgument_getMTensor(argv[2]));
            initialExpressions = getSet(libData,
                                        MArgument_getMTensor(argv[3]),
                                        MArgument_getMTensor(argv[4]));
            const std::pair<EvaluationMode, int> modeCount = getSteps(libData,
                                                                      MArgument_getMTensor(argv[5]));
            mode = modeCount.first;
            count = modeCount.second;
        } catch (...) {
            return LIBRARY_FUNCTION_ERROR;
        }
        
        const auto shouldAbort = [&libData]() {
            return static_cast<bool>(libData->AbortQ());
        };
        try {
            Set set(rules, initialExpressions, mode.detectConfluence, shouldAbort);
            if (mode.stepType == StepType::Events) {
                set.createEvents(count);
            } else if (mode.stepType == StepType::Generations) {
                set.replaceUptoGeneration(count);
            }
            
            const auto& expressions = set.expressions();
            const auto& events = set.events();
            const bool isConfluent = set.isConfluent();
            
            MArgument_setMTensor(result, putSet(expressions, events, isConfluent, libData));
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
