<|
  "correctness" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];

      (* Assign variables that ToPatternRules would use to confuse setSubstitutionSystem as much as possible. *)
      v1 = v2 = v3 = v4 = v5 = 1;

      sameSetQ[x_, y_] := Module[{xAtoms, yAtoms},
        {xAtoms, yAtoms} = DeleteDuplicates[Flatten[#]] & /@ {x, y};
        If[Length[xAtoms] != Length[yAtoms], Return[False]];
        (x /. Thread[xAtoms -> yAtoms]) === y
      ];

      $systemsToTest = {
        {{{0, 1}} -> {{0, 2}, {2, 1}}, {{0, 1}}, 100, 6, 1000, 7, $branching},
        {{{{1}} -> {{1}}}, {{1}}, 100, 100, 1000, 1000, $sequential},
        {{{{1}} -> {{2}}}, {{1}}, 100, 100, 1000, 1000, $sequential},
        {{{{1}} -> {{2}, {1, 2}}}, {{1}}, 100, 6, 1000, 1000, $sequential},
        {{{{1}} -> {{1}, {2}, {1, 1}}}, {{1}}, 100, 6, 1000, 7, $branching},
        {{{{1}} -> {{1}, {2}, {1, 2}}}, {{1}}, 100, 6, 1000, 7, $branching},
        {{{{1}} -> {{1}, {2}, {1, 3}}}, {{1}}, 100, 6, 1000, 7, $branching},
        {{{{1}} -> {{2}, {2}, {1, 2}}}, {{1}}, 100, 6, 1000, 7, $branching},
        {{{{1}} -> {{2}, {3}, {1, 2}}}, {{1}}, 100, 6, 1000, 7, $branching},
        {{{{1}} -> {{2}, {3}, {1, 2, 4}}}, {{1}}, 100, 6, 1000, 7, $branching},
        {{{{1}} -> {{2}, {2}, {2}, {1, 2}}}, {{1}}, 100, 4, 1000, 5, $branching},
        {{{{1}} -> {{2}, {1, 2}}}, {{1}, {1}, {1}}, 100, 34, 1000, 400, $branching},
        {{{{1, 2}} -> {{1, 3}, {2, 3}}}, {{1, 1}}, 100, 6, 1000, 7, $branching},
        {{{0, 1}, {0, 2}, {0, 3}} -> {{4, 5}, {5, 4}, {4, 6}, {6, 4}, {5, 6}, {6, 5}, {4, 1}, {5, 2}, {6, 3}},
          {{0, 1}, {0, 2}, {0, 3}},
          30, 3, 100, 4,
          $branching},
        {{{0, 1}, {0, 2}, {0, 3}} -> {{4, 5}, {5, 4}, {4, 6}, {6, 4}, {5, 6}, {6, 5}, {4, 1}, {5, 2}, {6, 3}},
          {{0, 0}, {0, 0}, {0, 0}},
          30, 3, 100, 4,
          $branching},
        {{{0, 1}, {0, 2}, {0, 3}} ->
            {{4, 5}, {5, 4}, {4, 6}, {6, 4}, {5, 6}, {6, 5}, {4, 1}, {5, 2}, {6, 3}, {1, 6}, {3, 4}},
          {{0, 1}, {0, 2}, {0, 3}},
          30, 3, 100, 4,
          $branching},
        {{{0, 1}, {0, 2}, {0, 3}} ->
            {{4, 5}, {5, 4}, {4, 6}, {6, 4}, {5, 6}, {6, 5}, {4, 1}, {5, 2}, {6, 3}, {1, 6}, {3, 4}},
          {{0, 0}, {0, 0}, {0, 0}},
          30, 3, 100, 4,
          $branching},
        {{{1, 2}, {1, 3}, {1, 4}} -> {{2, 3}, {2, 4}, {3, 3}, {3, 5}, {4, 5}},
          {{1, 1}, {1, 1}, {1, 1}},
          50, 7, 100, 9,
          $branching},
        {{{1, 2, 3}, {4, 5, 6}, {1, 4}, {4, 1}} ->
            {{2, 7, 8}, {3, 9, 10}, {5, 11, 12}, {6, 13, 14}, {7, 11}, {8, 10}, {9, 13}, {10, 8}, {11, 7}, {12, 14},
              {13, 9}, {14, 12}},
          {{1, 2, 3}, {4, 5, 6}, {1, 4}, {2, 5}, {3, 6}, {4, 1}, {5, 2}, {6, 3}},
          8, 2, 100, 5,
          $branching},
        {{{1, 2, 2}, {3, 4, 2}} -> {{2, 5, 5}, {5, 3, 2}, {5, 4, 6}, {7, 4, 5}},
          {{1, 1, 1}, {1, 1, 1}},
          30, 30, 1000, 1000,
          $sequential},
        {{{1, 1, 2}} -> {{3, 2, 2}, {3, 3, 3}, {3, 3, 4}}, {{1, 1, 1}}, 100, 6, 2000, 10, $branching},
        {{{{1, 2}, {1, 3}, {1, 4}} -> {{2, 3}, {3, 4}, {4, 5}, {5, 2}, {5, 4}}},
          {{1, 1}, {1, 1}, {1, 1}},
          40, 10, 100, 12,
          $branching}
      };

      $graphsForMatching = {
        {{1, 2}, {2, 3}, {3, 4}, {4, 5}},
        {{1, 2}, {2, 3}, {3, 4}, {4, 1}},
        {{1, 2}, {2, 3}, {3, 4}, {1, 5}},
        {{2, 3}, {3, 1}, {4, 2}, {4, 5}},
        {{1, 5}, {2, 1}, {2, 3}, {2, 4}, {2, 5}, {3, 1}, {4, 2}, {4, 5}}
      };

      $methods = DeleteCases[$SetReplaceMethods, Automatic];

      graphFromHyperedges[edges_] := Graph[
        UndirectedEdge @@@ Flatten[Partition[#, 2, 1] & /@ edges, 1]];

      randomConnectedGraphs[edgeCount_, edgeLength_, graphCount_] := (
        #[[All, 1]] & @ Select[#[[2]] &] @ Map[
          {#, ConnectedGraphQ @ graphFromHyperedges @ #} &,
          BlockRandom[
            Table[
              With[{k = edgeCount}, Table[RandomInteger[edgeLength k], k, edgeLength]],
              graphCount],
            RandomSeeding -> ToString[{"randomConnectedGraphs", edgeCount, edgeLength, graphCount}]]]
      );

      (* Here we generate random graphs and try replacing them to nothing *)
      randomSameGraphMatchTests[edgeCount_, edgeLength_, graphCount_, method_] := Module[{
          tests},
        tests = randomConnectedGraphs[edgeCount, edgeLength, graphCount];
        Map[
          With[{set1 = #[[1]], set2 = #[[2]]},
            VerificationTest[SetReplace[set1, ToPatternRules[set2 -> {}], Method -> method], {}]] &,
          BlockRandom[
            {#, RandomSample[#]} & /@ tests,
            RandomSeeding -> ToString[{"randomSameGraphMatchTest", edgeCount, edgeLength, graphCount, method}]]]
      ];

      (* Here we generate pairs of different graphs, and check they are not being matched *)
      randomDistinctGraphMatchTests[
            edgeCount_, edgeLength_, graphCount_, method_] := Module[{
          tests},
        tests = Select[!IsomorphicGraphQ @@ (graphFromHyperedges /@ #) &]
          @ Partition[
            Select[SimpleGraphQ @* graphFromHyperedges]
              @ randomConnectedGraphs[edgeCount, edgeLength, graphCount],
            2];
        Map[
          (* degenerate graphs can still match if not isomorphic, i.e., {{0, 0}} will match {{0, 1}},
             that's why we need to try replacing both ways *)
          With[{set1 = #[[1]], set2 = #[[2]]},
            VerificationTest[SetReplace[set1, ToPatternRules[set2 -> {}], Method -> method] != {}
              || SetReplace[set2, ToPatternRules[set1 -> {}], Method -> method] != {}]] &,
          tests]
      ];

      (* Here we make initial condition degenerate, and check it still matches, i.e.,
         {{0, 0}} should still match {{0, 1}} *)
      randomDegenerateGraphMatchTests[
            edgeCount_, edgeLength_, graphCount_, method_] := Module[{
          tests},
        tests = randomConnectedGraphs[edgeCount, edgeLength, graphCount];
      Map[
          With[{set1 = #[[1]], identifiedVertex1 = #[[2]], identifiedVertex2 = #[[3]], set2 = #[[4]]},
            VerificationTest[
              SetReplace[
                set1 /. identifiedVertex1 -> identifiedVertex2,
                ToPatternRules[set2 -> {}],
                Method -> method],
              {}]] &,
          BlockRandom[
            {#, RandomChoice[Flatten[#]], RandomChoice[Flatten[#]], RandomSample[#]} & /@ tests,
            RandomSeeding -> ToString[{"randomDegenerateGraphMatchTest", edgeCount, edgeLength, graphCount, method}]]]
      ];
    ),
    "tests" -> {
      (* Fixed number of events *)

      VerificationTest[
        WolframModel[#1, #2, <|"MaxEvents" -> #3|>, Method -> "Symbolic"],
        WolframModel[#1, #2, <|"MaxEvents" -> #3|>, Method -> "LowLevel"]
      ] & @@@ $systemsToTest,

      (* Fixed number of events same seed consistentcy *)

      VerificationTest[
        SeedRandom[1655]; WolframModel[#1, #2, <|"MaxEvents" -> #5|>, "EventOrderingFunction" -> "Random"],
        SeedRandom[1655]; WolframModel[#1, #2, <|"MaxEvents" -> #5|>, "EventOrderingFunction" -> "Random"]
      ] & @@@ $systemsToTest,

      (* Fixed number of events different seeds difference *)

      VerificationTest[
        (SeedRandom[1655]; WolframModel[#1, #2, <|"MaxEvents" -> #5|>, "EventOrderingFunction" -> "Random"]) =!=
          (SeedRandom[1656]; WolframModel[#1, #2, <|"MaxEvents" -> #5|>, "EventOrderingFunction" -> "Random"])
      ] & @@@ Select[$systemsToTest, #[[7]] =!= $sequential &],

      (* Fixed number of generations *)

      VerificationTest[
        WolframModel[#1, #2, #4, Method -> "Symbolic"],
        WolframModel[#1, #2, #4, Method -> "LowLevel"]
      ] & @@@ $systemsToTest,

      (* Fixed number of generations same seed consistentcy *)

      VerificationTest[
        SeedRandom[1655]; WolframModel[#1, #2, #6, "EventOrderingFunction" -> "Random"],
        SeedRandom[1655]; WolframModel[#1, #2, #6, "EventOrderingFunction" -> "Random"]
      ] & @@@ $systemsToTest,

      (* Correct number of generations is obtained *)

      VerificationTest[
        SeedRandom[1655];
          WolframModel[
            #1, #2, #6, {"TotalGenerationsCount", "MaxCompleteGeneration"}, "EventOrderingFunction" -> "Random"],
        {#6, #6}
      ] & @@@ $systemsToTest,

      (* Fixed number of generations different seeds difference *)
      (* Even though final sets might be the same for some of these systems, different evaluation order will make *)
      (* evolution objects different *)

      VerificationTest[
        (SeedRandom[1655]; WolframModel[#1, #2, #6, "EventOrderingFunction" -> "Random"]) =!=
          (SeedRandom[1656]; WolframModel[#1, #2, #6, "EventOrderingFunction" -> "Random"])
      ] & @@@ Select[$systemsToTest, #[[7]] =!= $sequential &],

      (** Causal graphs properties check **)

      VerificationTest[
        AcyclicGraphQ[WolframModel[#1, #2, #6, "CausalGraph"]]
      ] & @@@ $systemsToTest,

      VerificationTest[
        LoopFreeGraphQ[WolframModel[#1, #2, #6, "CausalGraph"]]
      ] & @@@ $systemsToTest,

      VerificationTest[
        VertexCount[WolframModel[#1, #2, #6, "CausalGraph"]],
        WolframModel[#1, #2, #6, "EventsCount"]
      ] & @@@ $systemsToTest,

      Table[With[{seed = seed}, {
        VerificationTest[
          SeedRandom[seed]; AcyclicGraphQ[WolframModel[#1, #2, #6, "CausalGraph", "EventOrderingFunction" -> "Random"]]
        ] & @@@ $systemsToTest,

        VerificationTest[
          SeedRandom[seed]; LoopFreeGraphQ[WolframModel[#1, #2, #6, "CausalGraph", "EventOrderingFunction" -> "Random"]]
        ] & @@@ $systemsToTest,

        VerificationTest[
          SeedRandom[seed]; VertexCount[WolframModel[#1, #2, #6, "CausalGraph", "EventOrderingFunction" -> "Random"]],
          SeedRandom[seed]; WolframModel[#1, #2, #6, "EventsCount", "EventOrderingFunction" -> "Random"]
        ] & @@@ $systemsToTest
      }], {seed, 1534, 1634}],

      (** Complex matching **)

      Table[With[{graph = graph, method = method}, VerificationTest[
        SetReplace[
          graph,
          ToPatternRules[graph -> {}],
          1,
          Method -> method],
        {}
      ]], {graph, $graphsForMatching}, {method, $methods}],

      VerificationTest[
        SetReplace[
          {{1, 2}, {2, 3, 4}},
          ToPatternRules[{{2, 3, 4}, {1, 2}} -> {}],
          1,
          Method -> #],
        {}
      ] & /@ $methods,

      VerificationTest[
        SetReplace[
          {{1, 2}, {2, 2, 3}},
          ToPatternRules[{{2, 3, 4}, {1, 2}} -> {}],
          1,
          Method -> #],
        {}
      ] & /@ $methods,

      VerificationTest[
        SetReplace[
          {{1, 2}, {2, 1, 3}},
          ToPatternRules[{{2, 3, 4}, {1, 2}} -> {}],
          1,
          Method -> #],
        {}
      ] & /@ $methods,

      VerificationTest[
        SetReplace[
          {{1, 2}, {1, 1, 3}},
          ToPatternRules[{{2, 3, 4}, {1, 2}} -> {}],
          1,
          Method -> #],
        {{1, 2}, {1, 1, 3}}
      ] & /@ $methods,

      VerificationTest[
        SetReplace[
          {{1, 2}, {2, 1}},
          ToPatternRules[{{1, 2}, {2, 3}} -> {{1, 3}}],
          1,
          Method -> #],
        {{1, 1}}
      ] & /@ $methods,

      (** Random tests **)

      randomSameGraphMatchTests[10, 2, 10000, "LowLevel"],

      randomSameGraphMatchTests[10, 3, 5000, "LowLevel"],

      randomSameGraphMatchTests[10, 6, 1000, "LowLevel"],

      randomSameGraphMatchTests[6, 2, 5000, "Symbolic"],

      randomSameGraphMatchTests[6, 3, 500, "Symbolic"],

      randomSameGraphMatchTests[6, 10, 100, "Symbolic"],

      randomDistinctGraphMatchTests[10, 2, 10000, "LowLevel"],

      randomDistinctGraphMatchTests[10, 3, 10000, "LowLevel"],

      randomDistinctGraphMatchTests[10, 6, 10000, "LowLevel"],

      randomDistinctGraphMatchTests[6, 2, 5000, "Symbolic"],

      randomDistinctGraphMatchTests[6, 3, 5000, "Symbolic"],

      randomDistinctGraphMatchTests[6, 6, 5000, "Symbolic"],

      randomDegenerateGraphMatchTests[10, 2, 10000, "LowLevel"],

      randomDegenerateGraphMatchTests[10, 3, 5000, "LowLevel"],

      randomDegenerateGraphMatchTests[10, 6, 1000, "LowLevel"],

      randomDegenerateGraphMatchTests[6, 2, 5000, "Symbolic"],

      randomDegenerateGraphMatchTests[6, 3, 500, "Symbolic"],

      randomDegenerateGraphMatchTests[6, 10, 100, "Symbolic"],

      (** Evaluation order **)

      VerificationTest[
        SetReplace[{{1}, {2}, {3}, {4}, {5}}, {{{2}, {3}, {4}} -> {{X}}, {{3}} -> {{X}}}],
        {{1}, {2}, {4}, {5}, {X}}
      ],

      With[{methods = $methods}, {
        VerificationTest[
          Table[
            WolframModel[
                <|"PatternRules" -> {{{1, 2}, {2, 3}} -> {{R1}}, {{4, 5}, {5, 6}} -> {{R2}}}|>,
                #,
                <|"MaxEvents" -> 1|>,
                "FinalState",
                Method -> method][[-1, 1]] & /@
              Permutations[{{1, 2}, {2, 3}, {4, 5}, {5, 6}}],
            {method, methods}],
          ConstantArray[{
              R1, R1, R1, R2, R1, R2, R1, R1, R1, R2, R1, R2,
              R1, R2, R1, R2, R2, R2, R1, R2, R1, R2, R2, R2},
            2]
        ],

        VerificationTest[
          Table[
            WolframModel[
                <|"PatternRules" -> {{1, 2, x_}, {1, 2, z_}} :> {{x, z}}|>,
                #,
                <|"MaxEvents" -> 1|>,
                "FinalState",
                Method -> method][[-1]] & /@
              Permutations[{{1, 2, x}, {1, 2, y}, {1, 2, z}}],
            {method, methods}],
          ConstantArray[
            {{x, y}, {x, z}, {y, x}, {y, z}, {z, x}, {z, y}},
            2]
        ],

          VerificationTest[
            Table[
              WolframModel[
                  <|"PatternRules" -> {
                    {{1, 2, x_}, {1, 3, z_}} :> {{1, x, z}},
                    {{1, 2, x_}, {1, 2, z_}} :> {{2, x, z}}}|>,
                  #,
                  <|"MaxEvents" -> 1|>,
                  "FinalState",
                  Method -> method][[-1]] & /@
                Permutations[{{1, 2, x}, {1, 2, y}, {1, 3, z}}],
              {method, methods}],
            ConstantArray[
              {{2, x, y}, {1, x, z}, {2, y, x}, {1, y, z}, {1, x, z}, {1, y, z}},
              2]
        ]
      }],

      VerificationTest[
        WolframModel[
          {{b, c}, {a, b}} -> {},
          {{1, 2}, {3, 4}, {4, 5}, {2, 3}, {a, b}, {b, c}, {5, 6}},
          <|"MaxEvents" -> 1|>,
          "FinalState",
          "EventOrderingFunction" -> #1],
        #2
      ] & @@@ {
        {"OldestEdge", {{3, 4}, {4, 5}, {a, b}, {b, c}, {5, 6}}},
        {"LeastOldEdge", {{1, 2}, {3, 4}, {4, 5}, {2, 3}, {5, 6}}},
        {"LeastRecentEdge", {{1, 2}, {2, 3}, {a, b}, {b, c}, {5, 6}}},
        {"NewestEdge", {{1, 2}, {3, 4}, {2, 3}, {a, b}, {b, c}}},
        {"RuleOrdering", {{1, 2}, {4, 5}, {a, b}, {b, c}, {5, 6}}},
        {"ReverseRuleOrdering", {{1, 2}, {3, 4}, {2, 3}, {a, b}, {b, c}}}
      },

      Function[{ordering, result}, VerificationTest[
          WolframModel[
              <|"PatternRules" -> {{{1, 2}, {2, 3}} -> {{R1}}, {{4, 5}, {5, 6}} -> {{R2}}}|>,
              #,
              <|"MaxEvents" -> 1|>,
              "FinalState",
              "EventOrderingFunction" -> ordering][[-1, 1]] & /@
            Permutations[{{1, 2}, {2, 3}, {4, 5}, {5, 6}}],
          result
      ]] @@@ {
        {"OldestEdge",
          {R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2}},
        {"LeastOldEdge",
          {R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1}},
        {"LeastRecentEdge",
          {R1, R1, R1, R2, R1, R2, R1, R1, R1, R2, R1, R2, R1, R2, R1, R2, R2, R2, R1, R2, R1, R2, R2, R2}},
        {"NewestEdge",
          {R2, R2, R2, R1, R2, R1, R2, R2, R2, R1, R2, R1, R2, R1, R2, R1, R1, R1, R2, R1, R2, R1, R1, R1}},
        {"RuleOrdering",
          {R1, R1, R1, R1, R1, R1, R1, R1, R2, R2, R1, R2, R2, R2, R2, R2, R2, R2, R1, R1, R1, R2, R2, R2}},
        {"ReverseRuleOrdering",
          {R2, R2, R2, R2, R2, R2, R2, R2, R1, R1, R2, R1, R1, R1, R1, R1, R1, R1, R2, R2, R2, R1, R1, R1}},
        {"RuleIndex",
          {R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1}},
        {"ReverseRuleIndex",
          {R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2}}
      },

      Function[{ordering, result}, VerificationTest[
        WolframModel[
            <|"PatternRules" -> {{1, 2, x_}, {1, 2, z_}} :> {{x, z}}|>,
            #,
            <|"MaxEvents" -> 1|>,
            "FinalState",
            "EventOrderingFunction" -> ordering][[-1]] & /@
          Permutations[{{1, 2, x}, {1, 2, y}, {1, 2, z}}],
        result
      ]] @@@ {
        {{"OldestEdge", "RuleOrdering"}, {{x, y}, {x, z}, {y, x}, {y, z}, {z, x}, {z, y}}},
        {"RuleOrdering", {{x, y}, {x, z}, {y, x}, {y, z}, {z, x}, {z, y}}},
        {{"OldestEdge", "ReverseRuleOrdering"}, {{y, x}, {z, x}, {x, y}, {z, y}, {x, z}, {y, z}}}
      },

      Function[{ordering, result}, VerificationTest[
        WolframModel[
            <|"PatternRules" -> {{{1, 2, x_}, {1, 3, z_}} :> {{1, x, z}}, {{1, 2, x_}, {1, 2, z_}} :> {{2, x, z}}}|>,
            #,
            <|"MaxEvents" -> 1|>,
            "FinalState",
            "EventOrderingFunction" -> ordering][[-1]] & /@
          Permutations[{{1, 2, x}, {1, 2, y}, {1, 3, z}}],
        result
      ]] @@@ {
        {{"OldestEdge", "RuleOrdering"}, {{2, x, y}, {1, x, z}, {2, y, x}, {1, y, z}, {1, x, z}, {1, y, z}}},
        {{"RuleIndex", "RuleOrdering"}, {{1, x, z}, {1, x, z}, {1, y, z}, {1, y, z}, {1, x, z}, {1, y, z}}},
        {{"ReverseRuleIndex", "ReverseRuleOrdering"},
          {{2, y, x}, {2, y, x}, {2, x, y}, {2, x, y}, {2, y, x}, {2, x, y}}}
      },

      VerificationTest[
        WolframModel[
          {{{1, 2}, {2, 3}} -> {{1, 3}, {2, 4}, {4, 3}}, {{1, 1}, {2, 1}} -> {{1, 1}}},
          {{2, 2}, {1, 4}, {4, 2}, {1, 2}, {3, 5}, {5, 2}},
          <|"MaxEvents" -> 1|>,
          "FinalState",
          "EventOrderingFunction" -> #1],
        #2
      ] & @@@ {
        {{"OldestEdge", "RuleOrdering"}, {{1, 4}, {1, 2}, {3, 5}, {5, 2}, {2, 2}}},
        {{"OldestEdge", "ReverseRuleOrdering"}, {{1, 4}, {1, 2}, {3, 5}, {5, 2}, {4, 2}, {2, 6}, {6, 2}}},
        {"LeastOldEdge", {{2, 2}, {1, 4}, {4, 2}, {1, 2}, {3, 2}, {5, 6}, {6, 2}}},
        {{"LeastRecentEdge", "RuleOrdering"}, {{1, 4}, {1, 2}, {3, 5}, {5, 2}, {2, 2}}}
      },

      VerificationTest[
        Length[
          Counts[
            Table[
              SeedRandom[k];
              WolframModel[
                {{1, 2}, {1, 3}} -> {{2, 3}},
                {{1, 2}, {1, 3}, {1, 4}, {1, 5}, {1, 6}},
                <|"MaxEvents" -> 1|>,
                "FinalState",
                "EventOrderingFunction" -> "OldestEdge"][[-1]],
              {k, 100}]]],
        2
      ],

      (** Potential variable collision between different rule inputs and outputs **)
      VerificationTest[
        WolframModel[
          {{{1, 1}, {2, 3}} -> {{2, 1}, {2, 2}, {2, 3}, {4, 2}}, {{1, 2}, {1, 2}} -> {{3, 2}}},
          {{1, 0}, {6, 1}, {1, 0}, {1, 1}, {1, 0}, {7, 1}, {3, 0}, {3, 3}, {3, 1}, {8, 3}, {4, 0}, {4, 4}, {4, 0},
            {9, 4}, {2, 2}, {2, 2}, {2, 0}, {10, 2}, {2, 1}, {2, 2}, {2, 0}, {11, 2}, {5, 1}, {5, 5}, {5, 2}, {12, 5}},
          <|"MaxEvents" -> 1|>,
          "FinalState",
          Method -> "Symbolic"],
        {{6, 1}, {1, 1}, {1, 0}, {7, 1}, {3, 0}, {3, 3}, {3, 1}, {8, 3}, {4, 0}, {4, 4}, {4, 0}, {9, 4}, {2, 2}, {2, 2},
          {2, 0}, {10, 2}, {2, 1}, {2, 2}, {2, 0}, {11, 2}, {5, 1}, {5, 5}, {5, 2}, {12, 5}, {13, 0}}
      ],

      VerificationTest[
        SetReplace[{1}, ToPatternRules[{{1, 2} -> {}, {1} -> {2}}], Method -> "Symbolic"],
        {_ ? AtomQ},
        SameTest -> MatchQ
      ],

      (** Check invalid patterns produce a single message. **)
      testUnevaluated[
        SetReplace[
          {{1}},
          {{{Pattern[1, _], v2_}} :> {}, {{Pattern[2, _], v1_}} :> Module[{v2}, {v2}]},
          Method -> "Symbolic"],
        {Pattern::patvar}
      ],

      (** Nested Pattern in the inputs **)
      testUnevaluated[
        SetReplace[
          {{1}},
          {{{Pattern[Pattern[a, _], _], v2_}} :> {}, {{Pattern[2, _], v1_}} :> Module[{v2}, {v2}]},
          Method -> "Symbolic"],
        {Pattern::patvar}
      ],

      (** Relatively large prime number of rules **)
      VerificationTest[
        WolframModel[
          Array[{Range[1, #1]} -> {} &, 59],
          Array[Range[1, #1] &, 59],
          "FinalState"],
        {},
        SameTest -> SameQ
      ]
    }
  |>
|>
