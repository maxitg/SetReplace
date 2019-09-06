(* ::Package:: *)

(* ::Title:: *)
(*SetSubstitutionSystem*)


(* ::Text:: *)
(*This function is similar to SetReplace, except it produces a SetSubstitutionEvolution object that contains information about evolution of the network step-by-step.*)


Package["SetReplace`"]


PackageExport["SetSubstitutionSystem"]
PackageExport["$SetReplaceMethods"]


PackageScope["setSubstitutionSystem"]


(* ::Section:: *)
(*Documentation*)


SetSubstitutionSystem::usage = usageString[
	"SetSubstitutionSystem[`r`, `s`, `g`] computes ",
	"evolution of the set substitution system described by rules `r` ",
	"and initial set `s` for `g` generations. ",
	"All non-intersecting subsets are replaced ",
	"at once at each next generation ",
	"which is different from the behavior of SetReplace.",
	"\n",
	"SetSubstitutionSystem[`r`, `s`] runs evolution for one generation."];


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


setSubstitutionSystem[
		rules_, set_, generations_, maxEvents_, caller_, o : OptionsPattern[]] := 0 /;
	!ListQ[set] &&
	makeMessage[caller, "setNotList", set]


(* ::Subsection:: *)
(*Rules are valid*)


setReplaceRulesQ[rules_] :=
	MatchQ[rules, {(_Rule | _RuleDelayed)..} | _Rule | _RuleDelayed]


setSubstitutionSystem[
		rules_, set_, generations_, maxEvents_, caller_, o : OptionsPattern[]] := 0 /;
	!setReplaceRulesQ[rules] &&
	makeMessage[caller, "invalidRules", rules]


(* ::Subsection:: *)
(*Step count is valid*)


stepCountQ[n_] := IntegerQ[n] && n >= 0 || n == \[Infinity]


setSubstitutionSystem[
		rules_, set_, generations_, maxEvents_, caller_, o : OptionsPattern[]] := 0 /;
	!stepCountQ[generations] &&
	makeMessage[caller, "nonIntegerIterations", "generations", generations]


setSubstitutionSystem[
		rules_, set_, generations_, maxEvents_, caller_, o : OptionsPattern[]] := 0 /;
	!stepCountQ[maxEvents] &&
	makeMessage[caller, "nonIntegerIterations", "replacements", maxEvents]


(* ::Subsection:: *)
(*Method is valid*)


$cppMethod = "C++";
$wlMethod = "WolframLanguage";


$SetReplaceMethods = {Automatic, $cppMethod, $wlMethod};


setSubstitutionSystem[
		rules_, set_, generations_, maxEvents_, caller_, o : OptionsPattern[]] := 0 /;
	!MatchQ[OptionValue[Method], Alternatives @@ $SetReplaceMethods] &&
	makeMessage[caller, "invalidMethod"]


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
(*setSubstitutionSystem*)


(* ::Text:: *)
(*This is a more general function than SetSubstitutionSystem because it accepts both the number of generations and the number of steps as an input, and runs until the first of the two is reached.*)


Options[setSubstitutionSystem] = Options[SetSubstitutionSystem];


(* ::Text:: *)
(*Switching code between WL and C++ implementations*)


setSubstitutionSystem[
			rules_ ? setReplaceRulesQ,
			set_List,
			generations_ ? stepCountQ,
			steps_ ? stepCountQ,
			caller_,
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
			makeMessage[caller, "noCpp"],
			makeMessage[caller, "cppNotImplemented"]]];
	If[failedQ || !MatchQ[OptionValue[Method], Alternatives @@ $SetReplaceMethods],
		$Failed,
		setReplace$wl[canonicalRules, set, generations, steps]]
]


(* ::Subsection:: *)
(*SetSubstitutionSystem*)


SetSubstitutionSystem[
		rules_, set_, generations : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] :=
	Module[{result},
		result = Check[
			setSubstitutionSystem[
				rules, set, generations, Infinity, SetSubstitutionSystem, o],
			$Failed];
		result /; result =!= $Failed
	]
