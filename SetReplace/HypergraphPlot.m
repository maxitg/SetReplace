Package["SetReplace`"]

PackageExport["HypergraphPlot"]

(* Documentation *)

HypergraphPlot::usage = usageString[
	"HypergraphPlot[`s`, `opts`] plots a list of vertex lists `s` as a hypergraph."]

SyntaxInformation[HypergraphPlot] = {"ArgumentsPattern" -> {_, OptionsPattern[]}};

Options[HypergraphPlot] = Join[{
	"EdgeType" -> "Ordered",
	GraphLayout -> "SpringElectricalEmbedding"},
	Options[Graphics]];

$edgeTypes = {"Ordered", "CyclicClosed", "CyclicOpen"};
$graphLayouts = {"SpringElectricalEmbedding"};

(* Messages *)

HypergraphPlot::notImplemented =
	"Not implemented: `1`.";

HypergraphPlot::invalidEdges =
	"First argument of HypergraphPlot must be list of lists, where elements represent vertices.";

HypergraphPlot::invalidFiniteOption =
	"Value `2` of option `1` should be one of `3`.";

(* Evaluation *)

func : HypergraphPlot[args___] := Module[{result = hypergraphPlot$parse[args]},
	If[Head[result] === hypergraphPlot$failing,
		Message[HypergraphPlot::notImplemented, Defer[func]];
		result = $Failed];
	result /; result =!= $Failed
]

(* Arguments parsing *)

hypergraphPlot$parse[args___] /; !Developer`CheckArgumentCount[HypergraphPlot[args], 1, 1] := $Failed

hypergraphPlot$parse[edges : Except[{___List}], o : OptionsPattern[]] := (
	Message[HypergraphPlot::invalidEdges];
	$Failed
)

hypergraphPlot$parse[args : PatternSequence[edges_, o : OptionsPattern[]]] := With[{
		unknownOptions = Complement @@ {{o}, Options[HypergraphPlot]}[[All, All, 1]]},
	If[Length[unknownOptions] > 0,
		Message[HypergraphPlot::optx, unknownOptions[[1]], Defer[HypergraphPlot[args]]]
	];
	$Failed /; Length[unknownOptions] > 0
]

hypergraphPlot$parse[edges_, o : OptionsPattern[]] /;
		! (And @@ (supportedOptionQ[HypergraphPlot, ##, {o}] & @@@ {
			{"EdgeType", $edgeTypes},
			{GraphLayout, $graphLayouts}})) :=
	$Failed

hypergraphPlot$parse[edges : {___List}, o : OptionsPattern[]] :=
	hypergraphPlot[edges, ##, FilterRules[{o}, Options[Graphics]]] & @@
		(OptionValue[HypergraphPlot, {o}, #] & /@ {"EdgeType", GraphLayout})

supportedOptionQ[func_, optionToCheck_, validValues_, opts_] := Module[{value, supportedQ},
	value = OptionValue[func, {opts}, optionToCheck];
	supportedQ = MemberQ[validValues, value];
	If[!supportedQ,
		Message[MessageName[func, "invalidFiniteOption"], optionToCheck, value, validValues]
	];
	supportedQ
]

(* Implementation *)

hypergraphPlot[edges_, edgeType_, layout_, graphicsOptions_] :=
	Show[drawEmbedding @ hypergraphEmbedding[edgeType, layout] @ edges, graphicsOptions]

(** hypergraphEmbedding produces an embedding of vertices and edges. The format is {vertices, edges},
			where both vertices and edges are associations of the form <|vertex -> {graphicsPrimitive, ...}, ...|>,
			where graphicsPrimitive is either a Point, a Line, or a Polygon. **)

hypergraphEmbedding[edgeType_, layout : "SpringElectricalEmbedding"][edges_] := Module[{
		vertices, vertexEmbeddingNormalEdges, edgeEmbeddingNormalEdges},
	vertices = Union[Flatten[edges]];
	vertexEmbeddingNormalEdges = toNormalEdges[edgeType] /@ edges;
	edgeEmbeddingNormalEdges = If[edgeType === "CyclicOpen", Most /@ # &, Identity][vertexEmbeddingNormalEdges];
	normalToHypergraphEmbedding[
		edges,
		edgeEmbeddingNormalEdges,
		graphEmbedding[
			vertices,
			Catenate[vertexEmbeddingNormalEdges],
			Catenate[edgeEmbeddingNormalEdges],
			layout]]
]

toNormalEdges["Ordered"][hyperedge_] :=
	DirectedEdge @@@ Partition[hyperedge, 2, 1]

toNormalEdges["CyclicOpen" | "CyclicClosed"][hyperedge_] :=
	DirectedEdge @@@ Append[Partition[hyperedge, 2, 1], hyperedge[[{-1, 1}]]]

graphEmbedding[vertices_, edges_, edges_, layout_, coordinates_ : Automatic] := Reap[
	GraphPlot[
		Graph[vertices, edges],
		GraphLayout -> layout,
		VertexCoordinates -> coordinates,
		VertexShapeFunction -> (Sow[#2 -> #, "v"] &),
		EdgeShapeFunction -> (Sow[#2 -> #, "e"] &)],
	{"v", "e"}
][[2, All, 1]]

graphEmbedding[vertices_, vertexEmbeddingEdges_, edgeEmbeddingEdges_, layout_] := Module[{embedding},
	embedding = GraphEmbedding[Graph[vertices, vertexEmbeddingEdges], layout];
	graphEmbedding[vertices, edgeEmbeddingEdges, edgeEmbeddingEdges, layout, embedding]
]

normalToHypergraphEmbedding[edges_, normalEdges_, normalEmbedding_] := Module[{
		vertexEmbedding, edgeEmbedding, normalEdgeToLinePoints, normalEdgeToHyperedge, indexedHyperedges, lineSegments},
	vertexEmbedding = #[[1]] -> {Point[#[[2]]]} & /@ normalEmbedding[[1]];

	normalEdgeToLinePoints = Sort[If[Head[#] === DirectedEdge, #, Sort[#]] & /@ normalEmbedding[[2]]];
	(* vertices in the normalEdges should already be sorted by now. *)
	normalEdgeToHyperedge = Sort[Catenate[MapThread[Thread[#2 -> Defer[#]] &, {edges, normalEdges}]]];

	indexedHyperedges = MapIndexed[{#, #2} &, normalEdgeToHyperedge[[All, 2]]];
	lineSegments = Line /@ normalEdgeToLinePoints[[All, 2]];

	edgeEmbedding =
		#[[1, 1]] -> #[[2]] & /@ Normal[Merge[Thread[indexedHyperedges -> lineSegments], Identity]];

	{vertexEmbedding, edgeEmbedding}
]

drawEmbedding[embedding_] := Graphics[embedding[[{2, 1}, All, 2]] /. {
	Point[p_] :> {Opacity[.7], Disk[p, 0.03]},
	Polygon[pts_] :> {Opacity[.3], Polygon[pts]}
}]
