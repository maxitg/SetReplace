<|
  "MultisetSubstitutionSystemAPI" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];
    ),
    "tests" -> {
      With[{anEventOrdering = {"InputCount", "SortedInputExpressions", "UnsortedInputExpressions", "RuleIndex"}}, {
        (* Symbol Leak *)

        testSymbolLeak[
          GenerateMultihistory[
              MultisetSubstitutionSystem[{a_, b_} :> {a + b}], <|"MaxEventInputs" -> 2|>, None, anEventOrdering, <||>] @
            {1, 2, 3}],

        (* Rules *)

        testUnevaluated[
            GenerateMultihistory[MultisetSubstitutionSystem[##2], <||>, None, anEventOrdering, <||>] @ {1}, {#}] & @@@
          {{MultisetSubstitutionSystem::argx},
           {MultisetSubstitutionSystem::argx, 1, 2},
           {GenerateMultihistory::invalidMultisetRules, 1},
           {GenerateMultihistory::ruleOutputNotList, {1} -> 2}},

        (* Init *)

        testUnevaluated[
          GenerateMultihistory[MultisetSubstitutionSystem[{1} -> {2}], <||>, None, anEventOrdering, <||>] @ 1,
          {GenerateMultihistory::multisetInitNotList}],

        (* Parameters *)

        testUnevaluated[
            GenerateMultihistory[MultisetSubstitutionSystem[{1} -> {2}], <|# -> -1|>, None, anEventOrdering, <||>] @
              {1},
            {GenerateMultihistory::notNonNegativeIntegerOrInfinityParameter}] & /@
          {"MaxGeneration", "MaxDestroyerEvents", "MinEventInputs", "MaxEventInputs"},

        testUnevaluated[
          GenerateMultihistory[
              MultisetSubstitutionSystem[{1} -> {2}], <||>, None, anEventOrdering, <|"MaxEvents" -> -1|>] @ {1},
          {GenerateMultihistory::notNonNegativeIntegerOrInfinityParameter}]
      }]
    }
  |>
|>
