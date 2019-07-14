(* ::Package:: *)

(* ::Title:: *)
(*SetReplace C++*)


(* ::Text:: *)
(*Interface to the C++ implementation of SetReplace.*)


Package["SetReplace`"]


PackageScope["$cppSetReplaceAvailable"]


PackageScope["setReplace$cpp"]


(* ::Section:: *)
(*Load libSetReplace*)


With[{libraryFile = FindLibrary["libSetReplace"]},
	$cpp$setReplace = If[libraryFile =!= $Failed,
		LibraryFunctionLoad[
			libraryFile,
			"setReplace",
			{{Integer, 1}, {Integer, 1}, Integer},
			{Integer, 1}],
		$Failed]]


(* ::Section:: *)
(*Implementation*)


(* ::Subsection:: *)
(*Encoding / Decoding*)


(* ::Text:: *)
(*The following code turns a nested list into a single list, prepending sizes of each sublist. I.e., {{a}, {b, c, d}} becomes {2, 1, a, 3, b, c, d}, where the first 2 is the length of the entire list, and 1 and 3 are the lengths of sublists.*)


(* ::Text:: *)
(*This format is used to pass both rules and set data into libSetReplace over LibraryLink*)


encodeNestedLists[list_List] :=
		{list} //. {{l___, List[args___], r___} :> {l, Length[{args}], args, r}}


(* ::Text:: *)
(*This is the reverse, used to decode set data (a list of hyperedges) from libSetReplace*)


readList[list_, index_] := Module[{count = list[[index]]},
	Sow[list[[index + 1 ;; index + count]]];
	index + count + 1
]


decodeListOfLists[{0}] := {}
decodeListOfLists[list_List] := Reap[Nest[readList[list, #] &, 2, list[[1]]]][[2, 1]]


(* ::Subsection:: *)
(*ruleAtoms*)


(* ::Text:: *)
(*Check if we have simple anonymous rules and use C++ library in that case*)


ruleAtoms[left_ :> right : Except[_Module]] :=
	ruleAtoms[left :> Module[{}, right]]


ruleAtoms[left_ :> right_Module] := Module[{
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
(*setReplace$cpp*)


setReplace$cpp[set_, rules_, n_] /; $cppSetReplaceAvailable := Module[{
		setAtoms, atomsInRules, globalAtoms, globalIndex,
		mappedSet, localIndices, mappedRules, cppOutput, resultAtoms,
		inversePartialGlobalMap, inverseGlobalMap},
	setAtoms = Hold /@ Union[Flatten[set]];
	atomsInRules = ruleAtoms /@ rules;
	globalAtoms = Union @ Flatten @ {setAtoms, atomsInRules[[All, 1]]};
	globalIndex = Association @ Thread[globalAtoms -> Range[Length[globalAtoms]]];
	mappedSet = Map[globalIndex, Map[Hold, set, {2}], {2}];
	localIndices =
		Association @ Thread[#[[2]] -> - Range[Length[#[[2]]]]] & /@ atomsInRules;
	mappedRules = Table[
		ruleAtomsToIndices[
			rules[[K]],
			globalIndex,
			localIndices[[K]]],
		{K, Length[rules]}];
	cppOutput = decodeListOfLists @ $cpp$setReplace[
		encodeNestedLists[List @@@ mappedRules],
		encodeNestedLists[mappedSet],
		n];
	resultAtoms = Union[Flatten[cppOutput]];
	inversePartialGlobalMap = Association[Reverse /@ Normal @ globalIndex];
	inverseGlobalMap = Association @ Thread[resultAtoms
		-> (Lookup[inversePartialGlobalMap, #, Unique["v"]] & /@ resultAtoms)];
	ReleaseHold @ Map[inverseGlobalMap, cppOutput, {2}]
]
