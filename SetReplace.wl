(* ::Package:: *)

(* ::Title:: *)
(*Implementation of*)
(*Set Substitution System*)


(* ::Text:: *)
(*See https://github.com/maxitg/set-replace.*)


BeginPackage["SetReplace`"];


UnorderedSet::usage =
"UnorderedSet[\!\(\*SubscriptBox[\(e\), \(1\)]\), "~~
	"\!\(\*SubscriptBox[\(e\), \(2\)]\), \[Ellipsis]] is an unordered collection of elements.";


SetReplace::usage =
"SetReplace[s, {\!\(\*SubscriptBox[\(i\), \(1\)]\) \[Rule] "~~
	"\!\(\*SubscriptBox[\(o\), \(1\)]\), \!\(\*SubscriptBox[\(i\), \(2\)]\) \[Rule] "~~
	"\!\(\*SubscriptBox[\(o\), \(2\)]\), \[Ellipsis]}] attempts to replace a subset "~~
	"\!\(\*SubscriptBox[\(i\), \(1\)]\) of s with \!\(\*SubscriptBox[\(o\), \(1\)]\). "~~
	"If not found, replaces \!\(\*SubscriptBox[\(i\), \(2\)]\) with "~~
	"\!\(\*SubscriptBox[\(o\), \(2\)]\), etc.
SetReplace[s, {\!\(\*SubscriptBox[\(i\), \(1\)]\) \[Rule] "~~
	"\!\(\*SubscriptBox[\(o\), \(1\)]\), \!\(\*SubscriptBox[\(i\), \(2\)]\) \[Rule] "~~
	"\!\(\*SubscriptBox[\(o\), \(2\)]\), \[Ellipsis]}, n] performs replacement n times "~~
	"and returns the result.";


SetReplaceList::usage =
"SetReplaceList[s, {\!\(\*SubscriptBox[\(i\), \(1\)]\) \[Rule] "~~
	"\!\(\*SubscriptBox[\(o\), \(1\)]\), \!\(\*SubscriptBox[\(i\), \(2\)]\) \[Rule] "~~
	"\!\(\*SubscriptBox[\(o\), \(2\)]\), \[Ellipsis]}, n] performs SetReplace n times "~~
	"and returns the list of all intermediate sets.";


SetReplaceFixedPoint::usage =
"SetReplaceList[s, {\!\(\*SubscriptBox[\(i\), \(1\)]\) \[Rule] "~~
	"\!\(\*SubscriptBox[\(o\), \(1\)]\), \!\(\*SubscriptBox[\(i\), \(2\)]\) \[Rule] "~~
	"\!\(\*SubscriptBox[\(o\), \(2\)]\), \[Ellipsis]}] performs SetReplace repeatedly until "~~
	"the set no longer changes, and returns the final set.";


SetReplaceFixedPointList::usage =
"SetReplaceList[s, {\!\(\*SubscriptBox[\(i\), \(1\)]\) \[Rule] "~~
	"\!\(\*SubscriptBox[\(o\), \(1\)]\), \!\(\*SubscriptBox[\(i\), \(2\)]\) \[Rule] "~~
	"\!\(\*SubscriptBox[\(o\), \(2\)]\), \[Ellipsis]}] performs SetReplace repeatedly until "~~
	"the set no longer changes, and returns the list of all intermediate sets.";


UnorderedSetPlot::usage=
"UnorderedSetPlot[s, opts] plots a set of lists s as a directed hypergraph with each "~~
	"hyperedge represented as a sequence of same-color arrows.";


Begin["`Private`"];


(* ::Text:: *)
(*We are going to transform set substitution rules into a list of n! normal rules, where elements of the input*)
(*subset are arranged in every possible order with blank null sequences in between.*)


(* ::Text:: *)
(*This is for the case of no new vertices being created, so there is no need for a Module in the output*)


$ToNormalRules[input_ :> output_UnorderedSet] := Module[
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
(*Now, if there are new vertices that need to be created, we will disassemble the Module remembering which*)
(*variables it applies to, and then reassemble it for the output.*)


$ToNormalRules[input_ :> output_Module] := With[
		{ruleInputOriginal = input,
		 moduleInputContents = Hold[output][[1, 2]]},
	With[{ruleInputFinal = #[[1]],
		  moduleArguments = Hold[output][[1, 1]],
		  moduleOutputContents = #[[2]]},
		ruleInputFinal :> Module[moduleArguments, moduleOutputContents]
	] & /@ $ToNormalRules[ruleInputOriginal :> Evaluate @ moduleInputContents]
]


(* ::Text:: *)
(*If there are multiple rules, we just join them*)


$ToNormalRules[rules_List] := Join @@ $ToNormalRules /@ rules


(* ::Text:: *)
(*Now, we can use that to implement SetReplace*)


(* ::Text:: *)
(*TODO(maxitg): Implement checking of arguments*)


SyntaxInformation[SetReplace] = {"ArgumentsPattern" -> {_, _, _.}};


SetReplace[set_UnorderedSet, rules_, n_] := UnorderedSet @@ Quiet[
	ReplaceRepeated[List @@ set, $ToNormalRules @ rules, MaxIterations -> n],
	ReplaceRepeated::rrlim]


SetReplace[set_UnorderedSet, rules_] := SetReplace[set, rules, 1]


SyntaxInformation[SetReplaceList] = {"ArgumentsPattern" -> {_, _, _}};


SetReplaceList[set_UnorderedSet, rules_, n_] := UnorderedSet @@@ FixedPointList[
	Replace[#, $ToNormalRules @ rules] &,
	List @@ set, n]


(* ::Text:: *)
(*TODO(maxitg): There is a potential issue that has to do with the order of elements in the set being rearranged*)
(*at each replacement (even if the set contents are not changing), which will prevent FixedPoint from stopping.*)
(*Possible solution: use custom comparison for FixedPoint.*)


SyntaxInformation[SetReplaceFixedPoint] = {"ArgumentsPattern" -> {_, _}};


SetReplaceFixedPoint[set_UnorderedSet, rules_] := UnorderedSet @@
	SetReplace[set, rules, \[Infinity]]


SyntaxInformation[SetReplaceFixedPointList] = {"ArgumentsPattern" -> {_, _}};


SetReplaceFixedPointList[set_UnorderedSet, rules_] := UnorderedSet @@@
	SetReplaceList[set, rules, \[Infinity]]


(* ::Text:: *)
(*We might want to visualize the list-elements of the set as directed hyperedges. We can do that by drawing each*)
(*hyperedge as a sequence of same-color normal 2-edges.*)


Options[UnorderedSetPlot] = Options[Graph];


SyntaxInformation[UnorderedSetPlot] = {"ArgumentsPattern" -> {_, OptionsPattern[]}};


(* ::Text:: *)
(*TODO(maxitg): There is an issue here due to a bug in WL. If there are multiple edges in a Graph with the same*)
(*endpoints, it is impossible to color them differently due to how edges styles being handled internally in WL.*)
(*Must be fixed upstream.*)


UnorderedSetPlot[UnorderedSet[edges___List], o___] := Module[
		{normalEdges, styledEdges},
	normalEdges = Partition[#, 2, 1] & /@ {edges};
	styledEdges =
		With[{color = RandomColor[]}, Style[DirectedEdge @@ #, color] & /@ #] & /@
			normalEdges;
	Graph[Flatten[styledEdges], o]
]


End[];


EndPackage[];
