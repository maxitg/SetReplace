(* ::Package:: *)

(* ::Title:: *)
(*WolframModel*)


(* ::Text:: *)
(*Generates evolutions of Wolfram Model systems.*)


Package["SetReplace`"]


PackageExport["WolframModel"]
PackageExport["$WolframModelProperties"]


PackageScope["wolframModelRulesSpecQ"]


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


expr : WolframModel[
			rulesSpec_ ? wolframModelRulesSpecQ,
			initSpec_ ? wolframModelInitSpecQ,
			stepsSpec : _ ? wolframModelStepsSpecQ : 1,
			property : _ ? wolframModelPropertyQ : "EvolutionObject",
			o : OptionsPattern[] /; recognizedOptionsQ[expr, WolframModel, {o}]] :=
	Module[{
			patternRules, initialSet, steps, terminationReasonOverride, optionsOverride, abortBehavior, overridenOptionValue,
			evolution, modifiedEvolution, propertyEvaluateWithOptions, result},
		patternRules = fromRulesSpec[rulesSpec];
		initialSet = Catch[fromInitSpec[rulesSpec, initSpec]];
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
			$Failed];
		propertyEvaluateWithOptions = propertyEvaluate[
			overridenOptionValue["IncludePartialGenerations"],
			overridenOptionValue["IncludeBoundaryEvents"]][
			modifiedEvolution,
			WolframModel,
			#] &;
		result = Catch[Check[
			If[modifiedEvolution =!= $Failed,
				If[ListQ[property],
						Catch[
							Check[propertyEvaluateWithOptions[#], Throw[$Failed, $propertyMessages]] & /@ property,
							$propertyMessages,
							$Failed &],
						propertyEvaluateWithOptions @ property] /.
					HoldPattern[WolframModelEvolutionObject[data_Association]] :>
						WolframModelEvolutionObject[Join[data, <|$rules -> rulesSpec|>]],
				$Failed],
			$Failed]];
		result /; result =!= $Failed
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


wolframModelPropertyQ[property_String] /;
	MemberQ[$WolframModelProperties, property] := True


wolframModelPropertyQ[{property___String}] /;
	And @@ (wolframModelPropertyQ /@ {property}) := True


wolframModelPropertyQ[_] := False


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
		property : Except[OptionsPattern[]] ? (Not[wolframModelPropertyQ[#]] &),
		o : OptionsPattern[] /; recognizedOptionsQ[expr, WolframModel, {o}]] := 0 /;
	Message[WolframModel::invalidProperty, property]


(* ::Section:: *)
(*Autocompletion*)

With[{properties = $newParameterlessProperties},
	FE`Evaluate[FEPrivate`AddSpecialArgCompletion["WolframModel" -> {0, 0, 0, properties}]]];
