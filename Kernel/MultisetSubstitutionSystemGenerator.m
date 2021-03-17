Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

(* TODO: remove GenerateMultihistory from here *)
PackageExport["GenerateMultihistory"]
PackageExport["MultisetSubstitutionSystem"]

SetUsage @ "
MultisetSubstitutionSystem[{pattern$1, pattern$2, $$} :> output$] is a rewriting system that replaces subsets with \
elements matching pattern$1, pattern$2, $$ by a list produced by evaluating output$, where pattern$i can be matched in \
any order.
MultisetSubstitutionSystem should be used as the first argument in functions such as GenerateMultihistory.
";

SyntaxInformation[MultisetSubstitutionSystem] = {"ArgumentsPattern" -> {rules_}};

MultisetSubstitutionSystem /:
    expr : GenerateMultihistory[system : MultisetSubstitutionSystem[rules___], args___] /;
      CheckArguments[system, 1] && CheckArguments[expr, 6] := ModuleScope[
  result = Catch[multisetSubstitutionSystem[rules, args],
                 _ ? FailureQ,
                 message[GenerateMultihistory, #, <|"expr" -> HoldForm[expr]|>] &];
  result /; !FailureQ[result]
];

(* TODO: allow using multihistory objects as inputs *)

multisetSubstitutionSystem[rawRules_,
                           rawEventSelection_,
                           rawTokenDeduplication_,
                           rawEventOrdering_,
                           rawStoppingCondition_,
                           rawInit_] := ModuleScope[
  rules = parseRules[rawRules];
  {maxGeneration, maxDestroyerEvents, minEventInputs, maxEventInputs} = parseEventSelection[rawEventSelection];
  parseTokenDeduplication[rawTokenDeduplication]; (* TODO: implement token deduplication *)
  parseEventOrdering[rawEventOrdering];           (* TODO: implement event ordering *)
  {maxEvents} = parseStoppingCondition[rawStoppingCondition];
  init = parseInit[rawInit];

  (* TODO: implement automatic rule hints, such as inputs count and atoms index *)

  expressions = createDynamicArray[init];
  eventRuleIndices = createDynamicArray[{0}]; (* the first event is the initial event *)
  eventInputs = createDynamicArray[{{}}];
  eventOutputs = createDynamicArray[{Range @ Length @ init}];
  eventGenerations = createDynamicArray[{0}];
  expressionCreatorEvents = createDynamicArray[ConstantArray[1, Length @ init]];
  expressionDestroyerEventsCount = createDynamicArray[ConstantArray[0, Length @ init]];
  (* destroyerChoices[eventID][expressionID] -> eventID. See libSetReplace/Event.cpp for more information. *)
  destroyerChoices = createDynamicArray[{CreateDataStructure["HashTable"]}];
  eventInputsHashSet = CreateDataStructure["HashSet"];
  eventInputsHashSet["Insert", {}];

  (* TODO: eventInputsHashSet should be optimized significantly and be used to skip partial scans. Otherwise, past
           expressions are being continuously scanned every step.
           Essentially, we need to replace eventInputsHashSet with a data structure containing negative matching
           results. *)

  (* TODO: return partial evolution at abort *)

  (* TODO: add max match instantiations to allow the same match to be evaluated multiple times in case the right-hand
           side of the rule is non-deterministic *)

  (* Data structures are modified in-place. If the system runs out of matches, it throws and exception. *)
  conclusionReason = Catch[
    Do[
      evaluateSingleEvent[rules, maxGeneration, maxDestroyerEvents, minEventInputs, maxEventInputs][
          expressions,
          eventRuleIndices,
          eventInputs,
          eventOutputs,
          eventGenerations,
          expressionCreatorEvents,
          expressionDestroyerEventsCount,
          destroyerChoices,
          eventInputsHashSet],
        Replace[maxEvents, Infinity -> 2^63 - 1]];
    "MaxEvents"
  ];

  Multihistory[
    {MultisetSubstitutionSystem, 0},
    <|"Rules" -> rules,
      "ConclusionReason" -> conclusionReason,
      "Expressions" -> expressions,
      "EventRuleIndices" -> eventRuleIndices,
      "EventInputs" -> eventInputs,
      "EventOutputs" -> eventOutputs,
      "EventGenerations" -> eventGenerations,
      "ExpressionCreatorEvents" -> expressionCreatorEvents,
      "ExpressionDestroyerEventsCount" -> expressionDestroyerEventsCount,
      "DestroyerChoices" -> destroyerChoices,
      "EventInputsHashSet" -> eventInputsHashSet|>]
];

(* Evaluation *)

evaluateSingleEvent[
      rules_, maxGeneration_, maxDestroyerEvents_, minEventInputs_, maxEventInputs_][
    expressions_,
    eventRuleIndices_,
    eventInputs_,
    eventOutputs_,
    eventGenerations_,
    expressionCreatorEvents_,
    expressionDestroyerEventsCount_,
    destroyerChoices_,
    eventInputsHashSet_] := ModuleScope[
  {ruleIndex, matchedExpressions} = findMatch[rules, maxGeneration, maxDestroyerEvents, minEventInputs, maxEventInputs][
    expressions,
    eventGenerations,
    expressionCreatorEvents,
    expressionDestroyerEventsCount,
    destroyerChoices,
    eventInputsHashSet];
  createEvent[rules, ruleIndex, matchedExpressions][expressions,
                                                    eventRuleIndices,
                                                    eventInputs,
                                                    eventOutputs,
                                                    eventGenerations,
                                                    expressionCreatorEvents,
                                                    expressionDestroyerEventsCount,
                                                    destroyerChoices,
                                                    eventInputsHashSet]
];

(* Matching *)

findMatch[rules_, maxGeneration_, maxDestroyerEvents_, minEventInputs_, maxEventInputs_][
    expressions_,
    eventGenerations_,
    expressionCreatorEvents_,
    expressionDestroyerEventsCount_,
    destroyerChoices_,
    eventInputsHashSet_] := ModuleScope[
  (* TODO: skip expressions with exceeded destroyer count & generation from the scan *)
  (* TODO: stop enumerating a subset once a pair of elements in it is not spacelike *)
  eventInputsCountRange = {minEventInputs, Min[maxEventInputs, expressions["Length"]]};
  subsetCount = With[{n = expressions["Length"], a = eventInputsCountRange[[1]], b = eventInputsCountRange[[2]]},
    (* Sum[Binomial[n, k], {k, a, b}] *)
    Binomial[n, a] * Hypergeometric2F1[1, a - n, 1 + a, -1] -
      Binomial[n, 1 + b] * Hypergeometric2F1[1, 1 + b - n, 2 + b, -1]
  ];
  ScopeVariable[subsetIndex, possibleMatch, ruleIndex];
  Do[
    If[!eventInputsHashSet["MemberQ", {ruleIndex, possibleMatch}] &&
        AllTrue[expressionDestroyerEventsCount["Part", #] & /@ possibleMatch, # < maxDestroyerEvents &] &&
        AllTrue[possibleMatch, eventGenerations["Part", expressionCreatorEvents["Part", #]] < maxGeneration &] &&
        MatchQ[expressions["Part", #] & /@ possibleMatch, rules[[ruleIndex, 1]]] &&
        spacelikeSeparatedQ[expressionCreatorEvents, destroyerChoices][possibleMatch],
      Return[{ruleIndex, possibleMatch}, Module]
    ];
  ,
    {subsetIndex, 1, Min[subsetCount, 2 ^ 63 - 1]},
    {possibleMatch, Permutations[First @ Subsets[Range @ expressions["Length"], eventInputsCountRange, {subsetIndex}]]},
    {ruleIndex, Range @ Length @ rules}
  ];
  Throw["Terminated"];
];

(* TODO: switch to new names for separations *)

spacelikeSeparatedQ[expressionCreatorEvents_, destroyerChoices_][expressions_] := ModuleScope[
  AllTrue[
    Subsets[expressions, {2}], expressionsSeparation[expressionCreatorEvents, destroyerChoices] @@ # === "Spacelike" &]
];

expressionsSeparation[expressionCreatorEvents_, destroyerChoices_][firstExpression_, secondExpression_] := ModuleScope[
  If[firstExpression === secondExpression, Return["Identical", Module]];

  {firstDestroyerChoices, secondDestroyerChoices} =
    destroyerChoices["Part", expressionCreatorEvents["Part", #]] & /@ {firstExpression, secondExpression};

  If[firstDestroyerChoices["KeyExistsQ", secondExpression] || secondDestroyerChoices["KeyExistsQ", firstExpression],
    Return["Timelike", Module];
  ];

  KeyValueMap[Function[{expression, chosenEvent},
    If[secondDestroyerChoices["KeyExistsQ", expression] && secondDestroyerChoices["Lookup", expression] =!= chosenEvent,
      Return["Branchlike", Module];
    ];
  ], Normal @ firstDestroyerChoices];
  "Spacelike"
];

declareMessage[
  General::ruleOutputError, "Messages encountered while instantiating the output for rule `rule` and inputs `inputs`."];

declareMessage[General::ruleOutputNotList, "Rule `rule` for inputs `inputs` did not generate a List."];

createEvent[rules_, ruleIndex_, matchedExpressions_][expressions_,
                                                     eventRuleIndices_,
                                                     eventInputs_,
                                                     eventOutputs_,
                                                     eventGenerations_,
                                                     expressionCreatorEvents_,
                                                     expressionDestroyerEventsCount_,
                                                     destroyerChoices_,
                                                     eventInputsHashSet_] := ModuleScope[
  ruleInputContents = expressions["Part", #] & /@ matchedExpressions;
  outputExpressions = Check[
    Replace[ruleInputContents, rules[[ruleIndex]]],
    throw[Failure[
      "ruleOutputError",
      <|"rule" -> rules[[ruleIndex]], "inputs" -> ruleInputContents|>]];
  ];
  If[!ListQ[outputExpressions],
    throw[Failure["ruleOutputNotList", <|"rule" -> rules[[ruleIndex]], "inputs" -> ruleInputContents|>]]
  ];
  expressions["Append", #] & /@ outputExpressions;

  eventRuleIndices["Append", ruleIndex];
  eventInputs["Append", matchedExpressions];
  eventInputsHashSet["Insert", {ruleIndex, matchedExpressions}];
  eventOutputs["Append", Range[expressions["Length"] - Length[outputExpressions] + 1, expressions["Length"]]];

  inputExpressionCreatorEvents = expressionCreatorEvents["Part", #] & /@ matchedExpressions;
  inputExpressionGenerations = eventGenerations["Part", #] & /@ inputExpressionCreatorEvents;
  eventGenerations["Append", Max[inputExpressionGenerations, -1] + 1];

  Do[expressionCreatorEvents["Append", eventRuleIndices["Length"]], Length[outputExpressions]];

  Do[expressionDestroyerEventsCount["Append", 0], Length[outputExpressions]];
  Scan[
    expressionDestroyerEventsCount["SetPart", #, expressionDestroyerEventsCount["Part", #] + 1] &, matchedExpressions];

  newDestroyerChoices = CreateDataStructure["HashTable"];
  Scan[(
    newDestroyerChoices["Insert", # -> eventRuleIndices["Length"]];
    inputEvent = expressionCreatorEvents["Part", #];
    KeyValueMap[Function[{expression, chosenEvent},
      newDestroyerChoices["Insert", expression -> chosenEvent];
    ], Normal[destroyerChoices["Part", inputEvent]]];
  ) &, matchedExpressions];
  destroyerChoices["Append", newDestroyerChoices];
];

(* Init *)

createDynamicArray[contents_] := ModuleScope[
  array = CreateDataStructure["DynamicArray"];
  Scan[array["Append", #] &, contents];
  array
];

(* Parsing *)

declareMessage[
  General::nonNegativeIntegerParameter, "`name` should be a non-negative integer or Infinity instead of `value`."];
checkNonNegativeIntegerParameter[name_, value_] :=
  If[MatchQ[value,(_Integer ? (# >= 0 &)) | Infinity],
    value
  ,
    throw[Failure["nonNegativeIntegerParameter", <|"name" -> name, "value" -> value|>]]
  ];

$singleRulePattern = _Rule | _RuleDelayed;
parseRules[rawRules : $singleRulePattern] := {rawRules};
parseRules[rawRules : {$singleRulePattern...}] := rawRules;
declareMessage[General::invalidMultisetRules, "Rules `rules` must be a Rule, a RuleDelayed or a List of them."];
parseRules[rawRules_] := throw[Failure["invalidMultisetRules", <|"rules" -> rawRules|>]];

$eventSelectionDefaults =
  {"MaxGeneration" -> Infinity, "MaxDestroyerEvents" -> Infinity, "MinEventInputs" -> 0, "MaxEventInputs" -> Infinity};
parseEventSelection[rawEventSelection_Association] /; SubsetQ[Keys[$eventSelectionDefaults], Keys[rawEventSelection]] :=
  checkNonNegativeIntegerParameter[#, Lookup[rawEventSelection, ##]] & @@@ $eventSelectionDefaults;
declareMessage[General::invalidEventSelection,
               "Event selection parameters `value` should be an Association with some or all keys from `choices`."];
parseEventSelection[rawEventSelection_] :=
  throw[Failure["invalidEventSelection", <|"value" -> rawEventSelection, "choices" -> Keys[$eventSelectionDefaults]|>]];

parseTokenDeduplication[None] := None;
declareMessage[General::tokenDeduplicationNotImplemented,
               "Token deduplication is not implemented for Multiset Substitution System."];
parseTokenDeduplication[_] := throw[Failure["tokenDeduplicationNotImplemented", <||>]];

$supportedEventOrdering = {"InputCount", "SortedInputExpressions", "UnsortedInputExpressions", "RuleIndex"};
parseEventOrdering[ordering : $supportedEventOrdering] := ordering;
declareMessage[General::eventOrderingNotImplemented,
               "Only " <> $supportedEventOrdering <> " event ordering is implemented at this time."];
parseEventOrdering[_] := throw[Failure["eventOrderingNotImplemented", <||>]];

$stoppingConditionKeys = {"MaxEvents"};
parseStoppingCondition[rawStoppingCondition_Association] /;
    SubsetQ[$stoppingConditionKeys, Keys[rawStoppingCondition]] :=
  checkNonNegativeIntegerParameter[#, Lookup[rawStoppingCondition, #, Infinity]] & /@ $stoppingConditionKeys;
declareMessage[General::invalidStoppingConditions,
               "Stopping conditions `value` should be an Association with some or all keys from `choices`."];
parseStoppingCondition[rawStoppingCondition_] :=
  throw[Failure["invalidStoppingConditions", <|"value" -> rawStoppingCondition, "choices" -> $stoppingConditionKeys|>]];

parseInit[init_List] := init;
declareMessage[General::multisetInitNotList, "Multiset Substitution System init `init` should be a List."];
parseInit[init_] := throw[Failure["multisetInitNotList", <|"init" -> init|>]];

(* Syntax autocompletion *)

With[{eventSelectionKeys = Keys[$eventSelectionDefaults],
      orderingFunctions = $supportedEventOrdering,
      stoppingConditionKeys = $stoppingConditionKeys},
  FE`Evaluate[FEPrivate`AddSpecialArgCompletion[
    "GenerateMultihistory" -> {0, eventSelectionKeys, 0, orderingFunctions, stoppingConditionKeys, 0}]];
];
