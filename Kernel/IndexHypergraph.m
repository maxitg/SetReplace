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

(* main *)
expr : IndexHypergraph[args___] /; CheckArguments[IndexHypergraph[args], {1, 2}] :=
  With[{res = Catch[indexHypergraph[args], _ ? FailureQ, message[IndexHypergraph, #, <|"expr" -> HoldForm[expr]|>] &]},
    res /; !FailureQ[res]
  ];

(* Normal form *)
indexHypergraph[hg_] := indexHypergraph[hg, 1];

indexHypergraph[hypergraph_ ? HypergraphQ, startIndex : _Integer ? IntegerQ] := ModuleScope[
  vertices = Sort @ VertexList[hypergraph];
  vertexIndices = Range[0, Length[vertices] - 1] + startIndex;
  Hypergraph[Replace[EdgeList[hypergraph], Thread[vertices -> vertexIndices], {2}],
             HypergraphSymmetry[hypergraph]]
];

indexHypergraph[hyperedges : {___List}, startIndex : _Integer ? IntegerQ] :=
  Normal[indexHypergraph[Hypergraph[hyperedges], startIndex]];

(* Incorrect arguments messages *)
indexHypergraph[Except[(_ ? HypergraphQ) | {___List}], ___] :=
  throw[Failure["invalidHypergraph", <|"pos" -> 1|>]];

declareMessage[IndexHypergraph::invalidIndex,
               "Integer expected at position 2 in `expr`."];

indexHypergraph[_ , _] :=
  throw[Failure["invalidIndex", <||>]];
