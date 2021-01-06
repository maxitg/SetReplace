Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["IsomorphicHypergraphQ"]

(* Documentation *)

SetUsage @ "
IsomorphicHypergraphQ[h$1, h$2] yields True if the hypergraphs h$1 and h$2 are isomorphic, and False otherwise.
";

(* SyntaxInformation *)
SyntaxInformation[IsomorphicHypergraphQ] =
  {"ArgumentsPattern" -> {_, _}};

(* Argument count *)
IsomorphicHypergraphQ[args___] := 0 /;
  !Developer`CheckArgumentCount[IsomorphicHypergraphQ[args], 2, 2] && False;

(* main *)
expr : IsomorphicHypergraphQ[hgraph1_, hgraph2_] := ModuleScope[
  res = Catch[isomorphicHypergraphQ[HoldForm @ expr, hgraph1, hgraph2]];
  res /; res =!= $Failed
];

(* Normal form *)
isomorphicHypergraphQ[_, hgraph1_ ? hypergraphQ, hgraph2_ ? hypergraphQ] := With[{
    graph1 = HypergraphToGraph[hgraph1, "StructurePreserving"],
    graph2 = HypergraphToGraph[hgraph2, "StructurePreserving"]},
  IsomorphicGraphQ[graph1, graph2]
];

(* Incorrect arguments messages *)
isomorphicHypergraphQ[expr_, _ ? (Not @* hypergraphQ), _] :=
  (Message[IsomorphicHypergraphQ::invalidHypergraph, 1, HoldForm @ expr];
  Throw[$Failed]);

isomorphicHypergraphQ[expr_, _, _? (Not @* hypergraphQ)] :=
  (Message[IsomorphicHypergraphQ::invalidHypergraph, 2, HoldForm @ expr];
  Throw[$Failed])
