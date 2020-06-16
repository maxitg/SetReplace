<|
  "evolutionConsistency" -> <|
    "tests" -> (
      (* Assign variables that ToPatternRules would use to confuse setSubstitutionSystem as much as possible. *)
      v1 = v2 = v3 = v4 = v5 = 1;

      $singleSystemTimeConstraint = 0.1;

      consistentQ = Function[{evolution},
        AcyclicGraphQ[evolution["CausalGraph"]] &&
        LoopFreeGraphQ[evolution["CausalGraph"]] &&
        VertexCount[evolution["CausalGraph"]] === evolution["EventsCount"]];

      (* rule, init, global-spacelike low-level events, global-spacelike symbolic events, match-all events *)
      $systems = {
        {{{0, 1}} -> {{0, 2}, {2, 1}}, {{0, 1}}},
        {{{{1}} -> {{1}}}, {{1}}},
        {{{{1}} -> {{2}}}, {{1}}},
        {{{{1}} -> {{2}, {1, 2}}}, {{1}}},
        {{{{1}} -> {{1}, {2}, {1, 1}}}, {{1}}},
        {{{{1}} -> {{1}, {2}, {1, 2}}}, {{1}}},
        {{{{1}} -> {{1}, {2}, {1, 3}}}, {{1}}},
        {{{{1}} -> {{2}, {2}, {1, 2}}}, {{1}}},
        {{{{1}} -> {{2}, {3}, {1, 2}}}, {{1}}},
        {{{{1}} -> {{2}, {3}, {1, 2, 4}}}, {{1}}},
        {{{{1}} -> {{2}, {2}, {2}, {1, 2}}}, {{1}}},
        {{{{1}} -> {{2}, {1, 2}}}, {{1}, {1}, {1}}},
        {{{{1, 2}} -> {{1, 3}, {2, 3}}}, {{1, 1}}},
        {{{0, 1}, {0, 2}, {0, 3}} -> {{4, 5}, {5, 4}, {4, 6}, {6, 4}, {5, 6}, {6, 5}, {4, 1}, {5, 2}, {6, 3}},
         {{0, 1}, {0, 2}, {0, 3}}},
        {{{0, 1}, {0, 2}, {0, 3}} -> {{4, 5}, {5, 4}, {4, 6}, {6, 4}, {5, 6}, {6, 5}, {4, 1}, {5, 2}, {6, 3}},
         {{0, 0}, {0, 0}, {0, 0}}},
        {{{0, 1}, {0, 2}, {0, 3}} ->
           {{4, 5}, {5, 4}, {4, 6}, {6, 4}, {5, 6}, {6, 5}, {4, 1}, {5, 2}, {6, 3}, {1, 6}, {3, 4}},
         {{0, 1}, {0, 2}, {0, 3}}},
        {{{0, 1}, {0, 2}, {0, 3}} ->
           {{4, 5}, {5, 4}, {4, 6}, {6, 4}, {5, 6}, {6, 5}, {4, 1}, {5, 2}, {6, 3}, {1, 6}, {3, 4}},
         {{0, 0}, {0, 0}, {0, 0}}},
        {{{1, 2}, {1, 3}, {1, 4}} -> {{2, 3}, {2, 4}, {3, 3}, {3, 5}, {4, 5}}, {{1, 1}, {1, 1}, {1, 1}}},
        {{{1, 2, 3}, {4, 5, 6}, {1, 4}, {4, 1}} ->
           {{2, 7, 8}, {3, 9, 10}, {5, 11, 12}, {6, 13, 14}, {7, 11}, {8, 10}, {9, 13}, {10, 8}, {11, 7}, {12, 14},
            {13, 9}, {14, 12}},
         {{1, 2, 3}, {4, 5, 6}, {1, 4}, {2, 5}, {3, 6}, {4, 1}, {5, 2}, {6, 3}}},
        {{{1, 2, 2}, {3, 4, 2}} -> {{2, 5, 5}, {5, 3, 2}, {5, 4, 6}, {7, 4, 5}}, {{1, 1, 1}, {1, 1, 1}}},
        {{{1, 1, 2}} -> {{3, 2, 2}, {3, 3, 3}, {3, 3, 4}}, {{1, 1, 1}}},
        {{{{1, 2}, {1, 3}, {1, 4}} -> {{2, 3}, {3, 4}, {4, 5}, {5, 2}, {5, 4}}}, {{1, 1}, {1, 1}, {1, 1}}},
        {{{1, 2, 1}, {3, 4, 5}} -> {{2, 6, 2}, {5, 7, 6}, {3, 1, 5}}, {{1, 1, 1}, {1, 1, 1}}},
        {{{{1, 1, 2}} -> {{2, 2, 1}, {2, 3, 2}, {1, 2, 3}}, {{1, 2, 1}, {3, 4, 2}} -> {{4, 3, 2}}}, {{1, 1, 1}}},
        {<|"PatternRules" -> {a_, b_} :> a + b|>, {1, 2, 5, 3, 6}}
      };

      $features = <|
        "VertexNamingFunction" -> {Automatic, None, All},
        "IncludePartialGenerations" -> {True, False},
        "EventOrderingFunction" -> {Automatic, "NewestEdge", "OldestEdge", "Random",
                                    {"NewestEdge", "RuleIndex"},
                                    {"NewestEdge", "RuleOrdering", "RuleIndex"}},
        "Seed" -> Range[1534, 1536],
        "StepLimiter" -> {"MaxEvents", "MaxGenerations", "MaxEdges", "MaxVertices", "MaxVertexDegree"},
        "Method" -> {Automatic, "Symbolic"},
        "TimeConstraint" -> {Infinity, $singleSystemTimeConstraint / 2}
      |>;

      $featureCombinations = {{"VertexNamingFunction"},
                              {"IncludePartialGenerations"},
                              {"Seed", "EventOrderingFunction"},
                              {"StepLimiter", "Method"},
                              {"Method", "TimeConstraint"}};

      $featureValueCombinations = Union[Catenate[Function[{featuresToTest}, Module[{
          defaultValueFeatures, enumeratedValueFeatures, featureValueLists},
        defaultValueFeatures = #[[{1}]] & /@ $features;
        enumeratedValueFeatures = Association[Thread[featuresToTest -> $features /@ featuresToTest]];
        featureValueLists = Join[defaultValueFeatures, enumeratedValueFeatures];
        Association[Thread[Keys[featureValueLists] -> #]] & /@ Tuples[Values[featureValueLists]]
      ]] /@ $featureCombinations]];

      $systemsWithOptions =
        Join[<|"Rule" -> #[[1, 1]], "Init" -> #[[1, 2]]|>, #[[2]]] & /@ Tuples[{$systems, $featureValueCombinations}];

      nothingIfSmaller[value_, min_] := If[value < min, Nothing, value];

      $systemsWithSteps = ParallelMap[Module[{timedEvolution, stepLimitValue, stepLimit},
        If[#Method === Automatic && (AssociationQ[#Rule] ||
             !AllTrue[Replace[#Rule, {r_Rule :> {r}}], SetReplace`PackageScope`connectedHypergraphQ[#[[1]]] &]) ||
           #StepLimiter === "MaxVertexDegree" && AssociationQ[#Rule],
          Nothing,
        (* else, the system can be evaluated *)
          SeedRandom[#Seed];
          timedEvolution = WolframModel[#Rule,
                                        #Init,
                                        Infinity,
                                        "VertexNamingFunction" -> #VertexNamingFunction,
                                        "IncludePartialGenerations" -> #IncludePartialGenerations,
                                        "EventOrderingFunction" -> #EventOrderingFunction,
                                        Method -> #Method,
                                        TimeConstraint -> $singleSystemTimeConstraint];
          stepLimitValue = Switch[#StepLimiter,
            "MaxEvents", timedEvolution["AllEventsCount"],
            "MaxGenerations", nothingIfSmaller[timedEvolution["CompleteGenerationsCount"] - 1, 0],
            "MaxEdges", nothingIfSmaller[timedEvolution["FinalEdgeCount"] - 1, Length[#Init]],
            "MaxVertices", nothingIfSmaller[
              timedEvolution["FinalDistinctElementsCount"] - 1, CountDistinct[Cases[#Init, _ ? AtomQ, All]]],
            "MaxVertexDegree", nothingIfSmaller @@ (
              Max[Counts[Catenate[Union /@ #]]] + #2 & @@@ {{timedEvolution["FinalState"], -1}, {#Init, 0}})
          ];
          If[stepLimitValue === Nothing,
            Nothing,
          (* else, we got a new system to run *)
            Join[#, <|"StepLimit" -> <|#StepLimiter -> stepLimitValue|>|>]
          ]
        ]
      ] &, $systemsWithOptions];

      $systemsWithNoTimeConstraint = Select[#TimeConstraint == Infinity &][$systemsWithSteps];
      $systemPairsWithDifferentMethods =
        Values[Select[Length[#] >= 2 &][GroupBy[$systemsWithNoTimeConstraint, KeyDrop[#, {"StepLimit", "Method"}] &]]];
      $methodComparisonSystems =
        Join[KeyDrop[#[[1]], {"Method", "StepLimit"}], <|"StepLimit" -> Merge[#[[All, Key["StepLimit"]]], Min]|>] & /@
          $systemPairsWithDifferentMethods;

      {
        VerificationTest[
          SeedRandom[#Seed];
          consistentQ[WolframModel[#Rule,
                                   #Init,
                                   #StepLimit,
                                   "VertexNamingFunction" -> #VertexNamingFunction,
                                   "IncludePartialGenerations" -> #IncludePartialGenerations,
                                   "EventOrderingFunction" -> #EventOrderingFunction,
                                   Method -> #Method,
                                   TimeConstraint -> #TimeConstraint]]
        ] & /@ $systemsWithSteps,

        VerificationTest[
          SeedRandom[#Seed];
          WolframModel[#Rule,
                       #Init,
                       #StepLimit,
                       "VertexNamingFunction" -> #VertexNamingFunction,
                       "IncludePartialGenerations" -> #IncludePartialGenerations,
                       "EventOrderingFunction" -> #EventOrderingFunction,
                       Method -> "Symbolic"],
          SeedRandom[#Seed];
          WolframModel[#Rule,
                       #Init,
                       #StepLimit,
                       "VertexNamingFunction" -> #VertexNamingFunction,
                       "IncludePartialGenerations" -> #IncludePartialGenerations,
                       "EventOrderingFunction" -> #EventOrderingFunction,
                       Method -> "LowLevel"]
        ] & /@ $methodComparisonSystems
      }
    )
  |>
|>
