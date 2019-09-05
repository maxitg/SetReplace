(* ::Package:: *)

(* ::Title:: *)
(*SetReplaceList*)


(* ::Text:: *)
(*Same as SetReplace, but returns all intermediate steps in a List.*)


Package["SetReplace`"]


PackageExport["SetReplaceList"]


(* ::Section:: *)
(*Documentation*)


SetReplaceList::usage = usageString[
	"SetReplaceList[`s`, {\!\(\*SubscriptBox[\(`i`\), \(`1`\)]\) \[Rule] ",
	"\!\(\*SubscriptBox[\(`o`\), \(`1`\)]\), ",
	"\!\(\*SubscriptBox[\(`i`\), \(`2`\)]\) \[Rule] ",
	"\!\(\*SubscriptBox[\(`o`\), \(`2`\)]\), \[Ellipsis]}, `n`] performs SetReplace `n` times ",
	"and returns the list of all intermediate results."];


(* ::Section:: *)
(*Syntax Information*)


SyntaxInformation[SetReplaceList] = {"ArgumentsPattern" -> {_, _, _, OptionsPattern[]}};


(* ::Section:: *)
(*Argument Checks*)


(* ::Subsection:: *)
(*Argument count*)


SetReplaceList[args___] := 0 /;
	!Developer`CheckArgumentCount[SetReplaceList[args], 3, 3] && False


(* ::Subsection:: *)
(*Set is a list*)


SetReplaceList[set_, rules_, n : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] := 0 /;
	!ListQ[set] &&
	Message[SetReplace::setNotList, "first", SetReplaceList]


(* ::Subsection:: *)
(*Rules are valid*)


SetReplaceList[set_, rules_, n : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] := 0 /;
	!setReplaceRulesQ[rules] &&
	Message[SetReplace::invalidRules, "second", SetReplaceList]


(* ::Subsection:: *)
(*Step count is valid*)


SetReplaceList[set_, rules_, n : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] := 0 /;
	!stepCountQ[n] &&
	Message[SetReplace::nonIntegerIterations, SetReplaceList, n]


(* ::Section:: *)
(*Options*)


Options[SetReplaceList] := Options[SetSubstitutionSystem];


(* ::Section:: *)
(*Implementation*)


SetReplaceList[
			set_List,
			rules_ ? setReplaceRulesQ,
			n : Except[_ ? OptionQ] : 1,
			o : OptionsPattern[]] /; stepCountQ[n] := Module[{
		failed = False, evolution, result},
	evolution = Check[setSubstitutionSystem[rules, set, Infinity, n, o], failed = True];
	If[!failed,
		result = evolution["Step", #] & /@ Range[0, evolution["EventsCount"]]];
	result /; !failed
]
