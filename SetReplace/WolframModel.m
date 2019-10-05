(* ::Package:: *)

(* ::Title:: *)
(*WolframModel*)


(* ::Text:: *)
(*Generates evolutions of Wolfram Model systems.*)


Package["SetReplace`"]


PackageExport["WolframModel"]
PackageExport["$WolframModelMethods"]


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


(* ::Section:: *)
(*SyntaxInformation*)


SyntaxInformation[WolframModel] =
	{"ArgumentsPattern" -> {_, _..., OptionsPattern[]}};


(* ::Section:: *)
(*Options*)


Options[WolframModel] = {Method -> Automatic};


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


fromStepsSpec[generations_Integer] := {generations, Infinity}


fromStepsSpec[Infinity] := {Infinity, Infinity}


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
		patternRules, initialSet, generations, events, evolution},
	patternRules = fromRulesSpec[rulesSpec];
	initialSet = fromInitSpec[initSpec];
	{generations, events} = fromStepsSpec[stepsSpec];
	evolution = setSubstitutionSystem[
		patternRules, initialSet, generations, events, WolframModel, o];
	If[ListQ[property], evolution /@ property, evolution @ property]
]


(* ::Subsection:: *)
(*Operator form*)


WolframModel[
		rulesSpec_ ? wolframModelRulesSpecQ,
		o : OptionsPattern[]][
		initSpec_ ? wolframModelInitSpecQ] :=
	WolframModel[rulesSpec, initSpec, 1, "FinalState", o]


(* ::Subsection:: *)
(*Rule plot*)


WolframModel /: RulePlot[
		WolframModel[rulesSpec_ ? wolframModelRulesQ, o : OptionsPattern[]]] := 0


(* ::Section:: *)
(*Argument Checks*)


(* ::Subsection:: *)
(*Argument count*)


WolframModel[args___] := 0 /;
	!Developer`CheckArgumentCount[SetSubstitutionSystem[args], 1, Infinity] && False


(* ::Text:: *)
(*TODO: implement following checks*)


(* ::Subsection:: *)
(*Rules*)


wolframModelRulesSpecQ[rulesSpec_] := True


(* ::Subsection:: *)
(*Init*)


wolframModelInitSpecQ[init_] := True


(* ::Subsection:: *)
(*Steps*)


wolframModelStepsSpecQ[stepsSpec_] := True


(* ::Subsection:: *)
(*Property*)


wolframModelPropertyQ[property_] := True
