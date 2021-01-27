Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["HypergraphToGraph"]

(* Documentation *)

SetUsage @ "
HypergraphToGraph[hg$, method$] uses method$ to convert a hypergraph hg$ to a Graph.
";

(* Options *)
Options[HypergraphToGraph] = Options[Graph];

(* SyntaxInformation *)
SyntaxInformation[HypergraphToGraph] = {
  "ArgumentsPattern" -> {hypergraph_, method_, OptionsPattern[]},
  "OptionNames" -> Options[HypergraphToGraph][[All, 1]]};

(* Methods *)
$validMethods = {
  "DirectedDistancePreserving",
  "StructurePreserving",
  "UndirectedDistancePreserving"};

(* Error messages *)
HypergraphToGraph::invalidMethod = StringJoin[{
  "The argument at position 2 in `1` is not ",
  listToSentence @ $validMethods,
  "."}];

(* Autocompletition *)
 With[{methods = $validMethods},
   FE`Evaluate[FEPrivate`AddSpecialArgCompletion["HypergraphToGraph" -> {0, methods}]]];

(* Argument count *)
HypergraphToGraph[args___] := 0 /;
  !Developer`CheckArgumentCount[HypergraphToGraph[args], 2, 2] && False;

(* main *)
expr : HypergraphToGraph[
      hgraph_,
      method_,
      opts : OptionsPattern[]] /; recognizedOptionsQ[expr, HypergraphToGraph, {opts}] :=
  ModuleScope[
    res = Catch[hypergraphToGraph[HoldForm @ expr, hgraph, method, opts]];
    res /; res =!= $Failed
  ];

(* helper *)
graphJoin[{}, opts___] := Graph[{}, opts];
graphJoin[graphs : {__Graph}, opts___] := With[{
    vertices = Sort @ Union @ Catenate[VertexList /@ graphs],
    edges = Sort @ Catenate[EdgeList /@ graphs]},
  Graph[vertices, edges, opts]
];

(* Distance preserving *)
toDistancePreserving[{directedness_, hyperedge_}, opts___] :=
  Graph[hyperedge, directedness @@@ Subsets[hyperedge, {2}], opts];

hypergraphToGraph[
    _,
    hgraph_ ? hypergraphQ,
    method : "DirectedDistancePreserving" | "UndirectedDistancePreserving",
    opts : OptionsPattern[]] :=
  With[{directedness = Switch[method, "DirectedDistancePreserving", DirectedEdge, _, UndirectedEdge]},
    graphJoin[
      toDistancePreserving[{directedness, #}, opts] & /@ hgraph,
      opts]
  ];

(* Structure preserving *)
toStructurePreserving[{hyperedgeIndex_, {}}, opts___] :=
  Graph[{{"Hyperedge", hyperedgeIndex, 0}}, {}, opts];
toStructurePreserving[{hyperedgeIndex_, hyperedge_}, opts___] := ModuleScope[
  hyperedgeVertices = Table[
    {"Hyperedge", hyperedgeIndex, vertexPositionIndex},
    {vertexPositionIndex, 1, Length @ hyperedge}];
  vertexVertices = {"Vertex", #} & /@ hyperedge;
  Graph[
    hyperedgeVertices,
    Join[
      DirectedEdge @@@ Partition[hyperedgeVertices, 2, 1],
      Thread[DirectedEdge[hyperedgeVertices, vertexVertices]]],
    opts]
];

hypergraphToGraph[_, hgraph_ ? hypergraphQ, "StructurePreserving", opts : OptionsPattern[]] :=
  With[{
      hyperedgeGraphs = MapIndexed[toStructurePreserving[{#2[[1]], #1}, opts] &, hgraph]},
    graphJoin[
      hyperedgeGraphs,
      VertexStyle -> Replace[OptionValue[Graph, {opts}, VertexStyle],
        Automatic -> {{"Hyperedge", _, _} -> style[$lightTheme][$structurePreservingHyperedgeVertexStyle]}],
      EdgeStyle -> Replace[OptionValue[Graph, {opts}, EdgeStyle],
        Automatic -> {Rule[
          DirectedEdge[{"Hyperedge", _, _}, {"Hyperedge", _, _}],
          style[$lightTheme][$structurePreservingHyperedgeToHyperedgeEdgeStyle]]}],
      opts]
  ];

(* Incorrect arguments messages *)
hypergraphToGraph[expr_, hgraph_ ? (Not @* hypergraphQ), ___] :=
  (Message[HypergraphToGraph::invalidHypergraph, 1, HoldForm @ expr];
  Throw[$Failed]);

hypergraphToGraph[expr_, _, method_, ___] /; !MemberQ[$validMethods, method] :=
  (Message[HypergraphToGraph::invalidMethod, HoldForm @ expr];
  Throw[$Failed]);
