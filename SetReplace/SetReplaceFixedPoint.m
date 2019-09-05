(* ::Package:: *)

(* ::Title:: *)
(*SetReplaceFixedPoint*)


(* ::Text:: *)
(*Same as SetReplace, but automatically stops replacing when the set no longer changes.*)


Package["SetReplace`"]


PackageExport["SetReplaceFixedPoint"]


(* ::Section:: *)
(*Documentation*)


SetReplaceFixedPoint::usage = usageString[
	"SetReplaceFixedPoint[`s`, {\!\(\*SubscriptBox[\(`i`\), \(`1`\)]\) \[Rule] ",
	"\!\(\*SubscriptBox[\(`o`\), \(`1`\)]\), ",
	"\!\(\*SubscriptBox[\(`i`\), \(`2`\)]\) \[Rule] ",
	"\!\(\*SubscriptBox[\(`o`\), \(`2`\)]\), \[Ellipsis]}] performs SetReplace repeatedly ",
	"until the set no longer changes, and returns the final set.",
	"\n",
	"Fixed point requires not only the elements, but also the order of elements to be ",
	"fixed. Will go into infinite loop if fixed point does not exist."];


(* ::Section:: *)
(*Syntax Information*)


SyntaxInformation[SetReplaceFixedPoint] =
	{"ArgumentsPattern" -> {_, _, OptionsPattern[]}};


(* ::Section:: *)
(*Argument Checks*)


(* ::Subsection:: *)
(*Argument count*)


SetReplaceFixedPoint[args___] := 0 /;
	!Developer`CheckArgumentCount[SetReplaceFixedPoint[args], 2, 2] && False


(* ::Subsection:: *)
(*Set is a list*)


SetReplaceFixedPoint[set_, rules_, o : OptionsPattern[]] := 0 /; !ListQ[set] &&
	Message[SetReplace::setNotList, SetReplaceFixedPoint]


(* ::Subsection:: *)
(*Rules are valid*)


SetReplaceFixedPoint[set_, rules_, o : OptionsPattern[]] := 0 /; !setReplaceRulesQ[rules] &&
	Message[SetReplace::invalidRules, SetReplaceFixedPoint]


(* ::Section:: *)
(*Options*)


Options[SetReplaceFixedPoint] := Options[SetSubstitutionSystem]


(* ::Section:: *)
(*Implementation*)


SetReplaceFixedPoint[
			set_List, rules_ ? setReplaceRulesQ, o : OptionsPattern[]] := Module[{
		failed = False, result},
	result = Check[SetSubstitutionSystem[rules, set, Infinity, o][-1], failed = True];
	result /; !failed
]
