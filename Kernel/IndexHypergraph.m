Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["IndexHypergraph"]

(* Documentation *)

SetUsage @ "
IndexHypergraph[hypergraph$] replaces the vertices of hypergraph$ by its vertex indices.
IndexHypergraph[hypergraph$, startIndex$] replaces the vertices with integers startIndex$, startIndex$ + 1, $$.
";

(* SyntaxInformation *)
SyntaxInformation[IndexHypergraph] = {"ArgumentsPattern" -> {hypergraph_, startIndex_.}};

(* Argument count *)
IndexHypergraph[args___] := 0 /;
  !Developer`CheckArgumentCount[IndexHypergraph[args], 1, 2] && False;

(* main *)
expr : IndexHypergraph[hypergraph_, startIndex : _ : 1] := ModuleScope[
  res = Catch[indexHypergraph[HoldForm @ expr, hypergraph, startIndex]];
  res /; res =!= $Failed
];

(* Normal form *)
indexHypergraph[_, hypergraph_ ? hypergraphQ, startIndex : _Integer ? IntegerQ] := ModuleScope[
  vertices = vertexList @ hypergraph;
  vertexIndices = Range[0, Length[vertices] - 1] + startIndex;
  Replace[hypergraph, Thread[vertices -> vertexIndices], {2}]
];

(* Incorrect arguments messages *)
indexHypergraph[expr_, hypergraph_ ? (Not @* hypergraphQ), ___] :=
  (Message[IndexHypergraph::invalidHypergraph, 1, HoldForm @ expr];
  Throw[$Failed]);

indexHypergraph[expr_, _ , _] :=
  (Message[IndexHypergraph::int, expr, 2];
  Throw[$Failed]);
