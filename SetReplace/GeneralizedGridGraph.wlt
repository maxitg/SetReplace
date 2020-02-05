<|
  "GeneralizedGridGraph" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];
    ),
    "tests" -> {
      testSymbolLeak[
        GeneralizedGridGraph[{4, 4 -> "Circular", 5 -> "Directed"}]
      ],
      
      testUnevaluated[
        GeneralizedGridGraph[],
        {GeneralizedGridGraph::argx}
      ],

      testUnevaluated[
        GeneralizedGridGraph[1, 2],
        {GeneralizedGridGraph::argx}
      ],

      testUnevaluated[
        GeneralizedGridGraph[1],
        {GeneralizedGridGraph::dimsNotList}
      ],

      testUnevaluated[
        GeneralizedGridGraph[#],
        {GeneralizedGridGraph::invalidDimSpec}
      ] & /@ {
        {"x"}, {x}, {-1}, {1 -> x}, {1 -> "x"}, {1 -> 1}, {1 -> {"x"}}, {1 -> {"Directed", "x"}},
        {1 -> {"Directed", "Circular"}, 2, 3 -> x}},

      VerificationTest[
        EmptyGraphQ[GeneralizedGridGraph[{0}]]
      ],

      VerificationTest[
        Through[{VertexList, EdgeList} @ GeneralizedGridGraph[#]],
        {{1}, {}},
        SameTest -> MatchQ
      ] & /@ {{1}, {1 -> "Directed"}, {1 -> {"Directed"}}},

      VerificationTest[
        Through[{VertexList, EdgeList} @ GeneralizedGridGraph[{1 -> "Circular"}]],
        {{1}, {UndirectedEdge[1, 1]}},
        SameTest -> MatchQ
      ],

      VerificationTest[
        Through[{VertexList, EdgeList} @ GeneralizedGridGraph[#]],
        {{1}, {DirectedEdge[1, 1]}},
        SameTest -> MatchQ
      ] & /@ {{1 -> {"Circular", "Directed"}}, {1 -> {"Directed", "Circular", "Circular"}}},

      VerificationTest[
        EdgeCount[GeneralizedGridGraph[{1 -> {"Directed", "Circular"}, 2, 3 -> "Directed"}]],
        13
      ],

      VerificationTest[
        IsomorphicGraphQ[GeneralizedGridGraph[{10, 5, 2}], GridGraph[{10, 5, 2}]]
      ],

      VerificationTest[
        IsomorphicGraphQ[GeneralizedGridGraph[{10}], GridGraph[{10}]]
      ],

      VerificationTest[
        IsomorphicGraphQ[GeneralizedGridGraph[{10 -> "Circular"}], CycleGraph[10]]
      ],

      VerificationTest[
        IsomorphicGraphQ[GeneralizedGridGraph[{10 -> {"Circular", "Directed"}}], CycleGraph[10, DirectedEdges -> True]]
      ],

      VerificationTest[
        IsomorphicGraphQ[GeneralizedGridGraph[{10 -> "Directed"}], PathGraph[Range[10], DirectedEdges -> True]]
      ],

      VerificationTest[
        GeneralizedGridGraph[{2 -> "Directed", 2 -> {"Circular", "Directed"}}],
        Graph[Join[DirectedEdge @@@ {{1, 3}, {2, 4}, {1, 2}, {2, 1}, {3, 4}, {4, 3}}]],
        SameTest -> IsomorphicGraphQ
      ],

      VerificationTest[
        GroupOrder[GraphAutomorphismGroup[GeneralizedGridGraph[#1]]],
        #2
      ] & @@@ {
        {{10, 9}, 4},
        {{10 -> "Directed", 9 -> "Directed"}, 1},
        {{10 -> "Circular", 9}, 40},
        {{10 -> "Circular", 9 -> "Circular"}, 360},
        {{10 -> {"Circular", "Directed"}, 9 -> {"Circular", "Directed"}}, 90},
        {{10 -> {"Circular", "Directed"}, 9 -> {"Circular", "Directed"}, 3 -> {"Circular", "Directed"}}, 270}
      },

      VerificationTest[
        Options[GeneralizedGridGraph[#1], GraphLayout],
        {GraphLayout -> {"GridEmbedding", "Dimension" -> #2}}
      ] & @@@ {{{4, 6}, {4, 6}}, {{4 -> "Directed", 6}, {4, 6}}, {{6, 4}, {6, 4}}},

      VerificationTest[
        Options[GeneralizedGridGraph[#], GraphLayout],
        {GraphLayout -> "SpringElectricalEmbedding"}
      ] & /@ {{3}, {3, 3, 3}, {3 -> "Circular", 5}},

      VerificationTest[
        With[{graph = GeneralizedGridGraph[#]},
          AllTrue[
            EdgeList[graph] /.
              Thread[VertexList[graph] -> (VertexCoordinates /. AbsoluteOptions[graph, VertexCoordinates][[1]])] /.
              (UndirectedEdge | DirectedEdge) -> EuclideanDistance,
            0.999 < # < 1.001 &]
        ]
      ] & /@ {{4, 6}, {6, 4}, {3, 3}, {45, 76}, {6 -> "Directed", 8}, {5, 8 -> "Directed"}, {7 -> "Directed", 2 -> "Directed"}}
    }
  |>
|>
