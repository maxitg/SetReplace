Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageScope["setSubstitutionSystem$cpp"]

setSubstitutionSystem$cpp[
        rules_, set_, stepSpec_, returnOnAbortQ_, timeConstraint_, eventOrdering_, eventSelectionFunction_,
        eventDeduplication_] /;
      $libSetReplaceAvailable :=
  Module[{multihistory, eventSelection, eventOrderingMapped, stoppingCondition, evolutionObject},

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

    eventOrderingMapped = Replace[eventOrdering, s_String :> {s}];
    eventOrderingMapped = Replace[
      eventOrderingMapped,
      {"OldestEdge" -> "SortedInputTokenIndices",
        "LeastOldEdge" -> -"SortedInputTokenIndices",
        "LeastRecentEdge" -> "ReverseSortedInputTokenIndices",
        "NewestEdge" -> -"ReverseSortedInputTokenIndices",
        "RuleOrdering" -> "InputTokenIndices",
        "ReverseRuleOrdering" -> -"InputTokenIndices",
        "RuleIndex" -> "RuleIndex",
        "ReverseRuleIndex" -> -"RuleIndex"},
      {1}];

    stoppingCondition = {
      "TimeConstraint" -> timeConstraint,
      "MaxEvents" -> stepSpec[$maxEvents],
      "MaxVertices" -> stepSpec[$maxFinalVertices],
      "MaxVertexDegree" -> stepSpec[$maxFinalVertexDegree],
      "MaxEdges" -> stepSpec[$maxFinalExpressions]
    };
    stoppingCondition = DeleteMissing[stoppingCondition];

    CheckAbort[
      multihistory = GenerateMultihistory[
        HypergraphSubstitutionSystem[rules],
        eventSelection,
        eventDeduplication,
        eventOrderingMapped,
        stoppingCondition
      ] @ set;
    ,
      If[!returnOnAbortQ, Abort[]]
    ];

    CheckAbort[
      evolutionObject = SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @ multihistory
    ,
      If[!returnOnAbortQ, Abort[]]
    ];

    If[evolutionObject["TerminationReason"] === $timeConstraint && !returnOnAbortQ, Return @ $Aborted];

    evolutionObject
  ];
