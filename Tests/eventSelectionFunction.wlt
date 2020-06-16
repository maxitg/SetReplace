<|
  "globalSpacelikeEvolution" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
    ),
    "tests" -> {
      (* Global spacelike is the default *)
      VerificationTest[
        Options[WolframModel, "EventSelectionFunction"],
        {"EventSelectionFunction" -> "GlobalSpacelike"}
      ],

      (* no multiway branching *)
      VerificationTest[
        WolframModel[{{{1}} -> {{1, 2}}, {{1}} -> {{1, 2, 3}}},
                     {{1}},
                     1,
                     "AllEventsEdgesList",
                     "EventSelectionFunction" -> "GlobalSpacelike"],
        {{1}, {1, 2}}
      ],

      (* no timelike matching *)
      VerificationTest[
        WolframModel[{{{1}} -> {{1, 2}}, {{1, 2}} -> {{1, 2, 3}}, {{1, 2}, {1, 3, 4}} -> {{1, 2, 3, 4}}},
                     {{1}},
                     Infinity,
                     "AllEventsEdgesList",
                     "EventSelectionFunction" -> "GlobalSpacelike"],
        {{1}, {1, 2}, {1, 2, 3}}
      ],

      (* spacelike matching *)
      VerificationTest[
        WolframModel[{{{1}} -> {{1, 2}, {1, 2, 3}}, {{1, 2}, {1, 2, 3}} -> {{1, 2, 3, 4}}},
                     {{1}},
                     Infinity,
                     "AllEventsEdgesList",
                     "EventSelectionFunction" -> "GlobalSpacelike"],
        {{1}, {1, 2}, {1, 2, 3}, {1, 2, 3, 4}}
      ],

      (* no duplicate matching *)
      VerificationTest[
        WolframModel[{{{1}} -> {{1, 2}}},
                     {{1}},
                     Infinity,
                     "AllEventsEdgesList",
                     "EventSelectionFunction" -> "GlobalSpacelike"],
        {{1}, {1, 2}}
      ],

      (* no matching invalid patterns *)
      VerificationTest[
        WolframModel[{{1, 2}, {2, 3}} -> {{1, 2, 3}},
                     {{1, 2}, {1, 3}},
                     Infinity,
                     "EventsCount",
                     "EventSelectionFunction" -> "GlobalSpacelike"],
        0
      ],

      (* spatial merging *)
      VerificationTest[
        WolframModel[{{{1}, {1, 2}} -> {{1, 2}, {2}}, {{1}, {1}} -> {{1, 1, 1}}},
                     {{a1}, {a1, a2}, {a2, a3}, {a3, m1}, {b1}, {b1, b2}, {b2, m1}, {m1, m2}},
                     Infinity,
                     "AllEventsEdgesList",
                     "EventSelectionFunction" -> "GlobalSpacelike"],
        {{a1}, {a1, a2}, {a2, a3}, {a3, m1}, {b1}, {b1, b2}, {b2, m1}, {m1, m2}, {a1, a2}, {a2}, {b1, b2}, {b2},
         {a2, a3}, {a3}, {b2, m1}, {m1}, {a3, m1}, {m1}, {m1, m2}, {m2}, {m1, m2}, {m2}, {m2, m2, m2}}
      ],

      (* no branchial merging *)
      VerificationTest[
        WolframModel[{{{1}, {1, 2}} -> {{1, 2}, {2}}, {{1}, {1}} -> {{1, 1, 1}}},
                     {{o1}, {o1, a1}, {o1, b1}, {a1, a2}, {a2, a3}, {a3, m1}, {b1, b2}, {b2, m1}, {m1, m2}},
                     Infinity,
                     "AllEventsEdgesList",
                     "EventSelectionFunction" -> "GlobalSpacelike"],
        {{o1}, {o1, a1}, {o1, b1}, {a1, a2}, {a2, a3}, {a3, m1}, {b1, b2}, {b2, m1}, {m1, m2}, {o1, a1}, {a1}, {a1, a2},
         {a2}, {a2, a3}, {a3}, {a3, m1}, {m1}, {m1, m2}, {m2}}
      ]
    }
  |>,
  "matchAllEvolution" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
    ),
    "tests" -> {
      testUnevaluated[
        WolframModel[{1 -> 2, 1 -> 3}, {1}, "EventSelectionFunction" -> None, Method -> #1],
        #2
      ] & @@@ {{Automatic, WolframModel::symbNotImplemented}, {"Symbolic", WolframModel::symbOrdering}},

      (* multiway branching *)
      VerificationTest[
        WolframModel[
          {{{1}} -> {{1, 2}}, {{1}} -> {{1, 2, 3}}}, {{1}}, 1, "AllEventsEdgesList", "EventSelectionFunction" -> None],
        {{1}, {1, 2}, {1, 3, 4}}
      ],

      (* branchlike matching *)
      VerificationTest[
        WolframModel[{{{1}} -> {{1, 2}}, {{1}} -> {{1, 2, 3}}, {{1, 2}, {1, 3, 4}} -> {{1, 2, 3, 4}}},
                     {{1}},
                     Infinity,
                     "AllEventsEdgesList",
                     "EventSelectionFunction" -> None],
        {{1}, {1, 2}, {1, 3, 4}, {1, 2, 3, 4}}
      ],

      (* timelike matching *)
      VerificationTest[
        WolframModel[{{{1}} -> {{1, 2}}, {{1, 2}} -> {{1, 2, 3}}, {{1, 2}, {1, 3, 4}} -> {{1, 2, 3, 4}}},
                     {{1}},
                     Infinity,
                     "AllEventsEdgesList",
                     "EventSelectionFunction" -> None],
        {{1}, {1, 2}, {1, 2, 3}, {1, 2, 2, 3}}
      ],

      (* spacelike matching *)
      VerificationTest[
        WolframModel[{{{1}} -> {{1, 2}, {1, 2, 3}}, {{1, 2}, {1, 2, 3}} -> {{1, 2, 3, 4}}},
                     {{1}},
                     Infinity,
                     "AllEventsEdgesList",
                     "EventSelectionFunction" -> None],
        {{1}, {1, 2}, {1, 2, 3}, {1, 2, 3, 4}}
      ],

      (* no duplicate matching *)
      VerificationTest[
        WolframModel[{{{1}} -> {{1, 2}}}, {{1}}, Infinity, "AllEventsEdgesList", "EventSelectionFunction" -> None],
        {{1}, {1, 2}}
      ],

      (* no matching invalid patterns *)
      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 2, 3}}, {{1, 2}, {1, 3}}, Infinity, "EventsCount", "EventSelectionFunction" -> None],
        0
      ],

      (* non-overlapping systems produce the same behavior *)
      Function[{rule, init},
        VerificationTest[
          WolframModel[rule, init, <|"MaxEvents" -> 100|>, "EventSelectionFunction" -> None],
          WolframModel[rule, init, <|"MaxEvents" -> 100|>, "EventSelectionFunction" -> "GlobalSpacelike"]
        ]
      ] @@@ {
        {{{1, 2}, {2, 3, 4}} -> {{2, 3}, {3, 4, 5}, {1, 2, 3, 4}}, {{1, 2}, {2, 3, 4}}},
        {{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, Automatic}
      },

      (* mixed spacelike/branchlike edge matching *)
      VerificationTest[
        WolframModel[<|"PatternRules" -> {{{v, i}} -> {{v, 1}, {v, 2}},
                                          {{v, 1}} -> {{v, 1, 1}, {v, 1, 2}},
                                          {{v, 1, 1}, {v, 2}} -> {{v, f, 1}},
                                          {{v, 1, 2}, {v, 2}} -> {{v, f, 2}},
                                          {{v, f, 1}, {v, f, 2}} -> {{f}}}|>,
                     {{v, i}},
                     Infinity,
                     "AllEventsEdgesList",
                     "EventSelectionFunction" -> None],
        {{v, i}, {v, 1}, {v, 2}, {v, 1, 1}, {v, 1, 2}, {v, f, 1}, {v, f, 2}, {f}}
      ],

      (* spatial merging *)
      VerificationTest[
        WolframModel[{{{1}, {1, 2}} -> {{2}}, {{1}, {1}} -> {{1, 1, 1}}},
                     {{a1}, {a1, a2}, {a2, a3}, {a3, m1}, {b1}, {b1, b2}, {b2, m1}, {m1, m2}},
                     Infinity,
                     "AllEventsEdgesList",
                     "EventSelectionFunction" -> None],
        {{a1}, {a1, a2}, {a2, a3}, {a3, m1}, {b1}, {b1, b2}, {b2, m1}, {m1, m2}, {a2}, {b2}, {a3}, {m1}, {m1}, {m2},
         {m2}, {m1, m1, m1}, {m1, m1, m1}, {m2, m2, m2}, {m2, m2, m2}}
      ],

      (* branchial merging *)
      VerificationTest[
        WolframModel[{{{1}, {1, 2}} -> {{2}}, {{1}, {1}} -> {{1, 1, 1}}},
                     {{o1}, {o1, a1}, {o1, b1}, {a1, a2}, {a2, a3}, {a3, m1}, {b1, b2}, {b2, m1}, {m1, m2}},
                     Infinity,
                     "AllEventsEdgesList",
                     "EventSelectionFunction" -> None],
        {{o1}, {o1, a1}, {o1, b1}, {a1, a2}, {a2, a3}, {a3, m1}, {b1, b2}, {b2, m1}, {m1, m2}, {a1}, {b1}, {a2}, {b2},
         {a3}, {m1}, {m1}, {m2}, {m2}, {m1, m1, m1}, {m1, m1, m1}, {m2, m2, m2}, {m2, m2, m2}}
      ]
    }
  |>
|>
