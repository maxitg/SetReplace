(* ::Package:: *)

(* ::Title:: *)
(*setSubstitutionSystem$cpp*)


(* ::Text:: *)
(*Interface to the C++ implementation of setSubstitutionSystem.*)


Package["SetReplace`"]


PackageScope["$cppSetReplaceAvailable"]
PackageScope["setSubstitutionSystem$cpp"]


(* ::Section:: *)
(*Load libSetReplace*)


$libraryFile = FindLibrary["libSetReplace"];


$cpp$setCreate = If[$libraryFile =!= $Failed,
	LibraryFunctionLoad[
		$libraryFile,
		"setCreate",
		{{Integer, 1}, (* rules *)
			{Integer, 1}, (* initial set *)
			Integer, (* 0 -> sequential evaluation, 1 -> random evaluation *)
			Integer}, (* random seed *)
		Integer], (* set ptr *)
	$Failed];


$cpp$setDelete = If[$libraryFile =!= $Failed,
	LibraryFunctionLoad[
		$libraryFile,
		"setDelete",
		{Integer}, (* set ptr *)
		"Void"],
	$Failed];


$cpp$setReplace = If[$libraryFile =!= $Failed,
	LibraryFunctionLoad[
		$libraryFile,
		"setReplace",
		{Integer, (* set ptr *)
			{Integer, 1}}, (* {events, generations, atoms, max expressions per atom, expressions} *)
		"Void"],
	$Failed];


$cpp$setExpressions = If[$libraryFile =!= $Failed,
	LibraryFunctionLoad[
		$libraryFile,
		"setExpressions",
		{Integer}, (* set ptr *)
		{Integer, 1}], (* expressions *)
	$Failed];


$cpp$maxCompleteGeneration = If[$libraryFile =!= $Failed,
	LibraryFunctionLoad[
		$libraryFile,
		"maxCompleteGeneration",
		{Integer}, (* set ptr *)
		Integer], (* generation *)
	$Failed];


$cpp$terminationReason = If[$libraryFile =!= $Failed,
	LibraryFunctionLoad[
		$libraryFile,
		"terminationReason",
		{Integer}, (* set ptr *)
		Integer], (* reason *)
	$Failed];


$cpp$eventRuleIDs = If[$libraryFile =!= $Failed,
	LibraryFunctionLoad[
		$libraryFile,
		"eventRuleIDs",
		{Integer}, (* set ptr *)
		{Integer, 1}], (* ids *)
	$Failed];


(* ::Section:: *)
(*Implementation*)


(* ::Subsection:: *)
(*Encoding*)


(* ::Text:: *)
(*The following code turns a nested list into a single list, prepending sizes of each sublist. I.e., {{a}, {b, c, d}}
	becomes {2, 1, a, 3, b, c, d}, where the first 2 is the length of the entire list, and 1 and 3 are the lengths of
	sublists.*)


(* ::Text:: *)
(*This format is used to pass both rules and set data into libSetReplace over LibraryLink*)


encodeNestedLists[list_List] :=
		{list} //. {{l___, List[args___], r___} :> {l, Length[{args}], args, r}}


(* ::Subsection:: *)
(*Decoding*)


(* ::Text:: *)
(*This is the reverse, used to decode set data (a list of expressions) from libSetReplace*)


