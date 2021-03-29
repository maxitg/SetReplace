Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["MultisetSubstitutionSystem"]

SetUsage @ "
MultisetSubstitutionSystem[{pattern$1, pattern$2, $$} :> output$] is a rewriting system that replaces subsets with \
elements matching pattern$1, pattern$2, $$ by a list produced by evaluating output$, where pattern$i can be matched in \
any order.
MultisetSubstitutionSystem should be used as the first argument in functions such as GenerateMultihistory.
";

SyntaxInformation[MultisetSubstitutionSystem] = {"ArgumentsPattern" -> {rules_}};

declareMultihistoryGenerator[
  generateMultisetSubstitutionSystem,
  MultisetSubstitutionSystem,
  <|"MaxGeneration" -> {Infinity, "NonNegativeIntegerOrInfinity"},
    "MaxDestroyerEvents" -> {Infinity, "NonNegativeIntegerOrInfinity"},
    "MinEventInputs" -> {0, "NonNegativeIntegerOrInfinity"},
    "MaxEventInputs" -> {Infinity, "NonNegativeIntegerOrInfinity"}|>,
  {"InputCount", "SortedInputExpressions", "UnsortedInputExpressions", "RuleIndex"},
  <|"MaxEvents" -> {Infinity, "NonNegativeIntegerOrInfinity"}|>];

