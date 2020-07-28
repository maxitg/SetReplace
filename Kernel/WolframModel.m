(* ::Package:: *)

(* ::Title:: *)
(*WolframModel*)


(* ::Text:: *)
(*Generates evolutions of Wolfram Model systems.*)


Package["SetReplace`"]


PackageExport["WolframModel"]
PackageExport["$WolframModelProperties"]


PackageScope["wolframModelRulesSpecQ"]
PackageScope["wolframModelPropertyCheck"]
PackageScope["wolframModelPropertyQ"]
PackageScope["wolframModelPropertiesQ"]
PackageScope["$wolframObjectOptions"]
PackageScope["propertyCheck"]
PackageScope["optionsCheck"]


(* ::Section:: *)
(*Documentation*)


WolframModel::usage = usageString[
  "WolframModel[`rules`, `init`, `t`] generates an object representing the ",
  "evolution of the Wolfram Model with the specified rules from the initial ",
  "condition `init` for `t` generations.",
  "\n",
  "WolframModel[`rules`, `init`, `t`, `prop`] gives the property `prop` ",
  "of the evolution.",
  "\n",
  "WolframModel[`rules`] represents the operator form for a Wolfram Model."];


$WolframModelProperties::usage = usageString[
  "$WolframModelProperties gives the list of available properties of WolframModel."];


(* ::Section:: *)
(*SyntaxInformation*)


SyntaxInformation[WolframModel] =
  {"ArgumentsPattern" -> {_, _ ..., OptionsPattern[]}};


(* ::Section:: *)
(*Options*)


Options[WolframModel] := Join[{
  "VertexNamingFunction" -> Automatic,
  "IncludePartialGenerations" -> True,
  "IncludeBoundaryEvents" -> None},
  Options[setSubstitutionSystem]];


(* ::Section:: *)
(*Implementation*)


(* ::Subsection:: *)
(*Arguments parsing*)


(* ::Subsubsection:: *)
(*Rules*)


fromRulesSpec[rulesSpec : _List | _Rule] := ToPatternRules[rulesSpec]


fromRulesSpec[<|"PatternRules" -> rules_|>] := rules


(* ::Subsubsection:: *)
(*Init*)


fromInitSpec[rulesSpec_, initSpec_List] := initSpec


fromInitSpec[rulesSpec_Rule, Automatic] := fromInitSpec[{rulesSpec}, Automatic]


