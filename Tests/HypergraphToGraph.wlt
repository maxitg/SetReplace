<|
  "HypergraphToGraph" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];

      getVertexEdgeList[graph_?GraphQ] := Through[{VertexList, EdgeList} @ graph];
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
        Graph[{1, 2, 3, 4}, {1 -> 2, 1 -> 3, 1 -> 4, 2 -> 3, 2 -> 4, 3 -> 4}]
      ],

      VerificationTest[
        HypergraphToGraph[{{1, {3}, 2}, {2, 1, {3}}, {1, 1}, {2}}, "DirectedDistancePreserving"],
        Graph[{1, 2, {3}}, {1 -> 1, 1 -> 2, 1 -> {3}, 1 -> {3}, 2 -> 1, 2 -> {3}, {3} -> 2}]
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
      ],

      VerificationTest[
        HypergraphToGraph[{Range[4]}, "UndirectedDistancePreserving"],
        Graph[
          {1, 2, 3, 4},
          {1 -> 2, 1 -> 3, 1 -> 4, 2 -> 3, 2 -> 4, 3 -> 4},
          DirectedEdges -> False]
      ],

      VerificationTest[
        HypergraphToGraph[{{1, {3}, 2}, {2, 1, {3}}, {1, 1}, {2}}, "UndirectedDistancePreserving"],
        Graph[
          {1, 2, {3}},
          {1 -> 1, 1 -> 2, 1 -> {3}, 1 -> {3}, 2 -> 1, 2 -> {3}, {3} -> 2},
          DirectedEdges -> False]
      ],

      (* "StructurePreserving" *)
      VerificationTest[
        HypergraphToGraph[{}, "StructurePreserving"],
        Graph[{}, {}]
      ],

      VerificationTest[
        getVertexEdgeList @ HypergraphToGraph[{{}}, "StructurePreserving"],
        getVertexEdgeList @ Graph[{{"Hyperedge", 1, 0}}, {}]
      ],

      VerificationTest[
        getVertexEdgeList @ HypergraphToGraph[{{1}}, "StructurePreserving"],
        getVertexEdgeList @ Graph[
          {{"Vertex", 1}, {"Hyperedge", 1, 1}},
          {{"Hyperedge", 1, 1} -> {"Vertex", 1}}]
      ],

      VerificationTest[
        getVertexEdgeList @ HypergraphToGraph[{{1, 1}}, "StructurePreserving"],
        getVertexEdgeList @ Graph[
          {{"Vertex", 1}, {"Hyperedge", 1, 1}, {"Hyperedge", 1, 2}},
          {
            {"Hyperedge", 1, 1} -> {"Vertex", 1},
            {"Hyperedge", 1, 1} -> {"Hyperedge", 1, 2},
            {"Hyperedge", 1, 2} -> {"Vertex", 1}}]
      ],

      VerificationTest[
        getVertexEdgeList @ HypergraphToGraph[{{1, 1, 1}}, "StructurePreserving"],
        getVertexEdgeList @ Graph[
          {
            {"Vertex", 1},
            {"Hyperedge", 1, 1},
            {"Hyperedge", 1, 2},
            {"Hyperedge", 1, 3}},
          {
            {"Hyperedge", 1, 1} -> {"Vertex", 1},
            {"Hyperedge", 1, 1} -> {"Hyperedge", 1, 2},
            {"Hyperedge", 1, 2} -> {"Vertex", 1},
            {"Hyperedge", 1, 2} -> {"Hyperedge", 1, 3},
            {"Hyperedge", 1, 3} -> {"Vertex", 1}}]
      ],

      VerificationTest[
        getVertexEdgeList @ HypergraphToGraph[{{1, 2, 1}}, "StructurePreserving"],
        getVertexEdgeList @ Graph[
          {
            {"Vertex", 1},
            {"Vertex", 2},
            {"Hyperedge", 1, 1},
            {"Hyperedge", 1, 2},
            {"Hyperedge", 1, 3}},
          {
            {"Hyperedge", 1, 1} -> {"Vertex", 1},
            {"Hyperedge", 1, 1} -> {"Hyperedge", 1, 2},
            {"Hyperedge", 1, 2} -> {"Vertex", 2},
            {"Hyperedge", 1, 2} -> {"Hyperedge", 1, 3},
            {"Hyperedge", 1, 3} -> {"Vertex", 1}}]
      ],

      VerificationTest[
        getVertexEdgeList @ HypergraphToGraph[{{x, x, y, z}, {z, w}}, "StructurePreserving"],
        getVertexEdgeList @ Graph[
          {
            {"Vertex", w},
            {"Vertex", x},
            {"Vertex", y},
            {"Vertex", z},
            {"Hyperedge", 1, 1},
            {"Hyperedge", 1, 2},
            {"Hyperedge", 1, 3},
            {"Hyperedge", 1, 4},
            {"Hyperedge", 2, 1},
            {"Hyperedge", 2, 2}},
          {
            {"Hyperedge", 1, 1} -> {"Vertex", x},
            {"Hyperedge", 1, 1} -> {"Hyperedge", 1, 2},
            {"Hyperedge", 1, 2} -> {"Vertex", x},
            {"Hyperedge", 1, 2} -> {"Hyperedge", 1, 3},
            {"Hyperedge", 1, 3} -> {"Vertex", y},
            {"Hyperedge", 1, 3} -> {"Hyperedge", 1, 4},
            {"Hyperedge", 1, 4} -> {"Vertex", z},
            {"Hyperedge", 2, 1} -> {"Vertex", z},
            {"Hyperedge", 2, 1} -> {"Hyperedge", 2, 2},
            {"Hyperedge", 2, 2} -> {"Vertex", w}}]
      ],

      (* test style*)
      With[{graph = HypergraphToGraph[{{x, x, y, z}, {z, w}}, "StructurePreserving"]},
        VerificationTest[
          !MatchQ[
            AnnotationValue[{graph, VertexList[graph, {"Hyperedge", _, _}]}, VertexStyle],
            {__Automatic}] &&
          !MatchQ[
            AnnotationValue[{graph, VertexList[graph, {"Hyperedge", _, _}]}, EdgeStyle],
            {__Automatic}],
          True
        ]
      ]
    }
  |>
|>
