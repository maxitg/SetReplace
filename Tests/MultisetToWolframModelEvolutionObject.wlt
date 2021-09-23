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
          SetReplaceTypeConvert[WolframModelEvolutionObject] @
            GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} :> {a + b}], MaxGeneration -> 1] @ {1, 2, 3},
        15],

      VerificationTest[
        (#["EventsCount"] &) @
          SetReplaceTypeConvert[WolframModelEvolutionObject] @
            GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} :> {a + b}], MaxEvents -> 10] @ {1, 2, 3},
        10]
    }
  |>
|>
