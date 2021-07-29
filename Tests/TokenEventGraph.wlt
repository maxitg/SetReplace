<|
  "TokenEventGraph" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAllComplete};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];

      $sumsMultihistory = GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} /; a < b :> {a + b}]][Range[4]];

      $largeHistory = GenerateSingleHistory[
        MultisetSubstitutionSystem[{{x_, y_}, {x_, z_}} :> Module[{w}, {{x, y}, {x, w}, {y, w}, {z, w}}]],
        MaxGeneration -> 6] @ {{0, 0}, {0, 0}, {0, 0}};
    ),
    "tests" -> With[{sumsMultihistory = $sumsMultihistory, largeHistory = $largeHistory}, {
      testUnevaluated[TokenEventGraph[##] @ sumsMultihistory, {TokenEventGraph::unexpectedArguments}] & @@@
        {{1}, {1, opt -> 2}},

      testUnevaluated[TokenEventGraph[opt -> 2] @ sumsMultihistory, {TokenEventGraph::optx}],

      VerificationTest @ AcyclicGraphQ @ TokenEventGraph @ largeHistory,
      VerificationTest @ LoopFreeGraphQ @ TokenEventGraph @ largeHistory,

      (* TODO: compare TEGs for equivalent hypergraph and multiset systems once implemented. *)

      VerificationTest[
        Length @ Cases[GraphPlot @ TokenEventGraph[VertexLabels -> 186173] @ sumsMultihistory, Text[186173, ___], All],
        VertexCount @ TokenEventGraph @ sumsMultihistory],

      (* TODO: test the rest of VertexLabels and VertexStyle functionality. *)

      VerificationTest[
        Options[TokenEventGraph[EdgeStyle -> Automatic, VertexStyle -> Automatic] @ sumsMultihistory,
                {EdgeStyle, VertexStyle}],
        Options[TokenEventGraph @ sumsMultihistory, {EdgeStyle, VertexStyle}]]
    }]
  |>
|>

(* TODO: go through the code in TokenEventGraph.m and tests all features there. *)

(* TODO: adapt tests below to new syntax/functionality. *)

(*        VerificationTest[
          Options[
            WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, 4][
              type, EdgeStyle -> RGBColor[0.2, 0.3, 0.4], VertexStyle -> RGBColor[0.5, 0.6, 0.7]],
            {EdgeStyle, VertexStyle}],
          Options[
            Graph[{1 -> 2}, EdgeStyle -> RGBColor[0.2, 0.3, 0.4], VertexStyle -> RGBColor[0.5, 0.6, 0.7]],
            {EdgeStyle, VertexStyle}]
        ],

        VerificationTest[
          Options[
            WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, 4][type, GraphLayout -> Automatic],
            GraphLayout],
          Options[WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, 4][type], GraphLayout]
        ],

        VerificationTest[
          Options[
            WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, 4][
              type, GraphLayout -> {"Dimension" -> 2, "VertexLayout" -> "CircularEmbedding"}],
            GraphLayout
          ],
          Options[
            Graph[
              WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, 4, type],
              GraphLayout -> {"Dimension" -> 2, "VertexLayout" -> "CircularEmbedding"}],
            GraphLayout]
        ]
      }],

      Table[With[{type = type}, {
        With[{largeEvolution = $largeEvolution}, {
          VerificationTest[
            VertexCount[ReleaseHold[largeEvolution[type]]],
            ReleaseHold[largeEvolution["EventsCount"]]
          ],

          VerificationTest[
            GraphDistance[ReleaseHold[largeEvolution[type]], 1, ReleaseHold[largeEvolution["EventsCount"]]],
            ReleaseHold[largeEvolution["TotalGenerationsCount"]] - 1
          ],

          VerificationTest[
            Count[VertexInDegree[ReleaseHold[largeEvolution[type]]], 3],
            ReleaseHold[largeEvolution["EventsCount"]] - 1
          ]
        }] /. HoldPattern[ReleaseHold[Hold[expr_]]] :> expr,

        VerificationTest[
          Through[{VertexList, Rule @@@ EdgeList[#] &}[WolframModel[
            {{1, 2}, {2, 3}} -> {{1, 3}},
            pathGraph17,
            4][type]]],
          {Range[15],
            {1 -> 9, 2 -> 9, 3 -> 10, 4 -> 10, 5 -> 11, 6 -> 11, 7 -> 12, 8 -> 12, 9 -> 13, 10 -> 13, 11 -> 14,
              12 -> 14, 13 -> 15, 14 -> 15}}
        ],

        VerificationTest[
          Through[{VertexList, EdgeList}[WolframModel[
            {{1, 2}, {2, 3}} -> {{1, 3}},
            pathGraph17,
            1][type]]],
          {Range[8], {}}
        ],

        VerificationTest[
          Through[{VertexList, Rule @@@ EdgeList[#] &}[WolframModel[
            {{1, 2}, {2, 3}} -> {{1, 3}},
            Partition[Range[17], 2, 1],
            2][type]]],
          {Range[12], {1 -> 9, 2 -> 9, 3 -> 10, 4 -> 10, 5 -> 11, 6 -> 11, 7 -> 12, 8 -> 12}}
        ],

        VerificationTest[
          Through[{VertexList, Rule @@@ EdgeList[#] &}[WolframModel[
            {{1, 2}} -> {},
            {{1, 2}, {2, 3}},
            2][type]]],
          {{1, 2}, {}}
        ],

        VerificationTest[
          Through[{VertexList, Rule @@@ EdgeList[#] &}[WolframModel[
            {{1, 2}, {2, 3}} -> {{1, 3}},
            {{1, 2}, {2, 3}, {3, 4}, {4, 5}},
            2][type, "IncludeBoundaryEvents" -> #1]]],
          {#2, #3}
        ] & @@@ {
          {None, {1, 2, 3}, {1 -> 3, 2 -> 3}},
          {"Initial", {0, 1, 2, 3}, {0 -> 1, 0 -> 1, 0 -> 2, 0 -> 2, 1 -> 3, 2 -> 3}},
          {"Final", {1, 2, 3, Infinity}, {1 -> 3, 2 -> 3, 3 -> Infinity}},
          {All, {0, 1, 2, 3, Infinity}, {0 -> 1, 0 -> 1, 0 -> 2, 0 -> 2, 1 -> 3, 2 -> 3, 3 -> Infinity}}},

        VerificationTest[
          Through[{VertexList, Rule @@@ EdgeList[#] &}[WolframModel[
            {{1, 2}} -> {{1, 3}, {3, 2}},
            {{1, 2}},
            2][type, "IncludeBoundaryEvents" -> #1]]],
          {#2, #3}
        ] & @@@ {
          {None, {1, 2, 3}, {1 -> 2, 1 -> 3}},
          {"Initial", {0, 1, 2, 3}, {0 -> 1, 1 -> 2, 1 -> 3}},
          {"Final", {1, 2, 3, Infinity}, {1 -> 2, 1 -> 3, 2 -> Infinity, 2 -> Infinity, 3 -> Infinity, 3 -> Infinity}},
          {All,
            {0, 1, 2, 3, Infinity},
            {0 -> 1, 1 -> 2, 1 -> 3, 2 -> Infinity, 2 -> Infinity, 3 -> Infinity, 3 -> Infinity}}},

        VerificationTest[
          Through[{VertexList, Rule @@@ EdgeList[#] &}[WolframModel[
            {{1, 2}} -> {{1, 2}},
            {{1, 2}},
            0][type, "IncludeBoundaryEvents" -> #1]]],
          {#2, #3}
        ] & @@@ {
          {None, {}, {}},
          {"Initial", {0}, {}},
          {"Final", {Infinity}, {}},
          {All, {0, Infinity}, {0 -> Infinity}}}
      }], {type, {"CausalGraph", "LayeredCausalGraph"}}],

      VerificationTest[
        Round[Replace[VertexCoordinates, FilterRules[AbsoluteOptions[WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["LayeredCausalGraph"]], VertexCoordinates]][[All, 2]]],
        Floor[Log2[16 - Range[15]]]
      ],

      VerificationTest[
        Round[Replace[VertexCoordinates, FilterRules[AbsoluteOptions[WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["LayeredCausalGraph", "IncludeBoundaryEvents" -> All]], VertexCoordinates]][[All, 2]]],
        Join[{5}, Floor[Log2[16 - Range[15]]] + 1, {0}]
      ],

      VerificationTest[
        Cases[VertexStyle /. Options[
          WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, 4, #, "IncludeBoundaryEvents" -> "Initial"],
          VertexStyle][[1]], _Rule, {1}],
        {0 -> _},
        SameTest -> MatchQ
      ] & /@ {"CausalGraph", "LayeredCausalGraph"},

      VerificationTest[
        Sort[Cases[VertexStyle /. Options[
          WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, 4, "CausalGraph", "IncludeBoundaryEvents" -> #],
          VertexStyle][[1]], _Rule, {1}]],
        #2,
        SameTest -> MatchQ
      ] & @@@ {{None, {}}, {"Final", {Infinity -> _}}, {All, {0 -> _, Infinity -> _}}},

      With[{largeEvolution = $largeEvolution}, {
        VerificationTest[
          Count[VertexInDegree[ReleaseHold[largeEvolution["ExpressionsEventsGraph"]]], 1],
          ReleaseHold[largeEvolution["ExpressionsCountTotal"]] - 3
        ],

        VerificationTest[
          VertexCount[ReleaseHold[largeEvolution["ExpressionsEventsGraph"]]],
          ReleaseHold[largeEvolution["EventsCount"] + largeEvolution["ExpressionsCountTotal"]]
        ],

        VerificationTest[
          GraphDistance[
            ReleaseHold[largeEvolution["ExpressionsEventsGraph"]],
            {"Expression", 1},
            {"Expression", ReleaseHold[largeEvolution["ExpressionsCountTotal"]]}],
          2 ReleaseHold[largeEvolution["TotalGenerationsCount"]]
        ],

        VerificationTest[
          Count[VertexInDegree[ReleaseHold[largeEvolution["ExpressionsEventsGraph"]]], 3],
          ReleaseHold[largeEvolution["EventsCount"]]
        ]
      }] /. HoldPattern[ReleaseHold[Hold[expr_]]] :> expr,

      VerificationTest[
        Through[{VertexList, Rule @@@ EdgeList[#] &}[WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["ExpressionsEventsGraph"]]],
        {Join[Thread[{"Event", Range[15]}], Thread[{"Expression", Range[31]}]],
         Join[
          Thread[Thread[{"Event", Range[15]}] -> Thread[{"Expression", Range[17, 31]}]],
          Thread[Thread[{"Expression", Range[30]}] -> Thread[{"Event", Quotient[Range[30] + 1, 2]}]]]}
      ],

      VerificationTest[
        Through[{VertexList, Rule @@@ EdgeList[#] &}[WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          1]["ExpressionsEventsGraph"]]],
        {Join[Thread[{"Event", Range[8]}], Thread[{"Expression", Range[24]}]],
         Join[
          Thread[Thread[{"Event", Range[8]}] -> Thread[{"Expression", Range[17, 24]}]],
          Thread[Thread[{"Expression", Range[16]}] -> Thread[{"Event", Quotient[Range[16] + 1, 2]}]]]}
      ],

      VerificationTest[
        Through[{VertexList, Rule @@@ EdgeList[#] &}[WolframModel[
          {{1, 2}} -> {},
          {{1, 2}, {2, 3}},
          2]["ExpressionsEventsGraph"]]],
        {{{"Event", 1}, {"Event", 2}, {"Expression", 1}, {"Expression", 2}},
         {{"Expression", 1} -> {"Event", 1}, {"Expression", 2} -> {"Event", 2}}}
      ],

      VerificationTest[
        Sort[VertexLabels /. FilterRules[AbsoluteOptions[WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, 2][
          "ExpressionsEventsGraph", VertexLabels -> Automatic]], VertexLabels]],
        {{"Event", 1} -> None, {"Event", 2} -> None, {"Event", 3} -> None,
         {"Expression", 1} -> "{1, 1}", {"Expression", 2} -> "{1, 2}", {"Expression", 3} -> "{2, 1}",
         {"Expression", 4} -> "{1, 3}", {"Expression", 5} -> "{3, 2}", {"Expression", 6} -> "{2, 4}",
         {"Expression", 7} -> "{4, 1}"}
      ],

      VerificationTest[
        Sort[VertexLabels /. FilterRules[AbsoluteOptions[WolframModel[
          {{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, 2][
            "ExpressionsEventsGraph", VertexLabels -> Automatic, "IncludeBoundaryEvents" -> All]], VertexLabels]],
        {{"Event", 0} -> "Initial event", {"Event", 1} -> None, {"Event", 2} -> None, {"Event", 3} -> None,
         {"Event", Infinity} -> "Final event",
         {"Expression", 1} -> "{1, 1}", {"Expression", 2} -> "{1, 2}", {"Expression", 3} -> "{2, 1}",
         {"Expression", 4} -> "{1, 3}", {"Expression", 5} -> "{3, 2}", {"Expression", 6} -> "{2, 4}",
         {"Expression", 7} -> "{4, 1}"}
      ],

      VerificationTest[
        Sort[VertexLabels /. FilterRules[AbsoluteOptions[WolframModel[
          {{{1, 2}} -> {{1, 2, 3}}, {{1, 2, 3}} -> {{1, 2}, {2, 3}}}, {{1, 1}}, 2][
            "ExpressionsEventsGraph", VertexLabels -> Automatic]], VertexLabels]],
        {{"Event", 1} -> "Rule 1", {"Event", 2} -> "Rule 2",
         {"Expression", 1} -> "{1, 1}", {"Expression", 2} -> "{1, 1, 2}", {"Expression", 3} -> "{1, 1}",
         {"Expression", 4} -> "{1, 2}"}
      ],

      VerificationTest[
        Sort[VertexLabels /. FilterRules[AbsoluteOptions[WolframModel[
          {{{1, 2}} -> {{1, 2, 3}}, {{1, 2, 3}} -> {{1, 2}, {2, 3}}}, {{1, 1}}, 1][
            "ExpressionsEventsGraph", VertexLabels -> Automatic]], VertexLabels]],
        {{"Event", 1} -> "Rule 1", {"Expression", 1} -> "{1, 1}", {"Expression", 2} -> "{1, 1, 2}"}
      ],

      VerificationTest[
        Sort[VertexLabels /. FilterRules[AbsoluteOptions[WolframModel[
          {{{1, 2}} -> {{1, 2, 3}}, {{1, 2, 3}} -> {{1, 2}, {2, 3}}}, {{1, 1}}, 1][
            "ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]]], VertexLabels]],
        {{"Event", 1} -> Placed["Rule 1", After], {"Expression", 1} -> Placed["{1, 1}", After],
         {"Expression", 2} -> Placed["{1, 1, 2}", After]}
      ],

      VerificationTest[
        Sort[VertexLabels /. FilterRules[AbsoluteOptions[WolframModel[
          {{{1, 2}} -> {{1, 2, 3}}, {{1, 2, 3}} -> {{1, 2}, {2, 3}}}, {{1, 1}}, 2][
            "ExpressionsEventsGraph", VertexLabels -> Automatic, "IncludeBoundaryEvents" -> All]], VertexLabels]],
        {{"Event", 0} -> "Initial event", {"Event", 1} -> "Rule 1", {"Event", 2} -> "Rule 2",
         {"Event", Infinity} -> "Final event",
         {"Expression", 1} -> "{1, 1}", {"Expression", 2} -> "{1, 1, 2}", {"Expression", 3} -> "{1, 1}",
         {"Expression", 4} -> "{1, 2}"}
      ],

      VerificationTest[
        Through[{VertexList, Rule @@@ EdgeList[#] &}[WolframModel[
          {{{1, 2}} -> {{1, 2, 3}}, {{1, 2, 3}} -> {{1, 2}, {2, 3}}}, {{1, 1}}, 2][
            "ExpressionsEventsGraph", "IncludeBoundaryEvents" -> #1]]],
        {#2, #3}
      ] & @@@ {
        {None,
         {{"Event", 1}, {"Event", 2}, {"Expression", 1}, {"Expression", 2}, {"Expression", 3}, {"Expression", 4}},
         {{"Event", 1} -> {"Expression", 2}, {"Event", 2} -> {"Expression", 3}, {"Event", 2} -> {"Expression", 4},
          {"Expression", 1} -> {"Event", 1}, {"Expression", 2} -> {"Event", 2}}},
        {"Initial",
         {{"Event", 0}, {"Event", 1}, {"Event", 2}, {"Expression", 1}, {"Expression", 2}, {"Expression", 3},
          {"Expression", 4}},
         {{"Event", 0} -> {"Expression", 1}, {"Event", 1} -> {"Expression", 2}, {"Event", 2} -> {"Expression", 3},
          {"Event", 2} -> {"Expression", 4}, {"Expression", 1} -> {"Event", 1},
          {"Expression", 2} -> {"Event", 2}}},
        {"Final",
         {{"Event", 1}, {"Event", 2}, {"Event", Infinity}, {"Expression", 1}, {"Expression", 2}, {"Expression", 3},
          {"Expression", 4}},
         {{"Event", 1} -> {"Expression", 2}, {"Event", 2} -> {"Expression", 3}, {"Event", 2} -> {"Expression", 4},
          {"Expression", 1} -> {"Event", 1}, {"Expression", 2} -> {"Event", 2},
          {"Expression", 3} -> {"Event", Infinity}, {"Expression", 4} -> {"Event", Infinity}}},
        {All,
         {{"Event", 0}, {"Event", 1}, {"Event", 2}, {"Event", Infinity}, {"Expression", 1}, {"Expression", 2},
          {"Expression", 3}, {"Expression", 4}},
         {{"Event", 0} -> {"Expression", 1}, {"Event", 1} -> {"Expression", 2}, {"Event", 2} -> {"Expression", 3},
          {"Event", 2} -> {"Expression", 4}, {"Expression", 1} -> {"Event", 1}, {"Expression", 2} -> {"Event", 2},
          {"Expression", 3} -> {"Event", Infinity}, {"Expression", 4} -> {"Event", Infinity}}}},

      VerificationTest[
        Through[{VertexList, Rule @@@ EdgeList[#] &}[WolframModel[{{1, 2}} -> {{1, 2}}, {{1, 2}}, 0][
          "ExpressionsEventsGraph", "IncludeBoundaryEvents" -> #1]]],
        {#2, #3}
      ] & @@@ {
        {None, {{"Expression", 1}}, {}},
        {"Initial", {{"Event", 0}, {"Expression", 1}}, {{"Event", 0} -> {"Expression", 1}}},
        {"Final", {{"Event", Infinity}, {"Expression", 1}}, {{"Expression", 1} -> {"Event", Infinity}}},
        {All,
         {{"Event", 0}, {"Event", Infinity}, {"Expression", 1}},
         {{"Event", 0} -> {"Expression", 1}, {"Expression", 1} -> {"Event", Infinity}}}},

      VerificationTest[
        Round[Replace[VertexCoordinates, FilterRules[AbsoluteOptions[WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["ExpressionsEventsGraph"]], VertexCoordinates]][[All, 2]]],
        Join[2 Floor[Log2[16 - Range[15]]] + 1, 2 Floor[Log2[32 - Range[31]]]]
      ],

      VerificationTest[
        Round[Replace[VertexCoordinates, FilterRules[AbsoluteOptions[WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["ExpressionsEventsGraph", "IncludeBoundaryEvents" -> All]], VertexCoordinates]][[All, 2]]],
        Join[Join[{10}, 2 Floor[Log2[16 - Range[15]]] + 2, {0}], 2 Floor[Log2[32 - Range[31]]] + 1]
      ],

      Function[{events, sameStyleQ},
        VerificationTest[
          SameQ @@ (events /. (VertexStyle /. Options[
            WolframModel[
              {{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, 2, "ExpressionsEventsGraph", "IncludeBoundaryEvents" -> All],
            VertexStyle])),
          sameStyleQ
        ]
      ] @@@ {
        {{{"Event", 1}, {"Event", 2}}, True},
        {{{"Event", 0}, {"Event", 1}}, False},
        {{{"Event", 0}, {"Event", Infinity}}, False},
        {{{"Event", 1}, {"Event", Infinity}}, False}},

      VerificationTest[
        WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                     Infinity,
                     "EventSelectionFunction" -> None]["CausalGraph"],
        Graph[Range[7], {1 -> 4, 2 -> 5, 4 -> 6, 4 -> 7, 5 -> 6, 5 -> 7}],
        SameTest -> sameGraphQ
      ],

      VerificationTest[
        WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                     Infinity,
                     "EventSelectionFunction" -> None]["CausalGraph", "IncludeBoundaryEvents" -> All],
        Graph[Append[Range[0, 7], Infinity],
              {0 -> 1, 0 -> 1, 0 -> 2, 0 -> 2, 0 -> 3, 0 -> 3, 0 -> 4, 0 -> 5, 1 -> 4, 2 -> 5, 4 -> 6, 4 -> 7, 5 -> 6,
               5 -> 7, 3 -> Infinity}],
        SameTest -> sameGraphQ
      ],

      VerificationTest[
        WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                     Infinity,
                     "EventSelectionFunction" -> None]["ExpressionsEventsGraph"],
        Graph[
          Join[Thread[{"Event", Range[7]}], Thread[{"Expression", Range[9]}]],
          {{"Expression", 1} -> {"Event", 1}, {"Expression", 1} -> {"Event", 3}, {"Expression", 1} -> {"Event", 5},
           {"Expression", 2} -> {"Event", 1}, {"Expression", 2} -> {"Event", 2}, {"Expression", 3} -> {"Event", 2},
           {"Expression", 3} -> {"Event", 4}, {"Expression", 4} -> {"Event", 3}, {"Event", 1} -> {"Expression", 5},
           {"Event", 2} -> {"Expression", 6}, {"Event", 3} -> {"Expression", 7}, {"Expression", 5} -> {"Event", 4},
           {"Expression", 6} -> {"Event", 5}, {"Event", 4} -> {"Expression", 8}, {"Event", 5} -> {"Expression", 9},
           {"Expression", 8} -> {"Event", 6}, {"Expression", 8} -> {"Event", 7}, {"Expression", 9} -> {"Event", 6},
           {"Expression", 9} -> {"Event", 7}}],
        SameTest -> sameGraphQ
      ]
    }*)
