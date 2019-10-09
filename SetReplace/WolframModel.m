(* ::Package:: *)

(* ::Title:: *)
(*WolframModel*)


(* ::Text:: *)
(*Generates evolutions of Wolfram Model systems.*)


Package["SetReplace`"]


PackageExport["WolframModel"]
PackageExport["$WolframModelProperties"]


(* ::Section:: *)
(*Documentation*)


WolframModel::usage = usageString[
	"WolframModel[`rules`, `init`, `t`] generates an object representing the evolution ",
	"of the Wolfram Model with the specified rules from the initial condition `init` ",
	"for `t` generations.",
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


Options[WolframModel] := Options[setSubstitutionSystem];


(* ::Section:: *)
(*Implementation*)


(* ::Subsection:: *)
(*Arguments parsing*)


(* ::Subsubsection:: *)
(*Rules*)


fromRulesSpec[rulesSpec : _List | _Rule] := FromAnonymousRules[rulesSpec]


fromRulesSpec[<|"PatternRules" -> rules_|>] := rules


(* ::Subsubsection:: *)
(*Init*)


fromInitSpec[initSpec_] := initSpec


(* ::Subsubsection:: *)
(*Steps*)


fromStepsSpec[generations : (_Integer | Infinity)] := {generations, Infinity}


fromStepsSpec[spec_Association] :=
	{Lookup[spec, "Generations", Infinity], Lookup[spec, "Events", Infinity]}


(* ::Subsection:: *)
(*Normal form*)


WolframModel[
			rulesSpec_ ? wolframModelRulesSpecQ,
			initSpec_ ? wolframModelInitSpecQ,
			stepsSpec : _ ? wolframModelStepsSpecQ : 1,
			property : _ ? wolframModelPropertyQ : "EvolutionObject",
			o : OptionsPattern[]] := Module[{
		patternRules, initialSet, generations, events, method, evolution, result},
	patternRules = fromRulesSpec[rulesSpec];
	initialSet = fromInitSpec[initSpec];
	{generations, events} = fromStepsSpec[stepsSpec];
	method = Check[OptionValue[Method], $Failed, OptionValue::nodef];
	result = If[method =!= $Failed,
		evolution = Check[
			setSubstitutionSystem[
				patternRules,
				initialSet,
				generations,
				events,
				WolframModel,
				Method -> OptionValue[Method]],
			$Failed];
		If[evolution =!= $Failed,
			If[ListQ[property], evolution /@ property, evolution @ property],
			$Failed],
		$Failed];
	result /; result =!= $Failed
]


(* ::Subsection:: *)
(*Operator form*)


WolframModel[
		rulesSpec_ ? wolframModelRulesSpecQ,
		o : OptionsPattern[]][
		initSpec_ ? wolframModelInitSpecQ] := Module[{method, result},
	method = Quiet[Check[OptionValue[Method], $Failed]];
	result = If[method === $Failed,
		$Failed,
		Check[WolframModel[rulesSpec, initSpec, 1, "FinalState", o], $Failed]];
	result /; result =!= $Failed]


(* ::Subsection:: *)
(*Rule plot*)


WolframModel /: RulePlot[
		WolframModel[rulesSpec_ ? wolframModelRulesQ, o : OptionsPattern[]]] := 0


(* ::Subsection:: *)
(*$WolframModelProperties*)


$WolframModelProperties = Complement[$propertiesParameterless, {"Properties", "Rules"}];


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


wolframModelInitSpecQ[_] := False


(* ::Subsection:: *)
(*Steps*)


wolframModelStepsSpecQ[stepsSpec_ ? stepCountQ] := True


wolframModelStepsSpecQ[stepsSpec_Association] /;
	SubsetQ[{"Generations", "Events"}, Keys[stepsSpec]] &&
	stepCountQ[Lookup[stepsSpec, "Generations", Infinity]] &&
	stepCountQ[Lookup[stepsSpec, "Events", Infinity]] := True


wolframModelStepsSpecQ[_] := False


(* ::Subsection:: *)
(*Property*)


wolframModelPropertyQ[property_String] /;
	MemberQ[$WolframModelProperties, property] := True


wolframModelPropertyQ[_] := False


(* ::Subsection:: *)
(*Incorrect arguments messages*)


(* ::Subsubsection:: *)
(*Init*)


WolframModel::invalidState =
	"The initial state specification `1` should be a List.";


WolframModel[
		rulesSpec_ ? wolframModelRulesSpecQ,
		initSpec_ ? (Not[wolframModelInitSpecQ[#]] && Head[#] =!= Rule &),
		args___ ? (Head[#] =!= Rule &) /; 0 <= Length[{args}] <= 2,
		o : OptionsPattern[]] := 0 /;
	Message[WolframModel::invalidState, initSpec]


WolframModel[
		rulesSpec_ ? wolframModelRulesSpecQ,
		o : OptionsPattern[]] := 0 /;
	OptionValue[Method] && False


WolframModel[
		rulesSpec_ ? wolframModelRulesSpecQ,
		o : OptionsPattern[]][
		initSpec_ ? (Not @* wolframModelInitSpecQ)] := 0 /; Module[{method},
	method = Quiet[Check[OptionValue[Method], $Failed]];
	If[method =!= $Failed,
		Message[WolframModel::invalidState, initSpec]]]


(* ::Subsubsection:: *)
(*Rules*)


WolframModel::invalidRules =
	"The rule specification `1` should be either a Rule, " ~~
	"a List of rules, or <|\"PatternRules\" -> rules|>, where " ~~
	"rules is either a Rule, RuleDelayed, or a List of them."


WolframModel[
		rulesSpec_ ? (Not @* wolframModelRulesSpecQ),
		init : Except[_Rule],
		args___ ? (Head[#] =!= Rule &) /; 0 <= Length[{args}] <= 2,
		o : OptionsPattern[]] := 0 /;
	Message[WolframModel::invalidRules, rulesSpec]


WolframModel[
		rulesSpec_ ? (Not @* wolframModelRulesSpecQ),
		o : OptionsPattern[]] := 0 /;
	Message[WolframModel::invalidRules, rulesSpec]


(* ::Subsubsection:: *)
(*Steps*)


WolframModel::invalidSteps =
	"The steps specification `1` should be an Integer, Infinity, or an association " <>
	"with \"Generations\" key, \"Events\" key, or both.";


WolframModel[
		rulesSpec_ ? wolframModelRulesSpecQ,
		initSpec_ ? wolframModelInitSpecQ,
		stepsSpec_ ? (Not[wolframModelStepsSpecQ[#]] && Head[#] =!= Rule &),
		args___ ? (Head[#] =!= Rule &) /; 0 <= Length[{args}] <= 1,
		o : OptionsPattern[]] := 0 /;
	Message[WolframModel::invalidSteps, stepsSpec]


(* ::Subsubsection:: *)
(*Property*)


WolframModel::invalidProperty =
	"Property specification `1` should be one of $WolframModelProperties.";


WolframModel[
		rulesSpec_ ? wolframModelRulesSpecQ,
		initSpec_ ? wolframModelInitSpecQ,
		stepsSpec_ ? wolframModelStepsSpecQ,
		property : _ ? (Not[wolframModelPropertyQ[#]] && Head[#] =!= Rule &),
		o : OptionsPattern[]] := 0 /;
	Message[WolframModel::invalidProperty, property]
