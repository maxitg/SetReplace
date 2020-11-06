Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageScope["$cppSetReplaceAvailable"]
PackageScope["setSubstitutionSystem$cpp"]

(* Interface to the C++ implementation of setSubstitutionSystem. *)

(* Load libSetReplace *)

$expectedLibName = "libSetReplace." <> System`Dump`LibraryExtension[];

findLibraryIn[basePath_] := Scope[
	libraryResources = FileNameJoin[{basePath, "LibraryResources"}];
	libraries = FileNames[$expectedLibName, libraryResources, 2];
	First[libraries, $Failed]
];

$parentDirectory = FileNameDrop[$InputFileName, -2];
$buildDirectory = FileNameJoin[{$parentDirectory, "Build"}];

SetReplace::nolibsetreplace = "Could not locate ``, some functionality will not be available.";
SetReplace::alienlibsetreplace = "LibraryResources directory not present in ``, falling back on `` found in temporary build directory at ``.";

$libraryFile = findLibraryIn[$parentDirectory];
If[FailureQ[$libraryFile], 
	$libraryFile = findLibraryIn[$buildDirectory];
	If[FailureQ[$libraryFile],
		Message[SetReplace::nolibsetreplace, $expectedLibName];
	,
		(* for developers *) 
		Message[SetReplace::alienlibsetreplace, $parentDirectory, $expectedLibName, $buildDirectory];
	];
];

