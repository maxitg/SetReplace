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
        {HypergraphToGraph::argrx}
      ],

      testUnevaluated[
        HypergraphToGraph[{{1}}],
        {HypergraphToGraph::argr}
      ],

      testUnevaluated[
        HypergraphToGraph[{{1}}, "DirectedDistancePreserving", Automatic],
        {HypergraphToGraph::argrx}
      ],

      (** invalid options **)
      testUnevaluated[
        HypergraphToGraph[{{1}}, "StructurePreserving", "invalid" -> "option"],
        {HypergraphToGraph::optx}
      ],

      (** invalid hypergraph **)
      testUnevaluated[
        HypergraphToGraph[{1, {2}}, "DirectedDistancePreserving"],
        {HypergraphToGraph::invalidHypergraph}
      ],

      (** invalid method **)
      testUnevaluated[
        HypergraphToGraph[{{2}}, "DistancePreservin"],
        {HypergraphToGraph::invalidMethod}
      ],

      (* "DirectedDistancePreserving" *)
      VerificationTest[
        HypergraphToGraph[{}, "DirectedDistancePreserving"],
        Graph[{}, {}]
      ],

      VerificationTest[
        HypergraphToGraph[{{}}, "DirectedDistancePreserving"],
        Graph[{}, {}]
      ],

      VerificationTest[
        HypergraphToGraph[{{1}}, "DirectedDistancePreserving"],
        Graph[{1}, {}]
      ],

      VerificationTest[
        HypergraphToGraph[{{1, 1}}, "DirectedDistancePreserving"],
        Graph[{1}, {DirectedEdge[1, 1]}]
      ],

      VerificationTest[
        HypergraphToGraph[{{1, 1, 1}}, "DirectedDistancePreserving"],
        Graph[{1}, {DirectedEdge[1, 1], DirectedEdge[1, 1], DirectedEdge[1, 1]}]
      ],

      VerificationTest[
        HypergraphToGraph[{{1, 2, 1}}, "DirectedDistancePreserving"],
        Graph[{1}, {DirectedEdge[1, 1], DirectedEdge[1, 2], DirectedEdge[2, 1]}]
      ],

      VerificationTest[
        HypergraphToGraph[{Range[4]}, "DirectedDistancePreserving"],
        Graph[{1, 2, 3, 4}, {{{1, 2}, {1, 3}, {1, 4}, {2, 3}, {2, 4}, {3, 4}}, Null}]
      ],

      VerificationTest[
        HypergraphToGraph[{{1, {3}, 2}, {2, 1, {3}}, {1, 1}, {2}}, "DirectedDistancePreserving"],
        Graph[{1, 2, {3}}, {{{1, 1}, {1, 2}, {1, 3}, {1, 3}, {2, 1}, {2, 3}, {3, 2}}, Null}]
      ],

      (* "UndirectedDistancePreserving" *)
      VerificationTest[
        HypergraphToGraph[{}, "UndirectedDistancePreserving"],
        Graph[{}, {}]
      ],

      VerificationTest[
        HypergraphToGraph[{{}}, "UndirectedDistancePreserving"],
        Graph[{}, {}]
      ],

      VerificationTest[
        HypergraphToGraph[{{1}}, "UndirectedDistancePreserving"],
        Graph[{1}, {}]
      ],

      VerificationTest[
        HypergraphToGraph[{{1, 1}}, "UndirectedDistancePreserving"],
        Graph[{1}, {UndirectedEdge[1, 1]}]
      ],

      VerificationTest[
        HypergraphToGraph[{{1, 1, 1}}, "UndirectedDistancePreserving"],
        Graph[{1}, {UndirectedEdge[1, 1], UndirectedEdge[1, 1], UndirectedEdge[1, 1]}]
      ],

      VerificationTest[
        HypergraphToGraph[{{1, 2, 1}}, "UndirectedDistancePreserving"],
        Graph[{1}, {UndirectedEdge[1, 1], UndirectedEdge[1, 2], UndirectedEdge[2, 1]}]
      ]
    }
  |>
|>
