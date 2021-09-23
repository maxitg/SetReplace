Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["WolframModel"]
PackageExport["$WolframModelProperties"]

(* Generates evolutions of Wolfram Model systems. *)

PackageScope["wolframModelRulesSpecQ"]
PackageScope["fromRulesSpec"]

SetUsage @ "
WolframModel[rules$, init$, generationCount$] generates an object representing the evolution of the Wolfram model \
with the specified rules$ from the initial condition init$ for generationCount$ generations.
WolframModel[<|'PatternRules' -> rules$|>, init$, generationCount$] generates an evolution of the set substitution \
system with specified rules$.
WolframModel[rules$, init$, <|'property$1' -> constraint$1, 'property$2' -> constraint$2, $$|>] stops the evolution \
once any of the constraints are reached for specified properties.
WolframModel[rules$, init$, stepSpec$, property$] gives the specified property$ of the evolution.
WolframModel[rules$] represents the operator form for a Wolfram model.
";

SetUsage @ "
$WolframModelProperties gives the list of available properties of WolframModel.
";

Options[WolframModel] := Join[{
  "VertexNamingFunction" -> Automatic,
  "IncludePartialGenerations" -> True,
  "IncludeBoundaryEvents" -> None},
  Options[setSubstitutionSystem]];

SyntaxInformation[WolframModel] = {
  "ArgumentsPattern" -> {rules_, init_., stepSpec_., property_., OptionsPattern[]},
  "OptionNames" -> Options[WolframModel][[All, 1]]};

With[{properties = $newParameterlessProperties,
      stepSpecKeys = Values[$stepSpecKeys]},
  FE`Evaluate[FEPrivate`AddSpecialArgCompletion["WolframModel" -> {{"PatternRules"}, 0, stepSpecKeys, properties}]]];

(* Arguments parsing *)

(* Rules *)

fromRulesSpec[rulesSpec : _List | _Rule] := ToPatternRules[rulesSpec];

fromRulesSpec[<|"PatternRules" -> rules_|>] := rules;

(* Init *)

fromInitSpec[rulesSpec_, initSpec_List] := initSpec;

fromInitSpec[rulesSpec_Rule, Automatic] := fromInitSpec[{rulesSpec}, Automatic];

