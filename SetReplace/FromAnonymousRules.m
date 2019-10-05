(* ::Package:: *)

(* ::Title:: *)
(*FromAnonymousRules*)


(* ::Text:: *)
(*Anonymous rules make it easier to specify rules, especially when they involve creation of new vertices (objects). The idea is that in an anonymous rule all symbols on the left-hand side are treated as patterns even if they are explicitly named.*)


(* ::Text:: *)
(*Thus, for example, {{1, 2}}->{{1, 2, 3}} will get translated to {{a_, b_}} :> Module[{$0}, {{a, b, $0}}].*)


(* ::Text:: *)
(*The anonymous variant is easier to type, and, more importantly, easier to enumerate.*)


Package["SetReplace`"]


PackageExport["FromAnonymousRules"]


PackageScope["fromAnonymousRules"]


(* ::Section:: *)
(*Documentation*)


FromAnonymousRules::usage = usageString[
	"FromAnonymousRules[`r`] converts a list of anonymous rules `r` into a list of ",
	"rules that can be supplied into SetReplace.",
	"\n",
	"As an example, try FromAnonymousRules[{{{1, 2}} -> {{1, 2, 3}}}]."];


(* ::Section:: *)
(*Syntax Information*)


SyntaxInformation[FromAnonymousRules] = {"ArgumentsPattern" -> {_}};


(* ::Section:: *)
(*Argument Checks*)


(* ::Subsection:: *)
(*Argument count*)


FromAnonymousRules[args___] := 0 /;
	!Developer`CheckArgumentCount[FromAnonymousRules[args], 1, 1] && False


(* ::Subsection:: *)
(*Argument is a list of rules or a single rule*)


fromAnonymousRules[rules_, caller_] := 0 /;
	!MatchQ[rules, {___Rule} | _Rule] && makeMessage[caller, "notRules", rules]


(* ::Section:: *)
(*Implementation*)


(* ::Subsection:: *)
(*fromAnonymousRules*)


(* ::Text:: *)
(*We are going to find all non-lists in the rules, map them to symbols, and then replace original rules with these symbols using patterns and modules accordingly.*)


fromAnonymousRules[rule : _Rule, caller_] := Module[
		{leftSymbols, rightSymbols, symbols, newVertexNames, vertexPatterns,
		 newLeft, leftVertices, rightVertices, rightOnlyVertices},
	{leftSymbols, rightSymbols} =
		Union[Cases[#, _ ? AtomQ, 1], Cases[#, _, {2}]] & /@ List @@ rule;
	symbols = Union[leftSymbols, rightSymbols];
	newVertexNames =
		ToHeldExpression /@ StringTemplate["v``"] /@ Range @ Length @ symbols;
	vertexPatterns = Pattern[#, Blank[]] & /@ newVertexNames;
	newLeft = (rule[[1]] /. Thread[symbols -> vertexPatterns]);
	{leftVertices, rightVertices} =
		{leftSymbols, rightSymbols} /. Thread[symbols -> newVertexNames];
	rightOnlyVertices = Complement[rightVertices, leftVertices];
	With[
			{moduleVariables = rightOnlyVertices,
			moduleExpression = rule[[2]] /. Thread[symbols -> newVertexNames]},
		If[moduleVariables =!= {},
			newLeft :> Module[moduleVariables, moduleExpression],
			newLeft :> moduleExpression
		]
	] /. Hold[expr_] :> expr
]


fromAnonymousRules[rules : {___Rule}, caller_] :=
	fromAnonymousRules[#, caller] & /@ rules


(* ::Subsection:: *)
(*FromAnonymousRules*)


FromAnonymousRules[rules_] := Module[{result},
	result = Check[fromAnonymousRules[rules, FromAnonymousRules], $Failed];
	result /; result =!= $Failed
]
