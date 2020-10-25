<|
  "IsomorphicHypergraphQ" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] :=
        SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
    ),
    "tests" -> {

      (* unevaluated *)

      (** argument count **)
      testUnevaluated[
        IsomorphicHypergraphQ[],
        {IsomorphicHypergraphQ::argrx}
      ],

      testUnevaluated[
        IsomorphicHypergraphQ[{{1}}],
        {IsomorphicHypergraphQ::argr}
      ],

      testUnevaluated[
        IsomorphicHypergraphQ[{{1}}, {{1}}, {{2}}],
        {IsomorphicHypergraphQ::argrx}
      ],

      (** invalid hypergraph **)
      testUnevaluated[
        IsomorphicHypergraphQ[{1}, {{1}}],
        {IsomorphicHypergraphQ::invalidHypergraph}
      ],

      testUnevaluated[
        IsomorphicHypergraphQ[{{1}}, {1}],
        {IsomorphicHypergraphQ::invalidHypergraph}
      ],

      (* eval *)
      VerificationTest[
        IsomorphicHypergraphQ[{}, {}],
        True
      ],

      VerificationTest[
        IsomorphicHypergraphQ[{}, {{}}],
        False
      ],

      VerificationTest[
        IsomorphicHypergraphQ[{{}}, {{}}],
        True
      ],

      VerificationTest[
        IsomorphicHypergraphQ[{{{{1}}}}, {{x}}],
        True
      ],

      VerificationTest[
        IsomorphicHypergraphQ[{{1, 2}}, {{x, y}}],
        True
      ],

      VerificationTest[
        IsomorphicHypergraphQ[
          {{a, e, d}, {d, c}, {c, b}, {b, a}},
          {{2, 4}, {4, 5, 1}, {1, 3}, {3, 2}}],
        True
      ],

      VerificationTest[
        IsomorphicHypergraphQ[
          {{a, e, d}, {d, c}, {c, b}, {b, a}},
          {{2, 4}, {4, 3, 1}, {1, 3}, {5, 2}}],
        False
      ],

      VerificationTest[
        IsomorphicHypergraphQ[
          {{1, 2}, {2, 3}, {3, 4}, {4, 5}},
          {{1, 2}, {2, 3}, {3, 4}, {1, 5}}],
        False
      ],

      VerificationTest[
        IsomorphicHypergraphQ[
          {{}, {x, x, y, z}, {z, w}},
          {{}, {{x}, {x}, 2, 3}, {3, 4}}],
        True
      ]
    }
  |>
|>
