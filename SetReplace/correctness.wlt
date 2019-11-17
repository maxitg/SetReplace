<|
  "correctness" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];

      sameSetQ[x_, y_] := Module[{xAtoms, yAtoms},
        {xAtoms, yAtoms} = DeleteDuplicates[Flatten[#]] & /@ {x, y};
        If[Length[xAtoms] != Length[yAtoms], Return[False]];
        (x /. Thread[xAtoms -> yAtoms]) === y
      ];

      $systemsToTest = {
        {{{0, 1}}, ToPatternRules[{{0, 1}} -> {{0, 2}, {2, 1}}], 100, 6},
        {{{1}}, ToPatternRules[{{{1}} -> {{1}}}], 100, 100},
        {{{1}}, ToPatternRules[{{{1}} -> {{2}}}], 100, 100},
        {{{1}}, ToPatternRules[{{{1}} -> {{2}, {1, 2}}}], 100, 6},
        {{{1}}, ToPatternRules[{{{1}} -> {{1}, {2}, {1, 1}}}], 100, 6},
        {{{1}}, ToPatternRules[{{{1}} -> {{1}, {2}, {1, 2}}}], 100, 6},
        {{{1}}, ToPatternRules[{{{1}} -> {{1}, {2}, {1, 3}}}], 100, 6},
        {{{1}}, ToPatternRules[{{{1}} -> {{2}, {2}, {1, 2}}}], 100, 6},
        {{{1}}, ToPatternRules[{{{1}} -> {{2}, {3}, {1, 2}}}], 100, 6},
        {{{1}}, ToPatternRules[{{{1}} -> {{2}, {3}, {1, 2, 4}}}], 100, 6},
        {{{1}}, ToPatternRules[{{{1}} -> {{2}, {2}, {2}, {1, 2}}}], 100, 4},
        {{{1}, {1}, {1}}, ToPatternRules[{{{1}} -> {{2}, {1, 2}}}], 100, 34},
        {{{1, 1}}, ToPatternRules[{{{1, 2}} -> {{1, 3}, {2, 3}}}], 100, 6},
        {{{0, 1}, {0, 2}, {0, 3}},
          {{{a_, b_}, {a_, c_}, {a_, d_}} :>
            Module[{$0, $1, $2}, {
              {$0, $1}, {$1, $2}, {$2, $0}, {$0, $2}, {$2, $1}, {$1, $0},
              {$0, b}, {$1, c}, {$2, d}}]},
          30,
          3},
        {{{0, 0}, {0, 0}, {0, 0}},
          {{{a_, b_}, {a_, c_}, {a_, d_}} :>
            Module[{$0, $1, $2}, {
              {$0, $1}, {$1, $2}, {$2, $0}, {$0, $2}, {$2, $1}, {$1, $0},
              {$0, b}, {$1, c}, {$2, d}}]},
          30,
          3},
        {{{0, 1}, {0, 2}, {0, 3}},
          {{{a_, b_}, {a_, c_}, {a_, d_}} :>
            Module[{$0, $1, $2}, {
              {$0, $1}, {$1, $2}, {$2, $0}, {$0, $2}, {$2, $1}, {$1, $0},
              {$0, b}, {$1, c}, {$2, d}, {b, $2}, {d, $0}}]},
          30,
          3},
        {{{0, 0}, {0, 0}, {0, 0}},
          {{{a_, b_}, {a_, c_}, {a_, d_}} :>
            Module[{$0, $1, $2}, {
              {$0, $1}, {$1, $2}, {$2, $0}, {$0, $2}, {$2, $1}, {$1, $0},
              {$0, b}, {$1, c}, {$2, d}, {b, $2}, {d, $0}}]},
          30,
          3}
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
        SetReplace[##, Method -> "Symbolic"],
        SetReplace[##, Method -> "LowLevel"],
        SameTest -> sameSetQ
      ] & @@@ $systemsToTest[[All, {1, 2, 3}]],

      (* Fixed number of generations *)

      VerificationTest[
        SetReplaceAll[##, Method -> "Symbolic"],
        SetReplaceAll[##, Method -> "LowLevel"],
        SameTest -> sameSetQ
      ] & @@@ $systemsToTest[[All, {1, 2, 4}]],

      (* Causal graphs consistency *)

      VerificationTest[
        WolframModel[<|"PatternRules" -> #1|>, #2, #3, "CausalGraph", Method -> "Symbolic"],
        WolframModel[<|"PatternRules" -> #1|>, #2, #3, "CausalGraph", Method -> "LowLevel"]
      ] & @@@ $systemsToTest[[All, {2, 1, 4}]],

      (** Causal graphs properties check **)

      VerificationTest[
        AcyclicGraphQ[WolframModel[<|"PatternRules" -> #1|>, #2, #3, "CausalGraph"]]
      ] & @@@ $systemsToTest[[All, {2, 1, 4}]],

      VerificationTest[
        LoopFreeGraphQ[WolframModel[<|"PatternRules" -> #1|>, #2, #3, "CausalGraph"]]
      ] & @@@ $systemsToTest[[All, {2, 1, 4}]],

      VerificationTest[
        VertexCount[WolframModel[<|"PatternRules" -> #1|>, #2, #3, "CausalGraph"]],
        WolframModel[<|"PatternRules" -> #1|>, #2, #3, "EventsCount"]
      ] & @@@ $systemsToTest[[All, {2, 1, 4}]],

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

      VerificationTest[
        Table[
          WolframModel[
              <|"PatternRules" -> {{{1, 2}, {2, 3}} -> {{R1}}, {{4, 5}, {5, 6}} -> {{R2}}}|>,
              #,
              <|"Events" -> 1|>,
              "FinalState",
              Method -> method][[-1, 1]] & /@
            Permutations[{{1, 2}, {2, 3}, {4, 5}, {5, 6}}],
          {method, $methods}],
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
              <|"Events" -> 1|>,
              "FinalState",
              Method -> method][[-1]] & /@
            Permutations[{{1, 2, x}, {1, 2, y}, {1, 2, z}}],
          {method, $methods}],
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
              <|"Events" -> 1|>,
              "FinalState",
              Method -> method][[-1]] & /@
            Permutations[{{1, 2, x}, {1, 2, y}, {1, 3, z}}],
          {method, $methods}],
        ConstantArray[
          {{2, x, y}, {1, x, z}, {2, y, x}, {1, y, z}, {1, x, z}, {1, y, z}},
          2]
      ],

      (** Potential variable collision between different rule inputs and outputs **)
      VerificationTest[
        WolframModel[
          {{{1, 1}, {2, 3}} -> {{2, 1}, {2, 2}, {2, 3}, {4, 2}}, {{1, 2}, {1, 2}} -> {{3, 2}}},
          {{1, 0}, {6, 1}, {1, 0}, {1, 1}, {1, 0}, {7, 1}, {3, 0}, {3, 3}, {3, 1}, {8, 3}, {4, 0}, {4, 4}, {4, 0},
            {9, 4}, {2, 2}, {2, 2}, {2, 0}, {10, 2}, {2, 1}, {2, 2}, {2, 0}, {11, 2}, {5, 1}, {5, 5}, {5, 2}, {12, 5}},
          <|"Events" -> 1|>,
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
      ]
    }
  |>
|>
