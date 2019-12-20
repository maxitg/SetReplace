(* ::Package:: *)

(* ::Title:: *)
(*WolframModel*)


(* ::Text:: *)
(*Generates evolutions of Wolfram Model systems.*)


Package["SetReplace`"]


PackageExport["WolframModel"]
PackageExport["$WolframModelProperties"]


PackageScope["unrecognizedOptions"]
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
	{"ArgumentsPattern" -> {_, _..., OptionsPattern[]}};


(* ::Section:: *)
(*Options*)


Options[WolframModel] := Join[
	{"NodeNamingFunction" -> Automatic, "IncludePartialGenerations" -> True},
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


fromInitSpec[initSpec_] := initSpec


(* ::Subsubsection:: *)
(*Steps*)


fromStepsSpec[generations : (_Integer | Infinity)] :=
	fromStepsSpec[<|$stepSpecKeys[$maxGenerationsLocal] -> generations|>]


fromStepsSpec[spec_Association] := With[{
		stepSpecInverse = Association[Reverse /@ Normal[$stepSpecKeys]]},
	KeyMap[# /. stepSpecInverse &, spec]
]


(* ::Subsection:: *)
(*renameNodes*)


$nodeNamingFunctions = {Automatic, None, All};


renameNodes[evolution_, _, None] := evolution


renameNodesExceptExisting[
		evolution_, patternRulesQ_, existing_List] := Module[{
			evolutionAtoms, existingAtoms, atomsToName, newNames},
	{evolutionAtoms, existingAtoms} = DeleteDuplicates @ If[patternRulesQ,
			Cases[#, _ ? AtomQ, All],
			Catenate[If[AtomQ[#], {#}, #] & /@ #]] & /@
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


WolframModel::unknownNodeNamingFunction =
	"NodeNamingFunction `1` should be one of `2`.";


renameNodes[evolution_, _, func_] := (
	Message[WolframModel::unknownNodeNamingFunction, func, $nodeNamingFunctions];
	$Failed
)


(* ::Subsection:: *)
(*Normal form*)


WolframModel[
			rulesSpec_ ? wolframModelRulesSpecQ,
			initSpec_ ? wolframModelInitSpecQ,
			stepsSpec : _ ? wolframModelStepsSpecQ : 1,
			property : _ ? wolframModelPropertyQ : "EvolutionObject",
			o : OptionsPattern[] /; unrecognizedOptions[WolframModel, {o}] === {}] :=
	Module[{
			patternRules, initialSet, evolution, renamedNodesEvolution, result},
		patternRules = fromRulesSpec[rulesSpec];
		initialSet = fromInitSpec[initSpec];
		evolution = Check[
			setSubstitutionSystem[
				patternRules,
				initialSet,
				fromStepsSpec[stepsSpec],
				WolframModel,
				property === "EvolutionObject",
				Method -> OptionValue[Method],
				TimeConstraint -> OptionValue[TimeConstraint]],
			$Failed];
		If[evolution === $Aborted, Return[$Aborted]];
		renamedNodesEvolution = If[evolution =!= $Failed,
			Check[
				renameNodes[
					evolution,
					AssociationQ[rulesSpec],
					OptionValue["NodeNamingFunction"]],
				$Failed],
			$Failed];
		propertyEvaluateWithOptions =
			propertyEvaluate[OptionValue["IncludePartialGenerations"]][renamedNodesEvolution, WolframModel, #] &;
		result = If[renamedNodesEvolution =!= $Failed,
			If[ListQ[property],
					Catch[
						Check[propertyEvaluateWithOptions[#], Throw[$Failed, $propertyMessages]] & /@ property,
						$propertyMessages,
						$Failed &],
					propertyEvaluateWithOptions @ property] /.
				HoldPattern[WolframModelEvolutionObject[data_Association]] :>
					WolframModelEvolutionObject[Join[data, <|$rules -> rulesSpec|>]],
			$Failed];
		result /; result =!= $Failed
	]


(* ::Subsection:: *)
(*Operator form*)


WolframModel[
		rulesSpec_ ? wolframModelRulesSpecQ,
		o : OptionsPattern[] /; unrecognizedOptions[WolframModel, {o}] === {}][
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


unrecognizedOptions[func_, opts_] := FilterRules[opts, Except[Options[func]]]


expr : WolframModel[
		rulesSpec_ ? wolframModelRulesSpecQ,
		initSpec : _ ? wolframModelInitSpecQ,
		stepsSpec : _ ? wolframModelStepsSpecQ : 1,
		property : _ ? wolframModelPropertyQ : "EvolutionObject",
		o : OptionsPattern[]] := 0 /; With[{
	unrecognizedOptions = unrecognizedOptions[WolframModel, {o}]},
	If[unrecognizedOptions =!= {},
		Message[
			WolframModel::optx,
			unrecognizedOptions[[1]],
			Defer @ expr]]]


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


wolframModelInitSpecQ[_] := False


(* ::Subsection:: *)
(*Steps*)


wolframModelStepsSpecQ[stepsSpec_ ? stepCountQ] := True


wolframModelStepsSpecQ[stepsSpec_Association] /;
	SubsetQ[Values[$stepSpecKeys], Keys[stepsSpec]] &&
	AllTrue[fromStepsSpec[stepsSpec], stepCountQ] := True


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
		o : OptionsPattern[] /; unrecognizedOptions[WolframModel, {o}] === {}][
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
	"The steps specification `1` should be an Integer, Infinity, " <>
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


WolframModel[
		rulesSpec_ ? wolframModelRulesSpecQ,
		initSpec_ ? wolframModelInitSpecQ,
		stepsSpec_ ? wolframModelStepsSpecQ,
		property : Except[OptionsPattern[]] ? (Not[wolframModelPropertyQ[#]] &),
		o : OptionsPattern[] /; unrecognizedOptions[WolframModel, {o}] === {}] := 0 /;
	Message[WolframModel::invalidProperty, property]
