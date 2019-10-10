(* ::Package:: *)

(* ::Title:: *)
(*SetReplace*)


(* ::Text:: *)
(*This function behaves similarly to StringReplace. The implementation is done with WolframModel, which is a more general function.*)


Package["SetReplace`"]


PackageExport["SetReplace"]


(* ::Section:: *)
(*Documentation*)


SetReplace::usage = usageString[
	"SetReplace[`s`, {\!\(\*SubscriptBox[\(`i`\), \(`1`\)]\) \[Rule] ",
	"\!\(\*SubscriptBox[\(`o`\), \(`1`\)]\), ",
	"\!\(\*SubscriptBox[\(`i`\), \(`2`\)]\) \[Rule] ",
	"\!\(\*SubscriptBox[\(`o`\), \(`2`\)]\), `\[Ellipsis]`}] attempts to replace a subset ",
	"\!\(\*SubscriptBox[\(`i`\), \(`1`\)]\) of list `s` with ",
	"\!\(\*SubscriptBox[\(`o`\), \(`1`\)]\). ",
	"If not found, replaces \!\(\*SubscriptBox[\(`i`\), \(`2`\)]\) with ",
	"\!\(\*SubscriptBox[\(`o`\), \(`2`\)]\), etc. ",
	"Elements of \!\(\*SubscriptBox[\(`i`\), \(`k`\)]\) can appear in `s` in any ",
	"order, however the elements closest to the beginning of `s` will be replaced, ",
	"and the elements of \!\(\*SubscriptBox[\(`o`\), \(`k`\)]\) ",
	"will be put at the end.",
	"\n",
	"SetReplace[`s`, {\!\(\*SubscriptBox[\(`i`\), \(`1`\)]\) \[Rule] ",
	"\!\(\*SubscriptBox[\(`o`\), \(`1`\)]\), ",
	"\!\(\*SubscriptBox[\(`i`\), \(`2`\)]\) \[Rule] ",
	"\!\(\*SubscriptBox[\(`o`\), \(`2`\)]\), \[Ellipsis]}, `n`] performs replacement ",
	"`n` times and returns the result."];


(* ::Section:: *)
(*Syntax Information*)


SyntaxInformation[SetReplace] = {"ArgumentsPattern" -> {_, _, _., OptionsPattern[]}};


(* ::Section:: *)
(*Argument Checks*)


(* ::Subsection:: *)
(*Argument count*)


SetReplace[args___] := 0 /;
	!Developer`CheckArgumentCount[SetReplace[args], 2, 3] && False


(* ::Section:: *)
(*Options*)


Options[SetReplace] := Options[setSubstitutionSystem]


(* ::Section:: *)
(*Implementation*)


SetReplace[set_, rules_, events : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] :=
	Module[{result},
		result = Check[
			setSubstitutionSystem[rules, set, Infinity, events, SetReplace, o][-1],
			$Failed];
		result /; result =!= $Failed
	]
