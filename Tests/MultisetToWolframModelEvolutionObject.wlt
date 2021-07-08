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
            GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} :> {a + b}], {1, 2, 3}, MaxGeneration -> 1],
        15],

      VerificationTest[
        (#["EventsCount"] &) @
          SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
            GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} :> {a + b}], {1, 2, 3}, MaxEvents -> 10],
        10]
    }
  |>
|>
