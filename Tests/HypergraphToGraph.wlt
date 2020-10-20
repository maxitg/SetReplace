<|
  "HypergraphToGraph" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
    ),
    "tests" -> {

      (* unevaluated *)

      (** argument count **)
      testUnevaluated[
        HypergraphToGraph[],
        {HypergraphToGraph::argx}
      ],

      testUnevaluated[
        HypergraphToGraph[{{1}}],
        {HypergraphToGraph::argr}
      ],

      testUnevaluated[
        HypergraphToGraph[{{1}}, "DistancePreserving", Automatic],
        {HypergraphToGraph::argx}
      ],

      (** invalid hypergraph **)
      testUnevaluated[
        HypergraphToGraph[{1, {2}}, "DistancePreserving"],
        {HypergraphToGraph::invalidHypergraph}
      ],

      (** invalid method **)
      testUnevaluated[
        HypergraphToGraph[{{2}}, "DistancePreservin"],
        {HypergraphToGraph::invalidMethod}
      ],

      (* "DistancePreserving" *)
      VerificationTest[
        HypergraphToGraph[{}, "DistancePreserving"],
        Graph[{}, {}]
      ],

      VerificationTest[
        HypergraphToGraph[{{}}, "DistancePreserving"],
        Graph[{}, {}]
      ],

      VerificationTest[
        HypergraphToGraph[{{{1}}}, "DistancePreserving"],
        Graph[{1}, {}]
      ],

      VerificationTest[
        HypergraphToGraph[{Range[4]}, "DistancePreserving"],
        Graph[
          {1, 2, 3, 4},
          {
            DirectedEdge[1, 2],
            DirectedEdge[1, 3],
            DirectedEdge[2, 3],
            DirectedEdge[1, 4],
            DirectedEdge[2, 4],
            DirectedEdge[3, 4]}]
      ],

      VerificationTest[
        HypergraphToGraph[{{1, {3}, 2}, {2, 1, {3}}, {1, 1}, {2}}, "DistancePreserving"],
        Graph[
          {1, 2, {3}},
          {
            DirectedEdge[1, {3}],
            DirectedEdge[1, 2],
            DirectedEdge[{3}, 2],
            DirectedEdge[2, 1],
            DirectedEdge[2, {3}],
            DirectedEdge[1, {3}],
            DirectedEdge[1, 1]}]
      ]
    }
  |>
|>
