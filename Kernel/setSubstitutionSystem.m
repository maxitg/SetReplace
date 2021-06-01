Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["$SetReplaceMethods"]

(* This is a main function of the package. This function calls either C++ or Wolfram Language implementation, and can
   produce a WolframModelEvolutionObject that contains information about evolution of the network step-by-step.
   All SetReplace* and WolframModel functions use argument checks and implementation done here. *)

PackageScope["setReplaceRulesQ"]
PackageScope["stepCountQ"]
PackageScope["multiwayEventSelectionFunctionQ"]
PackageScope["setSubstitutionSystem"]

PackageScope["$stepSpecKeys"]
PackageScope["$maxEvents"]
PackageScope["$maxGenerationsLocal"]
PackageScope["$maxDestroyerEvents"]
PackageScope["$maxFinalVertices"]
PackageScope["$maxFinalVertexDegree"]
PackageScope["$maxFinalExpressions"]
PackageScope["$fixedPoint"]
PackageScope["$timeConstraint"]

PackageScope["$globalSpacelike"]
PackageScope["$spacelike"]

PackageScope["$sameInputSetIsomorphicOutputs"]

PackageScope["simpleRuleQ"]

(* Termination reason values *)

$maxEvents = "MaxEvents";
$maxGenerationsLocal = "MaxGenerationsLocal";
$maxFinalVertices = "MaxFinalVertices";
$maxFinalVertexDegree = "MaxFinalVertexDegree";
$maxFinalExpressions = "MaxFinalExpressions";
$fixedPoint = "FixedPoint";
$timeConstraint = "TimeConstraint";

SetUsage @ "
$SetReplaceMethods gives the list of available values for Method option of SetReplace and related functions.
";

(* Argument Checks *)

(* Argument checks here produce messages for the caller which is specified as an argument. That is because
   setSubstitutionSystem is used by all SetReplace* and WolframModel functions, which need to produce their own
   messages.*)

(* Set is a list *)

General::setNotList =
  "The set specification `1` should be a List.";

setSubstitutionSystem[
    rules_, set_, stepSpec_, caller_, returnOnAbortQ_, o : OptionsPattern[]] := 0 /;
  !ListQ[set] &&
  Message[caller::setNotList, set];

(* Rules are valid *)

setReplaceRulesQ[rules_] :=
  MatchQ[rules, {(_Rule | _RuleDelayed)..} | _Rule | _RuleDelayed];

General::invalidRules =
  "The rule specification `1` should be either a Rule, RuleDelayed, or " ~~
  "a List of them.";

setSubstitutionSystem[
    rules_, set_, stepSpec_, caller_, returnOnAbortQ_, o : OptionsPattern[]] := 0 /;
  !setReplaceRulesQ[rules] &&
  Message[caller::invalidRules, rules];

(* Step count is valid *)

$stepSpecKeys = <|
  $maxEvents -> "MaxEvents",
  (* local means the evolution will keep running until no further matches can be made exceeding the max generation.
    This might result in a different evolution order. *)
  $maxGenerationsLocal -> "MaxGenerations",
  $maxDestroyerEvents -> "MaxDestroyerEvents",
  (* these are any level-2 expressions in the set, not just atoms. *)
  $maxFinalVertices -> "MaxVertices",
  $maxFinalVertexDegree -> "MaxVertexDegree",
  $maxFinalExpressions -> "MaxEdges"|>;

$stepSpecNamesInErrorMessage = <|
  $maxEvents -> "number of replacements",
  $maxGenerationsLocal -> "number of generations",
  $maxDestroyerEvents -> "number of destroyer events",
  $maxFinalVertices -> "number of vertices",
  $maxFinalVertexDegree -> "vertex degree",
  $maxFinalExpressions -> "number of edges"|>;

stepCountQ[n_] := IntegerQ[n] && n >= 0 || n == \[Infinity];

multiwayEventSelectionFunctionQ[None | $spacelike] = True;

multiwayEventSelectionFunctionQ[_] = False;

General::nonIntegerIterations =
  "The `1` `2` should be a non-negative integer or infinity.";

General::nonListExpressions =
  "Encountered expression `1` which is not a list, even though a constraint on vertices is specified.";

General::tooSmallStepLimit =
  "The maximum `1` `2` is smaller than that in initial condition `3`.";

General::multiwayFinalStepLimit =
  "The limit for the `2` is not supported for multiway systems.";

