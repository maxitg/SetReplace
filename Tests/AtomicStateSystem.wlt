<|
  "AtomicStateSystem" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];

      (* This will not be necessary once we have properties. *)
      allExpressions[Multihistory[_, data_]] := Normal @ data["MultisetMultihistory"][[2]]["Expressions"];
    ),
    "tests" -> {
      With[{anEventOrdering = EventOrderingFunctions[AtomicStateSystem]}, {
        (* Symbol Leak *)
        testSymbolLeak[
          GenerateMultihistory[AtomicStateSystem[a_ :> a + 1], {}, None, anEventOrdering, {"MaxEvents" -> 5}] @ 0],

        (* Rules *)
        testUnevaluated[GenerateMultihistory[AtomicStateSystem[##2], {}, None, anEventOrdering, {}] @ 1, {#}] & @@@
          {{AtomicStateSystem::argx},
           {AtomicStateSystem::argx, 1, 2},
           {GenerateMultihistory::invalidAtomicStateRules, 1}},

        (* Ordering not yet supported *)
        testUnevaluated[GenerateMultihistory[AtomicStateSystem[1 -> 2], {}, None, {"RuleIndex"}, {}] @ 1,
                        {GenerateMultihistory::atomicStateEventOrderingNotImplemented}],

        (* Token deduplication not yet supported *)
        testUnevaluated[GenerateMultihistory[AtomicStateSystem[1 -> 2], {}, All, anEventOrdering, {}] @ 1,
                        {GenerateMultihistory::atomicStateTokenDeduplicationNotImplemented}],

        (* Parameters *)
        testUnevaluated[
          GenerateMultihistory[AtomicStateSystem[1 -> 2], {"MaxGeneration" -> -1}, None, anEventOrdering, {}] @ 1,
          {GenerateMultihistory::notNonNegativeIntegerOrInfinityParameter}],

        Function[{rules, selection, stopping, init, expectedCreatedExpressions},
            VerificationTest[
              allExpressions @ GenerateMultihistory[
                AtomicStateSystem[rules], selection, None, anEventOrdering, stopping] @ init,
              Join[{init}, expectedCreatedExpressions],
              SameTest -> MatchQ]] @@@
          {{1 -> 1, <||>, <|"MaxEvents" -> 1|>, 1, {1}},
           {1 -> 2, <||>, <|"MaxEvents" -> 1|>, 1, {2}},
           {1 -> 2, <|"MaxGeneration" -> 1|>, <||>, 1, {2}},
           {2 :> 5, <|"MaxGeneration" -> 1|>, <||>, 2, {5}},
           {{2 -> 5, 2 :> 6}, <|"MaxGeneration" -> 1|>, <||>, 2, {5, 6}},
           {{2 :> 3, 3 :> 4}, <|"MaxGeneration" -> 2|>, <||>, 2, {3, 4}},
           {x_ :> x + 1, <|"MaxGeneration" -> 2|>, <||>, 2, {3, 4}},
           {{x_ :> x - 1, x_ :> x + 1}, <|"MaxGeneration" -> 2|>, <||>, 0, {-1, 1, -2, 0, 0, 2}},
           {{x_ ? EvenQ :> x - 1, x_ ? OddQ :> x + 1}, <|"MaxGeneration" -> 2|>, <||>, 0, {-1, 0}},
           (* only valid patterns should be matched *)
           {x_String :> x <> "x", {}, {"MaxEvents" -> 2}, 0, {}}}
      }],

      VerificationTest[
        allExpressions @ GenerateMultihistory[
          AtomicStateSystem[{1 -> 3, 2 -> 3, 0 -> 1, 0 -> 2}], {}, None, {"InputIndex", "RuleIndex"}, {}] @ 0,
        {0, 1, 2, 3, 3}
      ]
    }
  |>
|>
