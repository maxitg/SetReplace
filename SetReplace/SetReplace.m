(* ::Package:: *)

(* ::Title:: *)
(*SetReplace*)


(* ::Text:: *)
(*This is the main function of the package, which behaves similarly to StringReplace. In this file only argument checks and selection between C++ and WL implementations is done, the implementations themselves are in different files.*)


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


(* ::Subsection:: *)
(*Set is a list*)


SetReplace[set_, rules_, n : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] := 0 /;
	!ListQ[set] &&
	Message[SetReplace::setNotList, "first", SetReplace]


(* ::Subsection:: *)
(*Rules are valid*)


SetReplace[set_, rules_, n : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] := 0 /;
	!setReplaceRulesQ[rules] && Message[SetReplace::invalidRules, "second", SetReplace]


(* ::Subsection:: *)
(*Step count is valid*)


SetReplace[set_, rules_, n : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] := 0 /;
	!stepCountQ[n] &&
	Message[SetReplace::nonIntegerIterations, SetReplace, n]


(* ::Subsection:: *)
(*Method is valid*)


SetReplace[set_, rules_, n : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] := 0 /;
	!MatchQ[OptionValue[Method], Alternatives @@ $SetReplaceMethods] &&
	Message[SetReplace::invalidMethod]


(* ::Section:: *)
(*Options*)


Options[SetReplace] = {Method -> Automatic};


(* ::Section:: *)
(*Implementation*)


(* ::Subsection:: *)
(*SetReplace*)


SetReplace[
				set_List,
				rules_ ? setReplaceRulesQ,
				n : Except[_ ? OptionQ] : 1,
				o : OptionsPattern[]] /;
			stepCountQ[n] := Module[{
		result},
	result = setSubstitutionSystem[rules, set, Infinity, n, o];
	result[-1]
/; MatchQ[OptionValue[Method], Alternatives @@ $SetReplaceMethods] &&
	result =!= $Failed]
