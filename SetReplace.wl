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
	SetReplaceAll, FromAnonymousRules, HypergraphPlot};


Unprotect @@ SetReplace`Private`$PublicSymbols;
ClearAll @@ SetReplace`Private`$PublicSymbols;


(* ::Section:: *)
(*Implementation*)


Begin["`Private`"];


(* ::Subsection:: *)
(*$UsageString*)


$ArgStyle[arg_Integer] := "TR";
$ArgStyle["\[Ellipsis]"] := "TR";
$ArgStyle[str_String] := "TI";


$ArgString[arg_] :=
	"\!\(\*StyleBox[\"" <> ToString[arg] <> "\", \"" <> $ArgStyle[arg] <> "\"]\)"


$UsageString[str__] :=
	(StringTemplate[StringJoin[{str}]] /. {TemplateSlot[s_] :> $ArgString[s]})[]


(* ::Subsection:: *)
(*Load C++ library*)


$libraryDirectory =
	FileNameJoin[{DirectoryName[$InputFileName], "LibraryResources", $SystemID}];
If[Not @ MemberQ[$LibraryPath, $libraryDirectory],
	PrependTo[$LibraryPath, $libraryDirectory]
];


$cpp$setReplace = LibraryFunctionLoad[
	FindLibrary["libSetReplace"],
	"setReplace",
	{{Integer, 1}, {Integer, 1}, Integer},
	{Integer, 1}];


(* ::Text:: *)
(*The following code turns a nested list into a single list, prepending sizes of each sublist. I.e., {{a}, {b, c, d}} becomes {2, 1, a, 3, b, c, d}, where the first 2 is the length of the entire list, and 1 and 3 are the lengths of sublists.*)


(* ::Text:: *)
(*This format is used to pass both rules and set data into libSetReplace over LibraryLink*)


ClearAll[$encodeNestedLists];
$encodeNestedLists[list_List] :=
		{list} //. {{l___, List[args___], r___} :> {l, Length[{args}], args, r}}


(* ::Text:: *)
(*This is the reverse, used to decode set data (a list of hyperedges) from libSetReplace*)


ClearAll[$readList];
$readList[list_, index_] := Module[{count = list[[index]]},
	Sow[list[[index + 1 ;; index + count]]];
	index + count + 1
]


