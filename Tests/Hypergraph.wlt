<|
  "HypergraphPlot" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];

      Global`$hypergraphSymmetries = SetReplace`Hypergraph`PackagePrivate`$hypergraphSymmetries;
    ),
    "tests" -> {
      (* Argument Checks *)

      (** Argument count **)

      testUnevaluated[
        Hypergraph[],
        {Hypergraph::argt}
      ],

      testUnevaluated[
        Hypergraph[{{1, 1, 1}}, "Ordered", 1],
        {Hypergraph::argt}
      ],

      (** 1st argument **)

      testUnevaluated[
        Hypergraph[{1, 1, 1}],
        {Hypergraph::invalidHyperedges}
      ],

      (** 2nd argument **)

      testUnevaluated[
        Hypergraph[{{1, 1, 1}}, "Directed"],
        {Hypergraph::invalidSymmetry}
      ],

      (* Constructor *)

      VerificationTest[HypergraphQ[Hypergraph[{{1, 1, 1}}]]],

      VerificationTest[HypergraphQ[Hypergraph[{{1, {1}}, {{1}, x, y}}]]],

      (* Default 2nd argument *)

      VerificationTest[Hypergraph[{{1}}] === Hypergraph[{{1}}, "Ordered"]],

      (* Available symmetries *)

      VerificationTest[AllTrue[Hypergraph[{{1}}, #] & /@ $hypergraphSymmetries, HypergraphQ]],

      (* Accessors *)

      With[{hg = Hypergraph[{{1, 1, 2}, {2, 5, 4, 3}, {3, 6}}, "Unordered"]},
        {
            VerificationTest[VertexList[hg], {1, 2, 5, 4, 3, 6}],

            VerificationTest[EdgeList[hg], {{1, 1, 2}, {2, 5, 4, 3}, {3, 6}}],

            VerificationTest[Normal[hg], EdgeList[hg]],

            VerificationTest[VertexCount[hg] === Length[VertexList[hg]] === 6],

            VerificationTest[EdgeCount[hg] === Length[EdgeList[hg]] === 3],

            VerificationTest[HypergraphSymmetry[hg], "Unordered"]
        }
      ]
    }
  |>
|>
