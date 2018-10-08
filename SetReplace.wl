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
	"\!\(\*SubscriptBox[\(o\), \(2\)]\), etc.";


Begin["`Private`"];


(* ::Text:: *)
(*We are going to transform set substitution rules into a list of n! normal rules, where elements of the input subset are arranged in every possible order with blank null sequences in between.*)


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
(*Now, if there are new vertices that need to be created, we will disassemble the Module remembering which variables it applies to, and then reassemble it for the output.*)


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


(* ::Text:: *)
(*TODO(maxitg): Implement SyntaxInformation*)


SetReplace[set_UnorderedSet, rules_, n_] := UnorderedSet @@ Quiet[
	ReplaceRepeated[List @@ set, $ToNormalRules @ rules, MaxIterations -> n],
	ReplaceRepeated::rrlim]


SetReplace[set_UnorderedSet, rules_] := SetReplace[set, rules, 1]


SetReplaceList[set_UnorderedSet, rules_, n_] := FixedPointList[
	Replace[#, $ToNormalRules @ rules] &,
	List @@ set, n]


SetReplaceFixedPoint[set_UnorderedSet, rules_] := SetReplace[set, rules, \[Infinity]]


SetReplaceFixedPointList[set_UnorderedSet, rules_] := SetReplaceList[set, rules, \[Infinity]]


End[];


EndPackage[];
