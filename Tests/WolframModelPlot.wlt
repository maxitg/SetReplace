<|
  "WolframModelPlot" -> <|
    "init" -> (
      $edgeTypes = {"Ordered", "Cyclic"};

      $simpleHypergraphs = {
        {{1, 3}, {2, 4}},
        {},
        {{1}},
        {{1}, {1}},
        {{1}, {2}},
        {{1}, {1}, {2}},
        {{1, 2}, {1}}
      };

      diskCoordinates[graphics_] := Sort[Cases[graphics, Disk[i_, ___] :> i, All]];

      $layoutTestHypergraphs = {
        {{1, 2, 3}, {3, 4, 5}},
        {{1, 2, 3, 4, 5}, {5, 6, 7, 8, 9}},
        {{1, 2, 3, 4, 5, 6, 7, 8, 9}, {1, 4, 7}},
        {{1, 2, 3, 4, 5, 6}, {1, 2, 3, 4}},
        {{1, 2, 3}, {3, 4, 5}, {1, 2, 3, 4}}
      };

      {$minArrowheadSize, $maxArrowheadSize} =
        WolframPhysicsProjectStyleData["SpatialGraph", "ArrowheadLengthFunction"][
          <|"PlotRange" -> #|>] & /@ {0, 1.*^100};

      $selfLoopLength = FirstCase[
        WolframModelPlot[{{1, 1}}, "HyperedgeRendering" -> "Subgraphs"],
        Line[pts_] :> RegionMeasure[Line[pts]],
        Missing[],
        All];

      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];

      {color, color2, color3, color4, color5} =
        BlockRandom[Table[RGBColor[RandomReal[{0, 1}, 3]], 5], RandomSeeding -> 0];

      testColor[
          shouldExistQ_,
          set_,
          opts_,
          colors_,
          renderings_ : {"Subgraphs", "Polygons"},
          edgeTypes_ : {"Ordered", "Cyclic"}] :=
        Outer[
          VerificationTest[
            With[{
                plot = WolframModelPlot[set, #1, "HyperedgeRendering" -> #2, Sequence @@ opts]},
              And @@ (If[shouldExistQ, Not, Identity][FreeQ[plot, #]] & /@ colors)
            ]
          ] &,
          edgeTypes,
          renderings];

      testColorAbsense[args___] := testColor[False, args];

      testColorPresence[args___] := testColor[True, args];
    ),
    "tests" -> {
      (* Symbol Leak *)

      testSymbolLeak[
        SeedRandom[123];
        WolframModelPlot[RandomInteger[200, {100, 3}]]
      ],

      (* Argument Checks *)

      (** Argument count **)

      testUnevaluated[
        WolframModelPlot[],
        {WolframModelPlot::argt}
      ],

      testUnevaluated[
        WolframModelPlot[{{1, 2}}, {{1, 2}}, {{1, 2}}],
        {WolframModelPlot::argt}
      ],

      (** Valid edges **)

      testUnevaluated[
        WolframModelPlot[1],
        {WolframModelPlot::invalidEdges}
      ],

      testUnevaluated[
        WolframModelPlot[{1, 2}],
        {WolframModelPlot::invalidEdges}
      ],

      testUnevaluated[
        WolframModelPlot[{{1, 3}, 2}],
        {WolframModelPlot::invalidEdges}
      ],

      testUnevaluated[
        WolframModelPlot[{{1, 3}, 6, {2, 4}}],
        {WolframModelPlot::invalidEdges}
      ],

      VerificationTest[
        WolframModelPlot[{{}}],
        {_Graphics},
        SameTest -> MatchQ
      ],

      testUnevaluated[
        WolframModelPlot[{{{}}}],
        {WolframModelPlot::invalidEdges}
      ],

      testUnevaluated[
        WolframModelPlot[{{1, 3}, {}}],
        {WolframModelPlot::invalidEdges}
      ],

      (** Valid EdgeType **)

      testUnevaluated[
        WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, None],
        {WolframModelPlot::invalidEdgeType}
      ],

      testUnevaluated[
        WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, "$$$Incorrect$$$"],
        {WolframModelPlot::invalidEdgeType}
      ],

      testUnevaluated[
        WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, {"$$$Incorrect$$$"}],
        {WolframModelPlot::invalidEdgeType}
      ],

      testUnevaluated[
        WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, {{1, 2, 3} -> "$$$Incorrect$$$"}],
        {WolframModelPlot::invalidEdgeType}
      ],

      testUnevaluated[
        WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, {None, {1, 2, 3} -> "Ordered"}],
        {WolframModelPlot::invalidEdgeType}
      ],

      testUnevaluated[
        WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, {"$$$Incorrect$$$", {1, 2, 3} -> "Ordered"}],
        {WolframModelPlot::invalidEdgeType}
      ],

      testUnevaluated[
        WolframModelPlot[
          {{1, 2, 3}, {3, 4, 5}},
          {{3, 4, 5} -> "Ordered", {1, 2, 3} -> "$$$Incorrect$$$"}],
        {WolframModelPlot::invalidEdgeType}
      ],

      VerificationTest[
        Head[WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, "Ordered"]],
        Graphics
      ],

      VerificationTest[
        Head[WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, "Cyclic"]],
        Graphics
      ],

      (* Valid options *)

      testUnevaluated[
        WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, "$$$InvalidOption###" -> True],
        {WolframModelPlot::optx}
      ],

      testUnevaluated[
        WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, "Ordered", "$$$InvalidOption###" -> True],
        {WolframModelPlot::optx}
      ],

      testUnevaluated[
        WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, "$$$Incorrect$$$", "$$$InvalidOption###" -> True],
        {WolframModelPlot::invalidEdgeType}
      ],

      (* Valid coordinates *)

      testUnevaluated[
        WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, VertexCoordinateRules -> $$$invalid$$$],
        {WolframModelPlot::invalidCoordinates}
      ],

      testUnevaluated[
        WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, VertexCoordinateRules -> {{0, 0}}],
        {WolframModelPlot::invalidCoordinates}
      ],

      testUnevaluated[
        WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, VertexCoordinateRules -> {1 -> {0}}],
        {WolframModelPlot::invalidCoordinates}
      ],

      VerificationTest[
        Head[WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, VertexCoordinateRules -> {1 -> {0, 0}}]],
        Graphics
      ],

      VerificationTest[
        Head[WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, "Ordered", VertexCoordinateRules -> {1 -> {0, 0}}]],
        Graphics
      ],

      (* Valid GraphHighlight *)

      testUnevaluated[
        WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> $$$invalid$$$],
        {WolframModelPlot::invalidHighlight}
      ],

      VerificationTest[
        Head[WolframModelPlot[{{1, 2, 3}, {1, 2, 3}}, GraphHighlight -> {{1, 2, 3}}]],
        Graphics
      ],

      VerificationTest[
        Head[WolframModelPlot[{{1, 2, 3}, {1, 2, 3}}, GraphHighlight -> {6}]],
        Graphics
      ],

      VerificationTest[
        Head[WolframModelPlot[{{1, 2, 3}, {1, 2, 3}}, GraphHighlight -> {{1, 2}}]],
        Graphics
      ],

      VerificationTest[
        Head[WolframModelPlot[{{1, 2, 3}, {1, 2, 3}}, GraphHighlight -> {{1, 2, 3}, {1, 2, 3}}]],
        Graphics
      ],

      VerificationTest[
        Head[WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {1}]],
        Graphics
      ],

      VerificationTest[
        Head[WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {{1, 2, 3}}]],
        Graphics
      ],

      VerificationTest[
        Head[WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {4, {1, 2, 3}}]],
        Graphics
      ],

      (* Valid GraphHighlightStyle *)

      testUnevaluated[
        WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {1}, GraphHighlightStyle -> None],
        {WolframModelPlot::invalidHighlightStyle}
      ],

      testUnevaluated[
        WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {1}, GraphHighlightStyle -> 2],
        {WolframModelPlot::invalidHighlightStyle}
      ],

      testUnevaluated[
        WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {1}, GraphHighlightStyle -> "Dashed"],
        {WolframModelPlot::invalidHighlightStyle}
      ],

      VerificationTest[
        Head[WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {1}, GraphHighlightStyle -> Black]],
        Graphics
      ],

      (* Valid VertexSize and "ArrowheadLength" *)

      {
        testUnevaluated[
          WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, # -> $$$invalid$$$],
          {WolframModelPlot::invalidSize}
        ],

        testUnevaluated[
          WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, # -> -1],
          {WolframModelPlot::invalidSize}
        ],

        VerificationTest[
          Head[WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, # -> 1]],
          Graphics
        ]
      } & /@ {VertexSize, "ArrowheadLength"},

      VerificationTest[
        Head[WolframModelPlot[#, "ArrowheadLength" -> Automatic]],
        Graphics
      ] & /@ {{{1, 2, 3}, {3, 4, 5}}, {{1, 1}}, {{1}}, {}},

      (* HypergraphPlot can still be used *)

      VerificationTest[
        Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}]],
        Graphics
      ],

      VerificationTest[
        Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "Ordered"]],
        Graphics
      ],

      (* Implementation *)

      (** Simple examples **)

      Table[With[{hypergraph = hypergraph}, VerificationTest[
        Head[WolframModelPlot[hypergraph, #]],
        Graphics
      ]] & /@ $edgeTypes, {hypergraph, $simpleHypergraphs}],

      (** Large graphs **)

      VerificationTest[
        Head @ WolframModelPlot @ SetReplace[
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
        diskCoordinates[WolframModelPlot[#, "Ordered"]] != diskCoordinates[WolframModelPlot[#, "Cyclic"]]
      ] & /@ $layoutTestHypergraphs,

      VerificationTest[
        Length[Union[Cases[
          WolframModelPlot[#, "HyperedgeRendering" -> "Subgraphs", "ArrowheadLength" -> 0],
          Polygon[___],
          All]]],
        0
      ] & /@ $layoutTestHypergraphs,

      VerificationTest[
        Length[Union[Cases[
          WolframModelPlot[#, "HyperedgeRendering" -> "Polygons", "ArrowheadLength" -> 0],
          Polygon[___],
          All]]],
        0 + Length[#]
      ] & /@ $layoutTestHypergraphs,

      (* VertexLabels *)

      VerificationTest[
        MissingQ[FirstCase[
          WolframModelPlot[#, VertexLabels -> None],
          Text[___],
          Missing[],
          All]]
      ] & /@ $layoutTestHypergraphs,

      VerificationTest[
        !MissingQ[FirstCase[
          WolframModelPlot[#, VertexLabels -> Automatic],
          Text[___],
          Missing[],
          All]]
      ] & /@ $layoutTestHypergraphs,

      (* Single-vertex edges *)

      VerificationTest[
        WolframModelPlot[{{1}, {1, 2}}] =!= WolframModelPlot[{{1, 2}}]
      ],

      VerificationTest[
        MissingQ[FirstCase[
          WolframModelPlot[{{1, 2}}, VertexLabels -> None],
          Circle[___],
          Missing[],
          All]]
      ],

      VerificationTest[
        !MissingQ[FirstCase[
          WolframModelPlot[{{1}, {1, 2}}, VertexLabels -> Automatic],
          Circle[___],
          Missing[],
          All]]
      ],

      (* VertexCoordinateRules *)

      VerificationTest[
        And @@ (MemberQ[
            diskCoordinates[WolframModelPlot[
              {{1, 2, 3}, {3, 4, 5}, {3, 3}},
              VertexCoordinateRules -> {1 -> {0, 0}, 2 -> {1, 0}}]],
            #] & /@
          {{0., 0.}, {1., 0.}})
      ],

      VerificationTest[
        Chop @ diskCoordinates[WolframModelPlot[
          {{1, 2, 3}, {3, 4, 5}},
          VertexCoordinateRules -> {3 -> {0, 0}}]] != Table[{0, 0}, 5]
      ],

      VerificationTest[
        Chop @ diskCoordinates[WolframModelPlot[
          {{1, 2, 3}, {3, 4, 5}},
          VertexCoordinateRules -> {3 -> {1, 0}, 3 -> {0, 0}}]] != Table[{0, 0}, 5]
      ],

      (** Same coordinates should not produce any messages **)
      VerificationTest[
        And @@ Cases[
          WolframModelPlot[{{1, 2, 3}}, VertexCoordinateRules -> {1 -> {1, 0}, 2 -> {1, 0}}],
          Rotate[_, {v1_, v2_}] :> v1 != {0, 0} && v2 != {0, 0},
          All]
      ],

      (* Styles *)
      testColorPresence[{{1, 2, 3}, {3, 4, 5}}, {"EdgePolygonStyle" -> color}, {color}, {"Polygons"}],

      testColorAbsense[{{1, 2, 3}, {3, 4, 5}}, {"EdgePolygonStyle" -> color}, {color}, {"Subgraphs"}],

      testColorPresence[{{1, 2, 3}, {3, 4, 5}}, {VertexStyle -> color}, {color}],

      testColorPresence[{{1}, {3}}, {VertexStyle -> color, EdgeStyle -> Transparent}, {color}],

      testColorAbsense[{}, {VertexStyle -> color}, {color}],

      testColorPresence[{{1, 2, 3}, {3, 4, 5}}, {EdgeStyle -> color}, {color}],

      testColorAbsense[{}, {EdgeStyle -> color}, {color}],

      testColorPresence[{{1, 2, 3}}, {EdgeStyle -> color, "EdgePolygonStyle" -> Black}, {color}, {"Polygons"}],

      testColorPresence[{{1, 2, 3}}, {EdgeStyle -> Black, "EdgePolygonStyle" -> color}, {color}, {"Polygons"}],

      testColorPresence[{{1, 2, 3}}, {PlotStyle -> color, EdgeStyle -> Automatic, VertexStyle -> Automatic}, {color}],

      testColorPresence[{{1, 2, 3}}, {PlotStyle -> color, EdgeStyle -> Black, VertexStyle -> Automatic}, {color}],

      testColorPresence[{{1, 2, 3}}, {PlotStyle -> color, EdgeStyle -> Automatic, VertexStyle -> Black}, {color}],

      testColorAbsense[{{1, 2, 3}, {3, 4, 5}}, {PlotStyle -> color, EdgeStyle -> Black, VertexStyle -> Black}, {color}],

      With[{hypergraph = {{1}, {1, 2}, {2, 3, 4}, {4, 5, 6, 7}}}, {
        testUnevaluated[
          WolframModelPlot[hypergraph, PlotStyle -> #],
          {WolframModelPlot::invalidPlotStyle}
        ] & /@ {{Red, Green, Blue, Yellow}, Table[Red, 7], {Red}},

        testColorAbsense[hypergraph, {PlotStyle -> <|_ -> color, _ -> color2|>}, {color}],

        testColorPresence[hypergraph, {PlotStyle -> <|_ -> color, 1 -> color2|>}, {color, color2}],

        testColorPresence[
          hypergraph, {PlotStyle -> <|_ -> color, _Integer -> color2, 1 -> color3|>}, {color, color2, color3}],

        testColorPresence[hypergraph, {PlotStyle -> <|_ -> color, _List -> color2|>}, {color, color2}]
      }],

      testColorPresence[
        {{1}, {2}, {1, 2}, {2, 4}, {2, 3, 4}, {4, 5, 6, 7}, {7, 8, 9}},
        {PlotStyle -> <|_ -> color, {_} -> color2, {_, _} -> color3, {_, _, _} -> color4, {_, _, _, _} -> color5|>},
        {color, color2, color3, color4, color5}],

      testColorPresence[
        {{1}, {1, 2}, {2, 3, 4}, {4, 5, 6, 7}}, {PlotStyle -> <|_ -> color, {1} -> color2|>}, {color, color2}],

      With[{hypergraph = {{1}, {1}, {1, 2}, {2, 4}, {2, 3, 4}, {4, 5, 6, 7}, {7, 8, 9}}}, {
        testColorPresence[
          hypergraph,
          {PlotStyle -> <|_ -> White|>, EdgeStyle -> ColorData[97] /@ Range[7]},
          ColorData[97] /@ Range[7]],

        testUnevaluated[
          WolframModelPlot[hypergraph, EdgeStyle -> {RGBColor[1, 0, 0]}],
          {WolframModelPlot::invalidStyleLength}
        ],

        testColorPresence[hypergraph, {PlotStyle -> <|_ -> color|>, EdgeStyle -> <|# -> color2|>}, {color, color2}] & /@
          {_, {_, _, _}, _ ? (FreeQ[4])},

        testColorPresence[hypergraph, {PlotStyle -> <|_ -> color, _ ? (FreeQ[4]) -> color2|>}, {color, color2}],

        testColorPresence[
          hypergraph,
          {PlotStyle -> <|_ -> color, _ ? (FreeQ[4]) -> color2|>, EdgeStyle -> <|{1, 2} -> color3|>},
          {color, color2, color3}],

        testColorPresence[
          hypergraph,
          {PlotStyle -> <|_ -> color, _ ? (FreeQ[4]) -> color2|>, VertexStyle -> #},
          {color, color2, color3}] & /@ {color3, <|3 -> color3|>, <|_ ? OddQ -> color3|>},

        testColorPresence[
          hypergraph,
          {PlotStyle -> <|_ -> color, _ ? (FreeQ[4]) -> color2|>, VertexStyle -> ColorData[97] /@ Range[9]},
          Join[{color, color2}, ColorData[97] /@ Range[9]]],

        testColorPresence[
          hypergraph,
          {PlotStyle -> <|_ -> color, _ ? (FreeQ[4]) -> color2|>,
            EdgeStyle -> <|{1, 2} -> color3|>,
            "EdgePolygonStyle" -> #},
          {color, color2, color3, color4},
          {"Polygons"}] & /@ {color4, <|{2, 3, 4} -> color4|>},

        testColorPresence[
          hypergraph,
          {PlotStyle -> <|_ -> color, _ ? (FreeQ[4]) -> color2|>,
            EdgeStyle -> <|{1, 2} -> color3|>,
            "EdgePolygonStyle" -> ColorData[97] /@ Range[7]},
          Join[{color, color2, color3}, ColorData[97] /@ Range[5, 7]],
          {"Polygons"},
          {"Ordered"}],

        testColorPresence[
          hypergraph,
          {PlotStyle -> <|_ -> color, _ ? (FreeQ[4]) -> color2|>,
            EdgeStyle -> <|{1, 2} -> color3|>,
            "EdgePolygonStyle" -> ColorData[97] /@ Range[7]},
          Join[{color, color2, color3}, ColorData[97] /@ Range[1, 7]],
          {"Polygons"},
          {"Cyclic"}],

        testColorAbsense[
          hypergraph,
          {PlotStyle -> <|_ -> color, _ ? (FreeQ[4]) -> color2|>,
            EdgeStyle -> <|{1, 2} -> color3|>,
            "EdgePolygonStyle" -> ColorData[97] /@ Range[7]},
          ColorData[97] /@ Range[1, 4],
          {"Polygons"},
          {"Ordered"}]
      }],

      testColorPresence[{{1}, {1, 2}, {2, 3, 4}}, {PlotStyle -> <|_List -> color|>}, {color}],

      testColorAbsense[{{1}, {1, 2}, {2, 3, 4}}, {GraphHighlight -> {5}, GraphHighlightStyle -> color}, {color}],

      VerificationTest[
        Head[WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, VertexSize -> 0.3]],
        Graphics
      ],

      VerificationTest[
        Head[WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, "ArrowheadLength" -> 0.3]],
        Graphics
      ],

      VerificationTest[
        Head[WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, VertexSize -> 0.4, "ArrowheadLength" -> 0.3]],
        Graphics
      ],

      (* GraphHighlight *)

      VerificationTest[
        Length[Union @ Cases[WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {#}], _ ? ColorQ, All]] >
          Length[Union @ Cases[WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}], _ ? ColorQ, All]]
      ] & /@ {4, {1, 2, 3}},

      (** Test multi-edge highlighting **)
      VerificationTest[
        Differences[
          Length[Union[Cases[#, _?ColorQ, All]]] & /@
            (WolframModelPlot[{{1, 2}, {1, 2}}, "HyperedgeRendering" -> "Subgraphs", GraphHighlight -> #] &) /@
            {{}, {{1, 2}}, {{1, 2}, {1, 2}}}],
        {1, -1}
      ],

      (* GraphHighlightStyle *)

      VerificationTest[
        With[{
            color = RGBColor[0.4, 0.6, 0.2]},
          FreeQ[WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> #, GraphHighlightStyle -> color], color] & /@
            {{}, {4}, {{1, 2, 3}}}],
        {True, False, False}
      ],

      (* Scaling consistency *)
      (* Vertex sizes, arrow sizes, average edge lengths, and loop lengths should always be the same. *)

      VerificationTest[
        SameQ @@ (
          Union[Cases[WolframModelPlot[#], Disk[_, r_] :> r, All]] & /@
            {{{1}}, {{1, 2, 3}}, {{1, 2, 3}, {3, 4, 5}}, RandomInteger[10, {5, 5}]})
      ],

      With[{$minArrowheadSize = $minArrowheadSize, $maxArrowheadSize = $maxArrowheadSize},
        VerificationTest[
          Length[DeleteDuplicates[
            Mean[Cases[
                WolframModelPlot[#, "HyperedgeRendering" -> "Subgraphs"],
                Line[pts_] :> EuclideanDistance @@ pts,
                All]] & /@
              {{{1, 2}}, {{1, 2, 3}}, {{1, 2, 3}, {3, 4, 5}}, {{1, 2, 3}, {3, 4, 5}, {5, 6, 1}}, {{1, 2, 3, 4, 5, 1}}},
            #2 - #1 <= $maxArrowheadSize - $minArrowheadSize &]] == 1
        ]],

      With[{
          $minArrowheadSize = $minArrowheadSize, $maxArrowheadSize = $maxArrowheadSize, $selfLoopLength = $selfLoopLength},
        VerificationTest[
          Abs[
                First[
                  Nearest[
                    Cases[
                      WolframModelPlot[#, "HyperedgeRendering" -> "Subgraphs"],
                      Line[pts_] :> RegionMeasure[Line[pts]],
                      All],
                    $selfLoopLength]] -
              $selfLoopLength] <
            $maxArrowheadSize - $minArrowheadSize
        ] & /@ {
          {{1, 1}},
          {{1, 2, 3}, {1, 1}},
          {{1, 2, 3}, {3, 4, 5}, {5, 5}},
          {{1, 2, 3}, {3, 4, 5}, {5, 6, 1, 1}},
          {{1, 2, 3, 4, 5, 5, 1}}}],

      (* Automatic image size *)
      VerificationTest[
        Table[OrderedQ[(ImageSizeRaw /. AbsoluteOptions[WolframModelPlot[#], ImageSizeRaw])[[k, 1]] & /@
          {{{1}}, {{1, 1}}, {{1, 2, 3}, {3, 4, 5}, {5, 6, 1}}, {{1, 2, 3}, {3, 4, 5}, {5, 6, 7}, {7, 8, 1}}}], {k, 2}],
        {True, True}
      ],

      testUnevaluated[
        WolframModelPlot[{{1, 2}, {2, 3}, {3, 1}}, "MaxImageSize" -> "$$$invalid$$$"],
        {WolframModelPlot::invalidMaxImageSize}
      ] & /@ {"$$$invalid$$$", {200, 200, 200}, UpTo[200], {{100, 200}, {100, 200}}, Full, Scaled[0.5]},

      VerificationTest[
        With[{
            sizes = (ImageSize /. AbsoluteOptions[#, ImageSize][[1]] & /@
              WolframModel[{{x, y}, {y, z}} -> {{w, y}, {y, z}, {z, w}, {x, w}}, {{0, 0}, {0, 0}}, 10][
                "StatesPlotsList", "MaxImageSize" -> #]) & /@ {100, 200}},
          AllTrue[sizes[[1]], # < 100.0001 &] &&
          !AllTrue[sizes[[1]], # > 99.9999 &] &&
          AllTrue[sizes[[2]] / sizes[[1]], 1.9999 < # < 2.0001 &]
        ]
      ],

      VerificationTest[
        With[{
            sizes = (ImageSize /. AbsoluteOptions[#, ImageSize][[1]] & /@
              WolframModel[{{x, y}, {y, z}} -> {{w, y}, {y, z}, {z, w}, {x, w}}, {{0, 0}, {0, 0}}, 10][
                "StatesPlotsList", "MaxImageSize" -> #]) & /@ {{100, 30}, {200, 60}}},
          AllTrue[sizes[[1, All, 1]], # < 100.0001 &] &&
          AllTrue[sizes[[1, All, 2]], # < 30.0001 &] &&
          !AllTrue[sizes[[1, All, 1]], # > 99.9999 &] &&
          !AllTrue[sizes[[1, All, 2]], # > 29.9999 &] &&
          And @@ ((AllTrue[sizes[[2, All, #]] / sizes[[1, All, #]], 1.9999 < # < 2.0001 &] &) /@ {1, 2})
        ]
      ],

      (* Multiple hypergraphs *)
      VerificationTest[
        Head /@ WolframModelPlot[{{{1, 2, 3}, {3, 4, 5}}, {{3, 4, 5}, {5, 6, 7}}, {{5, 6, 7}, {7, 8, 5}}}, ##],
        {Graphics, Graphics, Graphics}
      ] & @@@ {
        {},
        {GraphHighlight -> {3, {3, 4, 5}}},
        {VertexSize -> 0.1, "ArrowheadLength" -> 0.2},
        {EdgeStyle -> Red},
        {VertexCoordinateRules -> {3 -> {0, 0}, 4 -> {1, 0}}}
      }
    }
  |>
|>
