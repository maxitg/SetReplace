(* ::Package:: *)

(* ::Title:: *)
(*setSubstitutionSystem$wl*)


(* ::Text:: *)
(*Implementation of SetSubstitutionSystem in Wolfram Language. Works better with larger vertex degrees, but is otherwise much slower.*)


Package["SetReplace`"]


PackageScope["setSubstitutionSystem$wl"]


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


(* ::Text:: *)
(*This function just does the replacements, but it does not keep track of any metadata (generations and events).*)


setReplace$wl[set_, rules_, n_] := Quiet[
	ReplaceRepeated[List @@ set, toNormalRules @ rules, MaxIterations -> n],
	ReplaceRepeated::rrlim]


(* ::Subsection:: *)
(*addMetadataManagement*)


(* ::Text:: *)
(*This function adds metadata management to the rules. I.e., the rules will not only perform the replacements, but will also keep track of generations, events, etc.*)


addMetadataManagement[
			input_List :> output_Module,
			getNextEvent_,
			getNextExpression_,
			maxGeneration_] := Module[{
		inputIDs = Table[Unique["id"], Length[input]],
		inputCreators = Table[Unique["creator"], Length[input]],
		inputGenerations = Table[Unique["generation"], Length[input]],
		nextEvent},
	With[{
			heldModule = Map[Hold, Hold[output], {2}]},
		With[{
				moduleArguments = Append[
					ReleaseHold @ Map[Hold, heldModule[[1, 1]], {2}],
					Hold[nextEvent = getNextEvent[]]],
				moduleOutput = heldModule[[1, 2]]},
			With[{
					newModuleContents = Join[
						(* old expressions *)
						(* don't put them in the main set, sow them instead,
							that's much faster.
							Given that these look just like normal expressions,
							which just output Nothing at the end,
							they pass just fine through all the transformation. *)
						Hold[Sow[#]; Nothing] & @* ({
							#[[1]],
							#[[2]],
							nextEvent,
							#[[3]],
							#[[4]] /. x_Pattern :> x[[1]]} &) /@
								Transpose[{
									inputIDs, inputCreators, inputGenerations, input}],
						(* new expressions *)
						ReleaseHold @ Map[
							Function[
								o,
								{Hold[getNextExpression[]],
								 nextEvent,
								 Infinity,
								 Max[0, inputGenerations] + 1,
								 Hold[o]},
								HoldAll],
							moduleOutput,
							{2}]],
					originalInput = input},
				{Pattern[Evaluate[#[[1]]], Blank[]],
				 Pattern[Evaluate[#[[2]]], Blank[]],
				 Infinity,
				 Pattern[Evaluate[#[[3]]], Blank[]] ? (# < maxGeneration &),
				 #[[4]]} & /@
						Transpose[{
							inputIDs,
							inputCreators,
							inputGenerations,
							originalInput}] :>
					Module[moduleArguments, newModuleContents]]] //.
						Hold[expr_] :> expr]
]


(* ::Subsection:: *)
(*setSubstitutionSystem$wl*)


(* ::Text:: *)
(*This function runs a modified version of the set replace system that also keeps track of metadata such as generations and events. It uses setReplace$wl to evaluate that modified system.*)


setSubstitutionSystem$wl[rules_, set_, generations_, steps_] := Module[{
		setWithMetadata, rulesWithMetadata, outputWithMetadata, result,
		nextExpressionID = 1, nextEventID = 1, nextExpression},
	nextExpression = nextExpressionID++ &;
	(* {id, creator, destroyer, generation, atoms} *)
	setWithMetadata = {nextExpression[], 0, \[Infinity], 0, #} & /@ set;
	rulesWithMetadata = addMetadataManagement[
		#, nextEventID++ &, nextExpression, generations] & /@ rules;
	outputWithMetadata = Reap[setReplace$wl[setWithMetadata, rulesWithMetadata, steps]];
	result = SortBy[
		Join[
			outputWithMetadata[[1]],
			If[outputWithMetadata[[2]] == {}, {}, outputWithMetadata[[2, 1]]]],
		First];
	SetSubstitutionEvolution[<|
		$creatorEvents -> result[[All, 2]],
		$destroyerEvents -> result[[All, 3]],
		$generations -> result[[All, 4]],
		$atomLists -> result[[All, 5]],
		$rules -> rules|>]
]
