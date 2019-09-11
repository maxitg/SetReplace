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
	"until no further events can be matched, and returns the final set.",
	"\n",
	"Will go into infinite loop if fixed point does not exist."];


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


(* ::Section:: *)
(*Options*)


Options[SetReplaceFixedPoint] := Options[SetSubstitutionSystem]


(* ::Section:: *)
(*Implementation*)


SetReplaceFixedPoint[set_, rules_, o : OptionsPattern[]] := Module[{result},
	result = Check[
		setSubstitutionSystem[
			rules, set, Infinity, Infinity, SetReplaceFixedPoint, o][-1],
		$Failed];
	result /; result =!= $Failed
]
