Package["SetReplace`"]

PackageExport["HypergraphAutomorphismGroup"]

(* Documentation *)

HypergraphAutomorphismGroup::usage = usageString[
  "HypergraphAutomorphismGroup[`e`] gives the authomorphism group of a list of hyperedges `e`."];

SyntaxInformation[HypergraphAutomorphismGroup] = {"ArgumentsPattern" -> {_}};

(* Implementation *)

HypergraphAutomorphismGroup[e : {{Except[_List]...}...}] := With[{
    binaryGraph = Graph[Catenate[toStructurePreservingBinaryEdges /@ e]]},
  removeAuxiliaryElements[GraphAutomorphismGroup[binaryGraph], binaryGraph, e]
]

toStructurePreservingBinaryEdges[hyperedge_] := Module[{
    edgeVertices = Table[edge[Unique[v, {Temporary}]], Length[hyperedge]]},
  Join[
    EdgeList[PathGraph[edgeVertices, DirectedEdges -> True]],
    Thread[DirectedEdge[edgeVertices, hyperedge]]]
]

removeAuxiliaryElements[group_, graph_, hypergraph_] := Module[{
    trueVertexIndices, binaryGraphIndexToVertex, vertexToHypergraphIndex},
  trueVertexIndices = Position[VertexList[graph], Except[_edge], {1}, Heads -> False][[All, 1]];
  binaryGraphIndexToVertex = Thread[trueVertexIndices -> VertexList[graph][[trueVertexIndices]]];
  vertexToHypergraphIndex = Thread[vertexList[hypergraph] -> Range[Length[binaryGraphIndexToVertex]]];
  DeleteCases[group, Except[Alternatives @@ trueVertexIndices, _Integer], All] /.
    binaryGraphIndexToVertex /. vertexToHypergraphIndex /. Cycles[{}] -> Nothing
]
