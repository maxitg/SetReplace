<|
  "HypergraphOverlaps" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];

      correctOverlapQ[e1_, e2_, unifyingHypergraph_, match1_, match2_] := And @@ MapThread[
        DuplicateFreeQ[First /@ Union[Thread[Catenate[#1] -> Catenate[#2]]]] &,
        {{e1, e2}, (unifyingHypergraph[[Values[#]]] &) /@ {match1, match2}}]
    ),
    "tests" -> {
      testSymbolLeak[
        HypergraphOverlaps[{{1, 2}, {2, 3}, {3, 4, 5}}, {{a, b}, {b, c}, {c, d, e}}]
      ],
      
      testUnevaluated[
        HypergraphOverlaps[],
        {HypergraphOverlaps::argrx}
      ],

      testUnevaluated[
        HypergraphOverlaps[1],
        {HypergraphOverlaps::argr}
      ],

      testUnevaluated[
        HypergraphOverlaps[1, 2, 3],
        {HypergraphOverlaps::argrx}
      ],

      testUnevaluated[
        HypergraphOverlaps[{1}, 2],
        {HypergraphOverlaps::hypergraphNotList}
      ],

      testUnevaluated[
        HypergraphOverlaps[1, {2}],
        {HypergraphOverlaps::hypergraphNotList}
      ],

      testUnevaluated[
        HypergraphOverlaps[{1}, {2}],
        {HypergraphOverlaps::edgeNotList}
      ],

      testUnevaluated[
        HypergraphOverlaps[{{1}}, {2}],
        {HypergraphOverlaps::edgeNotList}
      ],

      testUnevaluated[
        HypergraphOverlaps[{1}, {{2}}],
        {HypergraphOverlaps::edgeNotList}
      ],

      VerificationTest[
        HypergraphOverlaps[{{1}}, {{2}}],
        {{{{1}}, <|1 -> 1|>, <|1 -> 1|>}}
      ],

      VerificationTest[
        HypergraphOverlaps[{{1, 2}}, {{1, 2}}],
        {{{{1, 2}}, <|1 -> 1|>, <|1 -> 1|>}}
      ],

      VerificationTest[
        Sort @ HypergraphOverlaps[{{1, 2}, {3, 4}}, {{1, 2}}][[All, 2]],
        {<|1 -> 1, 2 -> 2|>, <|1 -> 2, 2 -> 1|>}
      ],

      VerificationTest[
        Length[HypergraphOverlaps[{{1, 2}, {2, 3}, {3, 4}}, {{a, b}, {b, c}, {c, d}}]],
        33
      ],

      VerificationTest[
        Length[HypergraphOverlaps[{{1, 1}, {1, 1}, {1, 1}}, {{1, 1}, {1, 1}, {1, 1}}]],
        33
      ],

      VerificationTest[
        Length[HypergraphOverlaps[{{1, 2}, {2, 3}, {3, 4, 5}}, {{1, 2}, {2, 3}, {3, 4, 5}}]],
        13
      ],

      VerificationTest[
        Length[HypergraphOverlaps[{{1, 2}, {2, 3, 4}}, {{1, 2}, {2, 3, 4}}]],
        3
      ],

      VerificationTest[
        Length[HypergraphOverlaps[{{1, 2}, {2, 3}, {3, 4}}, {{a, b}, {b, c}, {c, d}}]],
        33
      ],

      Function[{e1, e2},
        VerificationTest[
          And @@ (correctOverlapQ[e1, e2, ##] & @@@ HypergraphOverlaps[e1, e2])
        ]
      ] @@@ {
        ConstantArray[{{1, 2}}, 2],
        ConstantArray[{{1, 2}, {2, 3}}, 2],
        ConstantArray[{{1, 2}, {2, 3}, {3, 4, 5}}, 2],
        ConstantArray[{{1, 2}, {3, 4}, {5, 6, 7}}, 2],
        ConstantArray[{{1, 2, 3}, {4, 5, 6}, {1, 4}}, 2],
        {{{1, 2}, {2, 3}, {3, 4, 5}}, {{1, 2}, {3, 4}, {5, 6, 7}}},
        {{{1, 2}, {2, 1}}, {{a, b}, {b, c}, {c, d, e}}},
        {{{1, 2}}, {{a, b}, {b, c}, {c, d, e}}},
        ConstantArray[{{1, 1}, {1, 1}, {1, 1}}, 2]
      }
    }
  |>
|>
