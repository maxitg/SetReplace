(* ::Package:: *)

(* ::Title:: *)
(*SetReplace WL*)


(* ::Text:: *)
(*Implementation of SetReplace in Wolfram Language. Works better with larger vertex degrees, but is otherwise much slower.*)


Package["SetReplace`"]


PackageScope["setReplace$wl"]
PackageScope["toNormalRules"]


(* ::Section:: *)
(*Implementation*)


(* ::Subsection:: *)
(*toNormalRules*)


(* ::Text:: *)
(*We are going to transform set substitution rules into a list of n! normal rules, where elements of the input subset are arranged in every possible order with blank null sequences in between.*)


(* ::Text:: *)
(*This is for the case of no new vertices being created, so there is no need for a Module in the output*)


toNormalRules[input_List :> output_List] := Module[
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


toNormalRules[input_List :> output_Module] := Module[
		{ruleInputOriginal = input,
		 heldModule = Map[Hold, Hold[output], {2}],
		 moduleInputContents},
	moduleInputContents = heldModule[[1, 2]];
	With[{ruleInputFinal = #[[1]],
		  moduleArguments = heldModule[[1, 1]],
		  moduleOutputContents = (Hold /@ #)[[2]]},
		ruleInputFinal :> Module[moduleArguments, moduleOutputContents]
	] & /@ toNormalRules[
			ruleInputOriginal :> Evaluate @ moduleInputContents /.
				Hold[expr_] :> expr] //.
		Hold[expr_] :> expr
]


(* ::Text:: *)
(*If there are multiple rules, we just join them*)


toNormalRules[rules_List] := Join @@ toNormalRules /@ rules


(* ::Subsection:: *)
(*setReplace$wl*)


setReplace$wl[set_, rules_, n_] := Quiet[
	ReplaceRepeated[List @@ set, toNormalRules @ rules, MaxIterations -> n],
	ReplaceRepeated::rrlim]
