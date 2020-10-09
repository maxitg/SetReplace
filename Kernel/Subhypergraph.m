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
expr : Subhypergraph[arg1_, arg2_] := With[{res = Catch[iSubhypergraph[HoldForm @ expr, arg1, arg2]]},
	res /; res =!= $Failed
]

expr : WeakSubhypergraph[arg1_, arg2_] := With[{res = Catch[iWeakSubhypergraph[HoldForm @ expr, arg1, arg2]]},
	res /; res =!= $Failed
]

(* operator form *)
expr : Subhypergraph[args0___][args1___] := With[{res = Catch[iSubhypergraph[HoldForm @ expr][args0][args1]]},
	res /; res =!= $Failed
]

expr : WeakSubhypergraph[args0___][args1___] := With[{res = Catch[iWeakSubhypergraph[HoldForm @ expr][args0][args1]]},
	res /; res =!= $Failed
]

(* Helper *)
hypergraphQ = MatchQ[#, {___List}] &;

(* Normal form *)
iSubhypergraph[_, h_ ? hypergraphQ, vertices_List] := Select[h, SubsetQ[vertices, #] &]

iWeakSubhypergraph[_, h_ ? hypergraphQ, vertices_List] := Select[h, ContainsAny[#, vertices] &]

(* Incorrect arguments messages *)

(** hypergraph **)
General::invalidHypergraph =
  "The argument at position `1` in `2` is not a valid hypergraph.";

iSubhypergraph[expr_, h_ ? (Not @* hypergraphQ), _] :=
  (Message[Subhypergraph::invalidHypergraph, 1, HoldForm @ expr];
  Throw[$Failed])

iWeakSubhypergraph[expr_, h_ ? (Not @* hypergraphQ), _] :=
  (Message[WeakSubhypergraph::invalidHypergraph, 1, HoldForm @ expr];
  Throw[$Failed])

(** vertices **)
General::invalidVertexList =
  "The argument at position `1` in `2` is not a valid hypergraph.";

iSubhypergraph[_, _ , v : Except[_List]] :=
	(Message[Subhypergraph::invl, 2];
	Throw[$Failed])

iWeakSubhypergraph[_, _ , v : Except[_List]] :=
	(Message[WeakSubhypergraph::invl, 2];
	Throw[$Failed])

(* operator form *)
iSubhypergraph[_][vertices_List][h_ ? hypergraphQ] := iSubhypergraph[None, h, vertices]

iWeakSubhypergraph[_][vertices_List][h_ ? hypergraphQ] := iWeakSubhypergraph[None, h, vertices]

(* The operator form of Select does not check that the zeroth argument is valid, it just returns {} *)
iSubhypergraph[_][_][h_ ? hypergraphQ] := {}

iWeakSubhypergraph[_][_][h_ ? hypergraphQ] := {}

(* Incorrect arguments messages *)

(** hypergraph **)
iSubhypergraph[expr_][args0___][h_ ? (Not @* hypergraphQ)] :=
  (Message[Subhypergraph::invalidHypergraph, 1, HoldForm @ expr];
  Throw[$Failed])

iWeakSubhypergraph[expr_][args0___][h_ ? (Not @* hypergraphQ)] :=
  (Message[WeakSubhypergraph::invalidHypergraph, 1, HoldForm @ expr];
  Throw[$Failed])

(** length **)
iSubhypergraph[expr_][args0___][args1___] /; (Length[{args1}] =!= 1) :=
  (Message[Subhypergraph::argx, HoldForm @ expr, Length @ {args1}, 1];
  Throw[$Failed])

iWeakSubhypergraph[expr_][args0___][args1___] /; (Length[{args1}] =!= 1) :=
  (Message[WeakSubhypergraph::argx, HoldForm @ expr, Length @ {args1}, 1];
  Throw[$Failed])
