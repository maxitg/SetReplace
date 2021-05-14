Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageScope["setSubstitutionSystem$cpp"]

(* GlobalSpacelike is syntactic sugar for "EventSelectionFunction" -> "MultiwaySpacelike", "MaxDestroyerEvents" -> 1 *)

maxDestroyerEvents[_, $globalSpacelike] = 1;
maxDestroyerEvents[Automatic | _ ? MissingQ | Infinity, _] = $maxInt64;
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
      $libSetReplaceAvailable := Module[{multihistory, nstepSpec},

  nstepSpec = KeyMap[$stepSpecKeys, stepSpec];

  multihistory = GenerateMultihistory[
    HypergraphSubstitutionSystem[rules],
    Echo @ KeyTake[nstepSpec, {"MaxDestroyerEvents", "MaxGeneration"}],
    None,  (* TODO(daniel): Add existing deduplication *)
    eventOrdering,
    Append["TimeConstraint" -> timeConstraint] @
      Echo @ KeyTake[nstepSpec, {"MaxEvents", "MaxVertices", "MaxVertexDegree", "MaxEdges"}]
  ] @ set;

  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @ multihistory
];
