<|
  "RandomHypergraph" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
    ),
    "tests" -> {

      (* unevaluated *)

      (** argument count **)
      testUnevaluated[
        RandomHypergraph[],
        {RandomHypergraph::argx}
      ],

      testUnevaluated[
        RandomHypergraph[1, 2],
        {RandomHypergraph::argx}
      ],

      (** invalid 1st argument **)
      testUnevaluated[
        RandomHypergraph[-1],
        {RandomHypergraph::invalidEnum}
      ],

      testUnevaluated[
        RandomHypergraph[{-8, {3, 2}}],
        {RandomHypergraph::invalidEnum}
      ],

      testUnevaluated[
        RandomHypergraph[{8, {-3, 2}}],
        {RandomHypergraph::invalidEnum}
      ],

      testUnevaluated[
        RandomHypergraph[{8, {3, -2}}],
        {RandomHypergraph::invalidEnum}
      ],

      (* "Complexity" *)
      VerificationTest[
        SeedRandom[123]; RandomHypergraph[8],
        {{5, 6, 3}, {5, 1}, {2, 2}, {5}}
      ],

      (* Signature *)
      VerificationTest[
        SeedRandom[123]; RandomHypergraph[{10, {5, 2}}],
        {{8, 5}, {1, 3}, {7, 8}, {10, 9}, {4, 10}}
      ],

      VerificationTest[
        SeedRandom[123]; RandomHypergraph[{10, {{5, 2}, {4, 3}}}],
        {{8, 5}, {1, 3}, {7, 8}, {10, 9}, {4, 10}, {9, 6, 3}, {7, 3, 7}, {3, 1, 5}, {2, 8, 7}}
      ]
    }
  |>
|>
