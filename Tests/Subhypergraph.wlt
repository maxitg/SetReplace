<|
  "Subhypergraph" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      $supportedHypergraphSymmetries = {"Ordered", "Unordered", "Cyclic"};
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

      VerificationTest[
        Subhypergraph[Hypergraph[{{1, 1, 1}, {1, 2}, {2, 3, 3}, {2, 3, 4}}], {2, 3, 4}],
        Hypergraph[{{2, 3, 3}, {2, 3, 4}}]
      ],

      With[{symmetry = #},
        VerificationTest[
          Subhypergraph[Hypergraph[{{7, 5, 5}, {4}, {7, 5}, {7, 6}}, symmetry], {5, 7}],
          Hypergraph[{{7, 5, 5}, {7, 5}}, symmetry]
        ]
      ] & /@ $supportedHypergraphSymmetries,

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
        {Subhypergraph::invalidVertices}
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

      With[{symmetry = #},
        VerificationTest[
          Subhypergraph[{5, 7}][Hypergraph[{{7, 5, 5}, {4}, {7, 5}, {7, 6}}, symmetry]],
          Hypergraph[{{7, 5, 5}, {7, 5}}, symmetry]
        ]
      ] & /@ $supportedHypergraphSymmetries,

      (** Wrong argument count **)
      testUnevaluated[
        Subhypergraph[{}][{{}}, {}],
        {Subhypergraph::invalidArgumentLength}
      ],

      (** Wrong zeroth argument **)
      testUnevaluated[
        Subhypergraph[1][{{1, 2}, {2, 3, 4}}],
        {Subhypergraph::invalidVertices}
      ],

      testUnevaluated[
        Subhypergraph[1][{2, 3, 4}],
        {Subhypergraph::invalidVertices}
      ],

      (** Wrong first argument **)
      testUnevaluated[
        Subhypergraph[{1}][{1, 2}],
        {Subhypergraph::invalidHypergraph}
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

      VerificationTest[
        WeakSubhypergraph[Hypergraph[{{1, 1, 1}, {1, 2}, {2, 3, 3}, {2, 3, 4}}], {2, 3, 4}],
        Hypergraph[{{1, 2}, {2, 3, 3}, {2, 3, 4}}]
      ],

      With[{symmetry = #},
        VerificationTest[
          WeakSubhypergraph[Hypergraph[{{7, 5, 5}, {4}, {7, 5}, {7, 6}}, symmetry], {5, 7}],
          Hypergraph[{{7, 5, 5}, {7, 5}, {7, 6}}, symmetry]
        ]
      ] & /@ $supportedHypergraphSymmetries,

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
        {WeakSubhypergraph::invalidVertices}
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

      With[{symmetry = #},
        VerificationTest[
          WeakSubhypergraph[{5, 7}][Hypergraph[{{7, 5, 5}, {4}, {7, 5}, {7, 6}}, symmetry]],
          Hypergraph[{{7, 5, 5}, {7, 5}, {7, 6}}, symmetry]
        ]
      ] & /@ $supportedHypergraphSymmetries,

      (** Wrong argument count **)
      testUnevaluated[
        WeakSubhypergraph[{}][{{}}, {}],
        {WeakSubhypergraph::invalidArgumentLength}
      ],

      (** Wrong zeroth argument **)
      testUnevaluated[
        WeakSubhypergraph[1][{{1, 2}, {2, 3, 4}}],
        {WeakSubhypergraph::invalidVertices}
      ],

      testUnevaluated[
        WeakSubhypergraph[1][{2, 3, 4}],
        {WeakSubhypergraph::invalidVertices}
      ],

      (** Wrong first argument **)
      testUnevaluated[
        WeakSubhypergraph[{1}][{1, 2}],
        {WeakSubhypergraph::invalidHypergraph}
      ]
    }
  |>
|>
