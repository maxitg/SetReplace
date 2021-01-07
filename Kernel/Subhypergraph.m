(* Subhypergraph *)
(* Subhypergraph is an utility function that selects hyperedges that only contain vertices from the requested list. *)

Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["Subhypergraph"]
PackageExport["WeakSubhypergraph"]

(* Documentation *)

SetUsage @ "
Subhypergraph[hg$, vertices$] selects hyperedges from hg$ that are subsets of vertices$.
Subhypergraph[vertices$] represents the operator form for a hypergraph.
";

SetUsage @ "
WeakSubhypergraph[hg$, vertices$] selects any hyperedge from hg$ whose elements are contained in vertices$.
WeakSubhypergraph[vertices$] represents the operator form for a hypergraph.
";

(* SyntaxInformation *)
SyntaxInformation[Subhypergraph] =
  {"ArgumentsPattern" -> {_, _.}};

SyntaxInformation[WeakSubhypergraph] =
  {"ArgumentsPattern" -> {_, _.}};

(* Argument count *)
Subhypergraph[args___] := 0 /;
  !Developer`CheckArgumentCount[Subhypergraph[args], 1, 2] && False;

WeakSubhypergraph[args___] := 0 /;
  !Developer`CheckArgumentCount[WeakSubhypergraph[args], 1, 2] && False;

(* main *)
expr : Subhypergraph[arg1_, arg2_] := With[{res = Catch[subhypergraph[HoldForm @ expr, arg1, arg2]]},
  res /; res =!= $Failed
];

expr : WeakSubhypergraph[arg1_, arg2_] := With[{res = Catch[weakSubhypergraph[HoldForm @ expr, arg1, arg2]]},
  res /; res =!= $Failed
];

(* operator form *)
expr : Subhypergraph[args0___][args1___] := With[{res = Catch[subhypergraph[HoldForm @ expr][args0][args1]]},
  res /; res =!= $Failed
];

expr : WeakSubhypergraph[args0___][args1___] := With[{res = Catch[weakSubhypergraph[HoldForm @ expr][args0][args1]]},
  res /; res =!= $Failed
];

(* Normal form *)
subhypergraph[_, h_ ? hypergraphQ, vertices_List] := Select[h, SubsetQ[vertices, #] &];

weakSubhypergraph[_, h_ ? hypergraphQ, vertices_List] := Select[h, ContainsAny[#, vertices] &];

(* Incorrect arguments messages *)

(** hypergraph **)

subhypergraph[expr_, h_ ? (Not @* hypergraphQ), _] :=
  (Message[Subhypergraph::invalidHypergraph, 1, HoldForm @ expr];
  Throw[$Failed]);

weakSubhypergraph[expr_, h_ ? (Not @* hypergraphQ), _] :=
  (Message[WeakSubhypergraph::invalidHypergraph, 1, HoldForm @ expr];
  Throw[$Failed]);

(** vertices **)

subhypergraph[expr_, _ , v : Except[_List]] :=
  (Message[Subhypergraph::invl, 2];
  Throw[$Failed]);

weakSubhypergraph[expr_, _ , v : Except[_List]] :=
  (Message[WeakSubhypergraph::invl, 2];
  Throw[$Failed]);

(* operator form *)
subhypergraph[_][vertices_List][h_ ? hypergraphQ] := subhypergraph[None, h, vertices];

weakSubhypergraph[_][vertices_List][h_ ? hypergraphQ] := weakSubhypergraph[None, h, vertices];

(* Incorrect arguments messages *)

(** vertices **)
subhypergraph[expr_][Except[_List]][_] :=
  (Message[Subhypergraph::invl, {0, 1}];
  Throw[$Failed]);

weakSubhypergraph[expr_][Except[_List]][_] :=
  (Message[WeakSubhypergraph::invl, {0, 1}];
  Throw[$Failed]);

(** hypergraph **)
subhypergraph[expr_][args0___][h_ ? (Not @* hypergraphQ)] :=
  (Message[Subhypergraph::invalidHypergraph, 1, HoldForm @ expr];
  Throw[$Failed]);

weakSubhypergraph[expr_][args0___][h_ ? (Not @* hypergraphQ)] :=
  (Message[WeakSubhypergraph::invalidHypergraph, 1, HoldForm @ expr];
  Throw[$Failed]);

(** length **)
subhypergraph[expr_][args0___][args1___] /; (Length[{args1}] =!= 1) :=
  (Message[Subhypergraph::argx, HoldForm @ expr, Length @ {args1}, 1];
  Throw[$Failed]);

weakSubhypergraph[expr_][args0___][args1___] /; (Length[{args1}] =!= 1) :=
  (Message[WeakSubhypergraph::argx, HoldForm @ expr, Length @ {args1}, 1];
  Throw[$Failed]);
