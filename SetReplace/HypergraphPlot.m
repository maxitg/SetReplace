Package["SetReplace`"]

PackageExport["HypergraphPlot"]

PackageScope["hypergraphEmbedding"]
PackageScope["hypergraphPlot"]

(* Documentation *)

HypergraphPlot::usage = usageString[
	"HypergraphPlot[`s`, `opts`] plots a list of vertex lists `s` as a hypergraph."]

SyntaxInformation[HypergraphPlot] = {"ArgumentsPattern" -> {_, OptionsPattern[]}};

Options[HypergraphPlot] = Join[{
	"EdgeType" -> "CyclicOpen",
	GraphHighlight -> {},
	GraphLayout -> "SpringElectricalPolygons",
	VertexCoordinateRules -> {},
	VertexLabels -> None},
	Options[Graphics]];

$edgeTypes = {"Ordered", "CyclicClosed", "CyclicOpen"};
$graphLayouts = {"SpringElectricalEmbedding", "SpringElectricalPolygons"};

(* Messages *)

HypergraphPlot::notImplemented =
	"Not implemented: `1`.";

HypergraphPlot::invalidEdges =
	"First argument of HypergraphPlot must be list of lists, where elements represent vertices.";

HypergraphPlot::invalidCoordinates =
	"Coordinates `1` should be a list of rules from vertices to pairs of numbers.";

HypergraphPlot::invalidHighlight =
	"GraphHighlight value `1` should be a list of vertices and edges.";

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

hypergraphPlot$parse[args : PatternSequence[edges_, o : OptionsPattern[]]] :=
	$Failed /; !knownOptionsQ[HypergraphPlot, Defer[HypergraphPlot[args]], {o}]

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

hypergraphPlot$parse[edges_, o : OptionsPattern[]] := Module[{
		result, vertexCoordinates},
	vertexCoordinates = OptionValue[HypergraphPlot, {o}, VertexCoordinateRules];
	result = If[!MatchQ[vertexCoordinates,
			Automatic |
			{(_ -> {Repeated[_ ? NumericQ, {2}]})...}],
		Message[HypergraphPlot::invalidCoordinates, vertexCoordinates];
		$Failed];
	result /; result === $Failed
]

