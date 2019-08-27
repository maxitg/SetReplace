(* ::Package:: *)

(* ::Title:: *)
(*SetSubstitutionSystem*)


(* ::Text:: *)
(*This function is similar to SetReplace, except it produces a SetSubstitutionEvolution object that contains information about evolution of the network step-by-step.*)


Package["SetReplace`"]


PackageExport["SetSubstitutionSystem"]


(* ::Section:: *)
(*Documentation*)


SetSubstitutionSystem::usage = usageString[
	"SetSubstitutionSystem[`r`, `s`, `n`] computes ",
	"evolution of the set substitution system described by rules `r` ",
	"and initial set `s` for `n` steps. All non-intersecting subsets are replaced ",
	"at once at each step which is different from the behavior of SetReplace.",
	"\n",
	"SetSubstitutionSystem[`r`, `s`] runs evolution for one step."];


(* ::Section:: *)
(*SyntaxInformation*)


SyntaxInformation[SetSubstitutionSystem] =
	{"ArgumentsPattern" -> {_, _, _., OptionsPattern[]}};


(* ::Section:: *)
(*Argument Checks*)


(* ::Subsection:: *)
(*Argument count*)


SetSubstitutionSystem[args___] := 0 /;
	!Developer`CheckArgumentCount[SetSubstitutionSystem[args], 2, 3] && False


(* ::Subsection:: *)
(*Set is a list*)


SetSubstitutionSystem::setNotList = "The second argument of `` must be a List.";


SetSubstitutionSystem[
		rules_, set_, n : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] := 0 /;
	!ListQ[set] &&
	Message[SetSubstitutionSystem::setNotList, SetSubstitutionSystem]


(* ::Subsection:: *)
(*Rules are valid*)


SetSubstitutionSystem::invalidRules =
	"The first argument of `` must be either a Rule, RuleDelayed, or " ~~
	"a List of them.";


SetSubstitutionSystem[
		rules_, set_, n : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] := 0 /;
	!setReplaceRulesQ[rules] &&
	Message[SetSubstitutionSystem::invalidRules, SetSubstitutionSystem]


(* ::Subsection:: *)
(*Step count is valid*)


SetSubstitutionSystem[
		rules_, set_, n : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] := 0 /;
	!stepCountQ[n] &&
	Message[SetReplace::nonIntegerIterations, SetSubstitutionSystem, n]


(* ::Subsection:: *)
(*Method is valid*)


SetSubstitutionSystem[
		rules_, set_, n : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] := 0 /;
	!MatchQ[OptionValue[Method], Alternatives @@ $SetReplaceMethods] &&
	Message[SetReplace::invalidMethod]


(* ::Section:: *)
(*Options*)


Options[SetSubstitutionSystem] = {Method -> Automatic};


(* ::Section:: *)
(*Implementation*)
