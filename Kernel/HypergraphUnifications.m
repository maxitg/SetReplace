Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["HypergraphUnifications"]

(* Documentation *)

SetUsage @ "
HypergraphUnifications[e$1, e$2] yields a list of edge pairings to hypergraphs \
containing both e$1 and e$2 as rule input matches.
";

SyntaxInformation[HypergraphUnifications] = {"ArgumentsPattern" -> {_, _}};

HypergraphUnifications::hypergraphNotList = "Hypergraph `` should be a List.";

HypergraphUnifications::edgeNotList = "Hypergraph edge `` should be a List.";

(* Implementation *)

HypergraphUnifications[args___] := ModuleScope[
  result = Catch[hypergraphUnifications[args]];
  result /; result =!= $Failed
];

hypergraphUnifications[args___] /; !Developer`CheckArgumentCount[HypergraphUnifications[args], 2, 2] := Throw[$Failed];

hypergraphUnifications[e1_List, e2_List] := With[{
    uniqueE1 = Map[$$1, e1, {2}], uniqueE2 = Map[$$2, e2, {2}]},
  findUnion[uniqueE1, uniqueE2, ##] & @@@
    Replace[
      Reap[findRemainingOverlaps[uniqueE1, uniqueE2, emptyEdgeMatch[], emptyVertexMatch[]]][[2]],
      {overlaps_} -> overlaps]
];

hypergraphUnifications[e : Except[_List], _] := hypergraphNotListFail[e];

hypergraphUnifications[_, e : Except[_List]] := hypergraphNotListFail[e];

hypergraphNotListFail[e_] := (
  Message[HypergraphUnifications::hypergraphNotList, e];
  Throw[$Failed]
);

findRemainingOverlaps[e1_, e2_, edgeMatch_, vertexMatch_] :=
  Outer[(tryMatch[e1, e2, edgeMatch, vertexMatch, #1, #2]) &, ##] & @@
    Range /@ Length /@ {e1, e2};

tryMatch[e1_, e2_, edgeMatch_, vertexMatch_, nextIndex1_, nextIndex2_] /;
      matchQ[e1[[nextIndex1]], e2[[nextIndex2]]] &&
      !edgesAlreadyUsedQ[edgeMatch, nextIndex1, nextIndex2] &&
      !backtrackingMatchQ[edgeMatch, nextIndex1, nextIndex2] := With[{
    newEdgeMatch = combinedEdgeMatch[edgeMatch, nextIndex1, nextIndex2],
    newVertexMatch = combinedVertexMatch[vertexMatch, e1[[nextIndex1]], e2[[nextIndex2]]]},
  Sow[{newEdgeMatch, Graph[newVertexMatch, VertexLabels -> Automatic]}];
  findRemainingOverlaps[e1, e2, newEdgeMatch, newVertexMatch];
];

matchQ[edge1_List, edge2_List] /; Length[edge1] == Length[edge2] := True;

matchQ[edge : Except[_List], _] := edgeNotListFail[edge];

matchQ[_, edge : Except[_List]] := edgeNotListFail[edge];

edgeNotListFail[edge_] := (
  Message[HypergraphUnifications::edgeNotList, edge];
  Throw[$Failed]
);

edgesAlreadyUsedQ[edgeMatch_, nextIndex1_, nextIndex2_] :=
  MemberQ[Keys[edgeMatch], nextIndex1] || MemberQ[Values[edgeMatch], nextIndex2];

backtrackingMatchQ[<||>, nextIndex1_, nextIndex2_] := False;

backtrackingMatchQ[edgeMatch_, nextIndex1_, nextIndex2_] /; nextIndex1 < Last[Keys[edgeMatch]] := True;

backtrackingMatchQ[edgeMatch_, nextIndex1_, nextIndex2_] /;
    nextIndex1 == Last[Keys[edgeMatch]] && nextIndex2 < Last[Values[edgeMatch]] := True;

backtrackingMatchQ[__] := False;

emptyEdgeMatch[] := <||>;

combinedEdgeMatch[match_, newIndex1_, newIndex2_] := Append[match, <|newIndex1 -> newIndex2|>];

(* every time we identify two vertices we add an edge, so that we consider each connected component to be identical *)

emptyVertexMatch[] := Graph[{}];

combinedVertexMatch[match_, newEdge1_, newEdge2_] := EdgeAdd[match, Thread[UndirectedEdge[newEdge1, newEdge2]]];

vertexIdentificationRules[match_] :=
  Catenate[Function[{edge}, # -> edge[[1]] & /@ edge[[2 ;;]]] /@ ConnectedComponents[match]];

findUnion[e1_, e2_, edgeMatch_, vertexMatch_] := With[{
    uniqueE1Edges = Complement[Range[Length[e1]], Keys[edgeMatch]],
    uniqueE2Edges = Complement[Range[Length[e2]], Values[edgeMatch]]}, {
  IndexHypergraph[Replace[
    Join[e1[[uniqueE1Edges]], e2[[uniqueE2Edges]], e1[[Keys[edgeMatch]]]],
    vertexIdentificationRules[vertexMatch],
    {2}]],
  Association @ Sort @ Join[
    Thread[uniqueE1Edges -> Range[Length[uniqueE1Edges]]],
    Thread[Keys[edgeMatch] -> Range[Length[edgeMatch]] + Length[uniqueE1Edges] + Length[uniqueE2Edges]]],
  Association @ Sort @ Join[
    Thread[uniqueE2Edges -> Range[Length[uniqueE2Edges]] + Length[uniqueE1Edges]],
    Thread[Values[edgeMatch] -> Range[Length[edgeMatch]] + Length[uniqueE1Edges] + Length[uniqueE2Edges]]]
}];
