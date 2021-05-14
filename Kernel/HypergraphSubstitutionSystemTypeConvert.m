Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

importLibSetReplaceFunction[
  "setExpressions" -> cpp$setExpressions,
  {Integer},     (* set ID *)
  {Integer, 1}]; (* expressions *)

importLibSetReplaceFunction[
  "setEvents" -> cpp$setEvents,
  {Integer},     (* set ID *)
  {Integer, 1}]; (* expressions *)

importLibSetReplaceFunction[
  "maxCompleteGeneration" -> cpp$maxCompleteGeneration,
  {Integer}, (* set ID *)
  Integer];  (* generation *)

importLibSetReplaceFunction[
  "terminationReason" -> cpp$terminationReason,
  {Integer}, (* set ID *)
  Integer];  (* reason *)

declareTypeTranslation[
  toWolframModelEvolutionObject, {HypergraphSubstitutionSystem, 0}, {WolframModelEvolutionObject, 2}];

toWolframModelEvolutionObject[obj : Multihistory[_, data_]] :=
  Module[{
      objID, numericAtomLists, events, maxCompleteGeneration, terminationReason,
      resultAtoms, inversePartialGlobalMap, inverseGlobalMap
    },
    objID = ManagedLibraryExpressionID[data["ObjectHandle"], "SetReplace"];
    terminationReason = data["TerminationReason"];

    numericAtomLists = decodeAtomLists[cpp$setExpressions[objID]];
    events = decodeEvents[cpp$setEvents[objID]];

    maxCompleteGeneration = CheckAbort[
      Replace[cpp$maxCompleteGeneration[objID], LibraryFunctionError[___] -> Missing["Unknown", $Aborted]]
    ,
      If[!returnOnAbortQ,
        Abort[]
      ,
        terminationReason = $Aborted;
        Missing["Unknown", $Aborted]
      ]
    ];

    terminationReason = Replace[$terminationReasonCodes[cpp$terminationReason[objID]], {
      $Aborted -> terminationReason,
      $notTerminated -> $timeConstraint}];

    resultAtoms = Union[Catenate[numericAtomLists]];
    inversePartialGlobalMap = Association @ Map[Reverse] @ Normal @ data["GlobalAtomsIndexMap"];
    inverseGlobalMap = AssociationThread[
      resultAtoms -> (Lookup[inversePartialGlobalMap, #, Unique["v", {Temporary}]] & /@ resultAtoms)];

    WolframModelEvolutionObject[Join[
      <|
        "Version" -> 2,
        "Rules" -> checkNotMissing[data["Rules"]],
        "MaxCompleteGeneration" -> maxCompleteGeneration,
        "TerminationReason" -> terminationReason,
        "AtomLists" -> ReleaseHold @ Map[inverseGlobalMap, numericAtomLists, {2}]
      |>,
      events]
    ]
  ];

declareMessage[
  General::corruptHypergraphMultihistory,
  "HypergraphSubstitutionSystem Multihistory is corrupt in `expr`. Use HypergraphSubstitutionSystem and a generator " <>
  "function such as GenerateMultihistory to generate HypergraphSubstitutionSystem Multihistory objects."];

checkNotMissing[_ ? MissingQ] := throw[Failure["corruptHypergraphMultihistory", <||>]];
checkNotMissing[arg_] := arg;

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