$cpp$setCreate = If[$libraryFile =!= $Failed,
  LibraryFunctionLoad[
    $libraryFile,
    "setCreate",
    {{Integer, 1}, (* rules *)
      {Integer, 1}, (* event selection functions for rules *)
      {Integer, 1}, (* initial set *)
      Integer, (* event selection function *)
      {Integer, 1}, (* ordering function index, forward / reverse, function, forward / reverse, ... *)
      Integer, (* event deduplication *)
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

$cpp$setEvents = If[$libraryFile =!= $Failed,
  LibraryFunctionLoad[
    $libraryFile,
    "setEvents",
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

(* The following code turns a nested list into a single list, prepending sizes of each sublist. I.e., {{a}, {b, c, d}}
   becomes {2, 1, a, 3, b, c, d}, where the first 2 is the length of the entire list, and 1 and 3 are the lengths of
   sublists. *)
(* This format is used to pass both rules and set data into libSetReplace over LibraryLink *)

encodeNestedLists[list_List] := Flatten @ {Length @ list, encodeNestedLists /@ list}
encodeNestedLists[arg_] := arg

(* This is the reverse, used to decode set data (a list of expressions) from libSetReplace *)

decodeAtomLists[list_List] := ModuleScope[
  count = list[[1]];
  atomPointers = list[[2 ;; (count + 1) + 1]];
  atomRanges = Partition[atomPointers, 2, 1];
  list[[#[[1]] ;; #[[2]] - 1]] & /@ atomRanges
]

(* Similar function for the events *)

decodeEvents[list_List] := ModuleScope[
  count = list[[1]];
  {ruleIDs, inputPointers, outputPointers, generations} =
    Transpose[Partition[list[[2 ;; 4 (count + 1) + 1]], 4]];
  {inputRanges, outputRanges} = Partition[#, 2, 1] & /@ {inputPointers, outputPointers};
  {inputLists, outputLists} = Map[list[[#[[1]] ;; #[[2]] - 1]] &, {inputRanges, outputRanges}, {2}];
  <|$eventRuleIDs -> Most[ruleIDs] + 1, (* Remove the fake event at the end *)
    $eventInputs -> inputLists + 1, (* C++ indexing starts from 0 *)
    $eventOutputs -> outputLists + 1,
    $eventGenerations -> Most[generations]|>
]

(* Check if we have simple anonymous rules and use C++ library in that case *)

ruleAtoms[left_ :> right_] := ModuleScope[
  leftVertices = Union @ Catenate[left[[1]]];
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

ruleAtomsToIndices[left_ :> right_, globalIndex_, localIndex_] := ModuleScope[
  newLeft = Replace[
    left[[1]],
    {x_ ? AtomQ :> globalIndex[Hold[x]],
      x_Pattern :> localIndex[Map[Hold, x, {1}][[1]]]},
    {2}];
  newRight = Replace[
    Map[Hold, Hold[right], {4}][[1, 2]],
    x_ :> Lookup[localIndex, x, globalIndex[x]],
    {2}];
  newLeft -> newRight
]

$cppSetReplaceAvailable = $cpp$setReplace =!= $Failed;

$maxInt64 = 2^63 - 1;
$maxUInt32 = 2^32 - 1;

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

systemTypeCode[eventSelectionFunction_] := Boole[multiwayEventSelectionFunctionQ[eventSelectionFunction]]

(* 0 -> All
   1 -> Spacelike *)

(* GlobalSpacelike is set to All because all concurrently matched expressions are always spacelike in that case,
   and All is much faster to evaluate. *)

eventSelectionCodes[eventSelectionFunction_, ruleCount_] :=
  ConstantArray[eventSelectionFunction /. {$globalSpacelike -> 0, None -> 0, $spacelike -> 1}, ruleCount]

$orderingFunctionCodes = <|
  $sortedExpressionIDs -> 0,
  $reverseSortedExpressionIDs -> 1,
  $expressionIDs -> 2,
  $ruleIndex -> 3,
  $any -> 4,
  $forward -> 0,
  $backward -> 1
|>;

$eventDeduplicationCodes = <|
  None -> 0,
  $sameInputSetIsomorphicOutputs -> 1
|>;

setSubstitutionSystem$cpp[
        rules_, set_, stepSpec_, returnOnAbortQ_, timeConstraint_, eventOrderingFunction_, eventSelectionFunction_,
        eventDeduplication_] /;
      $cppSetReplaceAvailable := ModuleScope[
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
    eventSelectionCodes[eventSelectionFunction, Length[canonicalRules]],
    encodeNestedLists[mappedSet],
    systemTypeCode[eventSelectionFunction],
    Catenate[Replace[eventOrderingFunction, $orderingFunctionCodes, {2}]],
    Replace[eventDeduplication, $eventDeduplicationCodes],
    RandomInteger[{0, $maxUInt32}]];
  TimeConstrained[
    CheckAbort[
      $cpp$setReplace[
        setPtr,
        stepSpec /@ {
            $maxEvents, $maxGenerationsLocal, $maxFinalVertices, $maxFinalVertexDegree, $maxFinalExpressions} /.
          {Infinity | (_ ? MissingQ) -> $maxInt64}],
      If[!returnOnAbortQ, Abort[], terminationReason = $Aborted]],
    timeConstraint,
    If[!returnOnAbortQ, Return[$Aborted], terminationReason = $timeConstraint]];
  numericAtomLists = decodeAtomLists[$cpp$setExpressions[setPtr]];
  events = decodeEvents[$cpp$setEvents[setPtr]];
  maxCompleteGeneration = CheckAbort[
    Replace[$cpp$maxCompleteGeneration[setPtr], LibraryFunctionError[___] -> Missing["Unknown", $Aborted]],
    If[!returnOnAbortQ, Abort[], terminationReason = $Aborted; Missing["Unknown", $Aborted]]];
  terminationReason = Replace[$terminationReasonCodes[$cpp$terminationReason[setPtr]], {
    $Aborted -> terminationReason,
    $notTerminated -> $timeConstraint}];
  $cpp$setDelete[setPtr];
  resultAtoms = Union[Catenate[numericAtomLists]];
  inversePartialGlobalMap = Association[Reverse /@ Normal @ globalIndex];
  inverseGlobalMap = Association @ Thread[resultAtoms
    -> (Lookup[inversePartialGlobalMap, #, Unique["v", {Temporary}]] & /@ resultAtoms)];
  WolframModelEvolutionObject[Join[
    <|$version -> 2,
      $rules -> rules,
      $maxCompleteGeneration -> maxCompleteGeneration,
      $terminationReason -> terminationReason,
      $atomLists -> ReleaseHold @ Map[inverseGlobalMap, numericAtomLists, {2}]|>,
    events]]
]
