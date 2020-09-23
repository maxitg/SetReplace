<|
  "eventDeduplication" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
    ),
    "tests" -> {
      (* No deduplication is the default *)
      VerificationTest[
        Options[WolframModel, "EventDeduplication"],
        {"EventDeduplication" -> None}
      ],

      (* Deduplication requires Method -> "LowLevel" *)
      testUnevaluated[
        WolframModel[{1 -> 2, 1 -> 3}, {1}, "EventDeduplication" -> "SameInputSetIsomorphicOutputs", Method -> #1],
        #2
      ] & @@@ {{Automatic, WolframModel::symbNotImplemented}, {"Symbolic", WolframModel::symbOrdering}},

      (* Non-symmetric case *)
      VerificationTest[
        WolframModel[{{1, 2}, {1, 3}} -> {{2, 3}},
                     {{1, 2}, {1, 3}},
                     1,
                     "EventSelectionFunction" -> "MultiwaySpacelike",
                     "EventDeduplication" -> "SameInputSetIsomorphicOutputs"],
        WolframModel[{{1, 2}, {1, 3}} -> {{2, 3}}, {{1, 2}, {1, 3}}, 1, "EventSelectionFunction" -> "MultiwaySpacelike"]
      ],

      (* Symmetric case *)
      VerificationTest[
        WolframModel[{{1, 2}, {1, 3}} -> {{2, 3}, {3, 2}},
                     {{1, 2}, {1, 3}},
                     1,
                     "EventSelectionFunction" -> "MultiwaySpacelike",
                     "EventDeduplication" -> "SameInputSetIsomorphicOutputs"]["EventsList"],
        {{1, {1, 2} -> {3, 4}}}
      ],

      (* System that becomes non-overlapping *)
      VerificationTest[
        WolframModel[{{1, 2}, {2, 1}} -> {{1, 3}, {3, 1}, {3, 2}, {2, 3}},
                     {{1, 2}, {2, 1}},
                     3,
                     "EventSelectionFunction" -> "MultiwaySpacelike",
                     "EventDeduplication" -> #1]["EventsCount"],
        #2
      ] & @@@ {{None, 42}, {"SameInputSetIsomorphicOutputs", 7}},

      VerificationTest[
        WolframModel[{{1, 2}, {2, 1}} -> {{1, 3}, {3, 1}, {3, 2}, {2, 3}},
                     {{1, 2}, {2, 1}},
                     3,
                     "EventSelectionFunction" -> "MultiwaySpacelike",
                     "EventDeduplication" -> "SameInputSetIsomorphicOutputs"]["FinalState"],
        {{1, 6}, {6, 1}, {6, 4}, {4, 6}, {4, 7}, {7, 4}, {7, 3}, {3, 7}, {3, 8}, {8, 3}, {8, 5}, {5, 8}, {5, 9}, {9, 5},
         {9, 2}, {2, 9}}
      ],

      (* Neat examples *)
      VerificationTest[
        WolframModel[{{x, y}, {x, z}} -> {{x, y}, {x, w}, {y, w}, {z, w}},
                     {{0, 0}, {0, 0}},
                     3,
                     "EventSelectionFunction" -> "MultiwaySpacelike",
                     "EventDeduplication" -> None]["EventsCount"] >
        WolframModel[{{x, y}, {x, z}} -> {{x, y}, {x, w}, {y, w}, {z, w}},
                     {{0, 0}, {0, 0}},
                     3,
                     "EventSelectionFunction" -> "MultiwaySpacelike",
                     "EventDeduplication" -> "SameInputSetIsomorphicOutputs"]["EventsCount"]
      ],

      (* Tests for correct isomorphism *)
      VerificationTest[
        WolframModel[#1,
                     #2,
                     #3,
                     "EventSelectionFunction" -> "MultiwaySpacelike",
                     "EventDeduplication" -> "SameInputSetIsomorphicOutputs"]["EventsCount"],
        #4
      ] & @@@ {
        (* Symmetric case *)
        {{{1, 2}, {1, 3}} -> {{2, 3}, {3, 2}}, {{1, 2}, {1, 3}}, 1, 1},
        (* Nontrivial isomorphism *)
        {{{1, 2}, {1, 3}} -> {{2, 4}, {4, 5}, {5, 3}, {3, 6}, {6, 2}}, {{1, 2}, {1, 3}}, 1, 2},
        {{{1, 2}, {1, 3}} -> {{2, 4}, {4, 3}, {3, 5}, {5, 2}}, {{1, 2}, {1, 3}}, 1, 1},
        (* Different size subgraph-isomorphic outputs *)
        {{{{1}} -> {{1, 2}}, {{1}} -> {{1, 2}, {1, 2}}}, {{1}}, 1, 2},
        {{{{1}} -> {{1, 2}, {1, 2}}, {{1}} -> {{1, 2}}}, {{1}}, 1, 2},
        (* Empty output *)
        {{{1}, {1}} -> {}, {{1}, {1}}, 1, 1},
        {{{1}, {1}} -> {}, {{1}, {1}, {1}}, 1, 3},
        {{{{1}, {1}} -> {}, {{1}, {1}} -> {}}, {{1}, {1}, {1}}, 1, 3},
        {{{{1}, {1}} -> {}, {{1}, {1}, {1}} -> {}}, {{1}, {1}, {1}}, 1, 4},
        (* Neat examples *)
        {{{1}, {1}} -> {{1}, {1}}, {{1}, {1}, {1}}, 2, 12},
        {{{0, 1}, {0, 6}} -> {{1, 4}, {2, 3}, {2, 4}, {3, 4}, {3, 5}, {4, 5}, {6, 4}}, {{0, 1}, {0, 6}}, 1, 1},
        {{{0, 1}, {0, 6}} -> {{1, 4}, {2, 3}, {2, 4}, {3, 4}, {3, 5}, {4, 5}, {4, 6}}, {{0, 1}, {0, 6}}, 1, 2},
        (* Pattern rules *)
        {<|"PatternRules" -> {{0, a_}, {0, b_}} :> Module[{c, d}, {{a, c}, {b, d}}]|>, {{0, 1}, {0, 2}}, 1, 1},
        {<|"PatternRules" -> {{0, a_}, {0, b_}} :> {{a, 1}, {b, 2}}|>, {{0, 1}, {0, 2}}, 1, 2},
        {<|"PatternRules" -> {{0, a_}, {0, b_}} :> {{a, 3}, {b, 4}}|>, {{0, 1}, {0, 2}}, 1, 2},
        {<|"PatternRules" -> {{0, a_}, {0, b_}} :> Module[{c, d}, {{a, 1}, {b, 2}}]|>, {{0, 1}, {0, 2}}, 1, 2}
      },

      (* Correct weights in random evolution *)
      VerificationTest[
        Count[Table[First[WolframModel[{{{1}, {1}, {1}, {1}} -> {}, {{1}} -> {}},
                                       {{1}, {1}, {1}, {1}},
                                       <|"MaxEvents" -> 1|>,
                                       "EventOrderingFunction" -> {}]["AllEventsRuleIndices"]], 1000], 2] < 200
      ],

      VerificationTest[
        Count[Table[First[WolframModel[{{{1}, {1}, {1}, {1}} -> {}, {{1}} -> {}},
                                       {{1}, {1}, {1}, {1}},
                                       <|"MaxEvents" -> 1|>,
                                       "EventOrderingFunction" -> {},
                                       "EventDeduplication" -> "SameInputSetIsomorphicOutputs"][
                                        "AllEventsRuleIndices"]], 1000], 1] < 300
      ]
    }
  |>
|>