hypergraphPlot$parse[edges_, o : OptionsPattern[]] := Module[{
		highlight, vertices, validQ},
	highlight = OptionValue[HypergraphPlot, {o}, GraphHighlight];
	vertices = vertexList[edges];
	validQ = ListQ[highlight] && (And @@ (MemberQ[Join[vertices, edges], #] & /@ highlight));
	If[!validQ, Message[HypergraphPlot::invalidHighlight, highlight]];
	$Failed /; !validQ
]

hypergraphPlot$parse[edges : {___List}, o : OptionsPattern[]] :=
	hypergraphPlot[edges, ##, FilterRules[{o}, Options[Graphics]]] & @@
		(OptionValue[HypergraphPlot, {o}, #] & /@ {
			"EdgeType", GraphHighlight, GraphLayout, VertexCoordinateRules, VertexLabels})

(* Implementation *)

$vertexSize = 0.06;
$arrowheadLength = 0.15;

hypergraphPlot[
		edges_,
		edgeType_,
		highlight_,
		layout_,
		vertexCoordinates_,
		vertexLabels_,
		graphicsOptions_,
		vertexSize_ : $vertexSize,
		arrowheadsSize_ : $arrowheadLength] := Show[
	drawEmbedding[vertexLabels, highlight, vertexSize, arrowheadsSize] @
		hypergraphEmbedding[edgeType, layout, vertexCoordinates] @
		edges,
	graphicsOptions
]

(** Embedding **)
(** hypergraphEmbedding produces an embedding of vertices and edges. The format is {vertices, edges},
			where both vertices and edges are associations of the form <|vertex -> {graphicsPrimitive, ...}, ...|>,
			where graphicsPrimitive is either a Point, a Line, or a Polygon. **)

(*** SpringElectricalEmbedding ***)

hypergraphEmbedding[edgeType_, layout : "SpringElectricalEmbedding", coordinateRules_][edges_] := Module[{
		vertices, vertexEmbeddingNormalEdges, edgeEmbeddingNormalEdges},
	vertices = vertexList[edges];
	vertexEmbeddingNormalEdges = toNormalEdges[edgeType] /@ edges;
	edgeEmbeddingNormalEdges = If[edgeType === "CyclicOpen",
		If[# === {}, Identity[#], Most[#]] & /@ # &,
		Identity][
			vertexEmbeddingNormalEdges];
	normalToHypergraphEmbedding[
		edges,
		edgeEmbeddingNormalEdges,
		graphEmbedding[
			vertices,
			Catenate[vertexEmbeddingNormalEdges],
			Catenate[edgeEmbeddingNormalEdges],
			layout,
			coordinateRules]]
]

toNormalEdges["Ordered"][hyperedge_] :=
	DirectedEdge @@@ Partition[hyperedge, 2, 1]

toNormalEdges["CyclicOpen" | "CyclicClosed"][hyperedge : Except[{}]] :=
	DirectedEdge @@@ Append[Partition[hyperedge, 2, 1], hyperedge[[{-1, 1}]]]

toNormalEdges["CyclicOpen" | "CyclicClosed"][{}] := {}

graphEmbedding[vertices_, vertexEmbeddingEdges_, edgeEmbeddingEdges_, layout_, coordinateRules_] := Module[{
		relevantCoordinateRules, vertexCoordinates, unscaledEmbedding},
	relevantCoordinateRules = Normal[Merge[Select[MemberQ[vertices, #[[1]]] &][coordinateRules], Last]];
	vertexCoordinates = constrainedGraphEmbedding[Graph[vertices, vertexEmbeddingEdges], layout, relevantCoordinateRules];
	unscaledEmbedding = graphEmbedding[vertices, edgeEmbeddingEdges, layout, vertexCoordinates];
	rescaleEmbedding[unscaledEmbedding, relevantCoordinateRules]
]

constrainedGraphEmbedding[graph_, layout_, coordinateRules_] := Module[{
		indexGraph, vertexToIndex, graphPlot, graphPlotCoordinateRules, displacement},
	indexGraph = IndexGraph[graph];
	vertexToIndex = Thread[VertexList[graph] -> VertexList[indexGraph]];
	graphPlot = GraphPlot[
		indexGraph, {
		Method -> layout,
		PlotTheme -> "Classic",
		If[Length[coordinateRules] > 1,
			VertexCoordinateRules ->
				Thread[(coordinateRules[[All, 1]] /. vertexToIndex) ->
					coordinateRules[[All, 2]]],
			Nothing]}];
	graphPlotCoordinateRules = VertexCoordinateRules /. Cases[graphPlot, _Rule, Infinity];
	If[Length[coordinateRules] != 1,
		graphPlotCoordinateRules,
		displacement =
			coordinateRules[[1, 2]] -
			(coordinateRules[[1, 1]] /. Thread[VertexList[graph] -> graphPlotCoordinateRules]);
		# + displacement & /@ graphPlotCoordinateRules
	]
]

graphEmbedding[vertices_, edges_, layout_, coordinates_] := Replace[
	Reap[
		GraphPlot[
			Graph[vertices, edges],
			GraphLayout -> layout,
			VertexCoordinates -> coordinates,
			VertexShapeFunction -> (Sow[#2 -> #, "v"] &),
			EdgeShapeFunction -> (Sow[#2 -> #, "e"] &)],
		{"v", "e"}][[2]],
	el : Except[{}] :> el[[1]],
	{1}
]

normalToHypergraphEmbedding[edges_, normalEdges_, normalEmbedding_] := Module[{
		vertexEmbedding, indexedHyperedges, normalEdgeToIndexedHyperedge, normalEdgeToLinePoints, lineSegments,
		indexedHyperedgesToLineSegments, edgeEmbedding, singleVertexEdges, singleVertexEdgeEmbedding},
	vertexEmbedding = #[[1]] -> {Point[#[[2]]]} & /@ normalEmbedding[[1]];

	indexedHyperedges = MapIndexed[{#, #2} &, edges];
	(* vertices in the normalEdges should already be sorted by now. *)
	normalEdgeToIndexedHyperedge = Sort[Catenate[MapThread[Thread[#2 -> Defer[#]] &, {indexedHyperedges, normalEdges}]]];

	normalEdgeToLinePoints = Sort[If[Head[#] === DirectedEdge, #, Sort[#]] & /@ normalEmbedding[[2]]];
	lineSegments = Line /@ normalEdgeToLinePoints[[All, 2]];

	indexedHyperedgesToLineSegments =
		#[[1, 1]] -> #[[2]] & /@
			Normal[Merge[Thread[normalEdgeToIndexedHyperedge[[All, 2]] -> lineSegments], Identity]];
	edgeEmbedding = #[[1, 1]] -> #[[2]] & /@ indexedHyperedgesToLineSegments;

	singleVertexEdges = Cases[edges[[Position[normalEdges, {}, 1][[All, 1]]]], Except[{}], 1];
	singleVertexEdgeEmbedding = (# -> (#[[1]] /. vertexEmbedding)) & /@ singleVertexEdges;

	{vertexEmbedding, Join[edgeEmbedding, singleVertexEdgeEmbedding]}
]

rescaleEmbedding[unscaledEmbedding_, {_, __}] := unscaledEmbedding

rescaleEmbedding[unscaledEmbedding_, {v_ -> pivotPoint_}] :=
	rescaleEmbedding[unscaledEmbedding, pivotPoint, 1 / edgeScale[unscaledEmbedding]]

rescaleEmbedding[unscaledEmbedding_, {}] := rescaleEmbedding[unscaledEmbedding, {0 -> {0.0, 0.0}}]

$selfLoopsScale = 0.7;
edgeScale[{vertexEmbedding_, edgeEmbedding : Except[{}]}] := Module[{selfLoops},
	selfLoops = Select[#[[1, 1]] == #[[1, 2]] &][edgeEmbedding][[All, 2]];
	Mean[RegionMeasure /@ Line /@ N /@ If[selfLoops =!= {}, $selfLoopsScale * selfLoops, edgeEmbedding[[All, 2]]]]
]

edgeScale[{{}, _}] := 1

edgeScale[{vertexEmbedding_, {}}] :=
	RegionMeasure[Line[Transpose[MinMax /@ Transpose[vertexEmbedding[[All, 2]]]]]] /
		(Sqrt[N[Length[vertexEmbedding]] / 2])

rescaleEmbedding[embedding_, center_, factor_] := embedding /.
	coords : {Repeated[_ ? NumericQ, {2}]} :> (coords - center) * factor + center

(*** SpringElectricalPolygons ***)

hypergraphEmbedding[edgeType_, layout : "SpringElectricalPolygons", vertexCoordinates_][edges_] := Module[{
		embeddingWithNoRegions, vertexEmbedding, edgePoints, edgePolygons, edgeEmbedding},
	embeddingWithNoRegions = hypergraphEmbedding[edgeType, "SpringElectricalEmbedding", vertexCoordinates][edges];
	vertexEmbedding = embeddingWithNoRegions[[1]];
	edgePoints =
		Flatten[#, 2] & /@ (embeddingWithNoRegions[[2, All, 2]] /. {Line[pts_] :> {pts}, Point[pts_] :> {{pts}}});
	edgePolygons = Map[
		Polygon,
		Map[
			With[{region = ConvexHullMesh[Map[# + RandomReal[1.*^-10] &, #, {2}]]},
				Table[MeshCoordinates[region][[polygon]], {polygon, MeshCells[region, 2][[All, 1]]}]
			] &,
			edgePoints],
		{2}];
	edgeEmbedding = MapThread[#1[[1]] -> Join[#1[[2]], #2] &, {embeddingWithNoRegions[[2]], edgePolygons}];
	{vertexEmbedding, edgeEmbedding}
]

(** Drawing **)

$highlightColor = Hue[1.0, 1.0, 0.7];
$edgeColor = Hue[0.6, 0.7, 0.5];
$vertexColor = Hue[0.6, 0.2, 0.8];

$arrowheadShape = Polygon[{
	{-1.10196, -0.289756}, {-1.08585, -0.257073}, {-1.05025, -0.178048}, {-1.03171, -0.130243}, {-1.01512, -0.0824391},
	{-1.0039, -0.037561}, {-1., 0.}, {-1.0039, 0.0341466}, {-1.01512, 0.0780486}, {-1.03171, 0.127805},
	{-1.05025, 0.178538}, {-1.08585, 0.264878}, {-1.10196, 0.301464}, {0., 0.}, {-1.10196, -0.289756}}];

drawEmbedding[vertexLabels_, highlight_, vertexSize_, arrowheadLength_][embedding_] := Module[{
		embeddingShapes, vertexPoints, lines, polygons, polygonBoundaries, edgePoints, labels, singleVertexEdgeCounts,
		getSingleVertexEdgeRadius},
	embeddingShapes = Map[
		#[[2]] /. (h : (Point | Line | Polygon))[pts_] :> highlighted[h[pts], MemberQ[highlight, #[[1]]]] &,
		embedding,
		{2}];

	vertexPoints = Cases[embeddingShapes[[1]], #, All] & /@ {
		highlighted[Point[p_], h_] :> {
			If[h,
				Directive[$highlightColor, EdgeForm[Directive[$highlightColor, Opacity[1]]]],
				Directive[$vertexColor, EdgeForm[Directive[GrayLevel[0], Opacity[0.7]]]]
			],
			Disk[p, vertexSize]}
	};

	singleVertexEdgeCounts = <||>;
	getSingleVertexEdgeRadius[coords_] := (
		singleVertexEdgeCounts[coords] = Lookup[singleVertexEdgeCounts, Key[coords], vertexSize] + vertexSize
	);

	{lines, polygons, polygonBoundaries, edgePoints} = Cases[embeddingShapes[[2]], #, All] & /@ {
		highlighted[Line[pts_], h_] :> {
			If[h,
				Directive[Opacity[1], $highlightColor],
				Directive[Opacity[0.7], $edgeColor]
			],
			arrow[$arrowheadShape, arrowheadLength, vertexSize][pts]},
		highlighted[Polygon[pts_], h_] :> {
			Opacity[0.3],
			If[h,
				$highlightColor,
				Lighter[$edgeColor, 0.7]
			],
			Polygon[pts]},
		highlighted[Polygon[pts_], h_] :> {
			EdgeForm[White],
			Transparent,
			Polygon[pts]},
		highlighted[Point[p_], h_] :> {
			If[h,
				Directive[Opacity[1], $highlightColor],
				Directive[Opacity[0.7], $edgeColor]
			],
			Circle[p, getSingleVertexEdgeRadius[p]]}
	};

	(* would only work if coordinates consist of a single point *)
	labels = If[VertexLabels === None,
		Nothing,
		GraphPlot[
			Graph[embedding[[1, All, 1]], {}],
			VertexCoordinates -> embedding[[1, All, 2, 1, 1]],
			VertexLabels -> vertexLabels,
			VertexShapeFunction -> None,
			EdgeShapeFunction -> None]];
	Show[Graphics[{polygons, polygonBoundaries, lines, vertexPoints, edgePoints}], labels]
]
