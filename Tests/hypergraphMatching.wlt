<|
  (* These tests are specifically for pattern matching left-hand sides of the rules in both implementations. *)
  "hypergraphMatching" -> <|
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

      $methods = {"Symbolic", "LowLevel", MultisetSubstitutionSystem};

      matchingFunction[method_String] := SetReplace[#Init, ToPatternRules[#HypergraphRule], Method -> method] === {} &;

      matchingFunction[MultisetSubstitutionSystem] =
        (#["EventRuleIndices"]["Length"] > 1 &) @
          Last @
            GenerateMultihistory[MultisetSubstitutionSystem[ToPatternRules[#HypergraphRule]],
                                 <||>,
                                 None,
                                 {"InputCount", "SortedInputTokenIndices", "InputTokenIndices", "RuleIndex"},
                                 <||>] @ #Init &;

      graphFromHyperedges[edges_] := Graph[UndirectedEdge @@@ Flatten[Partition[#, 2, 1] & /@ edges, 1]];

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
      randomSameGraphMatchTestsWithFunction[edgeCount_, edgeLength_, graphCount_, testFunction_] := ModuleScope[
        tests = randomConnectedGraphs[edgeCount, edgeLength, graphCount];
        Map[
          With[{set1 = #[[1]], set2 = #[[2]]},
            VerificationTest[testFunction[<|"Init" -> set1, "HypergraphRule" -> (set2 -> {})|>]]] &,
          BlockRandom[
            {#, RandomSample[#]} & /@ tests,
            RandomSeeding -> ToString[{"randomSameGraphMatchTest", edgeCount, edgeLength, graphCount, method}]]]
      ];

      randomSameGraphMatchTests[edgeCount_, edgeLength_, graphCount_, method_] :=
        randomSameGraphMatchTestsWithFunction[edgeCount, edgeLength, graphCount, matchingFunction[method]];

      (* Here we generate pairs of different graphs, and check they are not being matched *)
      randomDistinctGraphMatchTestsWithFunction[edgeCount_, edgeLength_, graphCount_, testFunction_] := ModuleScope[
        tests = Select[!IsomorphicGraphQ @@ (graphFromHyperedges /@ #) &]
          @ Partition[
            Select[SimpleGraphQ @* graphFromHyperedges]
              @ randomConnectedGraphs[edgeCount, edgeLength, graphCount],
            2];
        Map[
          (* degenerate graphs can still match if not isomorphic, i.e., {{0, 0}} will match {{0, 1}},
             that's why we need to try replacing both ways *)
          With[{set1 = #[[1]], set2 = #[[2]]},
            VerificationTest[testFunction[<|"Init" -> set1, "HypergraphRule" -> (set2 -> {})|>] ||
                             testFunction[<|"Init" -> set2, "HypergraphRule" -> (set1 -> {})|>]]] &,
          tests]
      ];

      randomDistinctGraphMatchTests[edgeCount_, edgeLength_, graphCount_, method_] :=
        randomDistinctGraphMatchTestsWithFunction[edgeCount, edgeLength, graphCount, Not @* matchingFunction[method]];

      (* Here we make initial condition degenerate, and check it still matches, i.e.,
         {{0, 0}} should still match {{0, 1}} *)
      randomDegenerateGraphMatchTestsWithFunction[edgeCount_, edgeLength_, graphCount_, testFunction_] := ModuleScope[
        tests = randomConnectedGraphs[edgeCount, edgeLength, graphCount];
        Map[
          With[{set1 = #[[1]], identifiedVertex1 = #[[2]], identifiedVertex2 = #[[3]], set2 = #[[4]]},
            VerificationTest[
              testFunction[
                <|"Init" -> set1 /. identifiedVertex1 -> identifiedVertex2, "HypergraphRule" -> (set2 -> {})|>]]] &,
          BlockRandom[
            {#, RandomChoice[Flatten[#]], RandomChoice[Flatten[#]], RandomSample[#]} & /@ tests,
            RandomSeeding -> ToString[{"randomDegenerateGraphMatchTest", edgeCount, edgeLength, graphCount, method}]]]
      ];

      randomDegenerateGraphMatchTests[edgeCount_, edgeLength_, graphCount_, method_] :=
        randomDegenerateGraphMatchTestsWithFunction[edgeCount, edgeLength, graphCount, matchingFunction[method]];
    ),
    "tests" -> {
      (** Complex matching **)

      Function[{graph, method},
          VerificationTest[matchingFunction[method][<|"Init" -> graph, "HypergraphRule" -> (graph -> {})|>]]] @@@
        Tuples[{$graphsForMatching, $methods}],

      Function[{method},
        Function[{init, hypergraphRule},
            VerificationTest[matchingFunction[method][<|"Init" -> init, "HypergraphRule" -> hypergraphRule|>]]] @@@
          {{{{1, 2}, {2, 3, 4}}, {{2, 3, 4}, {1, 2}} -> {}},
          {{{1, 2}, {2, 2, 3}}, {{2, 3, 4}, {1, 2}} -> {}},
          {{{1, 2}, {2, 1, 3}}, {{2, 3, 4}, {1, 2}} -> {}}}] /@ $methods,

      VerificationTest[
          Not @
            matchingFunction[#][
              <|"Init" -> {{1, 2}, {1, 1, 3}}, "HypergraphRule" -> ({{2, 3, 4}, {1, 2}} -> {})|>]] & /@
        $methods,

      VerificationTest[
        SetReplace[
          {{1, 2}, {2, 1}},
          ToPatternRules[{{1, 2}, {2, 3}} -> {{1, 3}}],
          1,
          Method -> #],
        {{1, 1}}
      ] & /@ {"LowLevel", "Symbolic"},

      VerificationTest[
        Normal @
          (#["Expressions"] &) @
            Last @
              GenerateMultihistory[MultisetSubstitutionSystem[ToPatternRules[{{1, 2}, {2, 3}} -> {{1, 3}}]],
                                   <||>,
                                   None,
                                   {"InputCount", "SortedInputTokenIndices", "InputTokenIndices", "RuleIndex"},
                                   <|"MaxEvents" -> 1|>][{{1, 2}, {2, 1}}],
        {{1, 2}, {2, 1}, {1, 1}}
      ],

      (** Random tests **)

      randomSameGraphMatchTests[##, "LowLevel"] & @@@ {{10, 2, 10000}, {10, 3, 5000}, {10, 6, 1000}},
      {randomSameGraphMatchTests[##, "Symbolic"], randomSameGraphMatchTests[##, MultisetSubstitutionSystem]} & @@@
        {{6, 2, 5000}, {6, 3, 500}, {6, 10, 100}},

      randomDistinctGraphMatchTests[##, "LowLevel"] & @@@ {{10, 2, 10000}, {10, 3, 10000}, {10, 6, 10000}},
      {randomDistinctGraphMatchTests[##, "Symbolic"],
          randomDistinctGraphMatchTests[##, MultisetSubstitutionSystem]} & @@@
        {{6, 2, 5000}, {6, 3, 5000}, {6, 6, 5000}},

      randomDegenerateGraphMatchTests[##, "LowLevel"] & @@@ {{10, 2, 10000}, {10, 3, 5000}, {10, 6, 1000}},
      {randomDegenerateGraphMatchTests[##, "Symbolic"],
          randomDegenerateGraphMatchTests[##, MultisetSubstitutionSystem]} & @@@
        {{6, 2, 5000}, {6, 3, 500}, {6, 10, 100}}
    }
  |>
|>
