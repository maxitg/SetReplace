<|
  "HypergraphPlot" -> <|
    "init" -> (
      $edgeTypes = {"Ordered", "Cyclic"};

      $simpleHypergraphs = {
        {{1, 3}, {2, 4}},
        {},
        {{}},
        {{1}},
        {{1}, {1}},
        {{1}, {2}},
        {{1}, {1}, {2}},
        {{1, 2}, {1}},
        {{1, 2}, {1}, {}}
      };

      diskCoordinates[graphics_] := Sort[Cases[graphics, Disk[i_, ___] :> i, All]];

      $layoutTestHypergraphs = {
        {{1, 2, 3}, {3, 4, 5}},
        {{1, 2, 3, 4, 5}, {5, 6, 7, 8, 9}},
        {{1, 2, 3, 4, 5, 6, 7, 8, 9}, {1, 4, 7}},
        {{1, 2, 3, 4, 5, 6}, {1, 2, 3, 4}},
        {{1, 2, 3}, {3, 4, 5}, {1, 2, 3, 4}}
      };

      $selfLoopLength = FirstCase[
        HypergraphPlot[{{1, 1}}, "HyperedgeRendering" -> "Subgraphs"],
        Line[pts_] :> RegionMeasure[Line[pts]],
        Missing[],
        All];

      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
    ),
    "tests" -> {
      (* Argument Checks *)

      (** Argument count **)

      testUnevaluated[
        HypergraphPlot[],
        {HypergraphPlot::argt}
      ],

      testUnevaluated[
        HypergraphPlot[{{1, 2}}, {{1, 2}}, {{1, 2}}],
        {HypergraphPlot::argt}
      ],

      (** Valid edges **)

      testUnevaluated[
        HypergraphPlot[1],
        {HypergraphPlot::invalidEdges}
      ],

      testUnevaluated[
        HypergraphPlot[{1, 2}],
        {HypergraphPlot::invalidEdges}
      ],

      testUnevaluated[
        HypergraphPlot[{{1, 3}, 2}],
        {HypergraphPlot::invalidEdges}
      ],

      testUnevaluated[
        HypergraphPlot[{{1, 3}, 6, {2, 4}}],
        {HypergraphPlot::invalidEdges}
      ],

      (** Valid EdgeType **)

      testUnevaluated[
        HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, None],
        {HypergraphPlot::invalidEdgeType}
      ],

      testUnevaluated[
        HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "$$$Incorrect$$$"],
        {HypergraphPlot::invalidEdgeType}
      ],

      testUnevaluated[
        HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, {"$$$Incorrect$$$"}],
        {HypergraphPlot::invalidEdgeType}
      ],

      testUnevaluated[
        HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, {{1, 2, 3} -> "$$$Incorrect$$$"}],
        {HypergraphPlot::invalidEdgeType}
      ],

      testUnevaluated[
        HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, {None, {1, 2, 3} -> "Ordered"}],
        {HypergraphPlot::invalidEdgeType}
      ],

      testUnevaluated[
        HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, {"$$$Incorrect$$$", {1, 2, 3} -> "Ordered"}],
        {HypergraphPlot::invalidEdgeType}
      ],

      testUnevaluated[
        HypergraphPlot[
          {{1, 2, 3}, {3, 4, 5}},
          {{3, 4, 5} -> "Ordered", {1, 2, 3} -> "$$$Incorrect$$$"}],
        {HypergraphPlot::invalidEdgeType}
      ],

      VerificationTest[
        Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "Ordered"]],
        Graphics
      ],

      VerificationTest[
        Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "Cyclic"]],
        Graphics
      ],

      (* Valid options *)

      testUnevaluated[
        HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "$$$InvalidOption###" -> True],
        {HypergraphPlot::optx}
      ],

      testUnevaluated[
        HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "Ordered", "$$$InvalidOption###" -> True],
        {HypergraphPlot::optx}
      ],

      testUnevaluated[
        HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "$$$Incorrect$$$", "$$$InvalidOption###" -> True],
        {HypergraphPlot::invalidEdgeType}
      ],

      (* Valid coordinates *)

      testUnevaluated[
        HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, VertexCoordinateRules -> $$$invalid$$$],
        {HypergraphPlot::invalidCoordinates}
      ],

      testUnevaluated[
        HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, VertexCoordinateRules -> {{0, 0}}],
        {HypergraphPlot::invalidCoordinates}
      ],

      testUnevaluated[
        HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, VertexCoordinateRules -> {1 -> {0}}],
        {HypergraphPlot::invalidCoordinates}
      ],

      VerificationTest[
        Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, VertexCoordinateRules -> {1 -> {0, 0}}]],
        Graphics
      ],

      VerificationTest[
        Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "Ordered", VertexCoordinateRules -> {1 -> {0, 0}}]],
        Graphics
      ],

      (* Valid GraphHighlight *)

      testUnevaluated[
        HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> $$$invalid$$$],
        {HypergraphPlot::invalidHighlight}
      ],

      testUnevaluated[
        HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {6}],
        {HypergraphPlot::invalidHighlight}
      ],

      testUnevaluated[
        HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {1, 1}],
        {HypergraphPlot::invalidHighlight}
      ],

      testUnevaluated[
        HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {{1, 2}}],
        {HypergraphPlot::invalidHighlight}
      ],

      VerificationTest[
        Head[HypergraphPlot[{{1, 2, 3}, {1, 2, 3}}, GraphHighlight -> {{1, 2, 3}}]],
        Graphics
      ],

      VerificationTest[
        Head[HypergraphPlot[{{1, 2, 3}, {1, 2, 3}}, GraphHighlight -> {{1, 2, 3}, {1, 2, 3}}]],
        Graphics
      ],

      testUnevaluated[
        HypergraphPlot[{{1, 2, 3}, {1, 2, 3}}, GraphHighlight -> {{1, 2, 3}, {1, 2, 3}, {1, 2, 3}}],
        {HypergraphPlot::invalidHighlight}
      ],

      VerificationTest[
        Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {1}]],
        Graphics
      ],

      VerificationTest[
        Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {{1, 2, 3}}]],
        Graphics
      ],

      VerificationTest[
        Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {4, {1, 2, 3}}]],
        Graphics
      ],

      (* Valid GraphHighlightStyle *)

      testUnevaluated[
        HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {1}, GraphHighlightStyle -> None],
        {HypergraphPlot::invalidHighlightStyle}
      ],

      testUnevaluated[
        HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {1}, GraphHighlightStyle -> 2],
        {HypergraphPlot::invalidHighlightStyle}
      ],

      testUnevaluated[
        HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {1}, GraphHighlightStyle -> "Dashed"],
        {HypergraphPlot::invalidHighlightStyle}
      ],

      VerificationTest[
        Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {1}, GraphHighlightStyle -> Black]],
        Graphics
      ],

      (* Valid VertexSize and "ArrowheadLength" *)

      {
        testUnevaluated[
          HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, # -> $$$invalid$$$],
          {HypergraphPlot::invalidSize}
        ],

        testUnevaluated[
          HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, # -> -1],
          {HypergraphPlot::invalidSize}
        ],

        VerificationTest[
          Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, # -> 1]],
          Graphics
        ]
      } & /@ {VertexSize, "ArrowheadLength"},

      (* Implementation *)

      (** Simple examples **)

      Table[With[{hypergraph = hypergraph}, VerificationTest[
        Head[HypergraphPlot[hypergraph, #]],
        Graphics
      ]] & /@ $edgeTypes, {hypergraph, $simpleHypergraphs}],

      (** Large graphs **)

      VerificationTest[
        Head @ HypergraphPlot @ SetReplace[
          {{0, 1}, {0, 2}, {0, 3}},
          ToPatternRules[
            {{0, 1}, {0, 2}, {0, 3}} ->
            {{4, 5}, {5, 4}, {4, 6}, {6, 4},
              {5, 6}, {6, 5}, {4, 1}, {5, 2}, {6, 3}}],
          #],
        Graphics
      ] & /@ {10, 5000},

      (* EdgeType *)

      VerificationTest[
        diskCoordinates[HypergraphPlot[#, "Ordered"]] != diskCoordinates[HypergraphPlot[#, "Cyclic"]]
      ] & /@ $layoutTestHypergraphs,

      VerificationTest[
        Length[Union[Cases[
          HypergraphPlot[#, "HyperedgeRendering" -> "Subgraphs"],
          Polygon[___],
          All]]],
        1
      ] & /@ $layoutTestHypergraphs,

      VerificationTest[
        Length[Union[Cases[
          HypergraphPlot[#, "HyperedgeRendering" -> "Polygons"],
          Polygon[___],
          All]]],
        1 + Length[#]
      ] & /@ $layoutTestHypergraphs,

      (* VertexLabels *)

      VerificationTest[
        MissingQ[FirstCase[
          HypergraphPlot[#, VertexLabels -> None],
          Text[___],
          Missing[],
          All]]
      ] & /@ $layoutTestHypergraphs,

      VerificationTest[
        !MissingQ[FirstCase[
          HypergraphPlot[#, VertexLabels -> Automatic],
          Text[___],
          Missing[],
          All]]
      ] & /@ $layoutTestHypergraphs,

      (* Single-vertex edges *)

      VerificationTest[
        HypergraphPlot[{{1}, {1, 2}}] =!= HypergraphPlot[{{1, 2}}]
      ],

      VerificationTest[
        MissingQ[FirstCase[
          HypergraphPlot[{{1, 2}}, VertexLabels -> None],
          Circle[___],
          Missing[],
          All]]
      ],

      VerificationTest[
        !MissingQ[FirstCase[
          HypergraphPlot[{{1}, {1, 2}}, VertexLabels -> Automatic],
          Circle[___],
          Missing[],
          All]]
      ],

      (* VertexCoordinateRules *)

      VerificationTest[
        And @@ (MemberQ[
            diskCoordinates[HypergraphPlot[
              {{1, 2, 3}, {3, 4, 5}, {3, 3}},
              VertexCoordinateRules -> {1 -> {0, 0}, 2 -> {1, 0}}]],
            #] & /@
          {{0., 0.}, {1., 0.}})
      ],

      VerificationTest[
        Chop @ diskCoordinates[HypergraphPlot[
          {{1, 2, 3}, {3, 4, 5}},
          VertexCoordinateRules -> {3 -> {0, 0}}]] != Table[{0, 0}, 5]
      ],

      VerificationTest[
        Chop @ diskCoordinates[HypergraphPlot[
          {{1, 2, 3}, {3, 4, 5}},
          VertexCoordinateRules -> {3 -> {1, 0}, 3 -> {0, 0}}]] != Table[{0, 0}, 5]
      ],

      (** Same coordinates should not produce any messages **)
      VerificationTest[
        And @@ Cases[
          HypergraphPlot[{{1, 2, 3}}, VertexCoordinateRules -> {1 -> {1, 0}, 2 -> {1, 0}}],
          Rotate[_, {v1_, v2_}] :> v1 != {0, 0} && v2 != {0, 0},
          All]
      ],

      (* Styles *)

      With[{color = RGBColor[0.4, 0.6, 0.2]}, {
        VerificationTest[
          FreeQ[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "EdgePolygonStyle" -> color], color],
          False
        ],

        VerificationTest[
          FreeQ[
            HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "HyperedgeRendering" -> "Subgraphs", "EdgePolygonStyle" -> color],
            color],
          True
        ],

        VerificationTest[
          FreeQ[HypergraphPlot[{{1, 2, 3}, {3}, {3, 4, 5}}, "UnaryEdgeStyle" -> color], color],
          False
        ],

        VerificationTest[
          FreeQ[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "UnaryEdgeStyle" -> color], color],
          True
        ],

        VerificationTest[
          FreeQ[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, VertexStyle -> color], color],
          False
        ],

        VerificationTest[
          FreeQ[HypergraphPlot[{{1}, {3}}, VertexStyle -> color, EdgeStyle -> Transparent], color],
          False
        ],

        VerificationTest[
          FreeQ[HypergraphPlot[{}, VertexStyle -> color], color],
          True
        ],

        VerificationTest[
          FreeQ[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, EdgeStyle -> color], color],
          False
        ],

        VerificationTest[
          FreeQ[HypergraphPlot[{}, EdgeStyle -> color], color],
          True
        ],

        VerificationTest[
          FreeQ[HypergraphPlot[{{1}}, EdgeStyle -> color, "UnaryEdgeStyle" -> Black], color],
          True
        ],

        VerificationTest[
          FreeQ[HypergraphPlot[{{1}}, EdgeStyle -> color, "UnaryEdgeStyle" -> Automatic], color],
          False
        ],

        VerificationTest[
          FreeQ[HypergraphPlot[{{1, 2, 3}}, EdgeStyle -> color, "EdgePolygonStyle" -> Black], color],
          False
        ],

        VerificationTest[
          FreeQ[HypergraphPlot[{{1, 2, 3}}, EdgeStyle -> Black, "EdgePolygonStyle" -> color], color],
          False
        ],

        VerificationTest[
          FreeQ[
            HypergraphPlot[{{1, 2, 3}}, PlotStyle -> color, EdgeStyle -> Automatic, VertexStyle -> Automatic], color],
          False
        ],

        VerificationTest[
          FreeQ[
            HypergraphPlot[{{1, 2, 3}}, PlotStyle -> color, EdgeStyle -> Black, VertexStyle -> Automatic], color],
          False
        ],

        VerificationTest[
          FreeQ[
            HypergraphPlot[{{1, 2, 3}}, PlotStyle -> color, EdgeStyle -> Automatic, VertexStyle -> Black], color],
          False
        ],

        VerificationTest[
          FreeQ[
            HypergraphPlot[
              {{1}}, PlotStyle -> color, EdgeStyle -> Automatic, "UnaryEdgeStyle" -> Black, VertexStyle -> Black],
            color],
          True
        ],

        VerificationTest[
          FreeQ[
            HypergraphPlot[
              {{1, 2, 3}, {3, 4, 5}}, PlotStyle -> color, EdgeStyle -> Black, VertexStyle -> Black],
            color],
          True
        ]
      }],

      VerificationTest[
        Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, VertexSize -> 0.3]],
        Graphics
      ],

      VerificationTest[
        Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "ArrowheadLength" -> 0.3]],
        Graphics
      ],

      VerificationTest[
        Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, VertexSize -> 0.4, "ArrowheadLength" -> 0.3]],
        Graphics
      ],

      (* GraphHighlight *)

      VerificationTest[
        Length[Union @ Cases[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {#}], _ ? ColorQ, All]] >
          Length[Union @ Cases[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}], _ ? ColorQ, All]]
      ] & /@ {4, {1, 2, 3}},

      (** Test multi-edge highlighting **)
      VerificationTest[
        Differences[
          Length[Union[Cases[#, _?ColorQ, All]]] & /@
            (HypergraphPlot[{{1, 2}, {1, 2}}, "HyperedgeRendering" -> "Subgraphs", GraphHighlight -> #] &) /@
            {{}, {{1, 2}}, {{1, 2}, {1, 2}}}],
        {1, -1}
      ],

      (* GraphHighlightStyle *)

      VerificationTest[
        With[{
            color = RGBColor[0.4, 0.6, 0.2]},
          FreeQ[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> #, GraphHighlightStyle -> color], color] & /@
            {{}, {4}, {{1, 2, 3}}}],
        {True, False, False}
      ],

      (* Scaling consistency *)
      (* Vertex sizes, arrow sizes, average edge lengths, and loop lengths should always be the same. *)

      VerificationTest[
        SameQ @@ (
          Union[Cases[HypergraphPlot[#], Disk[_, r_] :> r, All]] & /@
            {{{1}}, {{1, 2, 3}}, {{1, 2, 3}, {3, 4, 5}}, RandomInteger[10, {5, 5}]})
      ],

      VerificationTest[
        SameQ @@ (
          Union[Cases[HypergraphPlot[#, "HyperedgeRendering" -> "Subgraphs"], p : Polygon[___] :> Area[p], All]] & /@
            {{{1, 2}}, {{1, 2, 3}}, {{1, 2, 3}, {3, 4, 5}}, RandomInteger[10, {5, 5}]})
      ],

      VerificationTest[
        Equal @@ (
          Mean[Cases[
              HypergraphPlot[#, "HyperedgeRendering" -> "Subgraphs"],
              Line[pts_] :> EuclideanDistance @@ pts,
              All]] & /@
            {{{1, 2}}, {{1, 2, 3}}, {{1, 2, 3}, {3, 4, 5}}, {{1, 2, 3}, {3, 4, 5}, {5, 6, 1}}, {{1, 2, 3, 4, 5, 1}}})
      ],

      VerificationTest[
        Abs[
              First[
                Nearest[
                  Cases[
                    HypergraphPlot[#, "HyperedgeRendering" -> "Subgraphs"],
                    Line[pts_] :> RegionMeasure[Line[pts]],
                    All],
                  $selfLoopLength]] -
            $selfLoopLength] <
          1.*^-10
      ] & /@ {
        {{1, 1}},
        {{1, 2, 3}, {1, 1}},
        {{1, 2, 3}, {3, 4, 5}, {5, 5}},
        {{1, 2, 3}, {3, 4, 5}, {5, 6, 1, 1}},
        {{1, 2, 3, 4, 5, 5, 1}}}
    }
  |>
|>
