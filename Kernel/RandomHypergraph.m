Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["RandomHypergraph"]

(* Documentation *)
RandomHypergraph::usage = "\
RandomHypergraph[n$] generates a random hypergraph, where n$ is the total of its hyperedge arities.
RandomHypergraph[{n$, {e$, a$}}] generates a random hypergraph with e$ hyperedges of arity a$ and at most n$ vertices.
RandomHypergraph[{n$, {{e$(1), a$(1)}, {e$(2), a$(2)}, $$}}] generates a random hypergraph with e$(i) hyperedges \
of arity a$(i).";

SetUsage[RandomHypergraph, RandomHypergraph::usage];

(* SyntaxInformation *)
SyntaxInformation[RandomHypergraph] =
  {"ArgumentsPattern" -> {_}};

(* Argument count *)
RandomHypergraph[args___] := 0 /;
  !Developer`CheckArgumentCount[RandomHypergraph[args], 1, 1] && False

(* Main entry *)
RandomHypergraph[enum_] := ModuleScope[
  res = Catch[randomHypergraph[enum]];
  res /; res =!= $Failed
]

(* Error messages *)
RandomHypergraph::invalidEnum = "The argument at position 1 in `1` should be a non-negative integer or \
a list of positive integer and a signature(s).";

(*
In[]:= RandomHypergraph[8]
Out[]= {{4, 4, 3}, {2, 7}, {5, 6}, {8}}
*)
randomHypergraph[enum_Integer ? NonNegative] :=
  RandomInteger[{1, enum}, #] & /@ RandomChoice[IntegerPartitions[enum]]

(*
In[]:= RandomHypergraph[{10, {5, 2}}]
Out[]= {{5, 4}, {7, 8}, {7, 6}, {7, 1}, {4, 9}}
*)
randomHypergraph[{n_Integer ? Positive, {e_Integer ? NonNegative, a_Integer ? NonNegative}}] :=
  RandomInteger[{1, n}, {e, a}]

(*
In[]:= RandomHypergraph[{10, {{5, 2}, {4, 3}}}]
Out[]= {{1, 2}, {2, 9}, {6, 1}, {3, 3}, {10, 10}, {1, 8, 8}, {5, 7, 9}, {5, 7, 6}, {5, 3, 3}}
*)
randomHypergraph[{n_Integer ? Positive, sig : {{_Integer ? NonNegative, _Integer ? NonNegative} ..}}] :=
 Catenate[RandomInteger[{1, n}, #] & /@ sig]

(* Incorrect arguments messages *)
randomHypergraph[enum_] :=
  (Message[RandomHypergraph::invalidEnum, HoldForm @ RandomHypergraph[enum]];
  Throw[$Failed])
