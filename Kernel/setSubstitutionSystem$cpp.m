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

setSubstitutionSystem$cpp[
        rules_, set_, stepSpec_, returnOnAbortQ_, timeConstraint_, eventOrdering_, eventSelectionFunction_,
        eventDeduplication_] /;
      $libSetReplaceAvailable := Module[{multihistory, nstepSpec},

  nstepSpec = KeyMap[$stepSpecKeys, stepSpec];
  nstepSpec = KeyMap[Replace["MaxGenerations" -> "MaxGeneration"], nstepSpec];

  CheckAbort[
    multihistory = GenerateMultihistory[
      HypergraphSubstitutionSystem[rules],
      KeyTake[nstepSpec, {"MaxDestroyerEvents", "MaxGeneration"}],
      eventDeduplication,
      Replace[eventOrdering, s_String :> {s}],
      Append["TimeConstraint" -> timeConstraint] @
        KeyTake[nstepSpec, {"MaxEvents", "MaxVertices", "MaxVertexDegree", "MaxEdges"}]
    ] @ set;
  ,
    If[!returnOnAbortQ, Abort[]]
  ];

  CheckAbort[
    SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @ multihistory
  ,
    If[!returnOnAbortQ, Abort[]]
  ]
];
