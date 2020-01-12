<|
  "RulePlot" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];

      $rulesForVertexSizeConsistency = {
        {{1}} -> {{1}},
        {{1}} -> {{2}},
        {{1, 2}} -> {{1}},
        {{1, 2}} -> {{1, 2}},
        {{1, 2, 3}} -> {{1}},
        {{1, 2, 3}} -> {{1, 2}},
        {{1}, {2}} -> {{2}, {3}},
        {{1}, {2}, {3}} -> {{2}, {3}, {4}},
        {{1, 2, 3}} -> {{3, 4, 5}},
        {{1, 2, 3}} -> {{1, 2}, {2, 3}},
        {{1, 2, 3}} -> {{2, 3}, {3, 4}}};
    ),
    "tests" -> {
      (* Symbol Leak *)

      testSymbolLeak[
        SeedRandom[123];
        RulePlot[WolframModel[Rule @@ RandomInteger[100, {2, 50, 3}]]]
      ],

      (* Rule correctness checking *)

      testUnevaluated[
        RulePlot[WolframModel[1]],
        {RulePlot::invalidRules}
      ],

      testUnevaluated[
        RulePlot[WolframModel[1 -> 2]],
        {RulePlot::notHypergraphRule}
      ],

      testUnevaluated[
        RulePlot[WolframModel[{1} -> {2}]],
        {RulePlot::notHypergraphRule}
      ],

      testUnevaluated[
        RulePlot[WolframModel[{{1}} -> {2}]],
        {RulePlot::notHypergraphRule}
      ],

      VerificationTest[
        Head[RulePlot[WolframModel[{{1}} -> {{2}}]]],
        Graphics
      ],

      testUnevaluated[
        RulePlot[WolframModel[<|"PatternRules" -> {{1}} -> {{2}}|>]],
        {RulePlot::patternRules}
      ],

      VerificationTest[
        Head[RulePlot[WolframModel[{{1}} -> {{2}}, Method -> "$$$AnyMethod$$$"]]],
        Graphics
      ],

      testUnevaluated[
        RulePlot[WolframModel[{{{1}} -> {{2}}, 1}]],
        {RulePlot::invalidRules}
      ],

      testUnevaluated[
        RulePlot[WolframModel[{{{1}} -> {{2}}, 1 -> 2}]],
        {RulePlot::notHypergraphRule}
      ],

      VerificationTest[
        Head[RulePlot[WolframModel[{{{1}} -> {{2}}, {{1}} -> {{2}}}]]],
        Graphics
      ],

      (* Options *)

      (** EdgeType **)

      VerificationTest[
        Head[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], "EdgeType" -> #]],
        Graphics
      ] & /@ {"Ordered", "Cyclic"},

      testUnevaluated[
        RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], "EdgeType" -> "Invalid"],
        {RulePlot::invalidEdgeType}
      ],

      testUnevaluated[
        RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], "EdgeType" -> 3],
        {RulePlot::invalidEdgeType}
      ],

      (** GraphhighlightStyle **)

      testUnevaluated[
        RulePlot[WolframModel[{{1, 2, 3}, {3, 4, 5}} -> {{3, 4, 5}, {5, 6, 7}}], GraphHighlightStyle -> 1],
        {RulePlot::invalidHighlightStyle}
      ],

      VerificationTest[
        With[{
            color = RGBColor[0.4, 0.6, 0.2]},
          FreeQ[RulePlot[WolframModel[#], GraphHighlightStyle -> color], color] & /@
            {{{1}} -> {{2}}, {{1}} -> {{1}}, {{1, 2}} -> {{1, 2}}, {{1, 2}} -> {{2, 3}}, {{1, 2}} -> {{3, 4}}}],
        {True, False, False, False, True}
      ],

      (** HyperedgeRendering **)

      VerificationTest[
        Head[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], "HyperedgeRendering" -> #]],
        Graphics
      ] & /@ {"Subgraphs", "Polygons"},

      testUnevaluated[
        RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], "HyperedgeRendering" -> "Invalid"],
        {RulePlot::invalidFiniteOption}
      ],

      testUnevaluated[
        RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], "HyperedgeRendering" -> 3],
        {RulePlot::invalidFiniteOption}
      ],

      (** VertexCoordinateRules **)

      VerificationTest[
        SameQ @@
          Cases[
            RulePlot[
              WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}],
              VertexCoordinateRules -> {1 -> {0, 0}, 2 -> {1, 0}, 3 -> {2, 0}, 4 -> {3, 0}, 5 -> {4, 0}}],
            Disk[p_, _] :> p,
            All][[All, 2]]
      ],

      (*** Due to scaling and translation being computed in the frontend instead of ahead of time,
            coordinates on both sides of the rule might be the same. ***)
      VerificationTest[
        Length[
            Union[
              Cases[
                RulePlot[
                  WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}],
                  VertexCoordinateRules -> {1 -> {0, 0}, 2 -> {0, 0}, 3 -> {0, 0}, 4 -> {0, 0}, 5 -> {0, 0}}],
                Disk[p_, _] :> p,
                All]]]
          <= 2
      ],

      VerificationTest[
        Head[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], VertexCoordinateRules -> {}]],
        Graphics
      ],

      testUnevaluated[
        RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], VertexCoordinateRules -> {1}],
        {RulePlot::invalidCoordinates}
      ],

      (** VertexLabels **)

      VerificationTest[
        Sort[Cases[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], VertexLabels -> Automatic], Text[i_, ___] :> i, All]],
        {1, 2, 3, 3, 4, 5}
      ],

      VerificationTest[
        Length[Cases[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], VertexLabels -> x], Text[x, ___], All]],
        6
      ],

      (** Graphics **)

      VerificationTest[
        Background /. AbsoluteOptions[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], Background -> Black], Background],
        Black,
        SameTest -> Equal
      ],

      (** Frame **)

      VerificationTest[
        Head[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], Frame -> #]],
        Graphics
      ] & /@ {False, True},

      testUnevaluated[
        RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], Frame -> "Invalid"],
        {RulePlot::invalidFiniteOption}
      ],

      (** FrameStyle **)

      VerificationTest[
        MemberQ[
          Cases[
            RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], FrameStyle -> RGBColor[0.33, 0.66, 0.77]][[1]],
            _ ? ColorQ,
            All],
          RGBColor[0.33, 0.66, 0.77]]
      ],

      VerificationTest[
        Not @ MemberQ[
          Cases[
            RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], FrameStyle -> RGBColor[0.33, 0.66, 0.77], Frame -> False][[1]],
            _ ? ColorQ,
            All],
          RGBColor[0.33, 0.66, 0.77]]
      ],

      (** PlotLegends **)

      VerificationTest[
        MatchQ[
          RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], PlotLegends -> "Text"],
          Legended[_, Placed[StandardForm[{{1, 2, 3}} -> {{3, 4, 5}}], Below]]]
      ],

      VerificationTest[
        MatchQ[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], PlotLegends -> "test"], Legended[_, "test"]]
      ],

      VerificationTest[
        Not @ MatchQ[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}]], Legended[___]]
      ],

      (** Spacings **)

      VerificationTest[
        Head[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], Spacings -> #]],
        Graphics
      ] & /@ {0, 1, {{1, 0}, {0, 0}}, {{0, 1}, {0, 0}}, {{0, 0}, {1, 0}}, {{0, 0}, {0, 1}}},

      VerificationTest[
        Head[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], Spacings -> #]],
        Graphics
      ] & /@ {1, {{1, 1}, {1, 1}}},

      testUnevaluated[
        RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], Spacings -> #],
        {RulePlot::invalidSpacings}
      ] & /@ {
        "Incorrect",
        {1, 1},
        {{1, 2}, 1},
        {1, {1, 2}},
        {{1, 2, 3}, {1, 2}},
        {{1, {2, 3}}, {1, 2}}
      },

      (* Scaling consistency *)

      (** Vertex amplification **)

      VerificationTest[
        First[Cases[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}]], Disk[_, r_] :> r, All]] > 
          First[Cases[WolframModelPlot[{{1, 2, 3}}], Disk[_, r_] :> r, All]]
      ],

      (** Consistent vertex sizes **)

      VerificationTest[
        SameQ @@ Cases[RulePlot[WolframModel[#]], Disk[_, r_] :> r, All]
      ] & /@ $rulesForVertexSizeConsistency,

      (** Shared vertices are colored **)

      VerificationTest[
        Cases[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}]], _ ? ColorQ, All] =!=
          Cases[RulePlot[WolframModel[{{1, 2, 3}} -> {{4, 5, 6}}]], _ ? ColorQ, All]
      ]
    }
  |>
|>
