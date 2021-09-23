<|
  "Hypergraph System API" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];
    ),
    "tests" -> {
      With[{anEventOrdering = {"ReverseSortedInputTokenIndices", "InputTokenIndices", "RuleIndex"}}, {
        (* Symbol Leak *)
        testSymbolLeak[
          GenerateMultihistory[HypergraphSubstitutionSystem[{{a_, b_}, {a_, c_}} :> {{b, c}}],
                               {"MaxDestroyerEvents"->2},
                               None,
                               anEventOrdering,
                               {}] @ {{1, 2}, {1, 3}}],

        (* Invalid Rules *)
        testUnevaluated[
            GenerateMultihistory[HypergraphSubstitutionSystem[##2], {}, None, anEventOrdering, {}] @ {1}, {#}] & @@@
          {{HypergraphSubstitutionSystem::argx},
           {HypergraphSubstitutionSystem::argx, 1, 2},
           {GenerateMultihistory::invalidHypergraphRules, 1},
           {GenerateMultihistory::invalidHypergraphRules, {a_, b_} :> {a + b}}},

        (* Invalid Event Selection *)
        testUnevaluated[
            GenerateMultihistory[HypergraphSubstitutionSystem[{{a_, b_}, {b_, c_}} :> {{a, c}}],
                                 {#1 -> #2},
                                 None,
                                 anEventOrdering,
                                 {}] @ {{1, 2}, {2, 3}},
            {#3}] & @@@ {
              {"MaxGeneration", -1, GenerateMultihistory::notNonNegativeIntegerOrInfinityParameter},
              {"MaxDestroyerEvents", 4.2, GenerateMultihistory::notNonNegativeIntegerOrInfinityParameter},
              {"EventSeparation", "Timelike", GenerateMultihistory::invalidChoiceParameter}
            },

        (* Invalid Token Deduplication *)
        testUnevaluated[
          GenerateMultihistory[HypergraphSubstitutionSystem[{{v1_, v2_}, {v1_, v3_}} :> {{v2, v3}, {v3, v2}}],
                               {"MaxDestroyerEvents" -> 10},
                               All,
                               anEventOrdering,
                               {}] @ {{1, 2}, {1, 3}},
          {GenerateMultihistory::invalidTokenDeduplication}],

        (* Invalid Event Ordering *)
        testUnevaluated[
          GenerateMultihistory[HypergraphSubstitutionSystem[{{v1_, v2_}} :> Module[{v3}, {{v1, v3}, {v3, v2}}]],
                               {},
                               None,
                               {"ReverseSortedInputTokenIndices", "InputCount", "InputTokenIndices"},
                               {"MaxEvents" -> 1}] @ {{1, 2}, {2, 2}},
          {GenerateMultihistory::invalidEventOrdering}],

        (* Invalid Stopping Condition *)
        testUnevaluated[
            GenerateMultihistory[HypergraphSubstitutionSystem[{{a_, b_}, {b_, c_}} :> {{a, c}}],
                                 {},
                                 None,
                                 anEventOrdering,
                                 {#1 -> #2}] @ {{1, 2}, {2, 3}},
            {#3}] & @@@ {
              {"TimeConstraint", 0, GenerateMultihistory::notPositiveNumberOrInfinityParameter},
              {"MaxEvents", -1, GenerateMultihistory::notNonNegativeIntegerOrInfinityParameter},
              {"MaxVertices", -1, GenerateMultihistory::notNonNegativeIntegerOrInfinityParameter},
              {"MaxVertexDegree", -1, GenerateMultihistory::notNonNegativeIntegerOrInfinityParameter},
              {"MaxEdges", -1, GenerateMultihistory::notNonNegativeIntegerOrInfinityParameter}
            },

        (* Init *)
        testUnevaluated[
          GenerateMultihistory[HypergraphSubstitutionSystem[{{a_}} :> {{a, 2}}], {}, None, anEventOrdering, {}] @ {1},
          {GenerateMultihistory::hypergraphInitNotList}]
      }]
    }
  |>
|>
