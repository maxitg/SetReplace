(* ::Package:: *)

(* ::Title:: *)
(*setSubstitutionSystem$wl*)


(* ::Text:: *)
(*Implementation of setSubstitutionSystem in Wolfram Language. Works better with larger vertex degrees, but is otherwise much slower.*)


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
		{inputLength, inputPermutations, heldOutput},
	inputLength = Length @ input;

	inputPermutations = Permutations @ input;
	heldOutput = Thread @ Hold @ output;

	With[{right = heldOutput},
		# :> right & /@ inputPermutations] /. Hold[expr_] :> expr
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


toNormalRules[rules_List] := Module[{
		ruleNames, separateNormalRules, longestRuleLength, untouchedNames,
		finalMatchName, input, output},
	ruleNames = Table[Unique[], Length[rules]];
	separateNormalRules = toNormalRules /@ rules;
	longestRuleLength = Max[Map[Length, separateNormalRules[[All, All, 1]], {2}]];
	untouchedNames = Table[Unique[], longestRuleLength + 1];
	finalMatchName = Unique[];
	input = With[{match = finalMatchName}, List[
		match : Shortest[Alternatives @@ Catenate[Transpose @ PadRight[
			MapIndexed[
				With[{patternName = ruleNames[[#2[[1]]]]},
					Function[patternContent,
						Pattern[patternName, patternContent]] /@ #] &,
				Map[
					PatternSequence @@ If[# == {}, #, Riffle[
						#,
						Pattern[#, ___] & /@ untouchedNames,
						{1, 2 Length[#] - 1, 2}]] &,
					separateNormalRules[[All, All, 1]],
					{2}]],
			Automatic,
			nothing] /. nothing -> Nothing]],
		With[{lastPatternName = Last @ untouchedNames}, Pattern[lastPatternName, ___]]]];
	output = Hold @ Catenate @ # & @ Prepend[
		With[{ruleName = #[[1]], outputRule = #[[2]]},
			Hold[Replace[{ruleName}, outputRule]]] & /@
				Transpose[{
					ruleNames,
					With[{outputExpression = (Hold /@ #)[[2]]},
							{finalMatchName} :> outputExpression] & /@
						separateNormalRules[[All, 1]]}],
		untouchedNames];
	With[{evaluatedOutput = output}, input :> evaluatedOutput] //. Hold[expr_] :> expr
]


(* ::Subsection:: *)
(*setReplace$wl*)


(* ::Text:: *)
(*This function just does the replacements, but it does not keep track of any metadata (generations and events).*)


setReplace$wl[set_, rules_, n_, returnOnAbortQ_, timeConstraint_] := Module[{normalRules, partialResult},
	normalRules = toNormalRules @ rules;
	partialResult = set;
	TimeConstrained[
		CheckAbort[
			FixedPoint[AbortProtect[partialResult = Replace[#, normalRules]] &, List @@ set, n],
			If[returnOnAbortQ,
				partialResult,
				Abort[]
			]],
		timeConstraint,
		If[returnOnAbortQ,
			partialResult,
			Return[$Aborted]
		]]
]


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
		wholeInputPatternNames = Table[Unique["inputExpression"], Length[input]],
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
							#[[1]], #[[2]], nextEvent, #[[3]], #[[4]]} &) /@
								Transpose[{
									inputIDs,
									inputCreators,
									inputGenerations,
									wholeInputPatternNames}],
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
				 Pattern[Evaluate[#[[5]]], #[[4]]]} & /@
						Transpose[{
							inputIDs,
							inputCreators,
							inputGenerations,
							originalInput,
							wholeInputPatternNames}] :>
					Module[moduleArguments, newModuleContents]]] //.
						Hold[expr_] :> expr]
]


(* ::Subsection:: *)
(*setSubstitutionSystem$wl*)


(* ::Text:: *)
(*This function renames all rule inputs to avoid collisions with outputs from other rules.*)


renameRuleInputs[patternRules_] := Catch[Module[{pattern, inputAtoms, newInputAtoms},
	Attributes[pattern] = {HoldFirst};
	inputAtoms = Union[
		Quiet[
			Cases[
				# /. Pattern -> pattern,
				pattern[s_, rest___] :>
					If[MatchQ[Hold[s], Hold[_Symbol]], Hold[s], Message[Pattern::patvar, Pattern[s, rest]]; Throw[$Failed]],
				All],
			{RuleDelayed::rhs}]];
	newInputAtoms = Table[Unique[], Length[inputAtoms]];
	# /. (((HoldPattern[#1] /. Hold[s_] :> s) -> #2) & @@@ Thread[inputAtoms -> newInputAtoms])
] & /@ patternRules]


(* ::Text:: *)
(*This function runs a modified version of the set replace system that also keeps track of metadata such as generations and events. It uses setReplace$wl to evaluate that modified system.*)


setSubstitutionSystem$wl[rules_, set_, generations_, steps_, returnOnAbortQ_, timeConstraint_] := Module[{
		setWithMetadata, renamedRules, rulesWithMetadata, outputWithMetadata, result,
		nextExpressionID = 1, nextEventID = 1, nextExpression},
	nextExpression = nextExpressionID++ &;
	(* {id, creator, destroyer, generation, atoms} *)
	setWithMetadata = {nextExpression[], 0, \[Infinity], 0, #} & /@ set;
	renamedRules = renameRuleInputs[toCanonicalRules[rules]];
	If[renamedRules === $Failed, Return[$Failed]];
	rulesWithMetadata = addMetadataManagement[
		#, nextEventID++ &, nextExpression, generations] & /@ renamedRules;
	outputWithMetadata = Reap[setReplace$wl[setWithMetadata, rulesWithMetadata, steps, returnOnAbortQ, timeConstraint]];
	If[outputWithMetadata[[1]] === $Aborted, Return[$Aborted]];
	result = SortBy[
		Join[
			outputWithMetadata[[1]],
			If[outputWithMetadata[[2]] == {}, {}, outputWithMetadata[[2, 1]]]],
		First];
	WolframModelEvolutionObject[<|
		$creatorEvents -> result[[All, 2]],
		$destroyerEvents -> result[[All, 3]],
		$generations -> result[[All, 4]],
		$atomLists -> result[[All, 5]],
		$rules -> rules|>]
]
