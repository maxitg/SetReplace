<|
  "IndexHypergraph" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
    ),
    "tests" -> {

      VerificationTest[
        IndexHypergraph[{}],
        {}
      ],

      VerificationTest[
        IndexHypergraph[{{{1}}}],
        {{1}}
      ],

      VerificationTest[
        IndexHypergraph[{}, {1}],
        {}
      ],

      VerificationTest[
        IndexHypergraph[{Range[5]}, -10],
        {{-10, -9, -8, -7, -6}}
      ],

      VerificationTest[
        IndexHypergraph[{{x, y, z}, {y, z}, {y, y, x, z}}, 2],
        {{2, 3, 4}, {3, 4}, {3, 3, 2, 4}}
      ],

      (* unevaluated *)

      (** argument count **)
      testUnevaluated[
        IndexHypergraph[],
        {IndexHypergraph::argt}
      ],

      testUnevaluated[
        IndexHypergraph[{{x, y, z}, {y, z}}, 2, 3],
        {IndexHypergraph::argt}
      ],

      (** first argument **)
      testUnevaluated[
        IndexHypergraph[{x, y, {z}}],
        {IndexHypergraph::invalidHypergraph}
      ],

      testUnevaluated[
        IndexHypergraph[{x, y, {z}}, 2],
        {IndexHypergraph::invalidHypergraph}
      ],

      (** second argument **)
      testUnevaluated[
        IndexHypergraph[{{x, y, z}, {y, z, y}}, x],
        {IndexHypergraph::int}
      ]
    }
  |>
|>
