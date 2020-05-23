<|
  "FutureOverlapGraph" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];

      sameGraphQ[g1_, g2_] := And[
        SameQ @@ (Sort /@ VertexList /@ {g1, g2}),
        SameQ @@ (Sort /@ Replace[EdgeList /@ {g1, g2}, e_UndirectedEdge -> Sort[e], {1}])
      ];

      Attributes[sameGraphTest] = {HoldAllComplete};
      sameGraphTest[input_, expected_] := VerificationTest[input, expected, SameTest -> sameGraphQ]
    ),
    "tests" -> {
      testSymbolLeak[
        FutureOverlapGraph[Graph[{1 -> a, 1 -> b, 2 -> b, 2 -> c, 3 -> c}], {1, 2, 3}, {a, b, c}]
      ],

      (* Arguments handling *)

      testUnevaluated[
        FutureOverlapGraph[],
        {FutureOverlapGraph::argrx}
      ],

      testUnevaluated[
        FutureOverlapGraph[1],
        {FutureOverlapGraph::argr}
      ],

      testUnevaluated[
        FutureOverlapGraph[1, 2],
        {FutureOverlapGraph::argrx}
      ],

      testUnevaluated[
        FutureOverlapGraph[1, 2, 3, 4],
        {FutureOverlapGraph::argrx}
      ],

      testUnevaluated[
        FutureOverlapGraph[1, 2, 3],
        {FutureOverlapGraph::graph}
      ],

      testUnevaluated[
        FutureOverlapGraph[Graph[1, 2], 2, 3],
        {FutureOverlapGraph::graph}
      ],

      testUnevaluated[
        FutureOverlapGraph[Graph[{1 -> 2}], 2, 3],
        {FutureOverlapGraph::list}
      ],

      testUnevaluated[
        FutureOverlapGraph[Graph[{1 -> 2}], {1}, 3],
        {FutureOverlapGraph::list}
      ],

      testUnevaluated[
        FutureOverlapGraph[Graph[{1 -> 2}], {x}, {2}],
        {FutureOverlapGraph::inv}
      ],

      testUnevaluated[
        FutureOverlapGraph[Graph[{1 -> 2}], {1}, {x}],
        {FutureOverlapGraph::inv}
      ],

      testUnevaluated[
        FutureOverlapGraph[Graph[{1 -> 2}], {x}, {y}],
        {FutureOverlapGraph::inv}
      ],

      testUnevaluated[
        FutureOverlapGraph[Graph[{1 -> 2}], {1, x}, {2}],
        {FutureOverlapGraph::inv}
      ],

      testUnevaluated[
        FutureOverlapGraph[Graph[{1 -> 2}], {1}, {2}, InvalidOption -> 0],
        {FutureOverlapGraph::optx}
      ],

      testUnevaluated[
        FutureOverlapGraph[Graph[{1 -> 2}], {1}, {2}, VertexCoordinates -> -1],
        With[{
            before = $MessageList, after = (Quiet[Graph[{1}, {}, VertexCoordinates -> -1]; $MessageList])},
          Complement[after, before]]
      ],

      (* Implementation *)

      sameGraphTest[
        FutureOverlapGraph[Graph[{}], {}, {}],
        Graph[{}]
      ],

      sameGraphTest[
        FutureOverlapGraph[Graph[{1}, {}], {1}, {}],
        Graph[{{1}}, {}]
      ],

      sameGraphTest[
        FutureOverlapGraph[Graph[{1}, {}], {}, {1}],
        Graph[{{1}}, {}]
      ],

      sameGraphTest[
        FutureOverlapGraph[Graph[{1}, {}], {1}, {1}],
        Graph[{{1}}, {}]
      ],

      sameGraphTest[
        FutureOverlapGraph[Graph[{1, 2}, {}], {1, 2}, {}],
        Graph[{{1, 2}}, {}]
      ],

      sameGraphTest[
        FutureOverlapGraph[Graph[{1, 2}, {}], {1}, {2}],
        Graph[{{1}}, {}]
      ],

      sameGraphTest[
        FutureOverlapGraph[Graph[{1, 2}, {}], {1, 2}, {1}],
        Graph[{{1, 2}}, {}]
      ],

      sameGraphTest[
        FutureOverlapGraph[Graph[{1 -> 2}], {1, 2}, {1}],
        Graph[{{1, 2}}, {}]
      ],

      sameGraphTest[
        FutureOverlapGraph[Graph[{1 -> 2}], {1, 2}, {2}],
        Graph[{{1, 2}}, {}]
      ],

      sameGraphTest[
        FutureOverlapGraph[Graph[{1 -> 2}], {1, 2}, {1, 2}],
        Graph[{{1}, {2}}, {{1} -> {2}}]
      ],

      sameGraphTest[
        FutureOverlapGraph[Graph[{1 -> 2, 2 -> 1}], {1, 2}, {1, 2}],
        Graph[{{1, 2}}, {}]
      ],

      sameGraphTest[
        FutureOverlapGraph[Graph[{1 -> a, 2 -> b}], {1, 2}, {a, b}],
        Graph[{{1}, {2}}, {}]
      ],

      sameGraphTest[
        FutureOverlapGraph[Graph[{1 -> a, 1 -> b, 2 -> b}], {1, 2}, {a, b}],
        Graph[{{1}, {2}}, {{1} -> {2}}]
      ],

      sameGraphTest[
        FutureOverlapGraph[Graph[{1 -> a, 1 -> b, 2 -> a, 2 -> b}], {1, 2}, {a, b}],
        Graph[{{1, 2}}, {}]
      ],

      sameGraphTest[
        FutureOverlapGraph[Graph[{1 -> a, 1 -> b, 2 -> b, 2 -> c}], {1, 2}, {a, b, c}],
        Graph[{{1}, {2}}, {{1} <-> {2}}]
      ],

      sameGraphTest[
        FutureOverlapGraph[Graph[{1 -> a, 1 -> b, 2 -> b, 2 -> c, 3 -> c}], {1, 2, 3}, {a, b, c}],
        Graph[{{1}, {2}, {3}}, {{1} <-> {2}, {2} -> {3}}]
      ],

      sameGraphTest[
        FutureOverlapGraph[Graph[{1 -> a, 1 -> b, 2 -> b, 2 -> c, 3 -> c, 3 -> a}], {1, 2, 3}, {a, b, c}],
        Graph[{{1}, {2}, {3}}, {{1} <-> {2}, {2} <-> {3}, {1} <-> {3}}]
      ],

      sameGraphTest[
        FutureOverlapGraph[
          Graph[{1 -> 2, 2 -> 3, 3 -> 1, 1 -> a, 1 -> b, 2 -> b, 2 -> c, 3 -> c, 3 -> a}], {1, 2, 3}, {a, b, c}],
        Graph[{{1, 2, 3}}, {}]
      ],

      VerificationTest[
        Options[
          FutureOverlapGraph[Graph[{1 -> a, 1 -> b, 2 -> b, 2 -> c}], {1, 2}, {a, b, c}, VertexLabels -> Automatic],
          VertexLabels],
        Options[Graph[{1 <-> 2}, VertexLabels -> Automatic], VertexLabels]
      ]
    }
  |>
|>
