(* ::Package:: *)

(* ::Title:: *)
(*SetReplaceAll*)


(* ::Text:: *)
(*The idea for SetReplaceAll is to keep performing SetReplace on the graph until no replacement can be done without touching the same edge twice.*)


(* ::Text:: *)
(*Note, it's not doing replacement until all edges are touched at least once. That may not always be possible. We just don't want to touch edges twice in a single step.*)


Package["SetReplace`"]


PackageExport["SetReplaceAll"]


(* ::Section:: *)
(*Documentation*)


SetReplaceAll::usage = usageString[
	"SetReplaceAll[`s`, `r`] performs SetReplace[`s`, `r`] as many times as it takes ",
	"until no replacement can be done without touching the same edge twice.",
	"\n",
	"SetReplaceAll[`s`, `r`, `n`] performes the same operation `n` times, i.e., any ",
	"edge will at most be replaced `n` times."];


(* ::Section:: *)
(*Syntax Information*)


SyntaxInformation[SetReplaceAll] = {"ArgumentsPattern" -> {_, _, _.}};


(* ::Section:: *)
(*Argument Checks*)


(* ::Subsection:: *)
(*Argument count*)


SetReplaceAll[args___] := 0 /;
	!Developer`CheckArgumentCount[SetReplaceAll[args], 2, 3] && False


(* ::Subsection:: *)
(*Set is a list*)


SetReplaceAll[set_, rules_, n_: 0] := 0 /; !ListQ[set] &&
	Message[SetReplace::setNotList, SetReplaceAll]


(* ::Subsection:: *)
(*Rules are valid*)


SetReplaceAll[set_, rules_, n_: 0] := 0 /;
	!setReplaceRulesQ[rules] && Message[SetReplace::invalidRules, SetReplaceAll]


(* ::Subsection:: *)
(*Step count is valid*)


SetReplaceAll[set_, rules_, n_] := 0 /; !stepCountQ[n] &&
	Message[SetReplace::nonIntegerIterations, SetReplaceAll, n]


(* ::Section:: *)
(*Implementation*)


(* ::Subsection:: *)
(*toTouched*)


SetAttributes[toTouched, HoldAll];


toTouched[expr_List] := touched /@ Hold /@ expr


toTouched[expr_Module] := With[
		{heldModule = Map[Hold, Hold @ expr, {3}]},
	With[{
			moduleVariables = heldModule[[1, 1]],
			moduleExpression = touched /@ heldModule[[1, 2]]},
		Hold[Module[moduleVariables, moduleExpression]]
	]
]


(* ::Subsection:: *)
(*toSingleUseRule*)


toSingleUseRule[left_ :> right_] := With[
		{newLeft = untouched /@ left, newRight = toTouched @ right},
	(newLeft :> newRight) //. Hold[expr_] :> expr
]


(* ::Subsection:: *)
(*SetReplaceAll*)


(* ::Text:: *)
(*The idea here is to replace each element of the set, and each element of rules input with something like touched[original, False], and replace every element of the rules output with touched[original, True]. This way, rules can no longer be applied on the previous output. Then, we can call SetReplaceFixedPoint on that, which will take care of evaluating until everything is fixed.*)


SetReplaceAll[set_List, rules_ ? setReplaceRulesQ] := Module[
		{canonicalRules, setUntouched, singleUseRules},
	canonicalRules = toCanonicalRules[rules];
	setUntouched = untouched /@ set;
	singleUseRules = toSingleUseRule /@ canonicalRules;
	SetReplaceFixedPoint[setUntouched, singleUseRules] /.
		{touched[expr_] :> expr, untouched[expr_] :> expr}
]


(* ::Text:: *)
(*If multiple steps are requested, we just use Nest.*)


SetReplaceAll[set_List, rules_ ? setReplaceRulesQ, n_Integer ? stepCountQ] :=
	Nest[SetReplaceAll[#, rules] &, set, n]


(* ::Text:: *)
(*If infinite number of steps is requested, we simply do SetReplaceFixedPoint, because that would yield the same result.*)


SetReplaceAll[set_List, rules_ ? setReplaceRulesQ, \[Infinity]] :=
	SetReplaceFixedPoint[set, rules]