decodeExpressions[list_List] := Module[{
		count = list[[1]],
		creatorEvents, destroyerEvents, generations, atomPointers,
		atomRanges, atomLists},
	{creatorEvents, destroyerEvents, generations, atomPointers} =
		Transpose[Partition[list[[2 ;; 4 (count + 1) + 1]], 4]];
	atomRanges = Partition[atomPointers, 2, 1];
	atomLists = list[[#[[1]] ;; #[[2]] - 1]] & /@ atomRanges;
	<|$creatorEvents -> Most[creatorEvents],
		$destroyerEvents -> Most[destroyerEvents] /. {-1 -> Infinity},
		$generations -> Most[generations],
		$atomLists -> atomLists|>
]


(* ::Subsection:: *)
(*ruleAtoms*)


(* ::Text:: *)
(*Check if we have simple anonymous rules and use C++ library in that case*)


ruleAtoms[left_ :> right : Except[_Module]] :=
	ruleAtoms[left :> Module[{}, right]]


ruleAtoms[left_ :> right_Module] := Module[{
		leftVertices, patterns, leftAtoms, patternSymbols, createdAtoms, rightAtoms},
	leftVertices = Union @ Catenate[left];
	leftAtoms = Select[leftVertices, AtomQ];
	patterns = Complement[leftVertices, leftAtoms];
	patternSymbols = Map[Hold, patterns, {2}][[All, 1]];
	createdAtoms = Map[Hold, Hold[right], {3}][[1, 1]];
	rightAtoms = Complement[
		Union @ Catenate @ Map[Hold, Hold[right], {4}][[1, 2]],
		Join[patternSymbols, createdAtoms]];
	(* {global, local} *)
	{Union @ Join[Hold /@ leftAtoms, rightAtoms],
		Union @ Join[patternSymbols, createdAtoms]}
]


(* ::Subsection:: *)
(*ruleAtomsToIndices*)


ruleAtomsToIndices[left_ :> right : Except[_Module], globalIndex_, localIndex_] :=
	ruleAtomsToIndices[left :> Module[{}, right], globalIndex, localIndex]


ruleAtomsToIndices[left_ :> right_Module, globalIndex_, localIndex_] := Module[{
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


(* ::Subsection:: *)
(*$cppSetReplaceAvailable*)


$cppSetReplaceAvailable = $cpp$setReplace =!= $Failed;


(* ::Subsection:: *)
(*setSubstitutionSystem$cpp*)


$maxInt = 2^31 - 1;
$maxUnsignedInt = 2^32 - 1;


$terminationReasonCodes = <|
	0 -> $notTerminated,
	1 -> $maxEvents,
	2 -> $maxGenerationsLocal,
	3 -> $maxFinalVertices,
	4 -> $maxFinalVertexDegree,
	5 -> $maxFinalExpressions,
	6 -> $fixedPoint,
	7 -> $Aborted
|>;


setSubstitutionSystem$cpp[rules_, set_, stepSpec_, returnOnAbortQ_, timeConstraint_, eventOrderingFunction_] /;
			$cppSetReplaceAvailable := Module[{
		canonicalRules,
		setAtoms, atomsInRules, globalAtoms, globalIndex,
		mappedSet, localIndices, mappedRules, setPtr, cppOutput, maxCompleteGeneration, terminationReason, eventRuleIDs,
		resultAtoms, inversePartialGlobalMap, inverseGlobalMap},
	canonicalRules = toCanonicalRules[rules];
	setAtoms = Hold /@ Union[Catenate[set]];
	atomsInRules = ruleAtoms /@ canonicalRules;
	globalAtoms = Union @ Join[setAtoms, Catenate[atomsInRules[[All, 1]]]];
	globalIndex = Association @ Thread[globalAtoms -> Range[Length[globalAtoms]]];
	mappedSet = Map[globalIndex, Map[Hold, set, {2}], {2}];
	localIndices =
		Association @ Thread[#[[2]] -> - Range[Length[#[[2]]]]] & /@ atomsInRules;
	mappedRules = Table[
		ruleAtomsToIndices[
			canonicalRules[[K]],
			globalIndex,
			localIndices[[K]]],
		{K, Length[canonicalRules]}];
	setPtr = $cpp$setCreate[
		encodeNestedLists[List @@@ mappedRules],
		encodeNestedLists[mappedSet],
		Replace[eventOrderingFunction, {$EventOrderingFunctionSequential -> 0, $EventOrderingFunctionRandom -> 1}],
		If[eventOrderingFunction === $EventOrderingFunctionRandom, RandomInteger[{0, $maxUnsignedInt}], 0]];
	TimeConstrained[
		CheckAbort[
			$cpp$setReplace[
				setPtr,
				stepSpec /@ {
						$maxEvents, $maxGenerationsLocal, $maxFinalVertices, $maxFinalVertexDegree, $maxFinalExpressions} /.
					{Infinity | (_ ? MissingQ) -> $maxInt}],
			If[!returnOnAbortQ, Abort[], terminationReason = $Aborted]],
		timeConstraint,
		If[!returnOnAbortQ, Return[$Aborted], terminationReason = $timeConstraint]];
	cppOutput = decodeExpressions @ $cpp$setExpressions[setPtr];
	maxCompleteGeneration =
		Replace[$cpp$maxCompleteGeneration[setPtr], LibraryFunctionError[___] -> Missing["Unknown", $Aborted]];
	terminationReason = Replace[$terminationReasonCodes[$cpp$terminationReason[setPtr]], {
		$Aborted -> terminationReason,
		$notTerminated -> $timeConstraint}];
	eventRuleIDs = $cpp$eventRuleIDs[setPtr];
	$cpp$setDelete[setPtr];
	resultAtoms = Union[Catenate[cppOutput[$atomLists]]];
	inversePartialGlobalMap = Association[Reverse /@ Normal @ globalIndex];
	inverseGlobalMap = Association @ Thread[resultAtoms
		-> (Lookup[inversePartialGlobalMap, #, Unique["v", {Temporary}]] & /@ resultAtoms)];
	WolframModelEvolutionObject[Join[
		cppOutput,
		<|$atomLists ->
				ReleaseHold @ Map[inverseGlobalMap, cppOutput[$atomLists], {2}],
			$rules -> rules,
			$maxCompleteGeneration -> maxCompleteGeneration,
			$terminationReason -> terminationReason,
			$eventRuleIDs -> eventRuleIDs
		|>]]
]
