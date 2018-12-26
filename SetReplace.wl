(* ::Package:: *)

(* ::Title:: *)
(*SetReplace*)


(* ::Section:: *)
(*Begin*)


(* ::Text:: *)
(*See on GitHub: https://github.com/maxitg/SetReplace.*)


BeginPackage["SetReplace`"];


SetReplace`Private`$PublicSymbols = {
	SetReplace, SetReplaceList, SetReplaceFixedPoint, SetReplaceFixedPointList,
	HypergraphPlot};


Unprotect @@ SetReplace`Private`$PublicSymbols;
ClearAll @@ SetReplace`Private`$PublicSymbols;


(* ::Section:: *)
(*Dependencies*)


(* ::Subsection:: *)
(*UsageString*)


Get["https://raw.githubusercontent.com/maxitg/WLUsageString/master/UsageString.wl"]


(* ::Section:: *)
(*Implementation*)


Begin["`Private`"];


(* ::Subsection:: *)
(*$ToNormalRules*)


(* ::Text:: *)
(*We are going to transform set substitution rules into a list of n! normal rules, where elements of the input subset are arranged in every possible order with blank null sequences in between.*)


(* ::Text:: *)
(*This is for the case of no new vertices being created, so there is no need for a Module in the output*)


$ToNormalRules[(input_List :> output_List) | (input_List -> output_List)] := Module[
		{inputLength, untouchedElements, untouchedPatterns,
		 inputPermutations, inputsWithUntouchedElements, outputWithUntouchedElements},
	inputLength = Length @ input;
	untouchedElements = Table[Unique[], inputLength + 1];
	untouchedPatterns = Pattern[#, ___] & /@ untouchedElements;

	inputPermutations = Permutations @ (List @@ input);
	inputsWithUntouchedElements = Riffle[untouchedPatterns, #] & /@ inputPermutations;
	outputWithUntouchedElements = Join[untouchedElements, List @@ output];

	# :> Evaluate @ outputWithUntouchedElements & /@ inputsWithUntouchedElements
] 


(* ::Text:: *)
(*Now, if there are new vertices that need to be created, we will disassemble the Module remembering which variables it applies to, and then reassemble it for the output.*)


$ToNormalRules[input_List :> output_Module] := With[
		{ruleInputOriginal = input,
		 moduleInputContents = Hold[output][[1, 2]]},
	With[{ruleInputFinal = #[[1]],
		  moduleArguments = Hold[output][[1, 1]],
		  moduleOutputContents = #[[2]]},
		ruleInputFinal :> Module[moduleArguments, moduleOutputContents]
	] & /@ $ToNormalRules[ruleInputOriginal :> Evaluate @ moduleInputContents]
]


(* ::Text:: *)
(*If input is not a list, we assume it is a single element set, so we put it into a single element list.*)


$ToNormalRules[(input_ :> output_) | (input_ -> output_)] /; !ListQ[input] :=
	$ToNormalRules[{input} :> output]


$ToNormalRules[(input_ :> output_) | (input_ -> output_)] /; !ListQ[output] :=
	$ToNormalRules[input :> {output}]


(* ::Text:: *)
(*If there are multiple rules, we just join them*)


$ToNormalRules[rules_List] := Join @@ $ToNormalRules /@ rules


(* ::Subsection:: *)
(*SetReplace*)


(* ::Text:: *)
(*Now, we can use that to implement SetReplace*)


(* ::Subsubsection:: *)
(*Documentation*)


SetReplace::usage = UsageString[
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


(* ::Subsubsection:: *)
(*Syntax*)


SyntaxInformation[SetReplace] = {"ArgumentsPattern" -> {_, _, _.}};


SetReplace[args___] := 0 /;
	!Developer`CheckArgumentCount[SetReplace[args], 2, 3] && False


SetReplace::setNotList = "The first argument of `` must be a List.";
SetReplace[set_, rules_, n_] := 0 /; !ListQ[set] &&
	Message[SetReplace::setNotList, SetReplace]
SetReplace[set_, rules_] := 0 /; !ListQ[set] &&
	Message[SetReplace::setNotList, SetReplace]


$SetReplaceRulesQ[rules_] :=
	MatchQ[rules, {(_Rule | _RuleDelayed)..} | _Rule | _RuleDelayed]
SetReplace::invalidRules =
	"The second argument of `` must be either a Rule, RuleDelayed, or " ~~
	"a List of them.";
SetReplace[set_, rules_, n_] := 0 /;
	!$SetReplaceRulesQ[rules] && Message[SetReplace::invalidRules, SetReplace]
SetReplace[set_, rules_] := 0 /;
	!$SetReplaceRulesQ[rules] && Message[SetReplace::invalidRules, SetReplace]


$StepCountQ[n_] := IntegerQ[n] && n >= 0 || n == \[Infinity]
SetReplace::nonIntegerIterations =
	"The third argument `2` of `1` must be an integer or infinity.";
SetReplace[set_, rules_, n_] := 0 /; !$StepCountQ[n] &&
	Message[SetReplace::nonIntegerIterations, SetReplace, n]


(* ::Subsubsection:: *)
(*Implementation*)


SetReplace[
		set_List,
		rules_ ? $SetReplaceRulesQ,
		n_ ? $StepCountQ] :=
	Quiet[
		ReplaceRepeated[List @@ set, $ToNormalRules @ rules, MaxIterations -> n],
		ReplaceRepeated::rrlim]


SetReplace[set_List, rules_ ? $SetReplaceRulesQ] := SetReplace[set, rules, 1]


(* ::Subsection:: *)
(*SetReplaceList*)


(* ::Text:: *)
(*Same as SetReplace, but returns all intermediate steps in a List.*)


(* ::Subsubsection:: *)
(*Documentation*)


SetReplaceList::usage = UsageString[
	"SetReplaceList[`s`, {\!\(\*SubscriptBox[\(`i`\), \(`1`\)]\) \[Rule] ",
	"\!\(\*SubscriptBox[\(`o`\), \(`1`\)]\), ",
	"\!\(\*SubscriptBox[\(`i`\), \(`2`\)]\) \[Rule] ",
	"\!\(\*SubscriptBox[\(`o`\), \(`2`\)]\), \[Ellipsis]}, `n`] performs SetReplace `n` times ",
	"and returns the list of all intermediate results."];


(* ::Subsubsection:: *)
(*Syntax*)


SyntaxInformation[SetReplaceList] = {"ArgumentsPattern" -> {_, _, _}};


SetReplaceList[args___] := 0 /;
	!Developer`CheckArgumentCount[SetReplaceList[args], 3, 3] && False


SetReplaceList[set_, rules_, n_] := 0 /; !ListQ[set] &&
	Message[SetReplace::setNotList, SetReplaceList]


SetReplaceList[set_, rules_, n_] := 0 /;
	!$SetReplaceRulesQ[rules] && Message[SetReplace::invalidRules, SetReplaceList]


SetReplaceList[set_, rules_, n_] := 0 /; !$StepCountQ[n] &&
	Message[SetReplace::nonIntegerIterations, SetReplaceList, n]


(* ::Subsubsection:: *)
(*Implementation*)


SetReplaceList[set_List, rules_ ? $SetReplaceRulesQ, n_ ? $StepCountQ] :=
	FixedPointList[Replace[#, $ToNormalRules @ rules] &, set, n]


(* ::Subsection:: *)
(*SetReplaceFixedPoint*)


(* ::Text:: *)
(*Same as SetReplace, but automatically stops replacing when the set no longer changes.*)


(* ::Subsubsection:: *)
(*Documentation*)


SetReplaceFixedPoint::usage = UsageString[
	"SetReplaceFixedPoint[`s`, {\!\(\*SubscriptBox[\(`i`\), \(`1`\)]\) \[Rule] ",
	"\!\(\*SubscriptBox[\(`o`\), \(`1`\)]\), ",
	"\!\(\*SubscriptBox[\(`i`\), \(`2`\)]\) \[Rule] ",
	"\!\(\*SubscriptBox[\(`o`\), \(`2`\)]\), \[Ellipsis]}] performs SetReplace repeatedly ",
	"until the set no longer changes, and returns the final set.",
	"\n",
	"Fixed point requires not only the elements, but also the order of elements to be ",
	"fixed. Will go into infinite loop if fixed point does not exist."];


(* ::Subsubsection:: *)
(*Syntax*)


SyntaxInformation[SetReplaceFixedPoint] = {"ArgumentsPattern" -> {_, _}};


SetReplaceFixedPoint[args___] := 0 /;
	!Developer`CheckArgumentCount[SetReplaceFixedPoint[args], 2, 2] && False


SetReplaceFixedPoint[set_, rules_] := 0 /; !ListQ[set] &&
	Message[SetReplace::setNotList, SetReplaceFixedPoint]


SetReplaceFixedPoint[set_, rules_] := 0 /; !$SetReplaceRulesQ[rules] &&
	Message[SetReplace::invalidRules, SetReplaceFixedPoint]


(* ::Subsubsection:: *)
(*Implementation*)


SetReplaceFixedPoint[set_List, rules_ ? $SetReplaceRulesQ] := SetReplace[set, rules, \[Infinity]]


(* ::Subsection:: *)
(*SetReplaceFixedPointList*)


(* ::Text:: *)
(*Same as SetReplaceFixedPoint, but returns all intermediate steps.*)


(* ::Subsubsection:: *)
(*Documentation*)


SetReplaceFixedPointList::usage = UsageString[
	"SetReplaceFixedPointList[`s`, {\!\(\*SubscriptBox[\(`i`\), \(`1`\)]\) \[Rule] ",
	"\!\(\*SubscriptBox[\(`o`\), \(`1`\)]\), ",
	"\!\(\*SubscriptBox[\(`i`\), \(`2`\)]\) \[Rule] ",
	"\!\(\*SubscriptBox[\(`o`\), \(`2`\)]\), \[Ellipsis]}] performs SetReplace repeatedly ",
	"until the set no longer changes, and returns the list of all intermediate sets."];


(* ::Subsubsection:: *)
(*Syntax*)


SyntaxInformation[SetReplaceFixedPointList] = {"ArgumentsPattern" -> {_, _}};


SetReplaceFixedPointList[args___] := 0 /;
	!Developer`CheckArgumentCount[SetReplaceFixedPointList[args], 2, 2] && False


SetReplaceFixedPointList[set_, rules_] := 0 /; !ListQ[set] &&
	Message[SetReplace::setNotList, SetReplaceFixedPointList]


SetReplaceFixedPointList[set_, rules_] := 0 /; !$SetReplaceRulesQ[rules] &&
	Message[SetReplace::invalidRules, SetReplaceFixedPointList]


(* ::Subsubsection:: *)
(*Implementation*)


SetReplaceFixedPointList[set_List, rules_ ? $SetReplaceRulesQ] :=
	SetReplaceList[set, rules, \[Infinity]]


(* ::Subsection:: *)
(*HypergraphPlot*)


(* ::Text:: *)
(*We might want to visualize the list-elements of the set as directed hyperedges. We can do that by drawing each hyperedge as sequences of same-color normal 2-edges.*)


(* ::Text:: *)
(*We will have to work around the bug in Wolfram Language that prevents multi-edges appear in different colors regardless of their different styles.*)


(* ::Subsubsection:: *)
(*Documentation*)


HypergraphPlot::usage = UsageString[
	"HypergraphPlot[`s`, `opts`] plots a list of vertex lists `s` as a ",
	"hypergraph with each hyperedge represented as a sequence of same-color arrows. ",
	"Graph options `opts` can be used."];


Options[HypergraphPlot] = Join[Options[Graph], {PlotStyle -> ColorData[97]}];


(* ::Subsubsection:: *)
(*Syntax*)


SyntaxInformation[HypergraphPlot] = {"ArgumentsPattern" -> {_, OptionsPattern[]}};


HypergraphPlot[args___] := 0 /;
	!Developer`CheckArgumentCount[HypergraphPlot[args], 1, 1] && False


HypergraphPlot::invalidEdges =
	"First argument of HypergraphPlot must be list of lists, where elements " ~~
	"represent vertices."; 


HypergraphPlot[edges_, o : OptionsPattern[]] := 0 /;
	!MatchQ[edges, {___List}] && Message[HypergraphPlot::invalidEdges]


$CorrectOptions[HypergraphPlot][o___] := Module[
		{plotStyle = OptionValue[HypergraphPlot, {o}, PlotStyle]},
	Head[plotStyle] === ColorDataFunction &&
	plotStyle[[2]] === "Indexed"
]


HypergraphPlot::unsupportedPlotStyle =
	"Only indexed ColorDataFunction, i.e., ColorData[n] is supported as a plot style.";


HypergraphPlot[edges : {___List}, o : OptionsPattern[]] := 0 /;
	!$CorrectOptions[HypergraphPlot][o] &&
	Message[HypergraphPlot::unsupportedPlotStyle]


(* ::Subsubsection:: *)
(*Implementation*)


(* ::Text:: *)
(*The idea here is that we are going to draw Graph first while substituting EdgeShapeFunction with a function that collects edge shapes, and produces edge -> hash mapping.*)


(* ::Text:: *)
(*We can then use that to produce hash -> color association, which we use to properly color the edges.*)


HypergraphPlot[edges : {___List}, o : OptionsPattern[]] /;
	$CorrectOptions[HypergraphPlot][o] := Module[
		{normalEdges, edgeColors, shapeHashes, hashesToColors},
	normalEdges = Partition[#, 2, 1] & /@ edges;
	edgeColors = Sort @ Flatten @ MapIndexed[
		Thread[DirectedEdge @@@ #1 -> OptionValue[PlotStyle][#2[[1]]]] &, normalEdges];
	shapeHashes = Sort @ First @ Last @ Reap @ Rasterize @ Graph[
		DirectedEdge @@@ Flatten[normalEdges, 1], Join[{
			EdgeShapeFunction -> (Sow[#2 -> Hash[#1]] &)},
			FilterRules[{o}, Options[Graph]]]];
	hashesToColors =
		Association @ Thread[shapeHashes[[All, 2]] -> edgeColors[[All, 2]]];
	Graph[DirectedEdge @@@ Flatten[normalEdges, 1], Join[
		FilterRules[{o}, Options[Graph]],
		{EdgeShapeFunction -> ({hashesToColors[Hash[#1]], Line[#1]} &)}]]
]


(* ::Section:: *)
(*End*)


Protect @@ SetReplace`Private`$PublicSymbols;


End[];


EndPackage[];
