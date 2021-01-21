Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["AcyclicGraphTake"]

(* SyntaxInformation *)
SyntaxInformation[AcyclicGraphTake] =
  {"ArgumentsPattern" -> {_, _}};

(* Argument count *)
AcyclicGraphTake[args___] := 0 /;
  !Developer`CheckArgumentCount[AcyclicGraphTake[args], 2, 2] && False;

(* main *)
expr : AcyclicGraphTake[graph_, vertices_] := ModuleScope[
  res = Catch[acyclicGraphTake[HoldForm @ expr, graph, vertices]];
  res /; res =!= $Failed
];

(* Normal form *)
acyclicGraphTake[_, graph_ ? (AcyclicGraphQ[#] && DirectedGraphQ[#] &), {startVertex_, endVertex_}] /;
    VertexQ[graph, startVertex] && VertexQ[graph, endVertex] := ModuleScope[
  Subgraph[graph, Intersection[
    VertexInComponent[graph, endVertex], VertexOutComponent[graph, startVertex]]]
]

(* Incorrect arguments messages *)
AcyclicGraphTake::invalidGraph = "The argument at position `1` in `2` should be a directed, acyclic graph.";
acyclicGraphTake[expr_, graph_ ? (Not @* (AcyclicGraphQ[#] && DirectedGraphQ[#] &)), _] :=
  (Message[AcyclicGraphTake::invalidGraph, 1, HoldForm @ expr];
  Throw[$Failed]);

AcyclicGraphTake::invalidVertexList = "The argument at position `1` in `2` should be a list of two vertices.";
acyclicGraphTake[expr_, _, Except[{_, _}]] :=
  (Message[AcyclicGraphTake::invalidVertexList, 2, HoldForm @ expr];
  Throw[$Failed]);

AcyclicGraphTake::invalidVertex = "The argument `1` is not a valid vertex in `2`.";
acyclicGraphTake[expr_, graph_Graph, {startVertex_, endVertex_}] /;
    (Not @ (VertexQ[graph, startVertex] && VertexQ[graph, endVertex])) :=
  (Message[AcyclicGraphTake::invalidVertex, If[VertexQ[graph, startVertex], endVertex, startVertex], HoldForm @ expr];
  Throw[$Failed]);
  