fromInitSpec[rulesSpec_List, Automatic] := Catenate[
  If[#2 === 0, ConstantArray[1, #1], ConstantArray[1, {##}]] & @@@
    Reverse /@ Sort[Normal[Merge[Counts /@ Map[Length, If[ListQ[#], #, {#}] & /@ rulesSpec[[All, 1]], {2}], Max]]]]


WolframModel::noPatternAutomatic = "Automatic initial state is not supported for pattern rules ``";


fromInitSpec[rulesSpec_Association, Automatic] := (
  Message[WolframModel::noPatternAutomatic, rulesSpec];
  Throw[$Failed];
)


(* ::Subsubsection:: *)
(*Steps*)


fromStepsSpec[init_, generations : (_Integer | Infinity), timeConstraint_, eventSelectionFunction_] :=
  fromStepsSpec[init, <|$stepSpecKeys[$maxGenerationsLocal] -> generations|>, timeConstraint, eventSelectionFunction]


fromStepsSpec[_, spec_Association, _, _] := With[{
    stepSpecInverse = Association[Reverse /@ Normal[$stepSpecKeys]]}, {
      KeyMap[# /. stepSpecInverse &, spec],
      Inherited (* termination reason *),
      {} (* options override *),
      $$nonEvolutionOutputAbort}
]


fromStepsSpec[init_, Automatic, timeConstraint_, eventSelectionFunction_] :=
  fromStepsSpec[init, {Automatic, 1}, timeConstraint, eventSelectionFunction]


$automaticMaxEvents = 5000;
$automaticMaxFinalExpressions = 200;
$automaticStepsTimeConstraint = 5.0;

fromStepsSpec[init_, {Automatic, factor_}, timeConstraint_, eventSelectionFunction_] := {
  <|$maxEvents -> Round[factor $automaticMaxEvents],
    $maxFinalExpressions -> If[multiwayEventSelectionFunctionQ[eventSelectionFunction],
      Infinity,
      Max[Round[factor $automaticMaxFinalExpressions], Length[init]]]|>,
  Automatic, (* termination reason *)
  {TimeConstraint -> Min[timeConstraint, Replace[factor, 0 | 0. -> 1] $automaticStepsTimeConstraint],
    "IncludePartialGenerations" -> False},
  $$noAbort
}


(* ::Subsection:: *)
(*renameNodes*)


$vertexNamingFunctions = {Automatic, None, All};


renameNodes[evolution_, _, None] := evolution


renameNodesExceptExisting[
    evolution_, patternRulesQ_, existing_List] := Module[{
      evolutionAtoms, existingAtoms, atomsToName, newNames},
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
]


renameNodes[evolution_, patternRulesQ_, All] :=
  renameNodesExceptExisting[evolution, patternRulesQ, {}]


renameNodes[evolution_, True, Automatic] := renameNodes[evolution, True, None]


renameNodes[evolution_, False, Automatic] :=
  renameNodesExceptExisting[evolution, False, evolution[0]]


WolframModel::unknownVertexNamingFunction =
  "VertexNamingFunction `1` should be one of `2`.";


renameNodes[evolution_, _, func_] := (
  Message[WolframModel::unknownVertexNamingFunction, func, $vertexNamingFunctions];
  $Failed
)

(* ::Subsection:: *)
(*overrideTerminationReason*)


overrideTerminationReason[Inherited][evolution_] := evolution


overrideTerminationReason[newReason_][evolution_] :=
  WolframModelEvolutionObject[Join[First[evolution], <|$terminationReason -> newReason|>]]


(* ::Subsection:: *)
(*Normal form*)

propertyCheck[caller_][property___] := Module[{
    checkOne, checkMany
},
    checkOne = wolframModelPropertyCheck[property];
    checkMany = If[ MatchQ[{property}, {{__}}],
        Select[wolframModelPropertyCheck /@ property, FailureQ],
        Failure["NotMultiProperty", <||>]
    ];
    If[ Not[FailureQ[checkOne]] || (Not[FailureQ[checkMany]] && Length[checkMany] == 0),
        True,
        If[ FailureQ[checkOne],
            checkOne["CallMessage"][caller],
            Scan[checkMany, #["CallMessage"][caller] &]
        ];
        False
    ]
]

optionsCheck[expr_, caller_, allowedOptions_][property__, opts : OptionsPattern[]] := Module[{
    joinedPropertyOptions, masterOptions, $unrecognizedOptions
},
    {joinedPropertyOptions, masterOptions} = joinPropertyOptions[property, {opts}];
    $unrecognizedOptions = FilterRules[masterOptions, allowedOptions];
    If[ $unrecognizedOptions =!= {},
        Message[
            caller::optx,
            $unrecognizedOptions[[1]],
            expr
        ]
    ];
    {joinedPropertyOptions, masterOptions}
]


$allowedOptions := $allowedOptions = Except[Join[Options[WolframModel], $allPropertyOptions]];

expr : WolframModel[
        rulesSpec_ ? wolframModelRulesSpecQ,
           initSpec_ ? wolframModelInitSpecQ,
           o : OptionsPattern[]] :=
    WolframModel[rulesSpec, initSpec, 1, "EvolutionObject", o] /;
        Check[
            optionsCheck[Defer[expr], WolframModel, $allowedOptions]["EvolutionObject", o];
            Catch[fromInitSpec[rulesSpec, initSpec]];
            True,

            False]

expr : WolframModel[
            rulesSpec_ ? wolframModelRulesSpecQ,
            initSpec_ ? wolframModelInitSpecQ,
            property : _ ? (Not[wolframModelStepsSpecQ[#]] &),
            o : OptionsPattern[]] :=
    WolframModel[rulesSpec, initSpec, 1, property, o] /;
        Check[
            optionsCheck[Defer[expr], WolframModel, $allowedOptions][property, o];
            Catch[fromInitSpec[rulesSpec, initSpec]];
            propertyCheck[WolframModel][property];
            True,

            False
        ]

expr : WolframModel[
            rulesSpec_ ? wolframModelRulesSpecQ,
            initSpec_ ? wolframModelInitSpecQ,
            stepsSpec : _ ? wolframModelStepsSpecQ,
            property : _ ? (wolframModelPropertyQ[#] || wolframModelPropertiesQ[#] &) : "EvolutionObject",
            o : OptionsPattern[]] :=
    Module[{
            patternRules, initialSet, steps, terminationReasonOverride, optionsOverride, abortBehavior,
            joinedPropertyOptions, masterOptions, objectOptions, overridenOptionValue,
            evolution, modifiedEvolution, obj, result},
    (
        patternRules = fromRulesSpec[rulesSpec];
        objectOptions = FilterRules[masterOptions, Except[Options[setSubstitutionSystem]]];
        masterOptions = FilterRules[masterOptions, Options[WolframModel]];
        {steps, terminationReasonOverride, optionsOverride, abortBehavior} =
            fromStepsSpec[initialSet, stepsSpec,
                OptionValue[WolframModel, masterOptions, TimeConstraint],
                OptionValue[WolframModel, masterOptions, "EventSelectionFunction"]
            ];
        overridenOptionValue = OptionValue[WolframModel, Join[optionsOverride, masterOptions], #] &;
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
                "EventSelectionFunction" -> overridenOptionValue["EventSelectionFunction"]],
            $Failed],
        $Failed];
        If[evolution === $Aborted, Return[$Aborted]];
        modifiedEvolution = If[evolution =!= $Failed,
            Check[
                overrideTerminationReason[terminationReasonOverride] @ renameNodes[
                    evolution,
                    AssociationQ[rulesSpec],
                    overridenOptionValue["VertexNamingFunction"]],
                $Failed],
            $Failed
        ];
        result = If[modifiedEvolution =!= $Failed,
            Check[
                Catch[
                    Check[
                        obj = propertyEvaluate[
                            overridenOptionValue["IncludePartialGenerations"],
                            overridenOptionValue["IncludeBoundaryEvents"]][
                            modifiedEvolution,
                            WolframModel
                        ] /. HoldPattern[WolframModelEvolutionObject[data_Association, opts___]] :>
                            WolframModelEvolutionObject[Join[data, <|$rules -> rulesSpec|>], opts];
                        obj[##, Sequence @@ objectOptions] & @@@ Join @@@ joinedPropertyOptions,
                        Throw[$Failed, $propertyMessages]
                    ],
                    $propertyMessages,
                    $Failed &
                ] ,
                $Failed],
            $Failed
        ];
        If[Not[wolframModelPropertiesQ[property]], First @ result, result] /; result =!= $Failed
    ) /; Check[
        initialSet = Catch[fromInitSpec[rulesSpec, initSpec]];
        propertyCheck[WolframModel][property];
        {joinedPropertyOptions, masterOptions} = optionsCheck[
            Defer[expr],
            WolframModel,
            $allowedOptions][property, o];
        True,

        False]
]


(* ::Subsection:: *)
(*Operator form*)


expr : WolframModel[rulesSpec_ ? wolframModelRulesSpecQ, o : OptionsPattern[]] := 0 /;
	recognizedOptionsQ[expr, WolframModel, {o}] && False


WolframModel[
    rulesSpec_ ? wolframModelRulesSpecQ,
    o : OptionsPattern[] /; Quiet[recognizedOptionsQ[None, WolframModel, {o}]]][
    initSpec_ ? wolframModelInitSpecQ] := Module[{result},
  result = Check[WolframModel[rulesSpec, initSpec, 1, "FinalState", o], $Failed];
  result /; result =!= $Failed]


(* ::Subsection:: *)
(*$WolframModelProperties*)


$WolframModelProperties =
  Complement[$propertiesParameterless, {"Properties", "Rules"}];


(* ::Section:: *)
(*Argument Checks*)


(* ::Subsection:: *)
(*Argument count*)


WolframModel[args___] := 0 /;
  !Developer`CheckArgumentCount[WolframModel[args], 1, 4] && False


WolframModel[args0___][args1___] := 0 /;
  Length[{args1}] != 1 &&
  Message[WolframModel::argx, "WolframModel[\[Ellipsis]]", Length[{args1}], 1]


(* ::Subsection:: *)
(*Options*)

unrecognizedOptions[func_, opts_, property_: {}] :=
    FilterRules[opts, Except[Join[Options[func], Catenate @ Values @ joinPropertyOptions[property, opts]]]]


expr : WolframModel[
        rulesSpec_ ? wolframModelRulesSpecQ,
        o : OptionsPattern[]] := 0 /; With[{
    unrecognizedOptions = unrecognizedOptions[WolframModel, {o}]},
    If[unrecognizedOptions =!= {},
        Message[
            WolframModel::optx,
            unrecognizedOptions[[1]],
            Defer @ expr]]]


(* ::Subsection:: *)
(*Rules*)


wolframModelRulesSpecQ[rulesSpec_ ? anonymousRulesQ] := True


wolframModelRulesSpecQ[<|"PatternRules" -> rules_ ? setReplaceRulesQ|>] := True


wolframModelRulesSpecQ[_] := False


(* ::Subsection:: *)
(*Init*)


wolframModelInitSpecQ[init_ ? ListQ] := True


wolframModelInitSpecQ[Automatic] := True


wolframModelInitSpecQ[_] := False


(* ::Subsection:: *)
(*Steps*)


wolframModelStepsSpecQ[stepsSpec_ ? stepCountQ] := True


wolframModelStepsSpecQ[stepsSpec_Association] /;
  SubsetQ[Values[$stepSpecKeys], Keys[stepsSpec]] &&
  AllTrue[First[fromStepsSpec[{}, stepsSpec, Infinity, "GlobalSpacelike"]], stepCountQ] := True


wolframModelStepsSpecQ[Automatic] := True


wolframModelStepsSpecQ[{Automatic, _ ? (# >= 0 &)}] := True


wolframModelStepsSpecQ[_] := False


(* ::Subsection:: *)
(*Property*)

wolframModelPropertyCheck[n_Integer] := Success["Generation", <|"Arguments" -> {n}|>]

wolframModelPropertyCheck[
        property_String ? (MemberQ[$allProperties, #] &), 
        args___,
        opts : OptionsPattern[]
    ] := With[{argumentsCountRange = $propertyArgumentCounts[property]},
    If[Not[MissingQ[argumentsCountRange]] &&
        argumentsCountRange[[1]] <= Length[{args}] <= argumentsCountRange[[2]],
        Success[property, <|"Arguments" -> {args}, "Options" -> {opts}|>],
        Failure[property, <|
            "Arguments" -> {args},
            "Options" -> {opts},
            "CallMessage" -> Function[{caller}, makePargxMessage[property, caller, Length[{args}], argumentsCountRange]]|>
        ]
    ]
]

wolframModelPropertyCheck[property_List] := Apply[wolframModelPropertyCheck, property]

wolframModelPropertyCheck[property_String, ___] := Failure["Unknown",
    <|"CallMessage" -> Function[{caller}, makeMessage[caller, "unknownProperty", property]]|>
]

wolframModelPropertyCheck[property___] := Failure["Invalid",
    <|"CallMessage" -> Function[{caller}, makeMessage[caller, "badProperty", {property}]]|>
]


wolframModelPropertyQ[property___] := Not @ FailureQ[wolframModelPropertyCheck[property]]


wolframModelPropertiesQ[{property___}] /;
    AllTrue[{property}, wolframModelPropertyQ] := True

wolframModelPropertiesQ[___] := False


(* ::Subsection:: *)
(*Incorrect arguments messages*)


(* ::Subsubsection:: *)
(*Init*)


WolframModel::invalidState =
  "The initial state specification `1` should be a List.";


expr : WolframModel[
    rulesSpec_ ? wolframModelRulesSpecQ,
    initSpec : Except[OptionsPattern[]] ? (Not[wolframModelInitSpecQ[#]] &),
    args___] /; Quiet[Developer`CheckArgumentCount[expr, 1, 4]] := 0 /;
  Message[WolframModel::invalidState, initSpec]


WolframModel[
    rulesSpec_ ? wolframModelRulesSpecQ,
    o : OptionsPattern[] /; Quiet[recognizedOptionsQ[None, WolframModel, {o}]]][
    initSpec_ ? (Not @* wolframModelInitSpecQ)] := 0 /;
  Message[WolframModel::invalidState, initSpec]


(* ::Subsubsection:: *)
(*Rules*)


General::invalidRules =
  "The rule specification `1` should be either a Rule, " ~~
  "a List of rules, or <|\"PatternRules\" -> rules|>, where " ~~
  "rules is either a Rule, RuleDelayed, or a List of them.";


expr : WolframModel[
    rulesSpec_ ? (Not @* wolframModelRulesSpecQ),
    args___] /; Quiet[Developer`CheckArgumentCount[expr, 2, 4]] := 0 /;
  Message[WolframModel::invalidRules, rulesSpec]


(* ::Subsubsection:: *)
(*Steps*)


WolframModel::invalidSteps =
  "The steps specification `1` should be an Integer, Infinity, Automatic, " <>
  "or an association with one or more keys from `2`.";


expr : WolframModel[
    rulesSpec_ ? wolframModelRulesSpecQ,
    initSpec_ ? wolframModelInitSpecQ,
    stepsSpec : Except[OptionsPattern[]] ? (Not[wolframModelStepsSpecQ[#]] &),
    args___] /; Quiet[Developer`CheckArgumentCount[expr, 1, 4]] := 0 /;
  Message[WolframModel::invalidSteps, stepsSpec, Values[$stepSpecKeys]]



(* ::Subsubsection:: *)
(*Property*)


WolframModel::invalidProperty =
  "Property specification `1` should be one of $WolframModelProperties " <>
  "or a List of them.";


expr : WolframModel[
	rulesSpec_ ? wolframModelRulesSpecQ,
	initSpec_ ? wolframModelInitSpecQ,
	stepsSpec_ ? wolframModelStepsSpecQ,
	property : Except[OptionsPattern[]] ? (Not[wolframModelPropertyQ[##] || wolframModelPropertiesQ[##]] &),
	o : OptionsPattern[] /; recognizedOptionsQ[expr, WolframModel, {o}]] := 0 /;
  Message[WolframModel::invalidProperty, property]


(* ::Section:: *)
(*Autocompletion*)

With[{properties = $newParameterlessProperties},
  FE`Evaluate[FEPrivate`AddSpecialArgCompletion["WolframModel" -> {0, 0, 0, properties}]]];
