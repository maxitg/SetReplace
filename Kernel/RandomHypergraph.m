Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["RandomHypergraph"]

(* Documentation *)
RandomHypergraph::usage = "\
RandomHypergraph[n$] generates a random hypergraph, where n$ is the total of its hyperedge arities.
RandomHypergraph[{e$, a$}] generates a random hypergraph with e$ hyperedges of arity a$.
RandomHypergraph[{{e$(1), a$(1)}, {e$(2), a$(2)}, $$}] generates a random hypergraph with e$(i) hyperedges \
of arity a$(i).
RandomHypergraph[sig$, max$] generates a random hypergraph with at most max$ vertices.";

SetUsage[RandomHypergraph, RandomHypergraph::usage];

(* SyntaxInformation *)
SyntaxInformation[RandomHypergraph] =
  {"ArgumentsPattern" -> {_, _.}};

(* Argument count *)
RandomHypergraph[args___] := 0 /;
  !Developer`CheckArgumentCount[RandomHypergraph[args], 1, 2] && False

(* Main entry *)
expr : RandomHypergraph[sig_, max_ : Automatic] := ModuleScope[
  res = Catch[randomHypergraph[HoldForm @ expr, sig, max]];
  res /; res =!= $Failed
]

(* Error messages *)
RandomHypergraph::invalidSig = "\
The argument at position `2` in `1` should be a positive integer or a hypergraph signature.";

(* Support functions *)
randomPartition[n_] :=
  randomPartition[n, RandomInteger[{1, n}]]
randomPartition[n_Integer ? Positive, nparts_Integer ? Positive] :=
  RandomVariate @ MultinomialDistribution[n, ConstantArray[1 / nparts, nparts]]

$signaturePattern = {_Integer ? NonNegative, _Integer ? NonNegative};

(*
In[]:= RandomHypergraph[8]
Out[]= {{4, 4, 3}, {2, 7}, {5, 6}, {8}}
*)
randomHypergraph[caller_, complexity_Integer ? Positive, n : (_Integer ? Positive | Automatic)] :=
  With[{max = Replace[n, Automatic -> complexity]},
    RandomInteger[{1, max}, #] & /@ DeleteCases[randomPartition @ complexity, 0]
  ]

(*
In[]:= RandomHypergraph[{{5, 2}, {4, 3}}, 10]
Out[]= {{1, 2}, {2, 9}, {6, 1}, {3, 3}, {10, 10}, {1, 8, 8}, {5, 7, 9}, {5, 7, 6}, {5, 3, 3}}
*)
randomHypergraph[caller_, sig : {$signaturePattern ..}, n : (_Integer ? Positive | Automatic)] :=
  ModuleScope[
    If[n === Automatic,
      (* Maximum possible number of atoms *)
      max = Total[Times @@@ sig],
      max = n
    ];
    Catenate[RandomInteger[{1, max}, #] & /@ sig]
  ]

(*
In[]:= RandomHypergraph[{5, 2}, 10]
Out[]= {{5, 4}, {7, 8}, {7, 6}, {7, 1}, {4, 9}}
*)
randomHypergraph[caller_, sig : $signaturePattern, n_] :=
  randomHypergraph[caller, {sig}, n]

(* Incorrect arguments messages *)
randomHypergraph[caller_, sig : Except[$signaturePattern | {$signaturePattern ..} | _Integer ? Positive], _] :=
  (Message[RandomHypergraph::invalidSig, caller, 1];
  Throw[$Failed])

randomHypergraph[caller_, sig_, max_] :=
  (Message[RandomHypergraph::intpa, caller, 2];
  Throw[$Failed])
