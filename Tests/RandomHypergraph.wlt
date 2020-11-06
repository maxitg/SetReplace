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
      With[{
          random1 = Table[RandomHypergraph[8], 100],
          random2 = Table[RandomHypergraph[8, 20], 100]},
        {
          (* The hyperedge arities for each hypergraph should total 8 *)
          VerificationTest[AllTrue[random1, Total[Length /@ #] === 8 &], True],
          VerificationTest[AllTrue[random2, Total[Length /@ #] === 8 &], True],

          (* All generated hypergraphs should not be the same *)
          VerificationTest[Length[Tally[Map[Sort, random1, {1, 2}]]] > 1, True],
          VerificationTest[Length[Tally[Map[Sort, random2, {1, 2}]]] > 1, True],

          (* All vertices must be in the correct range *)
          VerificationTest[SubsetQ[Range[1, 8], Flatten @ random1], True],
          VerificationTest[SubsetQ[Range[1, 20], Flatten @ random2], True]
          }
      ],

      (* Signature *)
      With[{
          random1 = Table[RandomHypergraph[{5, 2}], 100],
          random2 = Table[RandomHypergraph[{5, 2}, 20], 100]},
        {
          (* Hypergraph signature *)
          VerificationTest[AllTrue[random1, MatchQ[#, {Repeated[{_, _}, {5}]}] &], True],
          VerificationTest[AllTrue[random2, MatchQ[#, {Repeated[{_, _}, {5}]}] &], True],

          (* All generated hypergraphs should not be the same *)
          VerificationTest[Length[Tally[Map[Sort, random1, {1, 2}]]] > 1, True],
          VerificationTest[Length[Tally[Map[Sort, random2, {1, 2}]]] > 1, True],

          (* Verify all vertices are in the correct range *)
          VerificationTest[SubsetQ[Range[1, 10], Flatten @ random1], True],
          VerificationTest[SubsetQ[Range[1, 20], Flatten @ random2], True]
          }
      ],

      (* Signature(s) *)
      With[{
          random1 = Table[RandomHypergraph[{{5, 2}, {2, 3}}], 100],
          random2 = Table[RandomHypergraph[{{5, 2}, {2, 3}}, 20], 100]},
        {
          (* Hypergraph signature *)
          VerificationTest[
            AllTrue[
              SortBy[random1, Length],
              MatchQ[#, {Repeated[{_, _}, {5}], Repeated[{_, _, _}, {2}]}] &],
            True
          ],
          VerificationTest[
            AllTrue[
              SortBy[random2, Length],
              MatchQ[#, {Repeated[{_, _}, {5}], Repeated[{_, _, _}, {2}]}] &],
            True
          ],

          (* All generated hypergraphs should not be the same *)
          VerificationTest[Length[Tally[Map[Sort, random1, {1, 2}]]] > 1, True],
          VerificationTest[Length[Tally[Map[Sort, random2, {1, 2}]]] > 1, True],

          (* Verify all vertices are in the correct range *)
          VerificationTest[SubsetQ[Range[1, 16], Flatten @ random1], True],
          VerificationTest[SubsetQ[Range[1, 20], Flatten @ random2], True]
          }
      ]
    }
  |>
|>
