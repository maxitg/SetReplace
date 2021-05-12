Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

declareTypeTranslation[
  toWolframModelEvolutionObject, {HypergraphSubstitutionSystem, 0}, {WolframModelEvolutionObject, 2}];

toWolframModelEvolutionObject[Multihistory[_, data_]] :=
  Module[{
      objID, numericAtomLists, events, maxCompleteGeneration, terminationReason,
      resultAtoms, inversePartialGlobalMap, inverseGlobalMap
    },

    objID = ManagedLibraryExpressionID[data["ObjectHandle"], "SetReplace"];

    numericAtomLists = decodeAtomLists[cpp$setExpressions[objID]];

    events = decodeEvents[cpp$setEvents[objID]];

    maxCompleteGeneration = CheckAbort[
      Replace[cpp$maxCompleteGeneration[objID], LibraryFunctionError[___] -> Missing["Unknown", $Aborted]]
    ,
      terminationReason = $Aborted;
      Missing["Unknown", $Aborted]
    ];

    (* TODO(daniel): Check this is being handled correctly *)
    terminationReason = Replace[$terminationReasonCodes[cpp$terminationReason[objID]], {
      $Aborted -> terminationReason,
      $notTerminated -> $timeConstraint}];

    resultAtoms = Union[Catenate[numericAtomLists]];
    inversePartialGlobalMap = Association[Reverse /@ Normal @ data["GlobalIndex"]];
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
