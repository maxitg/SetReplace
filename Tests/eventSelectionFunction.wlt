<|
  "eventSelectionFunction" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
    ),
    "tests" -> {
      (* Global spacelike is the default, many things will break if that is not the case *)
      VerificationTest[
        Options[WolframModel, "EventSelectionFunction"],
        {"EventSelectionFunction" -> "GlobalSpacelike"}
      ],

      (* Multiway system requires Method -> "LowLevel" *)
      Function[{selectionFunction}, testUnevaluated[
        WolframModel[{1 -> 2, 1 -> 3}, {1}, "EventSelectionFunction" -> selectionFunction, Method -> #1],
        #2
      ] & @@@ {{Automatic, WolframModel::symbNotImplemented}, {"Symbolic", WolframModel::symbOrdering}}] /@
        {None, "Spacelike"},

      (* multiway branching *)
      VerificationTest[
        WolframModel[{{{1}} -> {{1, 2}}, {{1}} -> {{1, 2, 3}}},
                     {{1}},
                     1,
                     "AllEventsEdgesList",
                     "EventSelectionFunction" -> #],
        {{1}, {1, 2}, ##2}
      ] & @@@ {{"GlobalSpacelike"}, {None, {1, 3, 4}}, {"Spacelike", {1, 3, 4}}},

      (* branchlike matching *)
      VerificationTest[
        WolframModel[{{{1}} -> {{1, 2}}, {{1}} -> {{1, 2, 3}}, {{1, 2}, {1, 3, 4}} -> {{1, 2, 3, 4}}},
                     {{1}},
                     Infinity,
                     "AllEventsEdgesList",
                     "EventSelectionFunction" -> #],
        {{1}, {1, 2}, {1, 3, 4}, ##2}
      ] & @@@ {{None, {1, 2, 3, 4}}, {"Spacelike"}},

      (* timelike matching *)
      VerificationTest[
        WolframModel[{{{1}} -> {{1, 2}}, {{1, 2}} -> {{1, 2, 3}}, {{1, 2}, {1, 3, 4}} -> {{1, 2, 3, 4}}},
                     {{1}},
                     Infinity,
                     "AllEventsEdgesList",
                     "EventSelectionFunction" -> #],
        {{1}, {1, 2}, {1, 2, 3}, ##2}
      ] & @@@ {{"GlobalSpacelike"}, {None, {1, 2, 2, 3}}, {"Spacelike"}},

      (* spacelike matching *)
      VerificationTest[
        WolframModel[{{{1}} -> {{1, 2}, {1, 2, 3}}, {{1, 2}, {1, 2, 3}} -> {{1, 2, 3, 4}}},
                     {{1}},
                     Infinity,
                     "AllEventsEdgesList",
                     "EventSelectionFunction" -> #],
        {{1}, {1, 2}, {1, 2, 3}, ##2}
      ] & @@@ {{"GlobalSpacelike", {1, 2, 3, 4}}, {None, {1, 2, 3, 4}}, {"Spacelike", {1, 2, 3, 4}}},

      (* duplicate matching *)
      VerificationTest[
        WolframModel[{{{1}} -> {{1, 2}}},
                     {{1}},
                     Infinity,
                     "AllEventsEdgesList",
                     "EventSelectionFunction" -> #],
        {{1}, {1, 2}, ##2}
      ] & @@@ {{"GlobalSpacelike"}, {None}, {"Spacelike"}},

      (* no matching invalid patterns *)
      VerificationTest[
        WolframModel[{{1, 2}, {2, 3}} -> {{1, 2, 3}},
                     {{1, 2}, {1, 3}},
                     Infinity,
                     "EventsCount",
                     "EventSelectionFunction" -> #],
        0
      ] & /@ {"GlobalSpacelike", None, "Spacelike"},

      (* non-overlapping systems produce the same behavior *)
      Function[{rule, init},
        VerificationTest[
          WolframModel[rule, init, <|"MaxEvents" -> 100|>, "EventSelectionFunction" -> #],
          WolframModel[rule, init, <|"MaxEvents" -> 100|>, "EventSelectionFunction" -> "GlobalSpacelike"]
        ]
      ] @@@ {
        {{{1, 2}, {2, 3, 4}} -> {{2, 3}, {3, 4, 5}, {1, 2, 3, 4}}, {{1, 2}, {2, 3, 4}}},
        {{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, Automatic}
      } & /@ {None, "Spacelike"},

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
                     "EventSelectionFunction" -> #],
        {{v, i}, {v, 1}, {v, 2}, {v, 1, 1}, {v, 1, 2}, {v, f, 1}, {v, f, 2}, ##2}
      ] & @@@ {{None, {f}}, {"Spacelike"}},

      (* singleway spatial merging *)
      VerificationTest[
        WolframModel[{{{1}, {1, 2}} -> {{1, 2}, {2}}, {{1}, {1}} -> {{1, 1, 1}}},
                     {{a1}, {a1, a2}, {a2, a3}, {a3, m1}, {b1}, {b1, b2}, {b2, m1}, {m1, m2}},
                     Infinity,
                     "AllEventsEdgesList",
                     "EventSelectionFunction" -> "GlobalSpacelike"],
        {{a1}, {a1, a2}, {a2, a3}, {a3, m1}, {b1}, {b1, b2}, {b2, m1}, {m1, m2}, {a1, a2}, {a2}, {b1, b2}, {b2},
         {a2, a3}, {a3}, {b2, m1}, {m1}, {a3, m1}, {m1}, {m1, m2}, {m2}, {m1, m2}, {m2}, {m2, m2, m2}}
      ],

      (* multiway spatial merging *)
      VerificationTest[
        WolframModel[{{{1}, {1, 2}} -> {{2}}, {{1}, {1}} -> {{1, 1, 1}}},
                     {{a1}, {a1, a2}, {a2, a3}, {a3, m1}, {b1}, {b1, b2}, {b2, m1}, {m1, m2}},
                     Infinity,
                     "AllEventsEdgesList",
                     "EventSelectionFunction" -> #],
        {{a1}, {a1, a2}, {a2, a3}, {a3, m1}, {b1}, {b1, b2}, {b2, m1}, {m1, m2}, {a2}, {b2}, {a3}, {m1}, {m1}, {m2},
         {m2}, ##2}
      ] & @@@ {
        {None, {m1, m1, m1}, {m1, m1, m1}, {m2, m2, m2}, {m2, m2, m2}}, {"Spacelike", {m1, m1, m1}, {m1, m1, m1}}},

      (* no singleway branchial merging *)
      VerificationTest[
        WolframModel[{{{1}, {1, 2}} -> {{1, 2}, {2}}, {{1}, {1}} -> {{1, 1, 1}}},
                     {{o1}, {o1, a1}, {o1, b1}, {a1, a2}, {a2, a3}, {a3, m1}, {b1, b2}, {b2, m1}, {m1, m2}},
                     Infinity,
                     "AllEventsEdgesList",
                     "EventSelectionFunction" -> "GlobalSpacelike"],
        {{o1}, {o1, a1}, {o1, b1}, {a1, a2}, {a2, a3}, {a3, m1}, {b1, b2}, {b2, m1}, {m1, m2}, {o1, a1}, {a1}, {a1, a2},
         {a2}, {a2, a3}, {a3}, {a3, m1}, {m1}, {m1, m2}, {m2}}
      ],

      (* multiway branchial merging *)
      VerificationTest[
        WolframModel[{{{1}, {1, 2}} -> {{2}}, {{1}, {1}} -> {{1, 1, 1}}},
                     {{o1}, {o1, a1}, {o1, b1}, {a1, a2}, {a2, a3}, {a3, m1}, {b1, b2}, {b2, m1}, {m1, m2}},
                     Infinity,
                     "AllEventsEdgesList",
                     "EventSelectionFunction" -> #],
        {{o1}, {o1, a1}, {o1, b1}, {a1, a2}, {a2, a3}, {a3, m1}, {b1, b2}, {b2, m1}, {m1, m2}, {a1}, {b1}, {a2}, {b2},
         {a3}, {m1}, {m1}, {m2}, {m2}, ##2}
      ] & @@@ {{None, {m1, m1, m1}, {m1, m1, m1}, {m2, m2, m2}, {m2, m2, m2}}, {"Spacelike"}}
    }
  |>
|>
