Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["IndexHypergraph"]

(* Documentation *)

SetUsage @ "
IndexHypergraph[hg$] replaces the vertices of the hypergraph hg$ by its vertex indices.
IndexHypergraph[hg$, r$] replaces the vertices with integers r$, r$ + 1, $$.
";

(* SyntaxInformation *)
SyntaxInformation[IndexHypergraph] =
  {"ArgumentsPattern" -> {_, _.}};

(* Argument count *)
IndexHypergraph[args___] := 0 /;
  !Developer`CheckArgumentCount[IndexHypergraph[args], 1, 2] && False;

(* main *)
expr : IndexHypergraph[hgraph_, start : _ : 1] := ModuleScope[
  res = Catch[indexHypergraph[HoldForm @ expr, hgraph, start]];
  res /; res =!= $Failed
];

(* Normal form *)
indexHypergraph[_, hgraph_ ? hypergraphQ, start : _Integer ? IntegerQ] := ModuleScope[
  vertices = vertexList @ hgraph;
  vertexIndices = Range[0, Length[vertices] - 1] + start;
  Replace[hgraph, Thread[vertices -> vertexIndices], {2}]
];

(* Incorrect arguments messages *)
indexHypergraph[expr_, hgraph_ ? (Not @* hypergraphQ), ___] :=
  (Message[IndexHypergraph::invalidHypergraph, 1, HoldForm @ expr];
  Throw[$Failed]);

indexHypergraph[expr_, _ , _] :=
  (Message[IndexHypergraph::int, expr, 2];
  Throw[$Failed]);
