<|
  "RandomHypergraph" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];

      distinctHypergraphQ[hypergraphs_] := Length[Tally[Map[Sort, hypergraphs, {1, 2}]]] > 1;
      validVertexRangeQ[range_, hypergraph_] := SubsetQ[range, Flatten @ hypergraph];

      seed = 123;
    ),
    "tests" -> {

      (* unevaluated *)

      (** argument count **)
      testUnevaluated[
        RandomHypergraph[],
        {RandomHypergraph::argt}
      ],

      testUnevaluated[
        RandomHypergraph[1, 2, 3],
        {RandomHypergraph::argt}
      ],

      (** invalid 1st argument **)
      testUnevaluated[
        RandomHypergraph[-1],
        {RandomHypergraph::invalidSig}
      ],

      testUnevaluated[
        RandomHypergraph[-1, 10],
        {RandomHypergraph::invalidSig}
      ],

      testUnevaluated[
        RandomHypergraph[{-3, 2}],
        {RandomHypergraph::invalidSig}
      ],

      testUnevaluated[
        RandomHypergraph[{{3, -2}}],
        {RandomHypergraph::invalidSig}
      ],

      (** invalid 2nd argument **)
      testUnevaluated[
        RandomHypergraph[8, -3],
        {RandomHypergraph::intpa}
      ],

      testUnevaluated[
        RandomHypergraph[{3, 2}, -3],
        {RandomHypergraph::intpa}
      ],

      testUnevaluated[
        RandomHypergraph[{{3, 2}}, -3],
        {RandomHypergraph::intpa}
      ],

      (* "Complexity" *)
      VerificationTest[
        SeedRandom[123];
        AllTrue[
          Table[RandomHypergraph[8], 100],
          Total[Length /@ #] === 8 &],
        True
      ],
      VerificationTest[
        SeedRandom[123];
        AllTrue[
          Table[RandomHypergraph[8, 20], 100],
          Total[Length /@ #] === 8 &],
        True
      ],

      (** All generated hypergraphs should not be the same **)
      VerificationTest[
        SeedRandom[123];
        distinctHypergraphQ @ Table[RandomHypergraph[8], 100],
        True
      ],
      VerificationTest[
        SeedRandom[123];
        distinctHypergraphQ @ Table[RandomHypergraph[8, 20], 100],
        True
      ],

      (** Verify all vertices are in the correct range **)
      VerificationTest[
        SeedRandom[123];
        validVertexRangeQ[Range[1, 8], Table[RandomHypergraph[8], 100]],
        True
      ],
      VerificationTest[
        SeedRandom[123];
        validVertexRangeQ[Range[1, 20], Table[RandomHypergraph[8, 20], 100]],
        True
      ],

      (* Signature *)
      (*** Hypergraph signature **)
      VerificationTest[
        SeedRandom[124];
        AllTrue[
          Table[RandomHypergraph[{5, 2}], 100],
          MatchQ[#, {Repeated[{_, _}, {5}]}] &],
        True
      ],
      VerificationTest[
        SeedRandom[124];
        AllTrue[
          Table[RandomHypergraph[{5, 2}, 20], 100],
          MatchQ[#, {Repeated[{_, _}, {5}]}] &],
        True
      ],

      (** All generated hypergraphs should not be the same **)
      VerificationTest[
        SeedRandom[124];
        distinctHypergraphQ @ Table[RandomHypergraph[{5, 2}], 100],
        True
      ],
      VerificationTest[
        SeedRandom[124];
        distinctHypergraphQ @ Table[RandomHypergraph[{5, 2}, 20], 100],
        True
      ],

      (** Verify all vertices are in the correct range **)
      VerificationTest[
        SeedRandom[124];
        validVertexRangeQ[Range[1, 10], Table[RandomHypergraph[{5, 2}], 100]],
        True
      ],
      VerificationTest[
        SeedRandom[124];
        validVertexRangeQ[Range[1, 20], Table[RandomHypergraph[{5, 2}, 20], 100]],
        True
      ],

      (* Signature(s) *)
      (*** Hypergraph signature **)
      VerificationTest[
        SeedRandom[125];
        AllTrue[
          Table[RandomHypergraph[{{5, 2}, {2, 3}}], 100],
          MatchQ[#, {Repeated[{_, _}, {5}], Repeated[{_, _, _}, {2}]}] &],
        True
      ],
      VerificationTest[
        SeedRandom[125];
        AllTrue[
          Table[RandomHypergraph[{{5, 2}, {2, 3}}, 20], 100],
          MatchQ[#, {Repeated[{_, _}, {5}], Repeated[{_, _, _}, {2}]}] &],
        True
      ],

      (** All generated hypergraphs should not be the same **)
      VerificationTest[
        SeedRandom[125];
        distinctHypergraphQ @ Table[RandomHypergraph[{{5, 2}, {2, 3}}], 100],
        True
      ],
      VerificationTest[
        SeedRandom[125];
        distinctHypergraphQ @ Table[RandomHypergraph[{{5, 2}, {2, 3}}, 20], 100],
        True
      ],

      (** Verify all vertices are in the correct range **)
      VerificationTest[
        SeedRandom[125];
        validVertexRangeQ[Range[1, 16], Table[RandomHypergraph[{{5, 2}, {2, 3}}], 100]],
        True
      ],
      VerificationTest[
        SeedRandom[125];
        validVertexRangeQ[Range[1, 20], Table[RandomHypergraph[{{5, 2}, {2, 3}}, 20], 100]],
        True
      ]
    }
  |>
|>