stepSpecQ[caller_, set_, spec_, eventSelectionFunction_] :=
  (* Check everything is a non-negative integer. *)
  And @@ KeyValueMap[
      If[stepCountQ[#2],
        True
      ,
        Message[caller::nonIntegerIterations, $stepSpecNamesInErrorMessage[#1], #2];
        False
      ] &,
      spec] &&
  (* Check vertices make sense if vertex constraints are specified. *)
  If[(MissingQ[spec[$maxFinalVertices]] && MissingQ[spec[$maxFinalVertexDegree]]) || AllTrue[set, ListQ],
    True
  ,
    Message[caller::nonListExpressions, SelectFirst[set, Not @* ListQ]];
    False
  ] &&
  (* Check initial condition does not violate the limits already. *)
  And @@ (
      If[Lookup[spec, #1, Infinity] >= #2,
        True
      ,
        Message[caller::tooSmallStepLimit, $stepSpecNamesInErrorMessage[#1], spec[#1], #2];
        False
      ] & @@@ {
    {$maxFinalVertices, If[MissingQ[spec[$maxFinalVertices]], 0, Length[Union[Catenate[set]]]]},
    {$maxFinalVertexDegree, If[MissingQ[spec[$maxFinalVertexDegree]], 0, Max[Counts[Catenate[Union /@ set]]]]},
    {$maxFinalExpressions, Length[set]}}) &&
  (* Check final step constraints are not requested for a multiway system *)
  (!multiwayEventSelectionFunctionQ[eventSelectionFunction] ||
    AllTrue[
      {$maxFinalVertices, $maxFinalExpressions, $maxFinalVertexDegree},
      If[spec[#] === Infinity || MissingQ[spec[#]],
        True
      ,
        Message[caller::multiwayFinalStepLimit, $stepSpecNamesInErrorMessage[#]];
        False
      ] &]);

(* Method is valid *)

$cppMethod = "LowLevel";
$wlMethod = "Symbolic";

$SetReplaceMethods = {Automatic, $cppMethod, $wlMethod};

General::invalidMethod =
  "Method should be one of " <> listToSentence[$SetReplaceMethods] <> ".";

setSubstitutionSystem[
    rules_, set_, stepSpec_, caller_, returnOnAbortQ_, o : OptionsPattern[]] := 0 /;
  !MatchQ[OptionValue[Method], Alternatives @@ $SetReplaceMethods] &&
  Message[caller::invalidMethod];

(* TimeConstraint is valid *)

setSubstitutionSystem[
    rules_, set_, stepSpec_, caller_, returnOnAbortQ_, o : OptionsPattern[]] := 0 /;
  !MatchQ[OptionValue[TimeConstraint], _ ? (# > 0 &)] &&
  Message[caller::timc, OptionValue[TimeConstraint]];

(* EventOrderingFunction is valid *)

$eventOrderingFunctions = {
  "OldestEdge",
  "LeastOldEdge",
  "LeastRecentEdge",
  "NewestEdge",
  "RuleOrdering",
  "ReverseRuleOrdering",
  "RuleIndex",
  "ReverseRuleIndex",
  "Random",
  "Any"
};

(* This applies only to C++ due to #158, WL code uses similar order but does not apply "LeastRecentEdge" correctly. *)
$eventOrderingFunctionDefault = {"LeastRecentEdge", "RuleOrdering", "RuleIndex"};

parseEventOrderingFunction[caller_, Automatic] := $eventOrderingFunctionDefault;

parseEventOrderingFunction[caller_, s_String] := parseEventOrderingFunction[caller, {s}];

parseEventOrderingFunction[caller_, func : {(Alternatives @@ $eventOrderingFunctions)...}] /;
    !FreeQ[func, "Random"] :=
  parseEventOrderingFunction[caller, func[[1 ;; FirstPosition[func, "Random"][[1]] - 1]]];

parseEventOrderingFunction[caller_, func : {(Alternatives @@ $eventOrderingFunctions)...}] /;
    !FreeQ[func, "Any"] && FirstPosition[func, "Any"][[1]] != Length[func] :=
    parseEventOrderingFunction[caller, func[[1 ;; FirstPosition[func, "Any"][[1]]]]];

parseEventOrderingFunction[caller_, func : {(Alternatives @@ $eventOrderingFunctions)...}] /;
    FreeQ[func, "Random"] :=
  func;

General::invalidEventOrdering = "EventOrderingFunction `1` should be one of `2`, or a list of them by priority.";

parseEventOrderingFunction[caller_, func_] := (
  Message[caller::invalidEventOrdering, func, $eventOrderingFunctions];
  $Failed
);

(* String-valued parameter is valid *)

$eventSelectionFunctions = {
  "GlobalSpacelike",
  None,
  "MultiwaySpacelike"
};

$eventDeduplications = {
  None,
  "SameInputSetIsomorphicOutputs"
};

parseParameterValue[caller_, name_, value_, list_] /; MemberQ[list, value] := value;

General::invalidParameterValue = "`1` `2` should be one of `3`.";

parseParameterValue[caller_, name_, value_, list_] := (
  Message[caller::invalidParameterValue, name, value, list];
  $Failed
);

(* Checks if a rule that can be understood by C++ code. Will be generalized in the future until simply returns True. *)

SetAttributes[inertCondition, HoldAll];

simpleRuleQ[rule_] := inertConditionSimpleRuleQ[rule /. Condition -> inertCondition];

(* Left-hand side of the rule must refer either to specific atoms, *)
atomPatternQ[pattern_ ? AtomQ] := True;

(* or to patterns referring to one atom at-a-time. *)
atomPatternQ[pattern_Pattern ? (AtomQ[#[[1]]] && #[[2]] === Blank[] &)] := True;

atomPatternQ[_] := False;

inertConditionSimpleRuleQ[
    (* empty expressions/subsets are not supported in the input, conditions are not supported *)
    inertCondition[left : {{__ ? atomPatternQ}..}, True]
    :> right : Module[{___ ? AtomQ} (* newly created atoms *), {{___ ? AtomQ}...}]] := Module[{p},
  ConnectedGraphQ @ Graph[
    Flatten[Apply[
        UndirectedEdge,
        (Partition[#, 2, 1] & /@ (Append[#, #[[1]]] &) /@ left),
        {2}]]
      /. x_Pattern :> p[x[[1]]]]
];

inertConditionSimpleRuleQ[___] := False;

(* This function accepts both the number of generations and the number of steps as an input, and runs until the first
   of the two is reached. it also takes a caller function as an argument, which is used for message generation. *)

Options[setSubstitutionSystem] = {
  Method -> Automatic,
  TimeConstraint -> Infinity,
  "EventOrderingFunction" -> Automatic,
  "EventSelectionFunction" -> "GlobalSpacelike",
  "EventDeduplication" -> None
};

(* It automatically switches between WL and C++ implementations *)

General::symbOrdering = "Custom event ordering, selection and deduplication are not supported for symbolic method.";

General::noLowLevel =
  "Low level implementation was not compiled for your system type.";

General::lowLevelNotImplemented =
  "Low level implementation is only available for local rules, " <>
  "and only for sets of lists (hypergraphs).";

General::symbNotImplemented =
  "Custom event ordering, selection and deduplication are only available for local rules, " <>
  "and only for sets of lists (hypergraphs).";

setSubstitutionSystem[
      rules_ ? setReplaceRulesQ,
      set_List,
      stepSpec_,
      caller_,
      returnOnAbortQ_,
      o : OptionsPattern[]] /;
        stepSpecQ[
          caller, set, stepSpec, OptionValue[setSubstitutionSystem, {o}, "EventSelectionFunction"]] := ModuleScope[
  method = OptionValue[Method];
  timeConstraint = OptionValue[TimeConstraint];
  eventOrdering = OptionValue["EventOrderingFunction"];
  eventOrderingFunction = parseEventOrderingFunction[caller, eventOrdering];
  eventSelectionFunction = parseParameterValue[
    caller, "EventSelectionFunction", OptionValue["EventSelectionFunction"], $eventSelectionFunctions];
  eventDeduplication = parseParameterValue[
    caller, "EventDeduplication", OptionValue["EventDeduplication"], $eventDeduplications];
  symbolicEvaluationSupportedQ = OptionValue["EventOrderingFunction"] === Automatic &&
                                 OptionValue["EventSelectionFunction"] === "GlobalSpacelike" &&
                                 OptionValue["EventDeduplication"] === None;
  failedQ = False;
  If[eventOrderingFunction === $Failed || eventSelectionFunction === $Failed || eventDeduplication === $Failed,
    Return[$Failed]
  ];
  If[!symbolicEvaluationSupportedQ && method === "Symbolic",
    Message[caller::symbOrdering];
    Return[$Failed]
  ];
  If[(timeConstraint > 0) =!= True, Return[$Failed]];
  canonicalRules = toCanonicalRules[rules];
  If[MatchQ[method, Automatic | $cppMethod]
      && MatchQ[set, {{___}...}]
      && MatchQ[canonicalRules, {___ ? simpleRuleQ}],
    If[$libSetReplaceAvailable,
      Return[
        setSubstitutionSystem$cpp[
          rules, set, stepSpec, returnOnAbortQ, timeConstraint, eventOrderingFunction,
          eventSelectionFunction,
          eventDeduplication]]
    ]
  ];
  If[MatchQ[method, $cppMethod],
    failedQ = True;
    If[!$libSetReplaceAvailable,
      Message[caller::noLowLevel]
    ,
      Message[caller::lowLevelNotImplemented]
    ]
  ];
  If[failedQ || !MatchQ[OptionValue[Method], Alternatives @@ $SetReplaceMethods],
    $Failed
  ,
    If[!symbolicEvaluationSupportedQ,
      Message[caller::symbNotImplemented];
      Return[$Failed]
    ];
    setSubstitutionSystem$wl[caller, rules, set, stepSpec, returnOnAbortQ, timeConstraint]
  ]
];
