<|
  (* These tests are specifically for pattern matching left-hand sides of the rules in both implementations. *)
  "matching" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];

      (* Assign variables that ToPatternRules would use to confuse setSubstitutionSystem as much as possible. *)
      v1 = v2 = v3 = v4 = v5 = 1;

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

      randomDegenerateGraphMatchTests[6, 10, 100, "Symbolic"]
    }
  |>
|>
