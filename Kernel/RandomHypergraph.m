Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["RandomHypergraph"]

(* Documentation *)
SetUsage @ "
RandomHypergraph[size$] generates a random hypergraph, where size$ is the total of its hyperedge arities.
RandomHypergraph[{count$, arity$}] generates a random hypergraph with count$ hyperedges of a specified arity$.
RandomHypergraph[{{count$(1), arity$(1)}, {count$(2), arity$(2)}, $$}] generates a random hypergraph with hyperedges \
of multiple arities.
RandomHypergraph[sizeSpec$, maxVertices$] also limits the vertex count.
";

(* SyntaxInformation *)
SyntaxInformation[RandomHypergraph] =
  {"ArgumentsPattern" -> {sizeSpec_, maxVertices_.}};

(* Argument count *)
RandomHypergraph[args___] := 0 /;
  !Developer`CheckArgumentCount[RandomHypergraph[args], 1, 2] && False;

(* Main entry *)
expr : RandomHypergraph[sizeSpec_, max_ : Automatic] := ModuleScope[
  res = Catch[randomHypergraph[HoldForm @ expr, sizeSpec, max]];
  res /; res =!= $Failed
];

(* Error messages *)
RandomHypergraph::invalidSizeSpec = "\
The argument at position `2` in `1` should be a positive integer or a hypergraph size specification.";

(* Support functions *)
randomPartition[n_] :=
  randomPartition[n, RandomInteger[{1, n}]];
randomPartition[n_Integer ? Positive, nparts_Integer ? Positive] :=
  RandomVariate @ MultinomialDistribution[n, ConstantArray[1 / nparts, nparts]];

$sizeSpecPattern = {_Integer ? NonNegative, _Integer ? NonNegative};

(*
In[]:= RandomHypergraph[8]
Out[]= {{4, 4, 3}, {2, 7}, {5, 6}, {8}}
*)
randomHypergraph[caller_, complexity_Integer ? Positive, n : (_Integer ? Positive | Automatic)] :=
  With[{max = Replace[n, Automatic -> complexity]},
    RandomInteger[{1, max}, #] & /@ DeleteCases[randomPartition @ complexity, 0]
  ];

(*
In[]:= RandomHypergraph[{{5, 2}, {4, 3}}, 10]
Out[]= {{1, 2}, {2, 9}, {6, 1}, {3, 3}, {10, 10}, {1, 8, 8}, {5, 7, 9}, {5, 7, 6}, {5, 3, 3}}
*)
randomHypergraph[caller_, sizeSpec : {$sizeSpecPattern ..}, n : (_Integer ? Positive | Automatic)] :=
  ModuleScope[
    If[n === Automatic,
      (* Maximum possible number of atoms *)
      max = Total[Times @@@ sizeSpec]
    ,
      max = n
    ];
    Catenate[RandomInteger[{1, max}, #] & /@ sizeSpec]
  ];

(*
In[]:= RandomHypergraph[{5, 2}, 10]
Out[]= {{5, 4}, {7, 8}, {7, 6}, {7, 1}, {4, 9}}
*)
randomHypergraph[caller_, sizeSpec : $sizeSpecPattern, n_] :=
  randomHypergraph[caller, {sizeSpec}, n];

(* Incorrect arguments messages *)
randomHypergraph[caller_, sizeSpec : Except[$sizeSpecPattern | {$sizeSpecPattern ..} | _Integer ? Positive], _] :=
  (Message[RandomHypergraph::invalidSizeSpec, caller, 1];
  Throw[$Failed]);

randomHypergraph[caller_, sizeSpec_, max_] :=
  (Message[RandomHypergraph::intpa, caller, 2];
  Throw[$Failed]);
