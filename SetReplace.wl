(* ::Package:: *)

(* ::Title:: *)
(*SetReplace*)


(* ::Section:: *)
(*Begin*)


(* ::Text:: *)
(*See on GitHub: https://github.com/maxitg/SetReplace.*)


BeginPackage["SetReplace`", {"UsageString`"}];


SetReplace`Private`$PublicSymbols = {
	SetReplace, SetReplaceList, SetReplaceFixedPoint, SetReplaceFixedPointList,
	SetReplaceAll, FromAnonymousRules, HypergraphPlot};


Unprotect @@ SetReplace`Private`$PublicSymbols;
ClearAll @@ SetReplace`Private`$PublicSymbols;


(* ::Section:: *)
(*Implementation*)


Begin["`Private`"];


(* ::Subsection:: *)
(*Load C++ library*)


$libraryDirectory =
	FileNameJoin[{DirectoryName[$InputFileName], "LibraryResources", $SystemID}];
If[Not @ MemberQ[$LibraryPath, $libraryDirectory],
	PrependTo[$LibraryPath, $libraryDirectory]
]


(* ::Subsection:: *)
(*$ToNormalRules*)


(* ::Text:: *)
(*We are going to transform set substitution rules into a list of n! normal rules, where elements of the input subset are arranged in every possible order with blank null sequences in between.*)


(* ::Text:: *)
(*This is for the case of no new vertices being created, so there is no need for a Module in the output*)


ClearAll[$ToNormalRules];


$ToNormalRules[(input_List :> output_List) | (input_List -> output_List)] := Module[
		{inputLength, untouchedElements, untouchedPatterns,
		 inputPermutations, inputsWithUntouchedElements, outputWithUntouchedElements},
	inputLength = Length @ input;
	untouchedElements = Table[Unique[], inputLength + 1];
	untouchedPatterns = Pattern[#, ___] & /@ untouchedElements;

	inputPermutations = Permutations @ input;
	inputsWithUntouchedElements = Riffle[untouchedPatterns, #] & /@ inputPermutations;
	outputWithUntouchedElements = Join[untouchedElements, Thread @ Hold @ output];

	With[{right = outputWithUntouchedElements},
		# :> right & /@ inputsWithUntouchedElements] /. Hold[expr_] :> expr
] 


(* ::Text:: *)
(*Now, if there are new vertices that need to be created, we will disassemble the Module remembering which variables it applies to, and then reassemble it for the output.*)


$ToNormalRules[input_List :> output_Module] := Module[
		{ruleInputOriginal = input,
		 heldModule = Map[Hold, Hold[output], {2}],
		 moduleInputContents},
	moduleInputContents = heldModule[[1, 2]];
	With[{ruleInputFinal = #[[1]],
		  moduleArguments = heldModule[[1, 1]],
		  moduleOutputContents = (Hold /@ #)[[2]]},
		ruleInputFinal :> Module[moduleArguments, moduleOutputContents]
	] & /@ $ToNormalRules[
			ruleInputOriginal :> Evaluate @ moduleInputContents /.
				Hold[expr_] :> expr] //.
		Hold[expr_] :> expr
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
SetReplace[set_, rules_, n_: 0] := 0 /; !ListQ[set] &&
	Message[SetReplace::setNotList, SetReplace]


ClearAll[$SetReplaceRulesQ];
$SetReplaceRulesQ[rules_] :=
	MatchQ[rules, {(_Rule | _RuleDelayed)..} | _Rule | _RuleDelayed]
SetReplace::invalidRules =
	"The second argument of `` must be either a Rule, RuleDelayed, or " ~~
	"a List of them.";
SetReplace[set_, rules_, n_: 0] := 0 /;
	!$SetReplaceRulesQ[rules] && Message[SetReplace::invalidRules, SetReplace]


ClearAll[$StepCountQ];
$StepCountQ[n_] := IntegerQ[n] && n >= 0 || n == \[Infinity]
SetReplace::nonIntegerIterations =
	"The third argument `2` of `1` must be an integer or infinity.";
SetReplace[set_, rules_, n_] := 0 /; !$StepCountQ[n] &&
	Message[SetReplace::nonIntegerIterations, SetReplace, n]


(* ::Subsubsection:: *)
(*Implementation*)


SetReplace[set_List, rules_ ? $SetReplaceRulesQ, n_: 1] /; $StepCountQ[n] :=
	Quiet[
		ReplaceRepeated[List @@ set, $ToNormalRules @ rules, MaxIterations -> n],
		ReplaceRepeated::rrlim]


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


ClearAll[$CorrectOptions];
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
		{normalEdges, edgeColors, shapeHashes, hashesToColors,
		 graphEdges, graphOptions, graphBoxes, arrowheads, arrowheadOffset},
	normalEdges = Partition[#, 2, 1] & /@ edges;
	edgeColors = Sort @ Flatten @ MapIndexed[
		Thread[DirectedEdge @@@ #1 -> OptionValue[PlotStyle][#2[[1]]]] &, normalEdges];
	graphEdges = DirectedEdge @@@ Flatten[normalEdges, 1];
	graphOptions = FilterRules[{o}, Options[Graph]];
	shapeHashes = Sort @ (If[# == {}, {}, #[[1]]] &) @ Last @ Reap @ Rasterize @
		Graph[graphEdges, Join[{
			EdgeShapeFunction -> (Sow[#2 -> Hash[#1]] &)},
			graphOptions]];
	graphBoxes = ToBoxes[Graph[graphEdges, DirectedEdges -> True]];
	arrowheads =
		If[Length[#] == 0, {}, #[[1]]] & @ Cases[graphBoxes, _Arrowheads, All];
	arrowheadOffset = If[Length[#] == 0, 0, #[[1]]] & @
		Cases[graphBoxes, ArrowBox[x_, offset_] :> offset, All];
	hashesToColors =
		Association @ Thread[shapeHashes[[All, 2]] -> edgeColors[[All, 2]]];
	Graph[graphEdges, Join[
		graphOptions,
		{EdgeShapeFunction -> ({
			arrowheads,
			hashesToColors[Hash[#1]],
			Arrow[#1, arrowheadOffset]} &),
		 If[arrowheadOffset > 0, Nothing, VertexShapeFunction -> Point]}]]
]


(* ::Subsection:: *)
(*FromAnonymousRules*)


(* ::Text:: *)
(*The reason for anonymous rules is to make it simpler to specify rules, especially when they involve creation of new vertices (objects). The idea is that in an anonymous rule all symbols on the left-hand side are treated as patterns even if they are explicitly named.*)


(* ::Text:: *)
(*Thus, for example, {{1, 2}}->{{1, 2, 3}} will get translated to {{a_, b_}} :> Module[{$0}, {{a, b, $0}}].*)


(* ::Text:: *)
(*Clearly, the anonymous variant is easier to type, and, more importantly, easier to enumerate.*)


(* ::Subsubsection:: *)
(*Documentation*)


FromAnonymousRules::usage = UsageString[
	"FromAnonymousRules[`r`] converts a list of anonymous rules `r` into a list of ",
	"rules that can be supplied into SetReplace.",
	"\n",
	"As an example, try FromAnonymousRules[{{{1, 2}} -> {{1, 2, 3}}}]."];


(* ::Subsubsection:: *)
(*Syntax*)


SyntaxInformation[FromAnonymousRules] = {"ArgumentsPattern" -> {_}};


FromAnonymousRules[args___] := 0 /;
	!Developer`CheckArgumentCount[FromAnonymousRules[args], 1, 1] && False


FromAnonymousRules::notRules =
	"First argument of FromAnonymousRules must be either a Rule or a list of rules.";


FromAnonymousRules[rules_] := 0 /;
	!MatchQ[rules, {___Rule} | _Rule] && Message[FromAnonymousRules::notRules]


(* ::Subsubsection:: *)
(*Implementation*)


(* ::Text:: *)
(*We are going to find all non-lists in the rules, map them to symbols, and then replace original rules with these symbols using patterns and modules accordingly.*)


FromAnonymousRules[rule : _Rule] := Module[
		{leftSymbols, rightSymbols, symbols, newVertexNames, vertexPatterns,
		 newLeft, leftVertices, rightVertices, rightOnlyVertices},
	{leftSymbols, rightSymbols} = Union @ Cases[#, _ ? AtomQ, All] & /@ List @@ rule;
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


FromAnonymousRules[rules : {___Rule}] := FromAnonymousRules /@ rules


(* ::Subsection:: *)
(*$ToCanonicalRules*)


(* ::Text:: *)
(*There are multiple ways SetReplace rules can be expressed, which is mostly manifested by missing lists in various places. Specifically, we could have either a single rule, or a list of rules. Then, inputs / outputs of every rules might either have a single element or a subset. The idea of this function is to ensure two things: (1) we have a list (even if a single-element) of rules, and (2) each rule goes from a list to another list.*)


ClearAll[$ToCanonicalRules];
SetAttributes[$ToCanonicalRules, HoldAll];


$ToCanonicalRules[r : (_Rule | _RuleDelayed)] := $ToCanonicalRules[{r}]


$ToCanonicalRules[rules : {(_Rule | _RuleDelayed)..}] := $ToCanonicalRule /@ rules


ClearAll[$ToCanonicalRule];
SetAttributes[$ToCanonicalRule, HoldAll];


$ToCanonicalRule[(left_ -> right_) | (left_ :> right_)] := With[
		{newLeft = $ToCanonicalRuleSide[left], newRight = $ToCanonicalRuleSide[right]},
	newLeft :> newRight
] //. Hold[expr_] :> expr


ClearAll[$ToCanonicalRuleSide];
SetAttributes[$ToCanonicalRuleSide, HoldAll];


$ToCanonicalRuleSide[expr_ : Except[_List | _Module]] := {expr}


$ToCanonicalRuleSide[expr_List] := expr


$ToCanonicalRuleSide[Module[args_, set_ ? (Not @* ListQ)]] := Hold @ Module[args, {set}]


$ToCanonicalRuleSide[Module[args_, set_List]] := Hold @ Module[args, set]


(* ::Subsection:: *)
(*SetReplaceAll*)


(* ::Text:: *)
(*The idea for SetReplaceAll is to keep performing SetReplace on the graph until no replacement can be done without touching the same edge twice.*)


(* ::Text:: *)
(*Note, it's not doing replacement until all edges are touched at least once. That may not always be possible. We just don't want to touch edges twice in a single step.*)


(* ::Subsubsection:: *)
(*Documentation*)


SetReplaceAll::usage = UsageString[
	"SetReplaceAll[`s`, `r`] performs SetReplace[`s`, `r`] as many times as it takes ",
	"until no replacement can be done without touching the same edge twice.",
	"\n",
	"SetReplaceAll[`s`, `r`, `n`] performes the same operation `n` times, i.e., any ",
	"edge will at most be replaced `n` times."];


(* ::Subsubsection:: *)
(*Syntax*)


SyntaxInformation[SetReplaceAll] = {"ArgumentsPattern" -> {_, _, _.}};


SetReplaceAll[args___] := 0 /;
	!Developer`CheckArgumentCount[SetReplaceAll[args], 2, 3] && False


SetReplaceAll[set_, rules_, n_: 0] := 0 /; !ListQ[set] &&
	Message[SetReplace::setNotList, SetReplaceAll]


SetReplaceAll[set_, rules_, n_: 0] := 0 /;
	!$SetReplaceRulesQ[rules] && Message[SetReplace::invalidRules, SetReplaceAll]


SetReplaceAll[set_, rules_, n_] := 0 /; !$StepCountQ[n] &&
	Message[SetReplace::nonIntegerIterations, SetReplaceAll, n]


(* ::Subsubsection:: *)
(*Implementation*)


(* ::Text:: *)
(*The idea here is to replace each element of the set, and each element of rules input with something like touched[original, False], and replace every element of the rules output with touched[original, True]. This way, rules can no longer be applied on the previous output. Then, we can call SetReplaceFixedPoint on that, which will take care of evaluating until everything is fixed.*)


SetReplaceAll[set_List, rules_ ? $SetReplaceRulesQ] := Module[
		{canonicalRules, setUntouched, singleUseRules},
	canonicalRules = $ToCanonicalRules[rules];
	setUntouched = $Untouched /@ set;
	singleUseRules = $ToSingleUseRule /@ canonicalRules;
	SetReplaceFixedPoint[setUntouched, singleUseRules] /.
		{$Touched[expr_] :> expr, $Untouched[expr_] :> expr}
]


ClearAll[$ToSingleUseRule];
$ToSingleUseRule[left_ :> right_] := With[
		{newLeft = $Untouched /@ left, newRight = $ToTouched @ right},
	(newLeft :> newRight) //. Hold[expr_] :> expr
]


ClearAll[$ToTouched];
SetAttributes[$ToTouched, HoldAll];


$ToTouched[expr_List] := $Touched /@ Hold /@ expr


$ToTouched[expr_Module] := With[
		{heldModule = Map[Hold, Hold @ expr, {3}]},
	With[{
			moduleVariables = heldModule[[1, 1]],
			moduleExpression = $Touched /@ heldModule[[1, 2]]},
		Hold[Module[moduleVariables, moduleExpression]]
	]
]


(* ::Text:: *)
(*If multiple steps are requested, we just use Nest.*)


SetReplaceAll[set_List, rules_ ? $SetReplaceRulesQ, n_Integer ? $StepCountQ] :=
	Nest[SetReplaceAll[#, rules] &, set, n]


(* ::Text:: *)
(*If infinite number of steps is requested, we simply do SetReplaceFixedPoint, because that would yield the same result.*)


SetReplaceAll[set_List, rules_ ? $SetReplaceRulesQ, \[Infinity]] :=
	SetReplaceFixedPoint[set, rules]


(* ::Section:: *)
(*End*)


Protect @@ SetReplace`Private`$PublicSymbols;


End[];


EndPackage[];
