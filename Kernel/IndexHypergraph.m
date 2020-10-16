Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["IndexHypergraph"]

(* Documentation *)
IndexHypergraph::usage = usageString[
  "IndexHypergraph[`h`] replaces the vertices of the hypergraph `h` by its vertex indices.",
  "\n",
  "IndexHypergraph[`h`, `r`] replaces the vertices with integers `r`, `r + 1`, \[Ellipsis]."];

(* SyntaxInformation *)
SyntaxInformation[IndexHypergraph] =
  {"ArgumentsPattern" -> {_, _.}};

(* Argument count *)
IndexHypergraph[args___] := 0 /;
  !Developer`CheckArgumentCount[IndexHypergraph[args], 1, 2] && False

(* main *)
expr : IndexHypergraph[hgraph_, r : _ : 1] := ModuleScope[
  res = Catch[indexHypergraph[HoldForm @ expr, hgraph, r]];
  res /; res =!= $Failed
]

(* Normal form *)
indexHypergraph[_, hgraph_ ? hypergraphQ, start : _Integer ? IntegerQ] := ModuleScope[
  vertices = vertexList @ hgraph;
  vertexIndices = Range[0, Length[vertices] - 1] + start;
  Replace[hgraph, Thread[vertices -> vertexIndices], {2}]
]

(* Incorrect arguments messages *)
indexHypergraph[expr_, hgraph_ ? (Not @* hypergraphQ), ___] :=
  (Message[IndexHypergraph::invalidHypergraph, 1, HoldForm @ expr];
  Throw[$Failed])

indexHypergraph[expr_, _ , r_] :=
  (Message[IndexHypergraph::int, expr, 2];
  Throw[$Failed])
