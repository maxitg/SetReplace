<|
  "Subhypergraph" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
    ),
    "tests" -> {
      (* Subhypergraph / normal form *)

      VerificationTest[
        Subhypergraph[{}, {}],
        {}
      ],

      VerificationTest[
        Subhypergraph[{{1}}, {}],
        {}
      ],

      VerificationTest[
        Subhypergraph[{}, {1}],
        {}
      ],

      VerificationTest[
        Subhypergraph[{{1, 2, 3}, {2, 3, 4}, {3, 4, 5}}, Range[3, 5]],
        {{3, 4, 5}}
      ],

      VerificationTest[
        Subhypergraph[{{1, 1, 1}, {1, 2}, {2, 3, 3}, {2, 3, 4}}, {2, 3, 4}],
        {{2, 3, 3}, {2, 3, 4}}
      ],

      (** Wrong argument count **)
      testUnevaluated[
        Subhypergraph[{{}}, {}, 3],
        {Subhypergraph::argt}
      ],

      (** Wrong first argument **)
      testUnevaluated[
        Subhypergraph[1, {2, 3, 4}],
        {Subhypergraph::invalidHypergraph}
      ],

      testUnevaluated[
        Subhypergraph[{1, 2}, {2, 3, 4}],
        {Subhypergraph::invalidHypergraph}
      ],

      testUnevaluated[
        Subhypergraph[{1, 2}, 1],
        {Subhypergraph::invalidHypergraph}
      ],

      (** Wrong second argument **)
      testUnevaluated[
        Subhypergraph[{{1, 1, 2}, {2, 3}, {2, 3, 4}}, 1],
        {Subhypergraph::invl}
      ],

      (* Subhypergraph / operator form *)

      VerificationTest[
        Subhypergraph[{}][{}],
        {}
      ],

      VerificationTest[
        Subhypergraph[{}][{{1, 1, 1}, {1, 2}, {2, 3, 3}, {2, 3, 4}}],
        {}
      ],

      VerificationTest[
        Subhypergraph[{2, 3, 4}][{{1, 1, 1}, {1, 2}, {2, 3, 3}, {2, 3, 4}}],
        {{2, 3, 3}, {2, 3, 4}}
      ],

      (** Wrong argument count **)
      testUnevaluated[
        Subhypergraph[{}][{{}}, {}],
        {Subhypergraph::argx}
      ],

      (** Wrong first argument **)
      testUnevaluated[
        Subhypergraph[1][{2, 3, 4}],
        {Subhypergraph::invalidHypergraph}
      ],

      (** Wrong second argument **)
      VerificationTest[
        Subhypergraph[1][{{1, 2}, {2, 3, 4}}],
        {}
      ],

      (* WeakSubhypergraph / normal form *)

      VerificationTest[
        WeakSubhypergraph[{}, {}],
        {}
      ],

      VerificationTest[
        WeakSubhypergraph[{{1}}, {}],
        {}
      ],

      VerificationTest[
        WeakSubhypergraph[{}, {1}],
        {}
      ],

      VerificationTest[
        WeakSubhypergraph[{{1, 2, 3}, {2, 3, 4}, {3, 4, 5}}, Range[4, 6]],
        {{2, 3, 4}, {3, 4, 5}}
      ],

      VerificationTest[
        WeakSubhypergraph[{{1, 1, 1}, {1, 2}, {2, 3, 3}, {2, 3, 4}}, {2, 3, 4}],
        {{1, 2}, {2, 3, 3}, {2, 3, 4}}
      ],

      (** Wrong argument count **)
      testUnevaluated[
        WeakSubhypergraph[{{}}, {}, 3],
        {WeakSubhypergraph::argt}
      ],

      (** Wrong first argument **)
      testUnevaluated[
        WeakSubhypergraph[1, {2, 3, 4}],
        {WeakSubhypergraph::invalidHypergraph}
      ],

      testUnevaluated[
        WeakSubhypergraph[{1, 2}, {2, 3, 4}],
        {WeakSubhypergraph::invalidHypergraph}
      ],

      testUnevaluated[
        WeakSubhypergraph[{1, 2}, 1],
        {WeakSubhypergraph::invalidHypergraph}
      ],

      (** Wrong second argument **)
      testUnevaluated[
        WeakSubhypergraph[{{1, 1, 2}, {2, 3}, {2, 3, 4}}, 1],
        {WeakSubhypergraph::invl}
      ],

      (* WeakSubhypergraph / operator form *)

      VerificationTest[
        WeakSubhypergraph[{}][{}],
        {}
      ],

      VerificationTest[
        WeakSubhypergraph[{}][{{1, 1, 1}, {1, 2}, {2, 3, 3}, {2, 3, 4}}],
        {}
      ],

      VerificationTest[
        WeakSubhypergraph[{2, 3, 4}][{{1, 1, 1}, {1, 2}, {2, 3, 3}, {2, 3, 4}}],
        {{1, 2}, {2, 3, 3}, {2, 3, 4}}
      ],

      (** Wrong argument count **)
      testUnevaluated[
        WeakSubhypergraph[{}][{{}}, {}],
        {WeakSubhypergraph::argx}
      ],

      (** Wrong first argument **)
      testUnevaluated[
        WeakSubhypergraph[1][{2, 3, 4}],
        {WeakSubhypergraph::invalidHypergraph}
      ],

      (** Wrong second argument **)
      VerificationTest[
        WeakSubhypergraph[1][{{1, 2}, {2, 3, 4}}],
        {}
      ]
    }
  |>
|>