ClearAll[$decodeListOfLists];
$decodeListOfLists[{0}] := {}
$decodeListOfLists[list_List] := Reap[Nest[$readList[list, #] &, 2, list[[1]]]][[2, 1]]


(* ::Subsection:: *)
(*$ToCanonicalRules*)


(* ::Text:: *)
(*Rules can be specified in various ways, in particular, single rule instead of a list, with or without a module, etc. This function is needed to standardize that:*)
(*(1) Rules should always be specified as a list of rules instead of a single rule*)
(*(2) RuleDelayed should be used instead of Rule*)
(*(3) Module should be used on the right-hand side of the rule, even if with the empty first argument*)
(*(4) Left- and right-hand side of the rules should explicitly be lists, possibly specifying sets of a single element*)


ClearAll[$ToCanonicalRules, $ToCanonicalRule];


(* ::Text:: *)
(*If there is a single rule, we put it in a list*)


$ToCanonicalRules[rules_List] := $ToCanonicalRule /@ rules


$ToCanonicalRules[rule : Except[_List]] := $ToCanonicalRules[{rule}]


(* ::Text:: *)
(*Force RuleDelayed*)


$ToCanonicalRule[input_ -> output_] := $ToCanonicalRule[input :> output]


(* ::Text:: *)
(*Force Module*)


$ToCanonicalRule[input_ :> output : Except[_Module]] :=
	$ToCanonicalRule[input :> Module[{}, output]]


(* ::Text:: *)
(*If input or output are not lists, we assume it is a single element set, so we put it into a single element list.*)


$ToCanonicalRule[input_ :> output_] /; !ListQ[input] :=
	$ToCanonicalRule[{input} :> output]


$ToCanonicalRule[input_ :> Module[vars_List, expr : Except[_List]]] :=
	input :> Module[vars, {expr}]


(* ::Text:: *)
(*After all of that's done, drop $ToCanonicalRule*)


$ToCanonicalRule[input_ :> Module[vars_List, expr_List]] := input :> Module[vars, expr]


(* ::Subsection:: *)
(*$ToNormalRules*)


(* ::Text:: *)
(*We are going to transform set substitution rules into a list of n! normal rules, where elements of the input subset are arranged in every possible order with blank null sequences in between.*)


(* ::Text:: *)
(*This is for the case of no new vertices being created, so there is no need for a Module in the output*)


ClearAll[$ToNormalRules];


$ToNormalRules[input_List :> output_List] := Module[
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
(*If there are multiple rules, we just join them*)


$ToNormalRules[rules_List] := Join @@ $ToNormalRules /@ rules


(* ::Subsection:: *)
(*SetReplace*)


(* ::Text:: *)
(*Now, we can use that to implement SetReplace*)


(* ::Subsubsection:: *)
(*Documentation*)


SetReplace::usage = $UsageString[
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


SyntaxInformation[SetReplace] = {"ArgumentsPattern" -> {_, _, _., OptionsPattern[]}};


SetReplace[args___] := 0 /;
	!Developer`CheckArgumentCount[SetReplace[args], 2, 3] && False


SetReplace::setNotList = "The first argument of `` must be a List.";
SetReplace[set_, rules_, n : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] := 0 /;
	!ListQ[set] &&
	Message[SetReplace::setNotList, SetReplace]


ClearAll[$SetReplaceRulesQ];
$SetReplaceRulesQ[rules_] :=
	MatchQ[rules, {(_Rule | _RuleDelayed)..} | _Rule | _RuleDelayed]
SetReplace::invalidRules =
	"The second argument of `` must be either a Rule, RuleDelayed, or " ~~
	"a List of them.";
SetReplace[set_, rules_, n : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] := 0 /;
	!$SetReplaceRulesQ[rules] && Message[SetReplace::invalidRules, SetReplace]


ClearAll[$StepCountQ];
$StepCountQ[n_] := IntegerQ[n] && n >= 0 || n == \[Infinity]
SetReplace::nonIntegerIterations =
	"The third argument `2` of `1` must be an integer or infinity.";
SetReplace[set_, rules_, n : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] := 0 /;
	!$StepCountQ[n] &&
	Message[SetReplace::nonIntegerIterations, SetReplace, n]


$cppMethod = "C++";
$wlMethod = "WolframLanguage";


$setReplaceMethods = {Automatic, $cppMethod, $wlMethod};


SetReplace::invalidMethod =
	"Method should be one of " <> ToString[$setReplaceMethods, InputForm] <> ".";


SetReplace[set_, rules_, n : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] := 0 /;
	!MatchQ[OptionValue[Method], Alternatives @@ $setReplaceMethods] &&
	Message[SetReplace::invalidMethod]


(* ::Subsubsection:: *)
(*Implementation choice*)


$slowImplementationMessage =
	"Slow Wolfram Language implementation will be used instead.";


SetReplace::cppNotImplemented =
	"C++ implementation is only available for local rules, " <>
	"and only for sets of lists (hypergraphs). " <>
	$slowImplementationMessage;


SetReplace::cppInfinite =
	"C++ implementation is only available for finite step count.";


SetReplace::noCpp =
	"C++ implementation was not compiled for your system type. " <>
	$slowImplementationMessage;


Options[SetReplace] = {Method -> Automatic};


SetReplace[
				set_List,
				rules_ ? $SetReplaceRulesQ,
				n : Except[_ ? OptionQ] : 1,
				o : OptionsPattern[]] /;
			$StepCountQ[n] := Module[{
		method = OptionValue[Method], canonicalRules},
	canonicalRules = $ToCanonicalRules[rules];
	If[MatchQ[method, Automatic | "C++"]
			&& MatchQ[set, {{___ ? AtomQ}...}]
			&& MatchQ[canonicalRules, {___ ? $SimpleRuleQ}]
			&& IntegerQ[n],
		If[$SetReplace$cpp === $Failed,
			Message[SetReplace::noCpp],
			Return[$SetReplace$cpp[set, canonicalRules, n]]]];
	If[MatchQ[method, "C++"],
		If[IntegerQ[n],
			Message[SetReplace::cppNotImplemented],
			Message[SetReplace::cppInfinite]]];
	$SetReplace$wl[set, canonicalRules, n]
] /; MatchQ[OptionValue[Method], Alternatives @@ $setReplaceMethods]


(* ::Subsubsection:: *)
(*WL Implementation*)


ClearAll[$SetReplace$wl];
$SetReplace$wl[set_, rules_, n_] := Quiet[
	ReplaceRepeated[List @@ set, $ToNormalRules @ rules, MaxIterations -> n],
	ReplaceRepeated::rrlim]


(* ::Subsubsection:: *)
(*C++ Implementation*)


(* ::Text:: *)
(*Check if we have simple anonymous rules and use C++ library in that case*)


ClearAll[$SimpleRuleQ];


$SimpleRuleQ[
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


$SimpleRuleQ[left_ :> right : Except[_Module]] :=
	$SimpleRuleQ[left :> Module[{}, right]]


$SimpleRuleQ[___] := False


ClearAll[$RuleAtoms];


$RuleAtoms[left_ :> right : Except[_Module]] :=
	$RuleAtoms[left :> Module[{}, right]]


$RuleAtoms[left_ :> right_Module] := Module[{
		leftVertices, patterns, leftAtoms, patternSymbols, createdAtoms, rightAtoms},
	leftVertices = Union @ Flatten[left];
	leftAtoms = Select[leftVertices, AtomQ];
	patterns = Complement[leftVertices, leftAtoms];
	patternSymbols = Map[Hold, patterns, {2}][[All, 1]];
	createdAtoms = Map[Hold, Hold[right], {3}][[1, 1]];
	rightAtoms = Complement[
		Union @ Flatten @ Map[Hold, Hold[right], {4}][[1, 2]],
		Join[patternSymbols, createdAtoms]];
	(* {global, local} *)
	{Union @ Join[Hold /@ leftAtoms, rightAtoms],
		Union @ Join[patternSymbols, createdAtoms]}
]


ClearAll[$RuleAtomsToIndices];


$RuleAtomsToIndices[left_ :> right : Except[_Module], globalIndex_, localIndex_] :=
	$RuleAtomsToIndices[left :> Module[{}, right], globalIndex, localIndex]


$RuleAtomsToIndices[left_ :> right_Module, globalIndex_, localIndex_] := Module[{
		newLeft, newRight},
	newLeft = Replace[
		left,
		{x_ ? AtomQ :> globalIndex[Hold[x]],
			x_Pattern :> localIndex[Map[Hold, x, {1}][[1]]]},
		{2}];
	newRight = Replace[
		Map[Hold, Hold[right], {4}][[1, 2]],
		x_ :> Lookup[localIndex, x, globalIndex[x]],
		{2}];
	newLeft -> newRight
]


ClearAll[$SetReplace$cpp];
$SetReplace$cpp[
			set : {{___ ? AtomQ}...},
			rules : {___ ? $SimpleRuleQ},
			n_] /; $SetReplace$cpp =!= $Failed := Module[{
		setAtoms, ruleAtoms, globalAtoms, globalIndex,
		mappedSet, localIndices, mappedRules, cppOutput, resultAtoms,
		inversePartialGlobalMap, inverseGlobalMap},
	setAtoms = Hold /@ Union[Flatten[set]];
	ruleAtoms = $RuleAtoms /@ rules;
	globalAtoms = Union @ Flatten @ {setAtoms, ruleAtoms[[All, 1]]};
	globalIndex = Association @ Thread[globalAtoms -> Range[Length[globalAtoms]]];
	mappedSet = Map[globalIndex, Map[Hold, set, {2}], {2}];
	localIndices =
		Association @ Thread[#[[2]] -> - Range[Length[#[[2]]]]] & /@ ruleAtoms;
	mappedRules = Table[
		$RuleAtomsToIndices[
			rules[[K]],
			globalIndex,
			localIndices[[K]]],
		{K, Length[rules]}];
	cppOutput = $decodeListOfLists @ $cpp$setReplace[
		$encodeNestedLists[List @@@ mappedRules],
		$encodeNestedLists[mappedSet],
		n];
	resultAtoms = Union[Flatten[cppOutput]];
	inversePartialGlobalMap = Association[Reverse /@ Normal @ globalIndex];
	inverseGlobalMap = Association @ Thread[resultAtoms
		-> (Lookup[inversePartialGlobalMap, #, Unique["v"]] & /@ resultAtoms)];
	ReleaseHold @ Map[inverseGlobalMap, cppOutput, {2}]
]


(* ::Subsection:: *)
(*SetReplaceList*)


(* ::Text:: *)
(*Same as SetReplace, but returns all intermediate steps in a List.*)


(* ::Subsubsection:: *)
(*Documentation*)


SetReplaceList::usage = $UsageString[
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
	FixedPointList[Replace[#, $ToNormalRules @ $ToCanonicalRules @ rules] &, set, n]


(* ::Subsection:: *)
(*SetReplaceFixedPoint*)


(* ::Text:: *)
(*Same as SetReplace, but automatically stops replacing when the set no longer changes.*)


(* ::Subsubsection:: *)
(*Documentation*)


SetReplaceFixedPoint::usage = $UsageString[
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


SetReplaceFixedPoint[set_List, rules_ ? $SetReplaceRulesQ] :=
	SetReplace[set, rules, \[Infinity], Method -> "WolframLanguage"]


(* ::Subsection:: *)
(*SetReplaceFixedPointList*)


(* ::Text:: *)
(*Same as SetReplaceFixedPoint, but returns all intermediate steps.*)


(* ::Subsubsection:: *)
(*Documentation*)


SetReplaceFixedPointList::usage = $UsageString[
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


HypergraphPlot::usage = $UsageString[
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
		{normalEdges, vertices, edgeColors, shapeHashes, hashesToColors,
		 graphEdges, graphOptions, graphBoxes, arrowheads, arrowheadOffset,
		 vertexColors},
	normalEdges = Partition[#, 2, 1] & /@ edges;
	vertices = Union @ Flatten @ edges;
	vertexColors = (# -> ColorData[97, Count[edges, {#}] + 1] & /@ vertices);
	edgeColors = Sort @ Flatten @ MapIndexed[
		Thread[DirectedEdge @@@ #1 -> OptionValue[PlotStyle][#2[[1]]]] &, normalEdges];
	graphEdges = DirectedEdge @@@ Flatten[normalEdges, 1];
	graphOptions = FilterRules[{o}, Options[Graph]];
	shapeHashes = Sort @ (If[# == {}, {}, #[[1]]] &) @ Last @ Reap @ Rasterize @
		GraphPlot[Graph[vertices, graphEdges, Join[{
			EdgeShapeFunction -> (Sow[#2 -> Hash[#1]] &)},
			graphOptions]]];
	graphBoxes = ToBoxes[Graph[graphEdges, DirectedEdges -> True]];
	arrowheads =
		If[Length[#] == 0, {}, #[[1]]] & @ Cases[graphBoxes, _Arrowheads, All];
	arrowheadOffset = If[Length[#] == 0, 0, #[[1]]] & @
		Cases[graphBoxes, ArrowBox[x_, offset_] :> offset, All];
	hashesToColors =
		Association @ Thread[shapeHashes[[All, 2]] -> edgeColors[[All, 2]]];
	GraphPlot[Graph[vertices, graphEdges, Join[
		graphOptions,
		{EdgeShapeFunction -> ({
			arrowheads,
			hashesToColors[Hash[#1]],
			Arrow[#1, arrowheadOffset]} &),
		 VertexStyle -> vertexColors}]]]
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


FromAnonymousRules::usage = $UsageString[
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
(*SetReplaceAll*)


(* ::Text:: *)
(*The idea for SetReplaceAll is to keep performing SetReplace on the graph until no replacement can be done without touching the same edge twice.*)


(* ::Text:: *)
(*Note, it's not doing replacement until all edges are touched at least once. That may not always be possible. We just don't want to touch edges twice in a single step.*)


(* ::Subsubsection:: *)
(*Documentation*)


SetReplaceAll::usage = $UsageString[
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
