(* ::Package:: *)

(* ::Title:: *)
(*SetReplace*)


(* ::Text:: *)
(*This is the main function of the package, which behaves similarly to StringReplace. In this file only argument checks and selection between C++ and WL implementations is done, the implementations themselves are in different files.*)


Package["SetReplace`"]


PackageExport["SetReplace"]
PackageExport["$SetReplaceMethods"]


PackageScope["setReplaceRulesQ"]
PackageScope["stepCountQ"]


(* ::Section:: *)
(*Documentation*)


SetReplace::usage = usageString[
	"SetReplace[`s`, {\!\(\*SubscriptBox[\(`i`\), \(`1`\)]\) \[Rule] ",
	"\!\(\*SubscriptBox[\(`o`\), \(`1`\)]\), ",
	"\!\(\*SubscriptBox[\(`i`\), \(`2`\)]\) \[Rule] ",
	"\!\(\*SubscriptBox[\(`o`\), \(`2`\)]\), `\[Ellipsis]`}] attempts to replace a subset ",
	"\!\(\*SubscriptBox[\(`i`\), \(`1`\)]\) of list s with ",
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


SetReplace::setNotList = "The first argument of `` must be a List.";


SetReplace[set_, rules_, n : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] := 0 /;
	!ListQ[set] &&
	Message[SetReplace::setNotList, SetReplace]


(* ::Subsection:: *)
(*Rules are valid*)


SetReplace::invalidRules =
	"The second argument of `` must be either a Rule, RuleDelayed, or " ~~
	"a List of them.";


setReplaceRulesQ[rules_] :=
	MatchQ[rules, {(_Rule | _RuleDelayed)..} | _Rule | _RuleDelayed]


SetReplace[set_, rules_, n : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] := 0 /;
	!setReplaceRulesQ[rules] && Message[SetReplace::invalidRules, SetReplace]


(* ::Subsection:: *)
(*Step count is valid*)


SetReplace::nonIntegerIterations =
	"The third argument `2` of `1` must be an integer or infinity.";


stepCountQ[n_] := IntegerQ[n] && n >= 0 || n == \[Infinity]


SetReplace[set_, rules_, n : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] := 0 /;
	!stepCountQ[n] &&
	Message[SetReplace::nonIntegerIterations, SetReplace, n]


(* ::Subsection:: *)
(*Method is valid*)


SetReplace::invalidMethod =
	"Method should be one of " <> ToString[$SetReplaceMethods, InputForm] <> ".";


$cppMethod = "C++";
$wlMethod = "WolframLanguage";


$SetReplaceMethods = {Automatic, $cppMethod, $wlMethod};


SetReplace[set_, rules_, n : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] := 0 /;
	!MatchQ[OptionValue[Method], Alternatives @@ $SetReplaceMethods] &&
	Message[SetReplace::invalidMethod]


(* ::Section:: *)
(*Options*)


Options[SetReplace] = {Method -> Automatic};


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
(*SetReplace*)


(* ::Text:: *)
(*Switching code between WL and C++ implementations*)


SetReplace::cppNotImplemented =
	"C++ implementation is only available for local rules, " <>
	"and only for sets of lists (hypergraphs).";


SetReplace::cppInfinite =
	"C++ implementation is only available for finite step count.";


SetReplace::noCpp = "C++ implementation was not compiled for your system type.";


SetReplace[
				set_List,
				rules_ ? setReplaceRulesQ,
				n : Except[_ ? OptionQ] : 1,
				o : OptionsPattern[]] /;
			stepCountQ[n] := Module[{
		method = OptionValue[Method], canonicalRules, failedQ = False},
	canonicalRules = toCanonicalRules[rules];
	If[MatchQ[method, Automatic | "C++"]
			&& MatchQ[set, {{___ ? AtomQ}...}]
			&& MatchQ[canonicalRules, {___ ? simpleRuleQ}]
			&& IntegerQ[n],
		If[$cppSetReplaceAvailable,
			Return[setReplace$cpp[set, canonicalRules, n]]]];
	If[MatchQ[method, "C++"],
		failedQ = True;
		If[!$cppSetReplaceAvailable, Message[SetReplace::noCpp]];
		If[!IntegerQ[n], Message[SetReplace::cppInfinite]];
		If[$cppSetReplaceAvailable && IntegerQ[n],
			Message[SetReplace::cppNotImplemented]]];
	setReplace$wl[set, canonicalRules, n]
/; MatchQ[OptionValue[Method], Alternatives @@ $SetReplaceMethods] && !failedQ]
