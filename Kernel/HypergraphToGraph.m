Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["HypergraphToGraph"]

(* Documentation *)
HypergraphToGraph::usage = usageString[
  "HypergraphToGraph[`hg`, `method`] uses `method` to convert a hypergraph `hg` to a Graph."];

(* Options *)
Options[HypergraphToGraph] = Options[Graph];

(* SyntaxInformation *)
SyntaxInformation[HypergraphToGraph] = {
  "ArgumentsPattern" -> {_, _, OptionsPattern[]},
  "OptionNames" -> Options[HypergraphToGraph][[All, 1]]};

(* Methods *)
$validMethods = {
  "DirectedDistancePreserving",
  "StructurePreserving",
  "UndirectedDistancePreserving"};

(* Error messages *)
HypergraphToGraph::invalidMethod = StringJoin[{
  "The argument at position 2 in `1` is not ",
  Replace[ToString[#, InputForm] & /@ $validMethods, {{a__, b_} :> {Riffle[{a}, ", "], " or ", b}}],
  "."}];

(* Autocompletition *)
 With[{methods = $validMethods},
   FE`Evaluate[FEPrivate`AddSpecialArgCompletion["HypergraphToGraph" -> {0, methods}]]];

(* Argument count *)
HypergraphToGraph[args___] := 0 /;
  !Developer`CheckArgumentCount[HypergraphToGraph[args], 2, 2] && False

(* main *)
expr : HypergraphToGraph[
      hgraph_,
      method_,
      opts : OptionsPattern[]] /; recognizedOptionsQ[expr, HypergraphToGraph, {opts}] :=
  ModuleScope[
    res = Catch[hypergraphToGraph[HoldForm @ expr, hgraph, method, opts]];
    res /; res =!= $Failed
  ]

(* helper *)
graphJoin[{}, opts___] := Graph[{}, opts]
graphJoin[graphs : {__Graph}, opts___] := With[{
    vertices = Sort @ Union @ Catenate[VertexList /@ graphs],
    edges = Sort@ Catenate[EdgeList /@ graphs]},
  Graph[vertices, edges, opts]
]

(* Directed distance preserving *)
hyperedgeToGraph$DirectedDistancePreserving[hyperedge_, opts___] :=
  Graph[hyperedge, DirectedEdge @@@ Subsets[hyperedge, {2}], opts]

hypergraphToGraph[_, hgraph_ ? hypergraphQ, "DirectedDistancePreserving", opts : OptionsPattern[]] :=
  With[{hyperedgeGraphs = hyperedgeToGraph$DirectedDistancePreserving[#, opts] & /@ hgraph},
    graphJoin[hyperedgeGraphs, opts]
  ]

(* Structure preserving *)
hyperedgeToGraph$StructurePreserving[hyperedge_, opts___] := With[{
    edgeVertices = Table[Unique["v", {Temporary}], Length @ hyperedge]},
  Graph[
    Annotation[#, "AuxiliaryQ" -> True] & /@ edgeVertices,
    Join[
      DirectedEdge @@@ Partition[edgeVertices, 2, 1],
      Thread[DirectedEdge[edgeVertices, hyperedge]]],
    opts]
]

hypergraphToGraph[_, hgraph_ ? hypergraphQ, "StructurePreserving", opts : OptionsPattern[]] :=
  ModuleScope[
    hyperedgeGraphs = hyperedgeToGraph$StructurePreserving[#, opts] & /@ hgraph;
    annotationRules = Replace[
      DeleteCases[AnnotationValue[#, AnnotationRules] & /@ hyperedgeGraphs, $Failed],
      {list : {__List} :> (AnnotationRules -> Catenate[list]), _ -> Sequence[]}];
    hgraphVertexPatt = Alternatives @@ (vertexList @ hgraph);
    graphJoin[
      hyperedgeGraphs,
      annotationRules,
      opts,
      VertexStyle -> {Except[hgraphVertexPatt] -> LightBlue},
      EdgeStyle -> {DirectedEdge[Except[hgraphVertexPatt], Except[hgraphVertexPatt]] -> Dashed}]
  ]

(* Undirected distance preserving:
   Each hyperedge is converted to a complete (undirected graph) *)
hyperedgeToGraph$UndirectedDistancePreserving[hyperedge_, opts___] :=
  Graph[hyperedge, UndirectedEdge @@@ Subsets[hyperedge, {2}], opts]

hypergraphToGraph[_, hgraph_ ? hypergraphQ, "UndirectedDistancePreserving", opts : OptionsPattern[]] :=
  With[{hyperedgeGraphs = hyperedgeToGraph$UndirectedDistancePreserving[#, opts] & /@ hgraph},
    graphJoin[hyperedgeGraphs, opts]
  ]

(* Incorrect arguments messages *)
hypergraphToGraph[expr_, hgraph_ ? (Not @* hypergraphQ), ___] :=
  (Message[HypergraphToGraph::invalidHypergraph, 1, HoldForm @ expr];
  Throw[$Failed])

hypergraphToGraph[expr_, _, method_, ___] /; !MemberQ[$validMethods, method] :=
  (Message[HypergraphToGraph::invalidMethod, HoldForm @ expr];
  Throw[$Failed])
