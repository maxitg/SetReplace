<|
  "WolframModelEvolutionObject" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];

      sameGraphQ[g1_, g2_] := And @@ (SameQ @@ Sort /@ # /@ {g1, g2} & /@ {VertexList, EdgeList});

      $largeEvolution = Hold[WolframModel[
        {{0, 1}, {0, 2}, {0, 3}} ->
          {{4, 5}, {5, 6}, {6, 4}, {4, 6}, {6, 5}, {5, 4},
          {4, 1}, {5, 2}, {6, 3},
          {1, 6}, {3, 4}},
        {{0, 0}, {0, 0}, {0, 0}},
        7]];
    ),
    "tests" -> With[{pathGraph17 = Partition[Range[17], 2, 1]}, {
      (* Symbol Leak *)

      testSymbolLeak[
        WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 5] /@ $WolframModelProperties
      ],

      (** Argument checks **)

      (** Leaking internal symbols when implicit "Generations" is called with more than 1 argument (#160)  **)

      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}][1, 2],
        WolframModelEvolutionObject[___][1, 2],
        {WolframModelEvolutionObject::invalidNargs},
        SameTest -> MatchQ
      ],

      (* Corrupt object *)

      testUnevaluated[
        WolframModelEvolutionObject[],
        {WolframModelEvolutionObject::argx}
      ],

      testUnevaluated[
        WolframModelEvolutionObject[<||>],
        {WolframModelEvolutionObject::corrupt}
      ],

      testUnevaluated[
        WolframModelEvolutionObject[<|a -> 1, b -> 2|>],
        {WolframModelEvolutionObject::corrupt}
      ],

      (* Incorrect property arguments *)

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4][],
        WolframModelEvolutionObject[___][],
        {WolframModelEvolutionObject::argm},
        SameTest -> MatchQ
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["$opt$" -> 3],
        WolframModelEvolutionObject[___]["$opt$" -> 3],
        {WolframModelEvolutionObject::unknownProperty},
        SameTest -> MatchQ
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["$$$UnknownProperty$$$,,,"],
        WolframModelEvolutionObject[___]["$$$UnknownProperty$$$,,,"],
        {WolframModelEvolutionObject::unknownProperty},
        SameTest -> MatchQ
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["TotalGenerationsCount", 3],
        WolframModelEvolutionObject[___]["TotalGenerationsCount", 3],
        {WolframModelEvolutionObject::pargx},
        SameTest -> MatchQ
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["TotalGenerationsCount", 3, 3],
        WolframModelEvolutionObject[___]["TotalGenerationsCount", 3, 3],
        {WolframModelEvolutionObject::pargx},
        SameTest -> MatchQ
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["Generation", 3, 3],
        WolframModelEvolutionObject[___]["Generation", 3, 3],
        {WolframModelEvolutionObject::pargx},
        SameTest -> MatchQ
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["Generation"],
        WolframModelEvolutionObject[___]["Generation"],
        {WolframModelEvolutionObject::pargx},
        SameTest -> MatchQ
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["SetAfterEvent"],
        WolframModelEvolutionObject[___]["SetAfterEvent"],
        {WolframModelEvolutionObject::pargx},
        SameTest -> MatchQ
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4][##2],
        WolframModelEvolutionObject[___][##2],
        {MessageName[WolframModelEvolutionObject, #]},
        SameTest -> MatchQ
      ] & @@@ {
        {"pargx", "FinalState", {}, {}},
        {"pargx", "FinalState", {{}, {}}},
        {"nonopt", "CausalGraph", {}},
        {"nonopt", "CausalGraph", {}, {}},
        {"nonopt", "CausalGraph", {{}, {}}},
        {"nonopt", "CausalGraph", {}, EdgeStyle -> Red},
        {"nonopt", "CausalGraph", {}, {EdgeStyle -> Red}},
        {"nonopt", "CausalGraph", {EdgeStyle -> Red}, {}},
        {"nonopt", "CausalGraph", EdgeStyle -> Red, {}},
        {"nonopt", "CausalGraph", {}, EdgeStyle -> Red, {}},
        {"unknownProperty", "$opt$" -> 3},
        {"unknownProperty", "$opt$" -> 3, {}}
      },

      VerificationTest[
        GraphQ[WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 3]["CausalGraph", {{}, EdgeStyle -> Red}]]
      ],

      (* Check options are being picked up even if they are in a list *)
      VerificationTest[
        VertexList[WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 2][
          "CausalGraph", {{"IncludeBoundaryEvents" -> "Initial"}, EdgeStyle -> Red}]],
        Range[0, 4]
      ],

      (* Incorrect step arguments *)

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["SetAfterEvent", 16],
        WolframModelEvolutionObject[___]["SetAfterEvent", 16],
        {WolframModelEvolutionObject::parameterTooLarge},
        SameTest -> MatchQ
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["SetAfterEvent", -17],
        WolframModelEvolutionObject[___]["SetAfterEvent", -17],
        {WolframModelEvolutionObject::parameterTooLarge},
        SameTest -> MatchQ
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["SetAfterEvent", 1.2],
        WolframModelEvolutionObject[___]["SetAfterEvent", 1.2],
        {WolframModelEvolutionObject::parameterNotInteger},
        SameTest -> MatchQ
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["SetAfterEvent", "good"],
        WolframModelEvolutionObject[___]["SetAfterEvent", "good"],
        {WolframModelEvolutionObject::parameterNotInteger},
        SameTest -> MatchQ
      ],

      (* Incorrect generation arguments *)

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["Generation", 5],
        WolframModelEvolutionObject[___]["Generation", 5],
        {WolframModelEvolutionObject::parameterTooLarge},
        SameTest -> MatchQ
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["Generation", -6],
        WolframModelEvolutionObject[___]["Generation", -6],
        {WolframModelEvolutionObject::parameterTooLarge},
        SameTest -> MatchQ
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["Generation", 2.3],
        WolframModelEvolutionObject[___]["Generation", 2.3],
        {WolframModelEvolutionObject::parameterNotInteger},
        SameTest -> MatchQ
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["GenerationEdgeIndices", 5],
        WolframModelEvolutionObject[___]["GenerationEdgeIndices", 5],
        {WolframModelEvolutionObject::parameterTooLarge},
        SameTest -> MatchQ
      ],

      (* IncludeBoundaryEvents *)

      With[{evo = WolframModel[{{1, 2}} -> {{1, 2}}, {{1, 1}}, 1]},
        testUnevaluated[
          evo["EventsCount", "IncludeBoundaryEvents" -> $$$invalid$$$],
          {WolframModelEvolutionObject::invalidFiniteOption}
        ]
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {{1, 2}},
          {{1, 1}},
          1]["TotalGenerationsCount", "IncludeBoundaryEvents" -> #],
        1
      ] & /@ {None, "Initial", "Final", All},

      (** Boxes **)

      VerificationTest[
        Head @ ToBoxes @ WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4],
        InterpretationBox
      ],

      (** Implementation of properties **)

      (* Properties *)

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["Properties"],
        _List,
        SameTest -> MatchQ
      ],

      (* EvolutionObject *)

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["EvolutionObject"],
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]
      ],

      (* Version *)

      (* Will need to be updated with each new version. *)
      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, 1, Method -> #]["Version"],
        2
      ] & /@ {"LowLevel", "Symbolic"},

      (* Rules *)

      VerificationTest[
        WolframModel[
          <|"PatternRules" -> {{a_, b_}, {b_, c_}} :> {{a, c}}|>,
          pathGraph17,
          4]["Rules"],
        <|"PatternRules" -> {{a_, b_}, {b_, c_}} :> {{a, c}}|>
      ],

      VerificationTest[
        WolframModel[
          {{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}} -> {{1, 3}, {3, 2}}},
          pathGraph17,
          4]["Rules"],
        {{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}} -> {{1, 3}, {3, 2}}}
      ],

      VerificationTest[
        WolframModel[1 -> 2, {1}, 4]["Rules"],
        1 -> 2
      ],

      (* TotalGenerationsCount *)

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["TotalGenerationsCount"],
        4
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {},
          {{1, 2}, {2, 3}},
          2]["TotalGenerationsCount"],
        1
      ],

      VerificationTest[
        WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                     Infinity,
                     "EventSelectionFunction" -> None]["TotalGenerationsCount"],
        3
      ],

      (* PartialGenerationsCount *)

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {{1, 3}, {3, 2}},
          {{1, 1}},
          <|"MaxEvents" -> 30|>]["PartialGenerationsCount"],
        1
      ],

      VerificationTest[
        WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                     <|"MaxEvents" -> 6|>,
                     "EventSelectionFunction" -> None]["PartialGenerationsCount"],
        1
      ],

      (* CompleteGenerationsCount *)

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {{1, 3}, {3, 2}},
          {{1, 1}},
          <|"MaxEvents" -> 30|>][#],
        4
      ] & /@ {"CompleteGenerationsCount", "MaxCompleteGeneration"},

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {{1, 3}, {3, 2}},
          {{1, 1}},
          <|"MaxEvents" -> 30|>][
          "CompleteGenerationsCount"],
        4
      ],

      VerificationTest[
        WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                     <|"MaxEvents" -> 6|>,
                     "EventSelectionFunction" -> None]["CompleteGenerationsCount"],
        2
      ],

      (* GenerationsCount *)

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {{1, 3}, {3, 2}},
          {{1, 1}},
          <|"MaxEvents" -> 30|>]["GenerationsCount"],
        {4, 1}
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {{1, 3}, {3, 2}},
          {{1, 1}},
          0]["GenerationsCount"],
        {0, 0}
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {{1, 3}, {3, 2}},
          {{1, 1}, {1, 1}},
          <|"MaxEvents" -> #|>]["GenerationsCount"] & /@ {1, 2},
        {{0, 1}, {1, 0}}
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {{1, 3}, {3, 2}},
          {{1, 1}},
          <|"MaxEvents" -> 30|>][
          "GenerationsCount"],
        {4, 1}
      ],

      VerificationTest[
        WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                     <|"MaxEvents" -> 6|>,
                     "EventSelectionFunction" -> None]["GenerationsCount"],
        {2, 1}
      ],

      (* GenerationComplete *)

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {{1, 3}, {3, 2}},
          {{1, 1}},
          <|"MaxEvents" -> 30|>]["GenerationComplete"],
        False
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {{1, 3}, {3, 2}},
          {{1, 1}},
          4]["GenerationComplete"],
        True
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {{1, 3}, {3, 2}},
          {{1, 1}},
          <|"MaxEvents" -> 30|>]["GenerationComplete", #] & /@ {-6, -5, -1, 0, 1, 4, 5, 10},
        {True, True, False, True, True, True, False, False}
      ],

      With[{evo = WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, <|"MaxEvents" -> 30|>]}, testUnevaluated[
        evo["GenerationComplete", #],
        {WolframModelEvolutionObject::parameterTooLarge}
      ] & /@ {-10, -7}],

      VerificationTest[
        WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                     <|"MaxEvents" -> 6|>,
                     "EventSelectionFunction" -> None]["GenerationComplete", #] & /@ {0, 1, 2, 3},
        {True, True, True, False}
      ],

      (* EventsCount *)

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4][#],
        15
      ] & /@ {"EventsCount", "AllEventsCount"},

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["EventsCount", "IncludeBoundaryEvents" -> #],
        #2
      ] & @@@ {{"Initial", 16}, {"Final", 16}, {All, 17}},

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {{1, 2}},
          {{1, 1}},
          0]["EventsCount", "IncludeBoundaryEvents" -> #],
        #2
      ] & @@@ {{None, 0}, {"Initial", 1}, {"Final", 1}, {All, 2}},

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {},
          {{1, 2}, {2, 3}},
          2]["EventsCount"],
        2
      ],

      VerificationTest[
        WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                     Infinity,
                     "EventSelectionFunction" -> None]["EventsCount", "IncludeBoundaryEvents" -> #],
        #2
      ] & @@@ {{None, 7}, {"Initial", 8}, {"Final", 8}, {All, 9}},

      (* GenerationEventsCountList *)

      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 4]["GenerationEventsCountList"],
        {1, 3, 9, 27}
      ],

      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 0]["GenerationEventsCountList"],
        {}
      ],

      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 4][
          "GenerationEventsCountList", "IncludeBoundaryEvents" -> #] & /@ {None, "Initial", "Final", All},
        {{1, 3, 9, 27}, {1, 1, 3, 9, 27}, {1, 3, 9, 27, 1}, {1, 1, 3, 9, 27, 1}}
      ],

      VerificationTest[
        WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                     Infinity,
                     "EventSelectionFunction" -> None]["GenerationEventsCountList", "IncludeBoundaryEvents" -> #],
        #2
      ] & @@@ {{None, {3, 2, 2}}, {"Initial", {1, 3, 2, 2}}, {"Final", {3, 2, 2, 1}}, {All, {1, 3, 2, 2, 1}}},

      (* GenerationEventsList *)

      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 2]["GenerationEventsList"],
        {{{1, {1} -> {2, 3, 4}}}, {{1, {2} -> {5, 6, 7}}, {1, {3} -> {8, 9, 10}}, {1, {4} -> {11, 12, 13}}}}
      ],

      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 0]["GenerationEventsList"],
        {}
      ],

      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 2][
          "GenerationEventsList", "IncludeBoundaryEvents" -> All],
        {
          {{0, {} -> {1}}},
          {{1, {1} -> {2, 3, 4}}},
          {{1, {2} -> {5, 6, 7}}, {1, {3} -> {8, 9, 10}}, {1, {4} -> {11, 12, 13}}},
          {{DirectedInfinity[1], {5, 6, 7, 8, 9, 10, 11, 12, 13} -> {}}}
        }
      ],

      VerificationTest[
        WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                     Infinity,
                     "EventSelectionFunction" -> None]["GenerationEventsList"],
        {{{1, {1, 2} -> {5}}, {1, {2, 3} -> {6}}, {1, {1, 4} -> {7}}},
         {{1, {5, 3} -> {8}}, {1, {1, 6} -> {9}}},
         {{2, {8, 9} -> {}}, {2, {9, 8} -> {}}}}
      ],

      VerificationTest[
        WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                     Infinity,
                     "EventSelectionFunction" -> None]["GenerationEventsList", "IncludeBoundaryEvents" -> All],
        {{{0, {} -> {1, 2, 3, 4}}},
         {{1, {1, 2} -> {5}}, {1, {2, 3} -> {6}}, {1, {1, 4} -> {7}}},
         {{1, {5, 3} -> {8}}, {1, {1, 6} -> {9}}},
         {{2, {8, 9} -> {}}, {2, {9, 8} -> {}}},
         {{Infinity, {7} -> {}}}}
      ],

      (* VertexCountList *)

      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 4]["VertexCountList"],
        {1, 2, 5, 14, 41}
      ],

      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 0]["VertexCountList"],
        {1}
      ],

      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{f[1, x, y], f[1, x, y]}}, 4]["VertexCountList"],
        {1, 2, 5, 14, 41}
      ],

      With[{evolution = WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                                     Infinity,
                                     "EventSelectionFunction" -> None]},
        testUnevaluated[
          evolution["VertexCountList"],
          {WolframModelEvolutionObject::multiwayState}
        ]
      ],

      (* EdgeCountList *)

      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 4]["EdgeCountList"],
        {1, 3, 9, 27, 81}
      ],

      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 0]["EdgeCountList"],
        {1}
      ],

      With[{evolution = WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                                     Infinity,
                                     "EventSelectionFunction" -> None]},
        testUnevaluated[
          evolution["EdgeCountList"],
          {WolframModelEvolutionObject::multiwayState}
        ]
      ],

      (* SetAfterEvent *)

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["SetAfterEvent", 0],
        pathGraph17
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4][#, 1],
        Join[Partition[Range[3, 17], 2, 1], {{1, 3}}]
      ] & /@ {"SetAfterEvent", "StateAfterEvent"},

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["SetAfterEvent", 2],
        Join[Partition[Range[5, 17], 2, 1], {{1, 3}, {3, 5}}]
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["SetAfterEvent", 14],
        {{1, 9}, {9, 17}}
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["SetAfterEvent", -2],
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["SetAfterEvent", 14]
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["SetAfterEvent", 15],
        {{1, 17}}
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["SetAfterEvent", -1],
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["SetAfterEvent", 15]
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {},
          {{1, 2}, {2, 3}},
          2]["SetAfterEvent", #],
        #2
      ] & @@@ {{0, {{1, 2}, {2, 3}}}, {1, {{2, 3}}}, {2, {}}},

      VerificationTest[
        WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                     Infinity,
                     "EventSelectionFunction" -> None]["SetAfterEvent", #] & /@ {0, 1},
        {{{1, 2}, {2, 3}, {3, 4}, {2, 5}}, {{3, 4}, {2, 5}, {1, 3}}}
      ],

      With[{evolution = WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                                     Infinity,
                                     "EventSelectionFunction" -> None]},
        testUnevaluated[
          evolution["SetAfterEvent", #],
          {WolframModelEvolutionObject::multiwayState}
        ]
      ] & /@ {2, 3, 4, 5, 6, 7},

      (* FinalState *)

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["FinalState"],
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["SetAfterEvent", -1]
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          0]["FinalState"],
        pathGraph17
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {},
          {{1, 2}, {2, 3}},
          2]["FinalState"],
        {}
      ],

      With[{evolution = WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                                     Infinity,
                                     "EventSelectionFunction" -> None]},
        testUnevaluated[
          evolution["FinalState"],
          {WolframModelEvolutionObject::multiwayState}
        ]
      ],

      (* UpdatedStatesList *)

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["UpdatedStatesList"],
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["SetAfterEvent", #] & /@ Range[0, 15]
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          0]["UpdatedStatesList"],
        {pathGraph17}
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {},
          {{1, 2}, {2, 3}},
          2][#],
        {{{1, 2}, {2, 3}}, {{2, 3}}, {}}
      ] & /@ {"UpdatedStatesList", "AllEventsStatesList"},

      With[{evolution = WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                                     Infinity,
                                     "EventSelectionFunction" -> None]},
        testUnevaluated[
          evolution["UpdatedStatesList"],
          {WolframModelEvolutionObject::multiwayState}
        ]
      ],

      (* AllEventsStatesEdgeIndicesList *)

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["AllEventsStatesEdgeIndicesList"],
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["StateEdgeIndicesAfterEvent", #] & /@ Range[0, 15]
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          0]["AllEventsStatesEdgeIndicesList"],
        {Range[Length[pathGraph17]]}
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {},
          {{1, 2}, {2, 3}},
          2]["AllEventsStatesEdgeIndicesList"],
        {{1, 2}, {2}, {}}
      ],

      With[{evolution = WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                                     Infinity,
                                     "EventSelectionFunction" -> None]},
        testUnevaluated[
          evolution["AllEventsStatesEdgeIndicesList"],
          {WolframModelEvolutionObject::multiwayState}
        ]
      ],

      (* Generation *)

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["Generation", 0],
        pathGraph17
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["Generation", 1],
        Partition[Range[1, 17, 2], 2, 1]
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["Generation", 2],
        Partition[Range[1, 17, 4], 2, 1]
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["Generation", 3],
        {{1, 9}, {9, 17}}
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["Generation", -2],
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["Generation", 3]
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["Generation", 4],
        {{1, 17}}
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["Generation", -1],
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["Generation", 4]
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {},
          {{1, 2}, {2, 3}},
          2]["Generation", #],
        #2
      ] & @@@ {{0, {{1, 2}, {2, 3}}}, {1, {}}},

      VerificationTest[
        WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                     Infinity,
                     "EventSelectionFunction" -> None][#1, 0],
        #2
      ] & @@@ {{"Generation", {{1, 2}, {2, 3}, {3, 4}, {2, 5}}}, {"GenerationEdgeIndices", Range[4]}},

      With[{evolution = WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                                     Infinity,
                                     "EventSelectionFunction" -> None]},
        testUnevaluated[
          evolution[#1, #2],
          {WolframModelEvolutionObject::multiwayState}
        ]
      ] & @@@ Tuples[{{"Generation", "GenerationEdgeIndices"}, {1, 2, 3}}],

      (* GenerationEdgeIndices *)

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["GenerationEdgeIndices", 0],
        Range[Length[pathGraph17]]
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["GenerationEdgeIndices", 1],
        Range[Length[pathGraph17] + 1, Length[pathGraph17] + Length[pathGraph17] / 2]
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["GenerationEdgeIndices", 3],
        {29, 30}
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["GenerationEdgeIndices", -2],
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["GenerationEdgeIndices", 3]
      ],

      (* StatesList *)

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["StatesList"],
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["Generation", #] & /@ Range[0, 4]
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          0]["StatesList"],
        {pathGraph17}
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {},
          {{1, 2}, {2, 3}},
          2]["StatesList"],
        {{{1, 2}, {2, 3}}, {}}
      ],

      With[{evolution = WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                                     Infinity,
                                     "EventSelectionFunction" -> None]},
        testUnevaluated[
          evolution["StatesList"],
          {WolframModelEvolutionObject::multiwayState}
        ]
      ],

      (* AtomsCountFinal *)

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4][#],
        2
      ] & /@ {"AtomsCountFinal", "FinalDistinctElementsCount"},

      VerificationTest[
        WolframModel[
          1 -> 2,
          {1},
          5]["AtomsCountFinal"],
        1
      ],

      VerificationTest[
        WolframModel[
          1 -> 1,
          {1},
          5]["AtomsCountFinal"],
        1
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {},
          {{1, 2}, {2, 3}},
          2]["AtomsCountFinal"],
        0
      ],

      With[{evolution = WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                                     Infinity,
                                     "EventSelectionFunction" -> None]},
        testUnevaluated[
          evolution["AtomsCountFinal"],
          {WolframModelEvolutionObject::multiwayState}
        ]
      ],

      (* AtomsCountTotal *)

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4][#],
        17
      ] & /@ {"AtomsCountTotal", "AllEventsDistinctElementsCount"},

      VerificationTest[
        WolframModel[
          1 -> 2,
          {1},
          5]["AtomsCountTotal"],
        6
      ],

      VerificationTest[
        WolframModel[
          1 -> 1,
          {1},
          5]["AtomsCountTotal"],
        1
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {},
          {{1, 2}, {2, 3}},
          2]["AtomsCountTotal"],
        3
      ],

      VerificationTest[
        WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                     Infinity,
                     "EventSelectionFunction" -> None]["AtomsCountTotal"],
        5
      ],

      (* ExpressionsCountFinal *)

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4][#],
        1
      ] & /@ {"ExpressionsCountFinal", "FinalEdgeCount"},

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {},
          {{1, 2}, {2, 3}},
          2]["ExpressionsCountFinal"],
        0
      ],

      With[{evolution = WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                                     Infinity,
                                     "EventSelectionFunction" -> None]},
        testUnevaluated[
          evolution["ExpressionsCountFinal"],
          {WolframModelEvolutionObject::multiwayState}
        ]
      ],

      (* ExpressionsCountTotal *)

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4][#],
        16 + 8 + 4 + 2 + 1
      ] & /@ {"ExpressionsCountTotal", "AllEventsEdgesCount"},

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {},
          {{1, 2}, {2, 3}},
          2]["ExpressionsCountTotal"],
        2
      ],

      VerificationTest[
        WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                     Infinity,
                     "EventSelectionFunction" -> None]["ExpressionsCountTotal"],
        9
      ],

      (* CreatorEvents *)

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4][#],
        Join[Table[0, 16], Range[15]]
      ] & /@ {"CreatorEvents", "EdgeCreatorEventIndices"},

      VerificationTest[
        WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                     Infinity,
                     "EventSelectionFunction" -> None]["CreatorEvents"],
        {0, 0, 0, 0, 1, 2, 3, 4, 5}
      ],

      (* DestroyerEvents *)

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4][#],
        Append[Riffle @@ ConstantArray[Range[15], 2], Infinity]
      ] & /@ {"DestroyerEvents", "EdgeDestroyerEventIndices"},

      With[{evolution = WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                                     Infinity,
                                     "EventSelectionFunction" -> None]},
        testUnevaluated[
          evolution["DestroyerEvents"],
          {WolframModelEvolutionObject::multiwayState}
        ]
      ],

      (* EdgeDestroyerEventsIndices, lists of destroyer events *)

      VerificationTest[
        WolframModel[{{1, 2}, {2, 3}} -> {{1, 3}}, pathGraph17, 4]["EdgeDestroyerEventsIndices"],
        Append[Riffle @@ ConstantArray[List /@ Range[15], 2], {}]
      ],

      VerificationTest[
        WolframModel[{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {2, 3}, {2, 4}}, 1, "EventSelectionFunction" -> None][
          "EdgeDestroyerEventsIndices"],
        {{1, 2}, {1}, {2}, {}, {}}
      ],

      VerificationTest[
        WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                     Infinity,
                     "EventSelectionFunction" -> None]["EdgeDestroyerEventsIndices"],
        {{1, 3, 5}, {1, 2}, {2, 4}, {3}, {4}, {5}, {}, {6, 7}, {6, 7}}
      ],

      (* ExpressionGenerations *)

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4][#],
        Catenate[Table[Table[k, 2^(4 - k)], {k, 0, 4}]]
      ] & /@ {"ExpressionGenerations", "EdgeGenerationsList"},

      VerificationTest[
        WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                     Infinity,
                     "EventSelectionFunction" -> None]["ExpressionGenerations"],
        {0, 0, 0, 0, 1, 1, 1, 2, 2}
      ],

      (* AllExpressions *)

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4][#],
        Catenate[Table[Partition[Range[1, 17, 2^k], 2, 1], {k, 0, 4}]]
      ] & /@ {"AllExpressions", "AllEventsEdgesList"},

      VerificationTest[
        WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                     Infinity,
                     "EventSelectionFunction" -> None]["AllExpressions"],
        {{1, 2}, {2, 3}, {3, 4}, {2, 5}, {1, 3}, {2, 4}, {1, 5}, {1, 4}, {1, 4}}
      ],

      (* EventGenerations *)

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4][#],
        {1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 4}
      ] & /@ {"EventGenerations", "EventGenerationsList", "AllEventsGenerationsList"},

      VerificationTest[
        WolframModel[
          {{1, 2}, {2, 3}} -> {{1, 3}},
          pathGraph17,
          4]["EventGenerations", "IncludeBoundaryEvents" -> #],
        #2
      ] & @@@ {
        {"Initial", {0, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 4}},
        {"Final", {1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 4, 5}},
        {All, {0, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 4, 5}}},

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {{1, 2}},
          {{1, 1}},
          0]["EventGenerations", "IncludeBoundaryEvents" -> #],
        #2
      ] & @@@ {{None, {}}, {"Initial", {0}}, {"Final", {1}}, {All, {0, 1}}},

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {},
          {{1, 2}, {2, 3}},
          2]["EventGenerations"],
        {1, 1}
      ],

      VerificationTest[
        WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                     Infinity,
                     "EventSelectionFunction" -> None]["EventGenerations", "IncludeBoundaryEvents" -> #],
        #2
      ] & @@@ {{None, {1, 1, 1, 2, 2, 3, 3}},
               {"Initial", {0, 1, 1, 1, 2, 2, 3, 3}},
               {"Final", {1, 1, 1, 2, 2, 3, 3, 4}},
               {All, {0, 1, 1, 1, 2, 2, 3, 3, 4}}},

      (* #258 *)
      VerificationTest[
        WolframModel[
          <|"PatternRules" ->
            {{{1, 2}} -> {{1, 4}}, {{1, 4}} -> {{1, 5}}, {{1, 3}} -> {{1, 6}}, {{1, 5}, {1, 6}} -> {}}|>,
          {{1, 2}, {1, 3}},
          Infinity,
          "AllEventsGenerationsList",
          "EventOrderingFunction" -> {"RuleIndex"}],
        {1, 2, 1, 3}
      ],

      (* CausalGraph *)

      Table[With[{type = type, largeEvolution = $largeEvolution}, {
        VerificationTest[
          WolframModel[
            {{1, 2}, {2, 3}} -> {{1, 3}},
            pathGraph17,
            4][type, 1],
          WolframModelEvolutionObject[___][type, 1],
          {WolframModelEvolutionObject::nonopt},
          SameTest -> MatchQ
        ],

        VerificationTest[
          WolframModel[
            {{1, 2}, {2, 3}} -> {{1, 3}},
            pathGraph17,
            4][type, 1, "str" -> 3],
          WolframModelEvolutionObject[___][type, 1, "str" -> 3],
          {WolframModelEvolutionObject::nonopt},
          SameTest -> MatchQ
        ],

        VerificationTest[
          WolframModel[
            {{1, 2}, {2, 3}} -> {{1, 3}},
            pathGraph17,
            4][type, "BadOpt" -> "NotExist"],
          WolframModelEvolutionObject[___][type, "BadOpt" -> "NotExist"],
          {WolframModelEvolutionObject::optx},
          SameTest -> MatchQ
        ],

        VerificationTest[
          AcyclicGraphQ[ReleaseHold[largeEvolution[type]]]
        ],

        VerificationTest[
          LoopFreeGraphQ[ReleaseHold[largeEvolution[type]]]
        ],

        VerificationTest[
          WolframModel[
            {{0, 1}, {0, 2}, {0, 3}} ->
              {{4, 5}, {5, 6}, {6, 4}, {4, 6}, {6, 5}, {5, 4},
              {4, 1}, {5, 2}, {6, 3},
              {1, 6}, {3, 4}},
            {{0, 0}, {0, 0}, {0, 0}},
            3,
            Method -> "Symbolic"][type],
          WolframModel[
            {{0, 1}, {0, 2}, {0, 3}} ->
              {{4, 5}, {5, 6}, {6, 4}, {4, 6}, {6, 5}, {5, 4},
              {4, 1}, {5, 2}, {6, 3},
              {1, 6}, {3, 4}},
            {{0, 0}, {0, 0}, {0, 0}},
            3,
            Method -> "LowLevel"][type]
        ],

        VerificationTest[
          FilterRules[AbsoluteOptions[WolframModel[
            {{1, 2}, {2, 3}} -> {{1, 3}},
            Partition[Range[17], 2, 1],
            2][type, VertexLabels -> "Name"]], VertexLabels],
          {VertexLabels -> {"Name"}}
        ],

        VerificationTest[
          Options[
            WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, 4][
              type, EdgeStyle -> Automatic, VertexStyle -> Automatic],
            {EdgeStyle, VertexStyle}],
          Options[
            WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, 4][type],
            {EdgeStyle, VertexStyle}]
        ],

        VerificationTest[
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
      }], {type, {"CausalGraph", "LayeredCausalGraph", "ExpressionsEventsGraph"}}],

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
      ],

      (* AllEventsList *)

      Table[With[{method = method}, {
        VerificationTest[
          WolframModel[{{{1}} -> {{1}}}, {{1}}, 4, Method -> method][#],
          {{1, {1} -> {2}}, {1, {2} -> {3}}, {1, {3} -> {4}}, {1, {4} -> {5}}}
        ] & /@ {"AllEventsList", "EventsList"},

        VerificationTest[
          WolframModel[{{{1}} -> {{1, 2}}, {{1, 2}} -> {{1}}}, {{1}}, 4, Method -> method]["AllEventsList"],
          {{1, {1} -> {2}}, {2, {2} -> {3}}, {1, {3} -> {4}}, {2, {4} -> {5}}}
        ],

        VerificationTest[
          WolframModel[{{{1, 2}} -> {{1}}, {{1}} -> {{1, 2}}}, {{1}}, 4, Method -> method]["AllEventsList"],
          {{2, {1} -> {2}}, {1, {2} -> {3}}, {2, {3} -> {4}}, {1, {4} -> {5}}}
        ],

        VerificationTest[
          WolframModel[{{{1, 2}} -> {{1}, {2}}, {{1}} -> {{1, 2}}}, {{1}}, 4, Method -> method]["AllEventsList"],
          {{2, {1} -> {2}}, {1, {2} -> {3, 4}}, {2, {3} -> {5}}, {2, {4} -> {6}}, {1, {5} -> {7, 8}},
           {1, {6} -> {9, 10}}}
        ],

        VerificationTest[
          WolframModel[{{{1, 2}} -> {}, {{1}} -> {{1, 2}}}, {{1}}, 4, Method -> method]["AllEventsList"],
          {{2, {1} -> {2}}, {1, {2} -> {}}}
        ],

        VerificationTest[
          WolframModel[{{{1, 2}} -> {{1}}, {{1}} -> {{1, 2}}}, {{1}}, 0, Method -> method]["AllEventsList"],
          {}
        ],

        VerificationTest[
          WolframModel[
            {{{1, 2}} -> {{1}}, {{1}} -> {{1, 2}}},
            {{1}},
            4,
            Method -> method][
            "AllEventsList",
            "IncludeBoundaryEvents" -> "Initial"],
          {{0, {} -> {1}}, {2, {1} -> {2}}, {1, {2} -> {3}}, {2, {3} -> {4}}, {1, {4} -> {5}}}
        ],

        VerificationTest[
          WolframModel[
            {{{1, 2}} -> {{1}}, {{1}} -> {{1, 2}}},
            {{1}},
            4,
            Method -> method][
            "AllEventsList",
            "IncludeBoundaryEvents" -> "Final"],
          {{2, {1} -> {2}}, {1, {2} -> {3}}, {2, {3} -> {4}}, {1, {4} -> {5}}, {\[Infinity], {5} -> {}}}
        ],

        VerificationTest[
          WolframModel[
            {{{1, 2}} -> {{1}}, {{1}} -> {{1, 2}}},
            {{1}},
            4,
            Method -> method][
            "AllEventsList",
            "IncludeBoundaryEvents" -> All],
          {{0, {} -> {1}}, {2, {1} -> {2}}, {1, {2} -> {3}}, {2, {3} -> {4}}, {1, {4} -> {5}}, {\[Infinity], {5} -> {}}}
        ]
      }], {method, DeleteCases[$SetReplaceMethods, Automatic]}],

      VerificationTest[
        WolframModel[{{{1, 2}} -> {{}}, {{}} -> {{1, 2}}}, {{}}, 4]["AllEventsList"],
        {{2, {1} -> {2}}, {1, {2} -> {3}}, {2, {3} -> {4}}, {1, {4} -> {5}}}
      ],

      (* #372, event inputs should be returned in the correct order *)
      VerificationTest[
        WolframModel[{{1, 2}, {2, 3, 4}} -> {{1, 2, 3, 4}}, {{2, 3, 4}, {1, 2}}, "EventsList"],
        {{1, {2, 1} -> {3}}}
      ],

      VerificationTest[
        WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                     Infinity,
                     "EventSelectionFunction" -> None]["AllEventsList"],
        {{1, {1, 2} -> {5}}, {1, {2, 3} -> {6}}, {1, {1, 4} -> {7}}, {1, {5, 3} -> {8}}, {1, {1, 6} -> {9}},
         {2, {8, 9} -> {}}, {2, {9, 8} -> {}}}
      ],

      VerificationTest[
        WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                     Infinity,
                     "EventSelectionFunction" -> None]["AllEventsList", "IncludeBoundaryEvents" -> All],
        {{0, {} -> {1, 2, 3, 4}}, {1, {1, 2} -> {5}}, {1, {2, 3} -> {6}}, {1, {1, 4} -> {7}}, {1, {5, 3} -> {8}},
         {1, {1, 6} -> {9}}, {2, {8, 9} -> {}}, {2, {9, 8} -> {}}, {Infinity, {7} -> {}}}
      ],

      (* EventsStatesList *)

      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, 2]["EventsStatesList"],
        {{{1, {1} -> {2, 3}}, {2, 3}}, {{1, {2} -> {4, 5}}, {3, 4, 5}}, {{1, {3} -> {6, 7}}, {4, 5, 6, 7}}}
      ],

      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, 2][
          "EventsStatesList", "IncludeBoundaryEvents" -> "Initial"],
        {
          {{0, {} -> {1}}, {1}},
          {{1, {1} -> {2, 3}}, {2, 3}},
          {{1, {2} -> {4, 5}}, {3, 4, 5}},
          {{1, {3} -> {6, 7}}, {4, 5, 6, 7}}
        }
      ],

      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, 2][
          "EventsStatesList", "IncludeBoundaryEvents" -> "Final"],
        {
          {{1, {1} -> {2, 3}}, {2, 3}},
          {{1, {2} -> {4, 5}}, {3, 4, 5}},
          {{1, {3} -> {6, 7}}, {4, 5, 6, 7}},
          {{DirectedInfinity[1], {4, 5, 6, 7} -> {}}, {}}
        }
      ],

      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, 2][
          "EventsStatesList", "IncludeBoundaryEvents" -> All],
        {
          {{0, {} -> {1}}, {1}},
          {{1, {1} -> {2, 3}}, {2, 3}},
          {{1, {2} -> {4, 5}}, {3, 4, 5}},
          {{1, {3} -> {6, 7}}, {4, 5, 6, 7}},
          {{DirectedInfinity[1], {4, 5, 6, 7} -> {}}, {}}
        }
      ],

      With[{evolution = WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                                     Infinity,
                                     "EventSelectionFunction" -> None]},
        testUnevaluated[
          evolution["EventsStatesList"],
          {WolframModelEvolutionObject::multiwayState}
        ]
      ],

      (* FeatureAssociation *)

      With[{evolutionObjects =
          WolframModel[{{x, y}, {x, z}} -> {{x, z}, {x, w}, {y, w}, {z, w}}, {{0, 0}, {0, 0}}, ##] & @@@
            {{0}, {3, "EventSelectionFunction" -> "MultiwaySpacelike"}, {3}, {8}}},
        VerificationTest[And @@ StringQ /@ Keys[#["FeatureAssociation"]]] & /@ evolutionObjects
      ],

      (* FeatureVector *)

      With[{evolutionObjects =
          WolframModel[{{x, y}, {x, z}} -> {{x, z}, {x, w}, {y, w}, {z, w}}, {{0, 0}, {0, 0}}, ##] & @@@
            {{0}, {3, "EventSelectionFunction" -> "MultiwaySpacelike"}, {3}, {8}}},
        VerificationTest[And @@ NumberQ /@ #["FeatureVector"]] & /@ evolutionObjects
      ],

      (* ExpressionsSeparation *)

      With[{
          mixedSeparationEvolution = WolframModel[
            <|"PatternRules" -> {
              {{v, i}} -> {{v, 1}, {v, 2}}, {{v, 1}} -> {{v, 1, 1}, {v, 1, 2}}, {{v, 1, 1}, {v, 2}} -> {{v, f, 1}},
              {{v, 1, 2}, {v, 2}} -> {{v, f, 2}}}|>,
            {{v, i}},
            Infinity,
            "EventSelectionFunction" -> None]}, {
        testUnevaluated[
          mixedSeparationEvolution["ExpressionsSeparation", #1, #2],
          {WolframModelEvolutionObject::parameterTooLarge}
        ] & @@@ {{-9, -9}, {-8, -9}, {8, -9}, {1, -8}, {1, 8}},

        testUnevaluated[
          mixedSeparationEvolution["ExpressionsSeparation", #1, #2],
          {WolframModelEvolutionObject::parameterTooSmall}
        ] & @@@ {{0, -9}, {1, 0}},

        testUnevaluated[
          mixedSeparationEvolution["ExpressionsSeparation", #1, #2],
          {WolframModelEvolutionObject::parameterNotInteger}
        ] & @@@ {{"s", 3}, {3, "s"}, {1.2, 3}, {I, 3}},

        VerificationTest[
          Table[mixedSeparationEvolution["ExpressionsSeparation", m, n], {m, 7}, {n, 7}],
          {{i, t, t, t, t, t, t},
           {t, i, s, t, t, t, t},
           {t, s, i, s, s, t, t},
           {t, t, s, i, s, t, s},
           {t, t, s, s, i, s, t},
           {t, t, t, t, s, i, b},
           {t, t, t, s, t, b, i}} /. {i -> "Identical", t -> "Timelike", s -> "Spacelike", b -> "Branchlike"}
        ],

        VerificationTest[
          Table[mixedSeparationEvolution["ExpressionsSeparation", m, n], {m, 7}, {n, 7}],
          Table[mixedSeparationEvolution["ExpressionsSeparation", m, n], {m, -7, -1}, {n, -7, -1}]
        ],

        VerificationTest[
          WolframModel[{{1, 2}} -> {{2, 3}, {3, 4}}, {{1, 2}}, 1]["ExpressionsSeparation", -2, -1],
          "Spacelike"
        ],

        VerificationTest[
          WolframModel[{{{1, 2}} -> {{2, 3}}, {{1, 2}} -> {{3, 4}}}, {{1, 2}}, 1, "EventSelectionFunction" -> None][
            "ExpressionsSeparation", -2, -1],
          "Branchlike"
        ],

        VerificationTest[
          WolframModel[{{{1, 2}} -> {{2, 3}}, {{1, 2}} -> {{3, 4}}}, {{1, 2}}, 2][
            "ExpressionsSeparation", -2, -1],
          "Timelike"
        ],

        VerificationTest[
          WolframModel[
            <|"PatternRules" -> {{{1, 2}} -> {{2, 3}}, {{1, 2}} -> {{3, 4}}, {{2, 3}, {3, 4}} -> {{4, 5}, {5, 6}}}|>,
            {{1, 2}},
            Infinity,
            "EventSelectionFunction" -> None]["ExpressionsSeparation", -2, -1],
          "Spacelike"
        ],

        (* MultiwayQ *)

        VerificationTest[
          WolframModel[{{1}} -> {{1}}, {{1}}, 0]["MultiwayQ"],
          False
        ],

        VerificationTest[
          WolframModel[{{1, 2}, {2, 3}} -> {{1, 2}, {2, 3}, {3, 4}}, {{1, 2}, {2, 3}, {3, 4}}, 1]["MultiwayQ"],
          False
        ],

        VerificationTest[
          WolframModel[{{1, 2}, {2, 3}} -> {{1, 2}, {2, 3}, {3, 4}},
                       {{1, 2}, {2, 3}, {3, 4}},
                       1,
                       "EventSelectionFunction" -> "MultiwaySpacelike"][
                       "MultiwayQ"],
          True
        ]
      }]
    }]
  |>,

  "WolframModelEvolutionObjectGraphics" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`checkGraphics[args___] := SetReplace`PackageScope`checkGraphics[args];
      Global`graphicsQ[args___] := SetReplace`PackageScope`graphicsQ[args];
    ),
    "tests" -> {
      (* FinalStatePlot *)

      VerificationTest[
        graphicsQ[WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 3]["FinalStatePlot"]]
      ],

      With[{evo = WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 3]}, testUnevaluated[
        evo["FinalStatePlot", "$$$invalid$$$"],
        {WolframModelEvolutionObject::nonopt}
      ]],

      With[{evo = WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 3]}, testUnevaluated[
        evo["FinalStatePlot", "$$$invalid$$$" -> 3],
        {WolframModelEvolutionObject::optx}
      ]],

      VerificationTest[
        AbsoluteOptions[
          checkGraphics @ WolframModel[
            {{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 3]["FinalStatePlot", ImageSize -> 123.],
          ImageSize],
        {ImageSize -> 123.}
      ],

      testUnevaluated[
        WolframModel[1 -> 2, {1}, 2, "FinalStatePlot"],
        {WolframModel::nonHypergraphPlot}
      ],

      With[{evo = WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, <|"MaxEvents" -> 30|>]}, testUnevaluated[
        evo["FinalStatePlot", VertexSize -> x],
        {HypergraphPlot::invalidSize}
      ]],

      With[{evolution = WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                                     Infinity,
                                     "EventSelectionFunction" -> None]},
        testUnevaluated[
          evolution["FinalStatePlot"],
          {WolframModelEvolutionObject::multiwayState}
        ]
      ],

      (* StatesPlotsList *)

      VerificationTest[
        graphicsQ /@ WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 3]["StatesPlotsList"],
        ConstantArray[True, 4]
      ],

      With[{evo = WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 3]}, testUnevaluated[
        evo["StatesPlotsList", "$$$invalid$$$"],
        {WolframModelEvolutionObject::nonopt}
      ]],

      With[{evo = WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 3]}, testUnevaluated[
        evo["StatesPlotsList", "$$$invalid$$$" -> 3],
        {WolframModelEvolutionObject::optx}
      ]],

      VerificationTest[
        AbsoluteOptions[#, ImageSize] & /@
          checkGraphics[WolframModel[
            {{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 3]["StatesPlotsList", ImageSize -> 123.]],
        ConstantArray[{ImageSize -> 123.}, 4]
      ],

      testUnevaluated[
        WolframModel[1 -> 2, {1}, 2, "StatesPlotsList"],
        {WolframModel::nonHypergraphPlot}
      ],

      With[{evo = WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, <|"MaxEvents" -> 30|>]}, testUnevaluated[
        evo["StatesPlotsList", VertexSize -> x],
        {HypergraphPlot::invalidSize}
      ]],

      With[{evolution = WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                                     Infinity,
                                     "EventSelectionFunction" -> None]},
        testUnevaluated[
          evolution["StatesPlotsList"],
          {WolframModelEvolutionObject::multiwayState}
        ]
      ],

      (* EventsStatesPlotsList *)

      VerificationTest[
        graphicsQ /@ WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 3]["EventsStatesPlotsList"],
        ConstantArray[True, WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 3, "EventsCount"] + 1]
      ],

      VerificationTest[
        graphicsQ /@ WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 3][
          "EventsStatesPlotsList", "IncludeBoundaryEvents" -> All],
        ConstantArray[True, WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 3, "EventsCount"] + 1]
      ],

      VerificationTest[
        graphicsQ /@ WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 0][
          "EventsStatesPlotsList", "IncludeBoundaryEvents" -> #],
        {True}
      ] & /@ {None, "Initial", "Final", All},

      With[{evo = WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 3]}, testUnevaluated[
        evo["EventsStatesPlotsList", "$$$invalid$$$"],
        {WolframModelEvolutionObject::nonopt}
      ]],

      With[{evo = WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 3]}, testUnevaluated[
        evo["EventsStatesPlotsList", "$$$invalid$$$" -> 3],
        {WolframModelEvolutionObject::optx}
      ]],

      VerificationTest[
        AbsoluteOptions[#, ImageSize] & /@
          checkGraphics @ WolframModel[
            {{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 1]["EventsStatesPlotsList", ImageSize -> 123.],
        ConstantArray[{ImageSize -> 123.}, 2]
      ],

      testUnevaluated[
        WolframModel[1 -> 2, {1}, 2, "EventsStatesPlotsList"],
        {WolframModel::nonHypergraphPlot}
      ],

      With[{evo = WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, <|"MaxEvents" -> 30|>]}, testUnevaluated[
        evo["EventsStatesPlotsList", VertexSize -> x],
        {HypergraphPlot::invalidSize}
      ]],

      VerificationTest[
        graphicsQ /@ WolframModel[{{1, 2}} -> {}, {{1, 2}}, Infinity, "EventsStatesPlotsList"],
        {True, True}
      ],

      VerificationTest[
        graphicsQ /@ WolframModel[{} -> {{1, 2}}, {}, <|"MaxEvents" -> 1|>, "EventsStatesPlotsList"],
        {True, True}
      ],

      With[{evolution = WolframModel[{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {1, 2}} -> {}},
                                     {{1, 2}, {2, 3}, {3, 4}, {2, 5}},
                                     Infinity,
                                     "EventSelectionFunction" -> None]},
        testUnevaluated[
          evolution["EventsStatesPlotsList"],
          {WolframModelEvolutionObject::multiwayState}
        ]
      ],

      (* CausalGraph *)

      VerificationTest[
        graphicsQ @ GraphPlot[WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, 4][#, Background -> Automatic]]
      ] & /@ {"CausalGraph", "LayeredCausalGraph", "ExpressionsEventsGraph"},

      VerificationTest[
        Options[
          checkGraphics @ GraphPlot[
            WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, 4][#, Background -> RGBColor[0.2, 0.5, 0.3]]],
          Background],
        {Background -> RGBColor[0.2, 0.5, 0.3]}
      ] & /@ {"CausalGraph", "LayeredCausalGraph", "ExpressionsEventsGraph"}
    },
    "options" -> {
      "Parallel" -> False
    }
  |>,
  "evolutionObjectMigration" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
    ),
    "tests" -> {
      (* v1 -> v2 *)
      VerificationTest[
        WolframModelEvolutionObject[<|"CreatorEvents" -> {0, 0, 0, 0, 1, 2, 3},
                                      "DestroyerEvents" -> {1, 1, 2, 2, 3, 3, Infinity},
                                      "Generations" -> {0, 0, 0, 0, 1, 1, 2},
                                      "AtomLists" -> {{1, 2}, {2, 3}, {3, 4}, {4, 5}, {1, 3}, {3, 5}, {1, 5}},
                                      "Rules" -> {{1, 2}, {2, 3}} -> {{1, 3}},
                                      "MaxCompleteGeneration" -> 2,
                                      "TerminationReason" -> "FixedPoint",
                                      "EventRuleIDs" -> {1, 1, 1}|>],
        WolframModelEvolutionObject[<|"Version" -> 2,
                                      "Rules" -> {{1, 2}, {2, 3}} -> {{1, 3}},
                                      "MaxCompleteGeneration" -> 2,
                                      "TerminationReason" -> "FixedPoint",
                                      "AtomLists" -> {{1, 2}, {2, 3}, {3, 4}, {4, 5}, {1, 3}, {3, 5}, {1, 5}},
                                      "EventRuleIDs" -> {0, 1, 1, 1},
                                      "EventInputs" -> {{}, {1, 2}, {3, 4}, {5, 6}},
                                      "EventOutputs" -> {{1, 2, 3, 4}, {5}, {6}, {7}},
                                      "EventGenerations" -> {0, 1, 1, 2}|>],
        {WolframModelEvolutionObject::migrationInputOrdering}
      ],

      (* reorder data in v1 *)
      VerificationTest[
        WolframModelEvolutionObject[<|"Rules" -> {{1, 2}, {2, 3}} -> {{1, 3}},
                                      "CreatorEvents" -> {0, 0, 0, 0, 1, 2, 3},
                                      "DestroyerEvents" -> {1, 1, 2, 2, 3, 3, Infinity},
                                      "Generations" -> {0, 0, 0, 0, 1, 1, 2},
                                      "AtomLists" -> {{1, 2}, {2, 3}, {3, 4}, {4, 5}, {1, 3}, {3, 5}, {1, 5}},
                                      "MaxCompleteGeneration" -> 2,
                                      "TerminationReason" -> "FixedPoint",
                                      "EventRuleIDs" -> {1, 1, 1}|>],
        WolframModelEvolutionObject[<|"Version" -> 2,
                                      "Rules" -> {{1, 2}, {2, 3}} -> {{1, 3}},
                                      "MaxCompleteGeneration" -> 2,
                                      "TerminationReason" -> "FixedPoint",
                                      "AtomLists" -> {{1, 2}, {2, 3}, {3, 4}, {4, 5}, {1, 3}, {3, 5}, {1, 5}},
                                      "EventRuleIDs" -> {0, 1, 1, 1},
                                      "EventInputs" -> {{}, {1, 2}, {3, 4}, {5, 6}},
                                      "EventOutputs" -> {{1, 2, 3, 4}, {5}, {6}, {7}},
                                      "EventGenerations" -> {0, 1, 1, 2}|>],
        {WolframModelEvolutionObject::migrationInputOrdering}
      ],

      (* missing keys *)
      testUnevaluated[
        WolframModelEvolutionObject[<|"Rules" -> {{1, 2}, {2, 3}} -> {{1, 3}},
                                      "CreatorEvents" -> {0, 0, 0, 0, 1, 2, 3},
                                      "DestroyerEvents" -> {1, 1, 2, 2, 3, 3, DirectedInfinity[1]},
                                      "Generations" -> {0, 0, 0, 0, 1, 1, 2},
                                      "AtomLists" -> {{1, 2}, {2, 3}, {3, 4}, {4, 5}, {1, 3}, {3, 5}, {1, 5}},
                                      "MaxCompleteGeneration" -> 2,
                                      "EventRuleIDs" -> {1, 1, 1}|>],
        {WolframModelEvolutionObject::corrupt}
      ],

      (* future version *)
      testUnevaluated[
        WolframModelEvolutionObject[<|"Version" -> 100|>],
        {WolframModelEvolutionObject::future}
      ]
    }
  |>
|>
