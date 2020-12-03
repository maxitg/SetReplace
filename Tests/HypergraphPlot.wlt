<|
  "HypergraphPlot" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];
      Global`checkGraphics[args___] := SetReplace`PackageScope`checkGraphics[args];
      Global`graphicsQ[args___] := SetReplace`PackageScope`graphicsQ[args];

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
        HypergraphPlot[{{1, 1}}, "HyperedgeRendering" -> "Subgraphs"],
        Line[pts_] :> RegionMeasure[Line[pts]],
        Missing[],
        All];

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
                plot = checkGraphics @ HypergraphPlot[set, #1, "HyperedgeRendering" -> #2, Sequence @@ opts]},
              And @@ (If[shouldExistQ, Not, Identity][FreeQ[plot, #]] & /@ colors)
            ]
          ] &,
          edgeTypes,
          renderings];

      testColorAbsense[args___] := testColor[False, args];

      testColorPresence[args___] := testColor[True, args];
    ),
    "options" -> {
      "Parallel" -> False
    },
    "tests" -> {
      (* Symbol Leak *)

      testSymbolLeak[
        SeedRandom[123];
        HypergraphPlot[RandomInteger[200, {100, 3}]]
      ],

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

      VerificationTest[
        graphicsQ /@ HypergraphPlot[{{}}],
        {True}
      ],

      testUnevaluated[
        HypergraphPlot[{{{}}}],
        {HypergraphPlot::invalidEdges}
      ],

      testUnevaluated[
        HypergraphPlot[{{1, 3}, {}}],
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
        graphicsQ[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "Ordered"]]
      ],

      VerificationTest[
        graphicsQ[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "Cyclic"]]
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
        graphicsQ[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, VertexCoordinateRules -> {1 -> {0, 0}}]]
      ],

      VerificationTest[
        graphicsQ[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "Ordered", VertexCoordinateRules -> {1 -> {0, 0}}]]
      ],

      (* Valid GraphHighlight *)

      testUnevaluated[
        HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> $$$invalid$$$],
        {HypergraphPlot::invalidHighlight}
      ],

      VerificationTest[
        graphicsQ[HypergraphPlot[{{1, 2, 3}, {1, 2, 3}}, GraphHighlight -> {{1, 2, 3}}]]
      ],

      VerificationTest[
        graphicsQ[HypergraphPlot[{{1, 2, 3}, {1, 2, 3}}, GraphHighlight -> {6}]]
      ],

      VerificationTest[
        graphicsQ[HypergraphPlot[{{1, 2, 3}, {1, 2, 3}}, GraphHighlight -> {{1, 2}}]]
      ],

      VerificationTest[
        graphicsQ[HypergraphPlot[{{1, 2, 3}, {1, 2, 3}}, GraphHighlight -> {{1, 2, 3}, {1, 2, 3}}]]
      ],

      VerificationTest[
        graphicsQ[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {1}]]
      ],

      VerificationTest[
        graphicsQ[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {{1, 2, 3}}]]
      ],

      VerificationTest[
        graphicsQ[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {4, {1, 2, 3}}]]
      ],

      VerificationTest[
        graphicsQ[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {1}, GraphHighlightStyle -> Black]]
      ],

      VerificationTest[
        graphicsQ[HypergraphPlot[
          {{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {1}, GraphHighlightStyle -> Directive[Black, Thick]]]
      ],

      VerificationTest[
        !graphicsQ[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {1}, GraphHighlightStyle -> "Dashed"]]
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
          graphicsQ[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, # -> 1]]
        ]
      } & /@ {VertexSize, "ArrowheadLength"},

      VerificationTest[
        graphicsQ[HypergraphPlot[#, "ArrowheadLength" -> Automatic]]
      ] & /@ {{{1, 2, 3}, {3, 4, 5}}, {{1, 1}}, {{1}}, {}},

      (* WolframModelPlot can still be used *)

      VerificationTest[
        graphicsQ[WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}]]
      ],

      VerificationTest[
        graphicsQ[WolframModelPlot[{{1, 2, 3}, {3, 4, 5}}, "Ordered"]]
      ],

      (* Implementation *)

      (** Simple examples **)

      Table[With[{hypergraph = hypergraph}, VerificationTest[
        graphicsQ[HypergraphPlot[hypergraph, #]]
      ]] & /@ $edgeTypes, {hypergraph, $simpleHypergraphs}],

      (** Large graphs **)

      VerificationTest[
        graphicsQ @ HypergraphPlot @ SetReplace[
          {{0, 1}, {0, 2}, {0, 3}},
          ToPatternRules[
            {{0, 1}, {0, 2}, {0, 3}} ->
            {{4, 5}, {5, 4}, {4, 6}, {6, 4},
              {5, 6}, {6, 5}, {4, 1}, {5, 2}, {6, 3}}],
          #]
      ] & /@ {10, 5000},

      (* EdgeType *)

      VerificationTest[
        diskCoordinates[checkGraphics @ HypergraphPlot[#, "Ordered"]] !=
          diskCoordinates[checkGraphics @ HypergraphPlot[#, "Cyclic"]]
      ] & /@ $layoutTestHypergraphs,

      VerificationTest[
        Length[Union[Cases[
          checkGraphics @ HypergraphPlot[#, "HyperedgeRendering" -> "Subgraphs", "ArrowheadLength" -> 0],
          Polygon[___],
          All]]],
        0
      ] & /@ $layoutTestHypergraphs,

      VerificationTest[
        Length[Union[Cases[
          checkGraphics @ HypergraphPlot[#, "HyperedgeRendering" -> "Polygons", "ArrowheadLength" -> 0],
          Polygon[___],
          All]]],
        0 + Length[#]
      ] & /@ $layoutTestHypergraphs,

      (* VertexLabels *)

      VerificationTest[
        MissingQ[FirstCase[
          checkGraphics @ HypergraphPlot[#, VertexLabels -> None],
          Text[___],
          Missing[],
          All]]
      ] & /@ $layoutTestHypergraphs,

      VerificationTest[
        !MissingQ[FirstCase[
          checkGraphics @ HypergraphPlot[#, VertexLabels -> Automatic],
          Text[___],
          Missing[],
          All]]
      ] & /@ $layoutTestHypergraphs,

      (* Single-vertex edges *)

      VerificationTest[
        checkGraphics @ HypergraphPlot[{{1}, {1, 2}}] =!= checkGraphics @ HypergraphPlot[{{1, 2}}]
      ],

      VerificationTest[
        MissingQ[FirstCase[
          checkGraphics @ HypergraphPlot[{{1, 2}}, VertexLabels -> None],
          Circle[___],
          Missing[],
          All]]
      ],

      VerificationTest[
        !MissingQ[FirstCase[
          checkGraphics @ HypergraphPlot[{{1}, {1, 2}}, VertexLabels -> Automatic],
          Circle[___],
          Missing[],
          All]]
      ],

      (* VertexCoordinateRules *)

      VerificationTest[
        And @@ (MemberQ[
            diskCoordinates[checkGraphics @ HypergraphPlot[
              {{1, 2, 3}, {3, 4, 5}, {3, 3}},
              VertexCoordinateRules -> {1 -> {0, 0}, 2 -> {1, 0}}]],
            #] & /@
          {{0., 0.}, {1., 0.}})
      ],

      VerificationTest[
        Chop @ diskCoordinates[checkGraphics @ HypergraphPlot[
          {{1, 2, 3}, {3, 4, 5}},
          VertexCoordinateRules -> {3 -> {0, 0}}]] != Table[{0, 0}, 5]
      ],

      VerificationTest[
        Chop @ diskCoordinates[checkGraphics @ HypergraphPlot[
          {{1, 2, 3}, {3, 4, 5}},
          VertexCoordinateRules -> {3 -> {1, 0}, 3 -> {0, 0}}]] != Table[{0, 0}, 5]
      ],

      (** Same coordinates should not produce any messages **)
      VerificationTest[
        And @@ Cases[
          checkGraphics @ HypergraphPlot[{{1, 2, 3}}, VertexCoordinateRules -> {1 -> {1, 0}, 2 -> {1, 0}}],
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
          HypergraphPlot[hypergraph, PlotStyle -> #],
          {HypergraphPlot::invalidPlotStyle}
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
          HypergraphPlot[hypergraph, EdgeStyle -> {RGBColor[1, 0, 0]}],
          {HypergraphPlot::invalidStyleLength}
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
        graphicsQ[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, VertexSize -> 0.3]]
      ],

      VerificationTest[
        graphicsQ[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "ArrowheadLength" -> 0.3]]
      ],

      VerificationTest[
        graphicsQ[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, VertexSize -> 0.4, "ArrowheadLength" -> 0.3]]
      ],

      (* weed #286 *)
      VerificationTest[
        graphicsQ[HypergraphPlot[{}, VertexStyle -> {}, EdgeStyle -> {}]]
      ],

      (* GraphHighlight *)

      VerificationTest[
        Length[Union @ Cases[
            checkGraphics @ HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {#}], _ ? ColorQ, All]] >
          Length[Union @ Cases[checkGraphics @ HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}], _ ? ColorQ, All]]
      ] & /@ {4, {1, 2, 3}},

      (** Test multi-edge highlighting **)
      VerificationTest[
        Differences[
          Length[Union[Cases[#, _?ColorQ, All]]] & /@
            (checkGraphics[HypergraphPlot[
              {{1, 2}, {1, 2}}, "HyperedgeRendering" -> "Subgraphs", GraphHighlight -> #]] &) /@
            {{}, {{1, 2}}, {{1, 2}, {1, 2}}}],
        {1, -1}
      ],

      (* GraphHighlightStyle *)

      With[{color = RGBColor[0.4, 0.6, 0.2]},
        With[{style = #},
          VerificationTest[
            FreeQ[checkGraphics @ HypergraphPlot[
                {{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> #, GraphHighlightStyle -> color], color] & /@
              {{}, {4}, {{1, 2, 3}}},
            {True, False, False}
          ]
        ] & /@ {color, Directive[Thick, color]}
      ],

      (* Scaling consistency *)
      (* Vertex sizes, arrow sizes, average edge lengths, and loop lengths should always be the same. *)

      VerificationTest[
        SameQ @@ (
          Union[Cases[checkGraphics @ HypergraphPlot[#], Disk[_, r_] :> r, All]] & /@
            {{{1}}, {{1, 2, 3}}, {{1, 2, 3}, {3, 4, 5}}, RandomInteger[10, {5, 5}]})
      ],

      With[{$minArrowheadSize = $minArrowheadSize, $maxArrowheadSize = $maxArrowheadSize},
        VerificationTest[
          Length[DeleteDuplicates[
            Mean[Cases[
                checkGraphics @ HypergraphPlot[#, "HyperedgeRendering" -> "Subgraphs"],
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
                      checkGraphics @ HypergraphPlot[#, "HyperedgeRendering" -> "Subgraphs"],
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
        Table[OrderedQ[(ImageSizeRaw /. AbsoluteOptions[checkGraphics @ HypergraphPlot[#], ImageSizeRaw])[[k, 1]] & /@
          {{{1}}, {{1, 1}}, {{1, 2, 3}, {3, 4, 5}, {5, 6, 1}}, {{1, 2, 3}, {3, 4, 5}, {5, 6, 7}, {7, 8, 1}}}], {k, 2}],
        {True, True}
      ],

      testUnevaluated[
        HypergraphPlot[{{1, 2}, {2, 3}, {3, 1}}, "MaxImageSize" -> "$$$invalid$$$"],
        {HypergraphPlot::invalidMaxImageSize}
      ] & /@ {"$$$invalid$$$", {200, 200, 200}, UpTo[200], {{100, 200}, {100, 200}}, Full, Scaled[0.5]},

      VerificationTest[
        With[{
            sizes = (ImageSize /. AbsoluteOptions[#, ImageSize][[1]] & /@
              checkGraphics /@ WolframModel[{{x, y}, {y, z}} -> {{w, y}, {y, z}, {z, w}, {x, w}}, {{0, 0}, {0, 0}}, 10][
                "StatesPlotsList", "MaxImageSize" -> #]) & /@ {100, 200}},
          AllTrue[sizes[[1]], # < 100.0001 &] &&
          !AllTrue[sizes[[1]], # > 99.9999 &] &&
          AllTrue[sizes[[2]] / sizes[[1]], 1.9999 < # < 2.0001 &]
        ]
      ],

      VerificationTest[
        With[{
            sizes = (ImageSize /. AbsoluteOptions[#, ImageSize][[1]] & /@
              checkGraphics /@ WolframModel[{{x, y}, {y, z}} -> {{w, y}, {y, z}, {z, w}, {x, w}}, {{0, 0}, {0, 0}}, 10][
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
        graphicsQ /@ HypergraphPlot[{{{1, 2, 3}, {3, 4, 5}}, {{3, 4, 5}, {5, 6, 7}}, {{5, 6, 7}, {7, 8, 5}}}, ##],
        ConstantArray[True, 3]
      ] & @@@ {
        {},
        {GraphHighlight -> {3, {3, 4, 5}}},
        {VertexSize -> 0.1, "ArrowheadLength" -> 0.2},
        {EdgeStyle -> Red},
        {VertexCoordinateRules -> {3 -> {0, 0}, 4 -> {1, 0}}}
      },

      (* GraphHighlight and style interaction *)

      With[{color1 = RGBColor[0.46, 0.51, 0.87], color2 = RGBColor[0.13, 0.64, 0.27]},
        testColorPresence[
          {{1, 2}},
          {GraphHighlight -> {2}, GraphHighlightStyle -> color1, VertexStyle -> color2},
          {color1, color2}
        ]
      ],

      (* Style inheritance *)
      SeedRandom[288];
      With[{
          colors = Table[RandomColor[5]], edgeColor = RandomColor[], extraColor = RandomColor[],
          set = {{1, 2, 3}, {3, 4, 5}}},
        {testColorPresence[set, #, #2, Replace[#4, All -> Sequence[]]],
            testColorAbsense[set, #, #3, Replace[#4, All -> Sequence[]]]} & @@@ {
          {{PlotStyle -> colors[[1]], EdgeStyle -> edgeColor, VertexStyle -> colors[[2]]},          {colors[[2]]},    {colors[[1]]}, All},
          {{PlotStyle -> colors[[1]], EdgeStyle -> edgeColor, VertexStyle -> Automatic},            {colors[[1]]},    {},            All},
          {{PlotStyle -> colors[[1]], EdgeStyle -> edgeColor, VertexStyle -> <|3 -> colors[[2]]|>}, colors[[1 ;; 2]], {},            All},
          {{PlotStyle -> extraColor,  EdgeStyle -> edgeColor, VertexStyle -> colors},               colors,           {extraColor},  All},
          {{PlotStyle -> Automatic,                           VertexStyle -> colors[[1]]},          {colors[[1]]},    {},            All},
          {{PlotStyle -> Automatic,                           VertexStyle -> Automatic},            {},               {},            All},
          {{PlotStyle -> Automatic,                           VertexStyle -> <|3 -> colors[[1]]|>}, {colors[[1]]},    {},            All},
          {{PlotStyle -> Automatic,                           VertexStyle -> colors},               colors,           {},            All},
          {{PlotStyle -> <|3 -> colors[[1]]|>,                VertexStyle -> colors[[2]]},          {colors[[2]]},    {colors[[1]]}, All},
          {{PlotStyle -> <|3 -> colors[[1]]|>,                VertexStyle -> Automatic},            {colors[[1]]},    {},            All},
          {{PlotStyle -> <|3 -> colors[[1]]|>,                VertexStyle -> <|4 -> colors[[2]]|>}, colors[[1 ;; 2]], {},            All},
          {{PlotStyle -> <|3 -> extraColor|>,                 VertexStyle -> colors},               colors,           {extraColor},  All},
          {{EdgeStyle -> colors[[1 ;; 2]],   "EdgePolygonStyle" -> colors[[3]]},                    colors[[1 ;; 3]], {},            {"Polygons"}},
          {{EdgeStyle -> colors[[1 ;; 2]],   "EdgePolygonStyle" -> Automatic},                      colors[[1 ;; 2]], {},            {"Polygons"}},
          {{EdgeStyle -> colors[[1 ;; 2]],   "EdgePolygonStyle" -> <|{1, 2, 3} -> colors[[3]]|>},   colors[[1 ;; 3]], {},            {"Polygons"}},
          {{EdgeStyle -> colors[[1 ;; 2]],   "EdgePolygonStyle" -> colors[[3 ;; 4]]},               colors[[1 ;; 4]], {},            {"Polygons"}}
        }
      ],

      VerificationTest[
        graphicsQ @ HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, Background -> Automatic]
      ],

      VerificationTest[
        Options[
          checkGraphics @ HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, Background -> RGBColor[0.2, 0.5, 0.3]], Background],
        {Background -> RGBColor[0.2, 0.5, 0.3]}
      ]
    }
  |>
|>
