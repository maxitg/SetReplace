Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageScope["setSubstitutionSystem$cpp"]

importLibSetReplaceFunction[
  "hypergraphSubstitutionSystemInitialize" -> cpp$setInitialize,
  {Integer,                  (* set ID *)
   {Integer, 1, "Constant"}, (* rules *)
   {Integer, 1, "Constant"}, (* event selection functions for rules *)
   {Integer, 1, "Constant"}, (* initial set *)
   Integer,                  (* event selection function *)
   {Integer, 1, "Constant"}, (* ordering function index, forward / reverse, function, forward / reverse, ... *)
   Integer,                  (* event deduplication *)
   (* random seed, passed as two numbers because LibraryLink does not support unsigned ints *)
   {Integer, 1, "Constant"}},
  "Void"];

importLibSetReplaceFunction[
  "hypergraphSubstitutionSystemReplace" -> cpp$setReplace,
  {Integer,                   (* set ID *)
   {Integer, 1, "Constant"}}, (* {events, generations, atoms, max expressions per atom, expressions} *)
  "Void"];

importLibSetReplaceFunction[
  "hypergraphSubstitutionSystemTokens" -> cpp$setExpressions,
  {Integer},     (* set ID *)
  {Integer, 1}]; (* expressions *)

importLibSetReplaceFunction[
  "hypergraphSubstitutionSystemEvents" -> cpp$setEvents,
  {Integer},     (* set ID *)
  {Integer, 1}]; (* expressions *)

importLibSetReplaceFunction[
  "hypergraphSubstitutionSystemMaxCompleteGeneration" -> cpp$maxCompleteGeneration,
  {Integer}, (* set ID *)
  Integer];  (* generation *)

importLibSetReplaceFunction[
  "hypergraphSubstitutionSystemTerminationReason" -> cpp$terminationReason,
  {Integer}, (* set ID *)
  Integer];  (* reason *)

(* The following code turns a nested list into a single list, prepending sizes of each sublist. I.e., {{a}, {b, c, d}}
   becomes {2, 1, a, 3, b, c, d}, where the first 2 is the length of the entire list, and 1 and 3 are the lengths of
   sublists. *)
(* This format is used to pass both rules and set data into libSetReplace over LibraryLink *)

encodeNestedLists[list_List] := Flatten @ {Length @ list, encodeNestedLists /@ list};
encodeNestedLists[arg_] := arg;

(* This is the reverse, used to decode set data (a list of expressions) from libSetReplace *)

decodeAtomLists[list_List] := ModuleScope[
  count = list[[1]];
  atomPointers = list[[2 ;; (count + 1) + 1]];
  atomRanges = Partition[atomPointers, 2, 1];
  list[[#[[1]] ;; #[[2]] - 1]] & /@ atomRanges
];

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
];

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
];

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
];

$unset = -1;
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

(* GlobalSpacelike is syntactic sugar for "EventSelectionFunction" -> "MultiwaySpacelike", "MaxDestroyerEvents" -> 1 *)

maxDestroyerEvents[_, $globalSpacelike] = 1;
maxDestroyerEvents[Automatic | _ ? MissingQ | Infinity, _] = $unset;
maxDestroyerEvents[n_, _] := n;

(* 0 -> All
   1 -> Spacelike *)

eventSelectionCodes[eventSelectionFunction_, ruleCount_] :=
  ConstantArray[eventSelectionFunction /. {None -> 0, ($globalSpacelike | $spacelike) -> 1}, ruleCount];

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
      $libSetReplaceAvailable := ModuleScope[
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
  setHandle = CreateManagedLibraryExpression["SetReplace", managedSet];
  setID = ManagedLibraryExpressionID[setHandle, "SetReplace"];
  cpp$setInitialize[
    setID,
    encodeNestedLists[List @@@ mappedRules],
    eventSelectionCodes[eventSelectionFunction, Length[canonicalRules]],
    encodeNestedLists[mappedSet],
    maxDestroyerEvents[stepSpec[$maxDestroyerEvents], eventSelectionFunction],
    Catenate[Replace[eventOrderingFunction, $orderingFunctionCodes, {2}]],
    Replace[eventDeduplication, $eventDeduplicationCodes],
    IntegerDigits[RandomInteger[{0, $maxUInt32}], 2^16, 2]
  ];
  TimeConstrained[
    CheckAbort[
      cpp$setReplace[
        setID,
        stepSpec /@ {
            $maxEvents, $maxGenerationsLocal, $maxFinalVertices, $maxFinalVertexDegree, $maxFinalExpressions} /.
          {Infinity | (_ ? MissingQ) -> $unset}],
      If[!returnOnAbortQ, Abort[], terminationReason = $Aborted]],
    timeConstraint,
    If[!returnOnAbortQ, Return[$Aborted], terminationReason = $timeConstraint]];
  numericAtomLists = decodeAtomLists[cpp$setExpressions[setID]];
  events = decodeEvents[cpp$setEvents[setID]];
  maxCompleteGeneration = CheckAbort[
    Replace[cpp$maxCompleteGeneration[setID], LibraryFunctionError[___] -> Missing["Unknown", $Aborted]],
    If[!returnOnAbortQ, Abort[], terminationReason = $Aborted; Missing["Unknown", $Aborted]]];
  terminationReason = Replace[$terminationReasonCodes[cpp$terminationReason[setID]], {
    $Aborted -> terminationReason,
    $notTerminated -> $timeConstraint}];
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
];
