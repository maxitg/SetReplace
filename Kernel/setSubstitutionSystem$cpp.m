Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageScope["setSubstitutionSystem$cpp"]

(* GlobalSpacelike is syntactic sugar for "EventSelectionFunction" -> "MultiwaySpacelike", "MaxDestroyerEvents" -> 1 *)

maxDestroyerEvents[_, $globalSpacelike] = 1;
maxDestroyerEvents[Automatic | _ ? MissingQ | Infinity, _] = $unset;
maxDestroyerEvents[n_, _] := n;

(* 0 -> All
   1 -> Spacelike *)

eventSelectionCodes[eventSelectionFunction_, ruleCount_] :=
  ConstantArray[eventSelectionFunction /. {None -> 0, ($globalSpacelike | $spacelike) -> 1}, ruleCount];

$eventDeduplicationCodes = <|
  None -> 0,
  $sameInputSetIsomorphicOutputs -> 1
|>;

setSubstitutionSystem$cpp[
        rules_, set_, stepSpec_, returnOnAbortQ_, timeConstraint_, eventOrdering_, eventSelectionFunction_,
        eventDeduplication_] /;
      $libSetReplaceAvailable := Module[{multihistory, nstepSpec, terminationReason},

  nstepSpec = KeyMap[$stepSpecKeys, stepSpec];

  CheckAbort[
    multihistory = GenerateMultihistory[
      HypergraphSubstitutionSystem[rules],
      Echo @ KeyTake[nstepSpec, {"MaxDestroyerEvents", "MaxGeneration"}],
      None,  (* TODO(daniel): Add existing deduplication *)
      eventOrdering,
      Append["TimeConstraint" -> timeConstraint] @
        Echo @ KeyTake[nstepSpec, {"MaxEvents", "MaxVertices", "MaxVertexDegree", "MaxEdges"}]
    ] @ set;
  ,
    If[!returnOnAbortQ, Abort[]]
  ];

  (* terminationReason = $terminationReasonCodes[cpp$terminationReason[setID]];
  If[(terminationReason === $timeConstraint) && !returnOnAbortQ, Return @ $Aborted];
  terminationReason = Replace[terminationReason, $notTerminated -> $timeConstraint]; *)

  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @ multihistory
];
