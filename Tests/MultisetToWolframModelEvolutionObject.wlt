<|
  "Multiset -> WolframModelEvolutionObject" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];
    ),
    "tests" -> {
      VerificationTest[
        (VertexCount @ #["ExpressionsEventsGraph"] &) @
          SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
            GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} :> {a + b}],
                                 {"MaxGeneration" -> 1, "MaxEventInputs" -> 2},
                                 None,
                                 EventOrderingFunctions[MultisetSubstitutionSystem],
                                 {}] @
              {1, 2, 3},
        15],

      VerificationTest[
        (#["EventsCount"] &) @
          SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
            GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} :> {a + b}],
                                 {"MaxEventInputs" -> 2},
                                 None,
                                 EventOrderingFunctions[MultisetSubstitutionSystem],
                                 {"MaxEvents" -> 10}] @
              {1, 2, 3},
        10]
    }
  |>
|>