generateMultisetSubstitutionSystem[MultisetSubstitutionSystem[rawRules___],
                                   rawEventSelection_,
                                   rawTokenDeduplication_,
                                   rawEventOrdering_,
                                   rawStoppingCondition_,
                                   rawInit_] := ModuleScope[
  rules = parseRules[rawRules];
  {maxGeneration, maxDestroyerEvents, minEventInputs, maxEventInputs} = Values @ rawEventSelection;
  parseTokenDeduplication[rawTokenDeduplication]; (* Token deduplication is not implemented at the moment *)
  parseEventOrdering[rawEventOrdering];           (* Event ordering is not implemented at the moment *)
  {maxEvents} = Values @ rawStoppingCondition;
  init = parseInit[rawInit];

  expressions = CreateDataStructure["DynamicArray", init];
  eventRuleIndices = CreateDataStructure["DynamicArray", {0}]; (* the first event is the initial event *)
  eventInputs = CreateDataStructure["DynamicArray", {{}}];
  eventOutputs = CreateDataStructure["DynamicArray", {Range @ Length @ init}];
  eventGenerations = CreateDataStructure["DynamicArray", {0}];
  expressionCreatorEvents = CreateDataStructure["DynamicArray", ConstantArray[1, Length @ init]];
  expressionDestroyerEventCounts = CreateDataStructure["DynamicArray", ConstantArray[0, Length @ init]];
  (* destroyerChoices[eventID][expressionID] -> eventID. See libSetReplace/Event.cpp for more information. *)
  destroyerChoices = CreateDataStructure["DynamicArray", {CreateDataStructure["HashTable"]}];
  eventInputsHashSet = CreateDataStructure["HashSet", {{}}];

  (* Data structures are modified in-place. If the system runs out of matches, it throws an exception. *)
  conclusionReason = Catch[
    Do[
      evaluateSingleEvent[rules, maxGeneration, maxDestroyerEvents, minEventInputs, maxEventInputs][
          expressions,
          eventRuleIndices,
          eventInputs,
          eventOutputs,
          eventGenerations,
          expressionCreatorEvents,
          expressionDestroyerEventCounts,
          destroyerChoices,
          eventInputsHashSet],
        Replace[maxEvents, Infinity -> 2^63 - 1]];
    "MaxEvents"
  ,
    $$conclusionReason
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
      "ExpressionDestroyerEventCounts" -> expressionDestroyerEventCounts,
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
    expressionDestroyerEventCounts_,
    destroyerChoices_,
    eventInputsHashSet_] := ModuleScope[
  {ruleIndex, matchedExpressions} = findMatch[rules, maxGeneration, maxDestroyerEvents, minEventInputs, maxEventInputs][
    expressions,
    eventGenerations,
    expressionCreatorEvents,
    expressionDestroyerEventCounts,
    destroyerChoices,
    eventInputsHashSet];
  createEvent[rules, ruleIndex, matchedExpressions][expressions,
                                                    eventRuleIndices,
                                                    eventInputs,
                                                    eventOutputs,
                                                    eventGenerations,
                                                    expressionCreatorEvents,
                                                    expressionDestroyerEventCounts,
                                                    destroyerChoices,
                                                    eventInputsHashSet]
];

(* Matching *)

findMatch[rules_, maxGeneration_, maxDestroyerEvents_, minEventInputs_, maxEventInputs_][
    expressions_,
    eventGenerations_,
    expressionCreatorEvents_,
    expressionDestroyerEventCounts_,
    destroyerChoices_,
    eventInputsHashSet_] := ModuleScope[
  eventInputsCountRange = {minEventInputs, Min[maxEventInputs, expressions["Length"]]};
  subsetCount = With[{n = expressions["Length"], a = eventInputsCountRange[[1]], b = eventInputsCountRange[[2]]},
    (* Sum[Binomial[n, k], {k, a, b}] *)
    Binomial[n, a] * Hypergeometric2F1[1, a - n, 1 + a, -1] -
      Binomial[n, 1 + b] * Hypergeometric2F1[1, 1 + b - n, 2 + b, -1]
  ];

  (* Matching is currently rather inefficient, because it enumerates all subsets no matter what.
     Three things need to happen to make it faster:
     1. We need to do some rule introspection to determine what to search for. For example, for some rules, we can
        automatically determine the number of input expressions, in which case we don't have to enumerate all subsets
        anymore. We can also make an atoms index for some rules (like we do in Matcher of libSetReplace). In this case,
        we can avoid searching entire subtrees if we see some expressions as non-intersecting.
     2. We need to skip expressions from matching based on metadata. For example, we shouldn't continue matching groups
        that are not spacelike or have exceeding generations or destroyer event count.
     3. We need to save partial searching results. They can probably be saved as non-intersecting ranges. Note that they
        have to be ranges because adding new expressions will introduce gaps in the sequence of matches ordered
        according to some (but not all) ordering functions. This new data structure will replace eventInputsHashSet. *)
  ScopeVariable[subsetIndex, possibleMatch, ruleIndex];
  Do[
    If[!eventInputsHashSet["MemberQ", {ruleIndex, possibleMatch}] &&
        AllTrue[expressionDestroyerEventCounts["Part", #] & /@ possibleMatch, # < maxDestroyerEvents &] &&
        AllTrue[possibleMatch, eventGenerations["Part", expressionCreatorEvents["Part", #]] < maxGeneration &] &&
        MatchQ[expressions["Part", #] & /@ possibleMatch, rules[[ruleIndex, 1]]] &&
        spacelikeExpressionsQ[expressionCreatorEvents, destroyerChoices][possibleMatch],
      Return[{ruleIndex, possibleMatch}, Module]
    ];
  ,
    {subsetIndex, 1, Min[subsetCount, 2 ^ 63 - 1]},
    {possibleMatch, Permutations[First @ Subsets[Range @ expressions["Length"], eventInputsCountRange, {subsetIndex}]]},
    {ruleIndex, Range @ Length @ rules}
  ];
  Throw["Terminated", $$conclusionReason];
];

spacelikeExpressionsQ[expressionCreatorEvents_, destroyerChoices_][expressions_] := ModuleScope[
  AllTrue[
    Subsets[expressions, {2}], expressionsSeparation[expressionCreatorEvents, destroyerChoices] @@ # === "Spacelike" &]
];

expressionsSeparation[expressionCreatorEvents_, destroyerChoices_][firstExpression_, secondExpression_] := ModuleScope[
  If[firstExpression === secondExpression, Return["Identical", Module]];

  {firstDestroyerChoices, secondDestroyerChoices} =
    destroyerChoices["Part", expressionCreatorEvents["Part", #]] & /@ {firstExpression, secondExpression};

  If[firstDestroyerChoices["KeyExistsQ", secondExpression] || secondDestroyerChoices["KeyExistsQ", firstExpression],
    Return["Timelike", Module]
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
                                                     expressionDestroyerEventCounts_,
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

  Do[expressionDestroyerEventCounts["Append", 0], Length[outputExpressions]];
  Scan[
    expressionDestroyerEventCounts["SetPart", #, expressionDestroyerEventCounts["Part", #] + 1] &, matchedExpressions];

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

(* Parsing *)

$singleRulePattern = _Rule | _RuleDelayed;
parseRules[rawRules : $singleRulePattern] := {rawRules};
parseRules[rawRules : {$singleRulePattern...}] := rawRules;
declareMessage[General::invalidMultisetRules, "Rules `rules` must be a Rule, a RuleDelayed or a List of them."];
parseRules[rawRules_] := throw[Failure["invalidMultisetRules", <|"rules" -> rawRules|>]];
parseRules[rawRules___] /; !CheckArguments[MultisetSubstitutionSystem[rawRules], 1] := throw[Failure[None, <||>]];

parseTokenDeduplication[None] := None;
declareMessage[General::tokenDeduplicationNotImplemented,
               "Token deduplication is not implemented for Multiset Substitution System."];
parseTokenDeduplication[_] := throw[Failure["tokenDeduplicationNotImplemented", <||>]];

$supportedEventOrdering = {"InputCount", "SortedInputExpressions", "UnsortedInputExpressions", "RuleIndex"};
parseEventOrdering[ordering : $supportedEventOrdering] := ordering;
declareMessage[General::eventOrderingNotImplemented,
               "Only " <> $supportedEventOrdering <> " event ordering is implemented at this time."];
parseEventOrdering[_] := throw[Failure["eventOrderingNotImplemented", <||>]];

parseInit[init_List] := init;
declareMessage[General::multisetInitNotList, "Multiset Substitution System init `init` should be a List."];
parseInit[init_] := throw[Failure["multisetInitNotList", <|"init" -> init|>]];
