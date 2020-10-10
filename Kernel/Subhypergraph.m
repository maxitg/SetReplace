(* ::Package:: *)

(* Subhypergraph *)
(* Subhypergraph is an utility function that selects hyperedges that only contain vertices from the requested list. *)

Package["SetReplace`"]

PackageExport["Subhypergraph"]
PackageExport["WeakSubhypergraph"]

(* Documentation *)
Subhypergraph::usage = usageString[
  "Subhypergraph[`h`, `vertices`] selects hyperedges from `h` that are subsets of `vertices`.",
  "\n",
  "Subhypergraph[`vertices`] represents the operator form for a hypergraph."];

WeakSubhypergraph::usage = usageString[
  "WeakSubhypergraph[`h`, `vertices`] selects any hyperedge from `h` whose elements are contained in `vertices`.",
  "\n",
  "WeakSubhypergraph[`vertices`] represents the operator form for a hypergraph."];

(* SyntaxInformation *)
SyntaxInformation[Subhypergraph] =
  {"ArgumentsPattern" -> {_, _.}};

SyntaxInformation[WeakSubhypergraph] =
  {"ArgumentsPattern" -> {_, _.}};

(* Argument count *)
Subhypergraph[args___] := 0 /;
  !Developer`CheckArgumentCount[Subhypergraph[args], 1, 2] && False

WeakSubhypergraph[args___] := 0 /;
  !Developer`CheckArgumentCount[WeakSubhypergraph[args], 1, 2] && False

(* main *)
expr : Subhypergraph[arg1_, arg2_] := With[{res = Catch[subhypergraph[HoldForm @ expr, arg1, arg2]]},
  res /; res =!= $Failed
]

expr : WeakSubhypergraph[arg1_, arg2_] := With[{res = Catch[weaksubhypergraph[HoldForm @ expr, arg1, arg2]]},
  res /; res =!= $Failed
]

(* operator form *)
expr : Subhypergraph[args0___][args1___] := With[{res = Catch[subhypergraph[HoldForm @ expr][args0][args1]]},
  res /; res =!= $Failed
]

expr : WeakSubhypergraph[args0___][args1___] := With[{res = Catch[weaksubhypergraph[HoldForm @ expr][args0][args1]]},
  res /; res =!= $Failed
]

(* Helper *)
hypergraphQ = MatchQ[#, {___List}] &;

(* Normal form *)
subhypergraph[_, h_ ? hypergraphQ, vertices_List] := Select[h, SubsetQ[vertices, #] &]

weaksubhypergraph[_, h_ ? hypergraphQ, vertices_List] := Select[h, ContainsAny[#, vertices] &]

(* Incorrect arguments messages *)

(** hypergraph **)
General::invalidHypergraph =
  "The argument at position `1` in `2` is not a valid hypergraph.";

subhypergraph[expr_, h_ ? (Not @* hypergraphQ), _] :=
  (Message[Subhypergraph::invalidHypergraph, 1, HoldForm @ expr];
  Throw[$Failed])

weaksubhypergraph[expr_, h_ ? (Not @* hypergraphQ), _] :=
  (Message[WeakSubhypergraph::invalidHypergraph, 1, HoldForm @ expr];
  Throw[$Failed])

(** vertices **)
General::invalidList =
  "The argument at position `1` in `2` is not a list.";

subhypergraph[expr_, _ , v : Except[_List]] :=
  (Message[Subhypergraph::invalidList, 2, expr];
  Throw[$Failed])

weaksubhypergraph[expr_, _ , v : Except[_List]] :=
  (Message[WeakSubhypergraph::invalidList, 2, expr];
  Throw[$Failed])

(* operator form *)
subhypergraph[_][vertices_List][h_ ? hypergraphQ] := subhypergraph[None, h, vertices]

weaksubhypergraph[_][vertices_List][h_ ? hypergraphQ] := weaksubhypergraph[None, h, vertices]

(* Incorrect arguments messages *)

(** vertices **)
subhypergraph[expr_][Except[_List]][_] :=
  (Message[Subhypergraph::invalidList, {0, 1}, expr];
  Throw[$Failed])

weaksubhypergraph[expr_][Except[_List]][_] :=
  (Message[WeakSubhypergraph::invalidList, {0, 1}, expr];
  Throw[$Failed])

(** hypergraph **)
subhypergraph[expr_][args0___][h_ ? (Not @* hypergraphQ)] :=
  (Message[Subhypergraph::invalidHypergraph, 1, HoldForm @ expr];
  Throw[$Failed])

weaksubhypergraph[expr_][args0___][h_ ? (Not @* hypergraphQ)] :=
  (Message[WeakSubhypergraph::invalidHypergraph, 1, HoldForm @ expr];
  Throw[$Failed])

(** length **)
subhypergraph[expr_][args0___][args1___] /; (Length[{args1}] =!= 1) :=
  (Message[Subhypergraph::argx, HoldForm @ expr, Length @ {args1}, 1];
  Throw[$Failed])

weaksubhypergraph[expr_][args0___][args1___] /; (Length[{args1}] =!= 1) :=
  (Message[WeakSubhypergraph::argx, HoldForm @ expr, Length @ {args1}, 1];
  Throw[$Failed])
