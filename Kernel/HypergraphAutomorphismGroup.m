Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["HypergraphAutomorphismGroup"]

(* Documentation *)

SetUsage @ "
HypergraphAutomorphismGroup[e$] gives the authomorphism group of a list of hyperedges e$.
";

SyntaxInformation[HypergraphAutomorphismGroup] = {"ArgumentsPattern" -> {_}};

HypergraphAutomorphismGroup::invalidHypergraph =
  "Hypergraph `` should be a list of lists of vertices, which are not themselves lists.";

(* Implementation *)

HypergraphAutomorphismGroup[args___] := ModuleScope[
  result = Catch[hypergraphAutomorphismGroup[args]];
  result /; result =!= $Failed
];

(* Algorithm has 3 steps:
    1. First, convert the hypergraph into a normal Graph preserving structure (but adding new vertices).
    2. Then, compute the automorhpism group for that normal Graph.
    3. Finally, remove added auxiliary vertices from the spec of that group. *)

hypergraphAutomorphismGroup[e : {{Except[_List]...}...}] := With[{
    binaryGraph = Graph[Catenate[toStructurePreservingBinaryEdges /@ e]]},
  removeAuxiliaryElements[GraphAutomorphismGroup[binaryGraph], binaryGraph, e]
];

toStructurePreservingBinaryEdges[hyperedge_] := ModuleScope[
  edgeVertices = Table[edge[Unique[v, {Temporary}]], Length[hyperedge]];
  Join[
    EdgeList[PathGraph[edgeVertices, DirectedEdges -> True]],
    Thread[DirectedEdge[edgeVertices, hyperedge]]]
];

(* Note, auxiliary vertices cannot mix with original vertices in the same cycle, since auxiliary vertices have
    out-degrees of at least 1, whereas original vertices always have out-degree 0.
    Hence, here we are taking a subgroup by identifying permutations of auxiliary vertices.
    In the original group there are either auxiliary-only generators (which would be turned into empty Cycles[{}]
    and deleted), generators affecting both (which will be trimmed), and generators of original vertices only
    (which will be preserved).*)

removeAuxiliaryElements[group_, graph_, hypergraph_] := ModuleScope[
  trueVertexIndices = Position[VertexList[graph], Except[_edge], {1}, Heads -> False][[All, 1]];
  binaryGraphIndexToVertex = Thread[trueVertexIndices -> VertexList[graph][[trueVertexIndices]]];
  vertexToHypergraphIndex = Thread[vertexList[hypergraph] -> Range[Length[binaryGraphIndexToVertex]]];
  DeleteCases[group, Except[Alternatives @@ trueVertexIndices, _Integer], All] /.
    binaryGraphIndexToVertex /. vertexToHypergraphIndex /. Cycles[{}] -> Nothing
];

hypergraphAutomorphismGroup[args___] /; !Developer`CheckArgumentCount[HypergraphAutomorphismGroup[args], 1, 1] :=
  Throw[$Failed];

hypergraphAutomorphismGroup[e : Except[{{Except[_List]...}...}]] := (
  Message[HypergraphAutomorphismGroup::invalidHypergraph, e];
  Throw[$Failed];
)
