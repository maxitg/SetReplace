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
        {GeneralizedGridGraph::nonopt}
      ],

      testUnevaluated[
        GeneralizedGridGraph[{2, 3}, "$$$invalid$$$" -> 123],
        {GeneralizedGridGraph::optx}
      ],

      (* same behavior as GridGraph *)
      testUnevaluated[
        GeneralizedGridGraph[{2, 3}, VertexCoordinates -> "$$$invalid$$$"],
        {}
      ],

      testUnevaluated[
        GeneralizedGridGraph[{4, 5}, "VertexNamingFunction" -> "$$$invalid$$$"],
        {GeneralizedGridGraph::invalidOptionChoice}
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
        EmptyGraphQ[#]
      ] & /@ {
        GeneralizedGridGraph[{0}],
        GeneralizedGridGraph[{}],
        GeneralizedGridGraph[{}, EdgeStyle -> {}],
        GeneralizedGridGraph[{}, EdgeStyle -> {Red}]},

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
      ] & /@ {
        {4, 6}, {6, 4}, {3, 3}, {45, 76}, {6 -> "Directed", 8}, {5, 8 -> "Directed"},
        {7 -> "Directed", 2 -> "Directed"}},

      VerificationTest[
        Options[GeneralizedGridGraph[{3, 4, 5}, EdgeStyle -> Red, "VertexNamingFunction" -> #], EdgeStyle],
        {EdgeStyle -> {Red}}
      ] & /@ {Automatic, "Coordinates"},

      With[{edgeStyle = {
          UndirectedEdge[1, 2] -> Red,
          UndirectedEdge[3, 4] -> Blue,
          UndirectedEdge[1, 3] -> Orange,
          UndirectedEdge[2, 4] -> Black}},
        VerificationTest[
          Sort[EdgeStyle /. Options[GeneralizedGridGraph[{2, 2}, EdgeStyle -> edgeStyle], EdgeStyle][[1]]],
          Sort[edgeStyle]
        ]
      ],

      VerificationTest[
        Options[GeneralizedGridGraph[{2}, EdgeStyle -> {UndirectedEdge[1, 2] -> Red}], EdgeStyle],
        {EdgeStyle -> {UndirectedEdge[1, 2] -> Red}}
      ],

      VerificationTest[
        Options[GeneralizedGridGraph[{2}, EdgeStyle -> {Red}], EdgeStyle],
        {EdgeStyle -> {UndirectedEdge[1, 2] -> Red}}
      ],

      VerificationTest[
        Sort[EdgeStyle /. Options[GeneralizedGridGraph[{3, 1}, EdgeStyle -> {Red, Blue}], EdgeStyle][[1]]],
        Sort[{UndirectedEdge[1, 2] -> Red, UndirectedEdge[2, 3] -> Red}]
      ],

      VerificationTest[
        Sort[EdgeStyle /. Options[
          GeneralizedGridGraph[{1, 3}, EdgeStyle -> {UndirectedEdge[1, 2] -> Red, UndirectedEdge[2, 3] -> Blue}],
          EdgeStyle][[1]]],
        Sort[{UndirectedEdge[1, 2] -> Red, UndirectedEdge[2, 3] -> Blue}]
      ],

      VerificationTest[
        Counts[
            (EdgeStyle /.
              Options[
                GeneralizedGridGraph[{3, 4, 5}, EdgeStyle -> {Red, Blue, Black}, "VertexNamingFunction" -> #],
                EdgeStyle])[[All, 2]]] /@
          {Red, Blue, Black},
        {40, 45, 48}
      ] & /@ {Automatic, "Coordinates"},

      VerificationTest[
        Sort[EdgeStyle /. Options[GeneralizedGridGraph[{2, 2}, EdgeStyle -> {Red, Blue}], EdgeStyle][[1]]],
        Sort[{
          UndirectedEdge[2, 4] -> Blue,
          UndirectedEdge[1, 2] -> Red,
          UndirectedEdge[3, 4] -> Red,
          UndirectedEdge[1, 3] -> Blue}]
      ],

      VerificationTest[
        Counts[
            (EdgeStyle /. Options[
              GeneralizedGridGraph[
                {4 -> "Circular", 3 -> {"Circular", "Directed"}, 5}, EdgeStyle -> {Red, Blue, Green}],
              EdgeStyle])[[All, 2]]] /@
          {Red, Blue, Green},
        {60, 60, 48}
      ],

      VerificationTest[
        Sort[VertexList[GeneralizedGridGraph[{3, 4 -> "Directed", 5 -> "Circular"}]]],
        Range[60]
      ],

      VerificationTest[
        Sort[VertexList[GeneralizedGridGraph[{3}, "VertexNamingFunction" -> "Coordinates"]]],
        {{1}, {2}, {3}}
      ],

      VerificationTest[
        Sort[VertexList[GeneralizedGridGraph[{3, 4 -> "Directed"}, "VertexNamingFunction" -> "Coordinates"]]],
        Tuples[{Range[3], Range[4]}]
      ],

      VerificationTest[
        Sort[VertexList[GeneralizedGridGraph[{3, 4, 5 -> "Circular"}, "VertexNamingFunction" -> "Coordinates"]]],
        Tuples[{Range[3], Range[4], Range[5]}]
      ]
    }
  |>
|>
