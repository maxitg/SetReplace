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
	"until no further events can be matched, ",
	"and returns the list of all intermediate sets."];


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


(* ::Section:: *)
(*Options*)


Options[SetReplaceFixedPointList] := Options[setSubstitutionSystem]


(* ::Section:: *)
(*Implementation*)


SetReplaceFixedPointList[set_, rules_, o : OptionsPattern[]] := Module[{result},
	result = Check[
		setSubstitutionSystem[
			rules, set, Infinity, Infinity, SetReplaceFixedPointList, o],
		$Failed];
	result["SetAfterEvent", #] & /@ Range[0, result["EventsCount"]] /;
		result =!= $Failed
]
