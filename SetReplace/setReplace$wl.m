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
(*setReplace$wlRaw*)


(* ::Text:: *)
(*This function just does the replacements, but it does not keep track of any metadata (generations and events).*)


setReplace$wlRaw[set_, rules_, n_] := Quiet[
	ReplaceRepeated[List @@ set, toNormalRules @ rules, MaxIterations -> n],
	ReplaceRepeated::rrlim]


(* ::Subsection:: *)
(*addMetadataManagement*)


(* ::Text:: *)
(*This function adds metadata management to the rules. I.e., the rules will not only perform the replacements, but will also keep track of generations, events, etc.*)


addMetadataManagement[
			input_List :> output_Module, getNextEvent_, maxGeneration_] := Module[{
		inputCreators = Table[Unique["creator"], Length[input]],
		inputGenerations = Table[Unique["generation"], Length[input]],
		nextEvent},
	Echo @ With[{
			heldModule = Map[Hold, Hold[output], {2}]},
		With[{
				moduleArguments = Append[
					ReleaseHold @ Map[Hold, heldModule[[1, 1]], {2}],
					Hold[nextEvent = getNextEvent[]]],
				moduleOutput = heldModule[[1, 2]]},
			With[{
					newModuleContents = Join[
						ReleaseHold @ Map[
							Function[
								o,
								{nextEvent, \[Infinity], Max @@ inputGenerations + 1, Hold[o]},
								HoldAll],
							moduleOutput,
							{2}],
						{#[[1]],
						 nextEvent,
						 #[[2]],
						 #[[3]] /. x_Pattern :> x[[1]]} & /@
							Transpose[{inputCreators, inputGenerations, input}]],
					originalInput = input},
				{Pattern[Evaluate[#[[1]]], Blank[]],
				 Infinity,
				 Pattern[Evaluate[#[[2]]], Blank[]] ? (# < maxGeneration &),
				 #[[3]]} & /@
						Transpose[{inputCreators, inputGenerations, originalInput}] :>
					Module[moduleArguments, newModuleContents]]] //.
						Hold[expr_] :> expr]
]


(* ::Subsection:: *)
(*setReplace$wl*)


(* ::Text:: *)
(*This function runs a modified version of the set replace system that also keeps track of metadata such as generations and events. It uses setReplace$wlRaw to evaluate that modified system.*)


setReplace$wl[rules_, set_, generations_, steps_] := Module[{
		setWithMetadata, rulesWithMetadata, result, nextEventID = 1},
	(* {creator, destroyer, generation, atoms} *)
	setWithMetadata = {0, \[Infinity], 0, #} & /@ set;
	rulesWithMetadata =
		addMetadataManagement[#, nextEventID++ &, generations] & /@ rules;
	result = setReplace$wlRaw[setWithMetadata, rulesWithMetadata, steps];
	SetSubstitutionEvolution[<|
		$creatorEvents -> result[[All, 1]],
		$destroyerEvents -> result[[All, 2]],
		$generations -> result[[All, 3]],
		$atomLists -> result[[All, 4]],
		$rules -> rules|>]
]
