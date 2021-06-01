Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageScope["setSubstitutionSystem$cpp"]

setSubstitutionSystem$cpp[
        rules_, set_, stepSpec_, returnOnAbortQ_, timeConstraint_, eventOrdering_, eventSelectionFunction_,
        eventDeduplication_] /;
      $libSetReplaceAvailable := Module[{multihistory, eventSelection, stoppingCondition},

  eventSelection = <|
    "MaxDestroyerEvents" -> stepSpec[$maxDestroyerEvents],
    "MaxGeneration" -> stepSpec[$maxGenerationsLocal],
    "EventSeparation" -> Replace[eventSelectionFunction,
                                 {None -> "Any", ("GlobalSpacelike" | "MultiwaySpacelike") -> "Spacelike"}]
  |>;
  eventSelection = DeleteMissing[eventSelection];
  (* GlobalSpacelike is equivalent to "EventSelectionFunction" -> "MultiwaySpacelike", "MaxDestroyerEvents" -> 1 *)
  If[eventSelectionFunction === "GlobalSpacelike",
    eventSelection["MaxDestroyerEvents"] = 1
  ];

  stoppingCondition = {
    "TimeConstraint" -> timeConstraint,
    "MaxEvents" -> stepSpec[$maxEvents],
    "MaxVertices" -> stepSpec[$maxFinalVertices],
    "MaxVertexDegree" -> stepSpec[$maxFinalVertexDegree],
    "MaxEdges" -> stepSpec[maxFinalExpressions]
  };
  stoppingCondition = DeleteMissing[stoppingCondition];

  CheckAbort[
    multihistory = GenerateMultihistory[
      HypergraphSubstitutionSystem[rules],
      eventSelection,
      eventDeduplication,
      Replace[eventOrdering, s_String :> {s}],
      stoppingCondition
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
