(* ::Package:: *)

(* ::Title:: *)
(*SetReplaceFixedPointList*)


(* ::Text:: *)
(*Same as SetReplaceFixedPoint, but returns all intermediate steps.*)


Package["SetReplace`"]


PackageExport["SetReplaceFixedPointList"]


(* ::Section:: *)
(*Documentation*)


SetReplaceFixedPointList::usage = usageString[
	"SetReplaceFixedPointList[`s`, {\!\(\*SubscriptBox[\(`i`\), \(`1`\)]\) \[Rule] ",
	"\!\(\*SubscriptBox[\(`o`\), \(`1`\)]\), ",
	"\!\(\*SubscriptBox[\(`i`\), \(`2`\)]\) \[Rule] ",
	"\!\(\*SubscriptBox[\(`o`\), \(`2`\)]\), \[Ellipsis]}] performs SetReplace repeatedly ",
	"until the set no longer changes, and returns the list of all intermediate sets."];


(* ::Section:: *)
(*Syntax Information*)


SyntaxInformation[SetReplaceFixedPointList] =
	{"ArgumentsPattern" -> {_, _, OptionsPattern[]}};


(* ::Section:: *)
(*Argument Checks*)


(* ::Subsection:: *)
(*Argument count*)


SetReplaceFixedPointList[args___] := 0 /;
	!Developer`CheckArgumentCount[SetReplaceFixedPointList[args], 2, 2] && False


(* ::Subsection:: *)
(*Set is a list*)


SetReplaceFixedPointList[set_, rules_, o : OptionsPattern[]] := 0 /; !ListQ[set] &&
	Message[SetReplace::setNotList, "first", SetReplaceFixedPointList]


(* ::Subsection:: *)
(*Rules are valid*)


SetReplaceFixedPointList[set_, rules_, o : OptionsPattern[]] := 0 /;
	!setReplaceRulesQ[rules] &&
	Message[SetReplace::invalidRules, "second", SetReplaceFixedPointList]


(* ::Section:: *)
(*Options*)


Options[SetReplaceFixedPointList] := Options[SetSubstitutionSystem]


(* ::Section:: *)
(*Implementation*)


SetReplaceFixedPointList[
			set_List, rules_ ? setReplaceRulesQ, o : OptionsPattern[]] := Module[{
		failed = False, result},
	result = Check[SetReplaceList[set, rules, Infinity, o], failed = True];
	result /; !failed
]
