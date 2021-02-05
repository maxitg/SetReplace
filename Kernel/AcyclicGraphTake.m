Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["AcyclicGraphTake"]

PackageScope["acyclicGraphTake"]

(* Utility function to check for directed, acyclic graphs *)
dagQ[graph_] := AcyclicGraphQ[graph] && DirectedGraphQ[graph] && LoopFreeGraphQ[graph]

(* Documentation *)
SetUsage @ "
AcyclicGraphTake[gr$, vrts$] gives the intersection in graph gr$ of the in-component of the first vertex in vrts$ \
with the out-component of the second vertex in vrts$.
";

(* SyntaxInformation *)
SyntaxInformation[AcyclicGraphTake] =
  {"ArgumentsPattern" -> {_, _}};

(* Argument count *)
AcyclicGraphTake[args___] := 0 /;
  !Developer`CheckArgumentCount[AcyclicGraphTake[args], 2, 2] && False;

(* main *)
expr : AcyclicGraphTake[graph_, vertices_] := ModuleScope[
  res = Catch[acyclicGraphTake[graph, vertices]];
  If[FailureQ[res], Switch[res[[1]],
    "invalidGraph", Message[AcyclicGraphTake::invalidGraph, 1, HoldForm @ expr],
    "invalidVertexList", Message[AcyclicGraphTake::invalidVertexList, 2, HoldForm @ expr],
    "invalidVertex", Message[AcyclicGraphTake::invalidVertex, res[[2, "vertex"]], HoldForm @ expr]
  ]];
  res /; !FailureQ[res]
];

(* Normal form *)
acyclicGraphTake[graph_ ? dagQ, {startVertex_, endVertex_}] /;
    VertexQ[graph, startVertex] && VertexQ[graph, endVertex] := ModuleScope[
  Subgraph[graph, Intersection[
    VertexInComponent[graph, endVertex], VertexOutComponent[graph, startVertex]]]
]

(* Incorrect arguments messages *)
General::invalidGraph = "The argument at position `1` in `2` should be a directed, acyclic graph.";
acyclicGraphTake[graph_ ? (Not @* dagQ), _] :=
  Throw[Failure["invalidGraph", <||>]];

General::invalidVertexList = "The argument at position `1` in `2` should be a list of two vertices.";
acyclicGraphTake[_, Except[{_, _}]] :=
  Throw[Failure["invalidVertexList", <||>]];

General::invalidVertex = "The argument `1` is not a valid vertex in `2`.";
acyclicGraphTake[graph_Graph, {startVertex_, endVertex_}] /;
    (Not @ (VertexQ[graph, startVertex] && VertexQ[graph, endVertex])) :=
  Throw[Failure["invalidVertex", <|"vertex" -> If[VertexQ[graph, startVertex], endVertex, startVertex]|>]];