fromInitSpec[rulesSpec_List, Automatic] := Catenate[
  If[#2 === 0, ConstantArray[1, #1], ConstantArray[1, {##}]] & @@@
    Reverse /@ Sort[Normal[Merge[Counts /@ Map[Length, If[ListQ[#], #, {#}] & /@ rulesSpec[[All, 1]], {2}], Max]]]];

declareMessage[
  WolframModel::noPatternAutomatic, "Automatic initial state is not supported for pattern rules `rulesSpec`"];

fromInitSpec[rulesSpec_Association, Automatic] := throw[Failure["noPatternAutomatic", <|"rulesSpec" -> rulesSpec|>]];

(* Steps *)

fromStepsSpec[init_, generations : (_Integer | Infinity), timeConstraint_, eventSelectionFunction_] :=
  fromStepsSpec[init, <|$stepSpecKeys[$maxGenerationsLocal] -> generations|>, timeConstraint, eventSelectionFunction];

fromStepsSpec[_, spec_Association, _, _] := With[{
    stepSpecInverse = Association[Reverse /@ Normal[$stepSpecKeys]]}, {
      KeyMap[# /. stepSpecInverse &, spec],
      Inherited (* termination reason *),
      {} (* options override *),
      $$nonEvolutionOutputAbort}
];

fromStepsSpec[init_, Automatic, timeConstraint_, eventSelectionFunction_] :=
  fromStepsSpec[init, {Automatic, 1}, timeConstraint, eventSelectionFunction];

$automaticMaxEvents = 5000;
$automaticMaxFinalExpressions = 200;
$automaticStepsTimeConstraint = 5.0;

fromStepsSpec[init_, {Automatic, factor_}, timeConstraint_, eventSelectionFunction_] := {
  <|$maxEvents -> Round[factor $automaticMaxEvents],
    $maxFinalExpressions -> If[multiwayEventSelectionFunctionQ[eventSelectionFunction],
      Infinity
    ,
      Max[Round[factor $automaticMaxFinalExpressions], Length[init]]
    ]|>,
  Automatic, (* termination reason *)
  {TimeConstraint -> Min[timeConstraint, Replace[factor, 0 | 0. -> 1] $automaticStepsTimeConstraint],
    "IncludePartialGenerations" -> False},
  $$noAbort
};

(* Vertex renaming *)

$vertexNamingFunctions = {Automatic, None, All};

renameNodes[evolution_, _, None] := evolution;

renameNodesExceptExisting[
    evolution_, patternRulesQ_, existing_List] := ModuleScope[
  {evolutionAtoms, existingAtoms} = (DeleteDuplicates @ Catenate[If[ListQ[#], #, {#}] & /@ #]) & /@
    {evolution[[1]][$atomLists], existing};
  atomsToName = DeleteCases[evolutionAtoms, Alternatives @@ existingAtoms];
  newNames = Take[
    Complement[Range[Length[atomsToName] + Length[existingAtoms]], existingAtoms],
    Length[atomsToName]];
  WolframModelEvolutionObject[Join[
    evolution[[1]],
    <|$atomLists ->
      (evolution[[1]][$atomLists] /.
        Dispatch @ Thread[atomsToName -> newNames])|>]]
];

renameNodes[evolution_, patternRulesQ_, All] :=
  renameNodesExceptExisting[evolution, patternRulesQ, {}];

renameNodes[evolution_, True, Automatic] := renameNodes[evolution, True, None];

renameNodes[evolution_, False, Automatic] :=
  renameNodesExceptExisting[evolution, False, evolution[0]];

declareMessage[
  WolframModel::unknownVertexNamingFunction, "VertexNamingFunction `namingFunction` should be one of `choices`."];

renameNodes[evolution_, _, func_] :=
  throw[Failure["unknownVertexNamingFunction", <|"namingFunction" -> func, "choices" -> $vertexNamingFunctions|>]];

(* Overriding termination reason (i.e., Automatic steps) *)

overrideTerminationReason[Inherited][evolution_] := evolution;

overrideTerminationReason[newReason_][evolution_] :=
  WolframModelEvolutionObject[Join[First[evolution], <|$terminationReason -> newReason|>]];

(* Normal form *)

Options[wolframModel] = Options[WolframModel];

expr : WolframModel[args___] /; Quiet[!CheckArguments[expr, 1]] && CheckArguments[expr, {1, 4}] := ModuleScope[
  result = Catch[
    wolframModel[args], _ ? FailureQ, message[WolframModel, #, <|"expr" -> HoldForm[expr]|>] &];
  result /; result === $Aborted || !FailureQ[result]
];

expr : (operator : WolframModel[args1___])[args2___] /; Quiet[CheckArguments[operator, 1]] := ModuleScope[
  result = Catch[
    wolframModelOperator[args1][args2], _ ? FailureQ, message[WolframModel, #, <|"expr" -> HoldForm[expr]|>] &];
  result /; result === $Aborted || !FailureQ[result]
];

expr : wolframModel[rulesSpec_ ? wolframModelRulesSpecQ,
                    initSpec_ ? wolframModelInitSpecQ,
                    stepsSpec : _ ? wolframModelStepsSpecQ : 1,
                    property : _ ? wolframModelPropertyQ : "EvolutionObject",
                    o : OptionsPattern[]] := ModuleScope[
  patternRules = fromRulesSpec[rulesSpec];
  initialSet = fromInitSpec[rulesSpec, initSpec];
  {steps, terminationReasonOverride, optionsOverride, abortBehavior} =
    fromStepsSpec[initialSet, stepsSpec, OptionValue[TimeConstraint], OptionValue["EventSelectionFunction"]];
  overridenOptionValue = OptionValue[WolframModel, Join[optionsOverride, {o}], #] &;
  evolution = If[initialSet =!= $Failed,
    Check[
      setSubstitutionSystem[
        patternRules,
        initialSet,
        steps,
        WolframModel,
        Switch[abortBehavior,
          $$nonEvolutionOutputAbort, property === "EvolutionObject",
          $$noAbort, True,
          _, False],
        Method -> overridenOptionValue[Method],
        TimeConstraint -> overridenOptionValue[TimeConstraint],
        "EventOrderingFunction" -> overridenOptionValue["EventOrderingFunction"],
        "EventSelectionFunction" -> overridenOptionValue["EventSelectionFunction"],
        "EventDeduplication" -> overridenOptionValue["EventDeduplication"]],
      $Failed]
  ,
    $Failed
  ];
  If[evolution === $Aborted, Return[$Aborted]];
  modifiedEvolution = If[evolution =!= $Failed,
    Check[
      overrideTerminationReason[terminationReasonOverride] @ renameNodes[
        evolution,
        AssociationQ[rulesSpec],
        overridenOptionValue["VertexNamingFunction"]],
      $Failed]
  ,
    $Failed
  ];
  propertyEvaluateWithOptions = propertyEvaluate[
    overridenOptionValue["IncludePartialGenerations"],
    overridenOptionValue["IncludeBoundaryEvents"]][
    modifiedEvolution,
    #] &;
  If[modifiedEvolution =!= $Failed,
    If[ListQ[property],
      propertyEvaluateWithOptions /@ property
    ,
      propertyEvaluateWithOptions @ property
    ] /.
      HoldPattern[WolframModelEvolutionObject[data_Association]] :>
        WolframModelEvolutionObject[Join[data, <|$rules -> rulesSpec|>]]
  ,
    $Failed
  ]
];

(* Operator form *)

wolframModelOperator[rulesSpec_ ? wolframModelRulesSpecQ, o : OptionsPattern[]][initSpec_ ? wolframModelInitSpecQ] :=
  wolframModel[rulesSpec, initSpec, 1, "FinalState", o];

(* $WolframModelProperties *)

$WolframModelProperties =
  Complement[$propertiesParameterless, {"Properties", "Rules"}];

(* Argument Checks *)

(* Rules *)

wolframModelRulesSpecQ[rulesSpec_ ? anonymousRulesQ] := True;

wolframModelRulesSpecQ[<|"PatternRules" -> rules_ ? setReplaceRulesQ|>] := True;

wolframModelRulesSpecQ[_] := False;

(* Init *)

wolframModelInitSpecQ[init_ ? ListQ] := True;

wolframModelInitSpecQ[Automatic] := True;

wolframModelInitSpecQ[_] := False;

(* Steps *)

wolframModelStepsSpecQ[stepsSpec_ ? stepCountQ] := True;

wolframModelStepsSpecQ[stepsSpec_Association] /;
  SubsetQ[Values[$stepSpecKeys], Keys[stepsSpec]] &&
  AllTrue[First[fromStepsSpec[{}, stepsSpec, Infinity, "GlobalSpacelike"]], stepCountQ] := True;

wolframModelStepsSpecQ[Automatic] := True;

wolframModelStepsSpecQ[{Automatic, _ ? (# >= 0 &)}] := True;

wolframModelStepsSpecQ[_] := False;

(* Property *)

wolframModelPropertyQ[property_String] /;
  MemberQ[$WolframModelProperties, property] := True;

wolframModelPropertyQ[{property___String}] /;
  And @@ (wolframModelPropertyQ /@ {property}) := True;

wolframModelPropertyQ[_] := False;

(* Incorrect arguments messages *)

(* Arguments count *)

expr : (operator : wolframModelOperator[args1___])[init_, args2__] /; Quiet[CheckArguments[operator, 1]] := ModuleScope[
  Message[WolframModel::argx, Defer[WolframModel[args1][init, args2]], Length[{init, args2}]];
  throw[Failure[None, <||>]]
];

(* Init *)

declareMessage[WolframModel::invalidState, "The initial state specification `init` should be a List."];

wolframModel[rulesSpec_ ? wolframModelRulesSpecQ,
             initSpec : Except[OptionsPattern[]] ? (Not[wolframModelInitSpecQ[#]] &),
             args___] := throw[Failure["invalidState", <|"init" -> initSpec|>]];

wolframModelOperator[rulesSpec_ ? wolframModelRulesSpecQ, o : OptionsPattern[]][
    initSpec_ ? (Not @* wolframModelInitSpecQ)] :=
  throw[Failure["invalidState", <|"init" -> initSpec|>]];

(* Rules *)

declareMessage[
  General::invalidWolframModelRules,
  "The rule specification `rules` should be either a Rule, a List of rules, or <|\"PatternRules\" -> rules|>, " <>
  "where rules is either a Rule, RuleDelayed, or a List of them."];

expr : wolframModel[rulesSpec_ ? (Not @* wolframModelRulesSpecQ), args___] :=
  throw[Failure["invalidWolframModelRules", <|"rules" -> rulesSpec|>]];

expr : wolframModelOperator[rulesSpec_ ? (Not @* wolframModelRulesSpecQ), args___] :=
  throw[Failure["invalidWolframModelRules", <|"rules" -> rulesSpec|>]];

(* Steps *)

declareMessage[
  WolframModel::invalidSteps,
  "The steps specification `stepSpec` should be an Integer, Infinity, Automatic, or an association with one or more " <>
  "keys from `choices`."];

expr : wolframModel[rulesSpec_ ? wolframModelRulesSpecQ,
                    initSpec_ ? wolframModelInitSpecQ,
                    stepsSpec : Except[OptionsPattern[]] ? (Not[wolframModelStepsSpecQ[#]] &),
                    args___] :=
  throw[Failure["invalidSteps", <|"stepSpec" -> stepsSpec, "choices" -> Values[$stepSpecKeys]|>]];

(* Property *)

declareMessage[WolframModel::invalidProperty,
               "Property specification `property` should be one of $WolframModelProperties or a List of them."];

expr : wolframModel[rulesSpec_ ? wolframModelRulesSpecQ,
                    initSpec_ ? wolframModelInitSpecQ,
                    stepsSpec_ ? wolframModelStepsSpecQ,
                    property : Except[OptionsPattern[]] ? (Not[wolframModelPropertyQ[#]] &),
                    o : OptionsPattern[]] := throw[Failure["invalidProperty", <|"property" -> property|>]];
