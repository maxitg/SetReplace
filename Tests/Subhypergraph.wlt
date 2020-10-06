<|
  "Subhypergraph" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
    ),
    "tests" -> {
      (* Subhypergraph *)

      VerificationTest[
        Subhypergraph[{},{}],
        {}
      ],

      VerificationTest[
        Subhypergraph[{{1}},{}],
        {}
      ],

      VerificationTest[
        Subhypergraph[{},{1}],
        {}
      ],

      VerificationTest[
        Subhypergraph[{{1,2,3},{2,3,4},{3,4,5}},{1,2,3,4}],
        {{1,2,3},{2,3,4}}
      ],

      VerificationTest[
        Subhypergraph[{{1,1,1},{1,2},{2,3,3},{2,3,4}},{2,3,4}],
        {{2,3,3},{2,3,4}}
      ],

      VerificationTest[
        Subhypergraph[{2,3,4}][{{1,1,1},{1,2},{2,3,3},{2,3,4}}],
        {{2,3,3},{2,3,4}}
      ],

      testUnevaluated[
        Subhypergraph[1,{2,3,4}],
        {Subhypergraph::invalidHypergraph}
      ],

      testUnevaluated[
        Subhypergraph[{{}},{},3],
        {Subhypergraph::argt}
      ],
      
      testUnevaluated[
        Subhypergraph[{}][{{}},{}],
        {Subhypergraph::argx}
      ],

      (* WeakSubhypergraph *)

      VerificationTest[
        WeakSubhypergraph[{},{}],
        {}
      ],

      VerificationTest[
        WeakSubhypergraph[{{1}},{}],
        {}
      ],

      VerificationTest[
        WeakSubhypergraph[{},{1}],
        {}
      ],

      VerificationTest[
        WeakSubhypergraph[{{1,2,3},{2,3,4},{3,4,5}},Range[4,6]],
        {{2,3,4},{3,4,5}}
      ],

      VerificationTest[
        WeakSubhypergraph[{{1,1,1},{1,2},{2,3,3},{2,3,4}},{2,3,4}],
        {{1,2},{2,3,3},{2,3,4}}
      ],

      VerificationTest[
        WeakSubhypergraph[{2,3,4}][{{1,1,1},{1,2},{2,3,3},{2,3,4}}],
        {{1,2},{2,3,3},{2,3,4}}
      ],

      testUnevaluated[
        WeakSubhypergraph[1,{2,3,4}],
        {WeakSubhypergraph::invalidHypergraph}
      ],

      testUnevaluated[
        WeakSubhypergraph[{{}},{},3],
        {WeakSubhypergraph::argt}
      ],

      testUnevaluated[
        WeakSubhypergraph[{}][{{}},{}],
        {WeakSubhypergraph::argx}
      ]
    }
  |>
|>
