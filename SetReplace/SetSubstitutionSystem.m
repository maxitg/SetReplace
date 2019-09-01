(* ::Package:: *)

(* ::Title:: *)
(*SetSubstitutionSystem*)


(* ::Text:: *)
(*This function is similar to SetReplace, except it produces a SetSubstitutionEvolution object that contains information about evolution of the network step-by-step.*)


Package["SetReplace`"]


PackageExport["SetSubstitutionSystem"]
PackageExport["$SetReplaceMethods"]


PackageScope["setReplaceRulesQ"]
PackageScope["stepCountQ"]


(* ::Section:: *)
(*Documentation*)


SetSubstitutionSystem::usage = usageString[
	"SetSubstitutionSystem[`r`, `s`, `n`] computes ",
	"evolution of the set substitution system described by rules `r` ",
	"and initial set `s` for `n` steps. All non-intersecting subsets are replaced ",
	"at once at each step which is different from the behavior of SetReplace.",
	"\n",
	"SetSubstitutionSystem[`r`, `s`] runs evolution for one step."];


$SetReplaceMethods::usage = usageString[
	"$SetReplaceMethods gives the list of available values for Method option of ",
	"SetReplace."];


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


SetReplace::setNotList = "The `` argument of `` must be a List.";


SetSubstitutionSystem[
		rules_, set_, n : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] := 0 /;
	!ListQ[set] &&
	Message[SetReplace::setNotList, "second", SetSubstitutionSystem]


(* ::Subsection:: *)
(*Rules are valid*)


SetReplace::invalidRules =
	"The `` argument of `` must be either a Rule, RuleDelayed, or " ~~
	"a List of them.";


setReplaceRulesQ[rules_] :=
	MatchQ[rules, {(_Rule | _RuleDelayed)..} | _Rule | _RuleDelayed]


SetSubstitutionSystem[
		rules_, set_, n : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] := 0 /;
	!setReplaceRulesQ[rules] &&
	Message[SetReplace::invalidRules, "first", SetSubstitutionSystem]


(* ::Subsection:: *)
(*Step count is valid*)


SetReplace::nonIntegerIterations =
	"The third argument `2` of `1` must be an integer or infinity.";


stepCountQ[n_] := IntegerQ[n] && n >= 0 || n == \[Infinity]


SetSubstitutionSystem[
		rules_, set_, n : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] := 0 /;
	!stepCountQ[n] &&
	Message[SetReplace::nonIntegerIterations, SetSubstitutionSystem, n]


(* ::Subsection:: *)
(*Method is valid*)


SetReplace::invalidMethod =
	"Method should be one of " <> ToString[$SetReplaceMethods, InputForm] <> ".";


$cppMethod = "C++";
$wlMethod = "WolframLanguage";


$SetReplaceMethods = {Automatic, $cppMethod, $wlMethod};


SetSubstitutionSystem[
		rules_, set_, n : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] := 0 /;
	!MatchQ[OptionValue[Method], Alternatives @@ $SetReplaceMethods] &&
	Message[SetReplace::invalidMethod]


(* ::Section:: *)
(*Options*)


Options[SetSubstitutionSystem] = {Method -> Automatic};


(* ::Section:: *)
(*Implementation*)


(* ::Subsection:: *)
(*simpleRuleQ*)


(* ::Text:: *)
(*This is the rule that can be understood by C++ code*)


simpleRuleQ[
		left : {{__ ? (AtomQ[#]
			|| MatchQ[#, _Pattern?(AtomQ[#[[1]]] && #[[2]] === Blank[] &)] &)}..}
		:> right : Module[{___ ? AtomQ}, {{___ ? AtomQ}...}]] := Module[{p},
	ConnectedGraphQ @ Graph[
		Flatten[Apply[
				UndirectedEdge,
				(Partition[#, 2, 1] & /@ (Append[#, #[[1]]] &) /@ left),
				{2}]]
			/. x_Pattern :> p[x[[1]]]]
]


simpleRuleQ[left_ :> right : Except[_Module]] :=
	simpleRuleQ[left :> Module[{}, right]]


simpleRuleQ[___] := False


(* ::Subsection:: *)
(*$SetSubstitutionSystem*)


(* ::Text:: *)
(*This is a more general function than SetSubstitutionSystem because it accepts both the number of generations and the number of steps as an input, and runs until the first of the two is reached.*)


Options[$SetSubstitutionSystem] = Options[SetSubstitutionSystem];


(* ::Text:: *)
(*Switching code between WL and C++ implementations*)


SetReplace::cppNotImplemented =
	"C++ implementation is only available for local rules, " <>
	"and only for sets of lists (hypergraphs).";


SetReplace::cppInfinite =
	"C++ implementation is only available for finite step count.";


SetReplace::noCpp =
	"C++ implementation was not compiled for your system type.";


$SetSubstitutionSystem[
			rules_,
			set_,
			generations_,
			steps_,
			o : OptionsPattern[]] := Module[{
		method = OptionValue[Method], canonicalRules, failedQ = False},
	canonicalRules = toCanonicalRules[rules];
	If[MatchQ[method, Automatic | "C++"]
			&& MatchQ[set, {{___ ? AtomQ}...}]
			&& MatchQ[canonicalRules, {___ ? simpleRuleQ}],
		If[$cppSetReplaceAvailable,
			Return[setReplace$cpp[set, canonicalRules, generations, steps]]]];
	If[MatchQ[method, "C++"],
		failedQ = True;
		If[!$cppSetReplaceAvailable,
			Message[SetReplace::noCpp],
			Message[SetReplace::cppNotImplemented]];
	setReplace$wl[set, canonicalRules, generations, steps]
]/; MatchQ[OptionValue[Method], Alternatives @@ $SetReplaceMethods] && !failedQ]


SetSubstitutionSystem[
		rules_,
		set_,
		generations_,
		o : OptionsPattern[]] :=
	$SetSubstitutionSystem[rules, set, generations, \[Infinity], o]
