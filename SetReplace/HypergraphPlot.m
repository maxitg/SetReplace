Package["SetReplace`"]

PackageExport["HypergraphPlot"]

PackageScope["correctHypergraphPlotOptionsQ"]
PackageScope["$edgeTypes"]
PackageScope["hypergraphEmbedding"]
PackageScope["hypergraphPlot"]

(* Documentation *)

HypergraphPlot::usage = usageString[
	"HypergraphPlot[`s`, `opts`] plots a list of vertex lists `s` as a hypergraph."];

SyntaxInformation[HypergraphPlot] = {"ArgumentsPattern" -> {_, _., OptionsPattern[]}};

Options[HypergraphPlot] = Join[{
	GraphHighlight -> {},
	GraphHighlightStyle -> Hue[1.0, 1.0, 0.7],
	"HyperedgeRendering" -> "Polygons",
	VertexCoordinateRules -> {},
	VertexLabels -> None},
	Options[Graphics]];

$edgeTypes = {"Ordered", "Cyclic"};
$defaultEdgeType = "Ordered";
$graphLayout = "SpringElectricalEmbedding";
$hyperedgeRenderings = {"Subgraphs", "Polygons", "Branes"};

(* Messages *)

General::invalidEdges =
	"First argument of HypergraphPlot must be list of lists, where elements represent vertices.";

General::invalidEdgeType =
	"Edge type `1` should be one of `2`.";

General::invalidCoordinates =
	"Coordinates `1` should be a list of rules from vertices to pairs of numbers.";

HypergraphPlot::invalidHighlight =
	"GraphHighlight value `1` should be a list of vertices and edges.";

General::invalidHighlightStyle =
	"GraphHighlightStyle `1` should be a color.";

(* Evaluation *)

func : HypergraphPlot[args___] := Module[{result = hypergraphPlot$parse[args]},
	result /; result =!= $Failed
]

(* Arguments parsing *)

hypergraphPlot$parse[args___] /; !Developer`CheckArgumentCount[HypergraphPlot[args], 1, 2] := $Failed

hypergraphPlot$parse[edges : Except[{___List}], edgeType_ : $defaultEdgeType, o : OptionsPattern[]] := (
	Message[HypergraphPlot::invalidEdges];
	$Failed
)

hypergraphPlot$parse[
		edges : {___List},
		edgeType : Except[Alternatives[Alternatives @@ $edgeTypes, OptionsPattern[]]],
		o : OptionsPattern[]] := (
	Message[HypergraphPlot::invalidEdgeType, edgeType, $edgeTypes];
	$Failed
)

hypergraphPlot$parse[
		edges : {___List}, edgeType : Alternatives @@ $edgeTypes : $defaultEdgeType, o : OptionsPattern[]] :=
	hypergraphPlot[edges, edgeType, ##, FilterRules[{o}, Options[Graphics]]] & @@
			(OptionValue[HypergraphPlot, {o}, #] & /@ {
				GraphHighlight, GraphHighlightStyle, "HyperedgeRendering", VertexCoordinateRules, VertexLabels}) /;
		correctHypergraphPlotOptionsQ[HypergraphPlot, Defer[HypergraphPlot[edges, o]], edges, {o}]

hypergraphPlot$parse[___] := $Failed

correctHypergraphPlotOptionsQ[head_, expr_, edges_, opts_] :=
	knownOptionsQ[head, expr, opts] &&
	(And @@ (supportedOptionQ[head, ##, opts] & @@@ {
			{"HyperedgeRendering", $hyperedgeRenderings}})) &&
	correctCoordinateRulesQ[head, OptionValue[HypergraphPlot, opts, VertexCoordinateRules]] &&
	correctHighlightQ[edges, OptionValue[HypergraphPlot, opts, GraphHighlight]] &&
	correctHighlightStyleQ[head, OptionValue[HypergraphPlot, opts, GraphHighlightStyle]]

correctCoordinateRulesQ[head_, coordinateRules_] :=
	If[!MatchQ[coordinateRules,
			Automatic |
			{(_ -> {Repeated[_ ? NumericQ, {2}]})...}],
		Message[head::invalidCoordinates, coordinateRules];
		False,
		True
	]

correctHighlightQ[edges : Except[Automatic], highlight_] := Module[{
		vertices, validQ},
	vertices = vertexList[edges];
	validQ = ListQ[highlight];
	If[!validQ, Message[HypergraphPlot::invalidHighlight, highlight]];
	validQ
]

correctHighlightQ[Automatic, _] := True

correctHighlightStyleQ[head_, highlightStyle_] :=
	If[ColorQ[highlightStyle], True, Message[head::invalidHighlightStyle, highlightStyle]; False]

(* Implementation *)

$vertexSize = 0.06;
$arrowheadLength = 0.15;

hypergraphPlot[
		edges_,
		edgeType_,
		highlight_,
		highlightColor_,
		hyperedgeRendering_,
		vertexCoordinates_,
		vertexLabels_,
		graphicsOptions_,
		vertexSize_ : $vertexSize,
		arrowheadsSize_ : $arrowheadLength] := Catch[Show[
	drawEmbedding[vertexLabels, highlight, highlightColor, vertexSize, arrowheadsSize] @
		hypergraphEmbedding[edgeType, hyperedgeRendering, vertexCoordinates] @
		edges,
	graphicsOptions
]]

(** Embedding **)
(** hypergraphEmbedding produces an embedding of vertices and edges. The format is {vertices, edges},
			where both vertices and edges are associations of the form <|vertex -> {graphicsPrimitive, ...}, ...|>,
			where graphicsPrimitive is either a Point, a Line, or a Polygon. **)

(*** Subgraphs ***)

hypergraphEmbedding[edgeType_, hyperedgeRendering : "Subgraphs", coordinateRules_] :=
	hypergraphEmbedding[edgeType, edgeType, hyperedgeRendering, coordinateRules]

hypergraphEmbedding[
			vertexLayoutEdgeType_,
			edgeLayoutEdgeType_,
			hyperedgeRendering : "Subgraphs",
			coordinateRules_][
			edges_] := Module[{
		vertices, vertexEmbeddingNormalEdges, edgeEmbeddingNormalEdges},
	vertices = vertexList[edges];
	{vertexEmbeddingNormalEdges, edgeEmbeddingNormalEdges} =
		(toNormalEdges[#] /@ edges) & /@ {vertexLayoutEdgeType, edgeLayoutEdgeType};
	normalToHypergraphEmbedding[
		edges,
		edgeEmbeddingNormalEdges,
		graphEmbedding[
			vertices,
			Catenate[vertexEmbeddingNormalEdges],
			Catenate[edgeEmbeddingNormalEdges],
			$graphLayout,
			coordinateRules]]
]

toNormalEdges["Ordered"][hyperedge_] :=
	DirectedEdge @@@ Partition[hyperedge, 2, 1]

toNormalEdges["Cyclic"][hyperedge : Except[{}]] :=
	DirectedEdge @@@ Append[Partition[hyperedge, 2, 1], hyperedge[[{-1, 1}]]]

toNormalEdges["Cyclic"][{}] := {}

graphEmbedding[vertices_, vertexEmbeddingEdges_, edgeEmbeddingEdges_, layout_, coordinateRules_] := Module[{
		relevantCoordinateRules, vertexCoordinateRules, unscaledEmbedding},
	relevantCoordinateRules = Normal[Merge[Select[MemberQ[vertices, #[[1]]] &][coordinateRules], Last]];
	vertexCoordinateRules = If[vertexEmbeddingEdges === edgeEmbeddingEdges,
		relevantCoordinateRules,
		graphEmbedding[vertices, vertexEmbeddingEdges, layout, relevantCoordinateRules][[1]]
	];
	unscaledEmbedding = graphEmbedding[vertices, edgeEmbeddingEdges, layout, vertexCoordinateRules];
	rescaleEmbedding[unscaledEmbedding, relevantCoordinateRules]
]

graphEmbedding[vertices_, edges_, layout_, coordinateRules_] := Replace[
	Reap[
		GraphPlot[
			Graph[vertices, edges],
			GraphLayout -> layout,
			VertexCoordinateRules -> coordinateRules,
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

lineLength[pts_] := Total[EuclideanDistance @@@ Partition[pts, 2, 1]]

$selfLoopsScale = 0.7;
edgeScale[{vertexEmbedding_, edgeEmbedding : Except[{}]}] := Module[{selfLoops},
	selfLoops = Select[#[[1, 1]] == #[[1, 2]] &][edgeEmbedding][[All, 2]];
	Mean[lineLength /@ N /@ If[selfLoops =!= {}, $selfLoopsScale * selfLoops, edgeEmbedding[[All, 2]]]]
]

edgeScale[{{} | {_ -> _}, _}] := 1

edgeScale[{vertexEmbedding_, {}}] :=
	lineLength[Transpose[MinMax /@ Transpose[vertexEmbedding[[All, 2]]]]] /
		(Sqrt[N[Length[vertexEmbedding]] / 2])

rescaleEmbedding[embedding_, center_, factor_] := Map[
	(#[[1]] -> (#[[2]] /. coords : {Repeated[_Real, {2}]} :> (coords - center) * factor + center)) &,
	embedding,
	{2}
]

(*** Polygons ***)

hypergraphEmbedding[edgeType_, hyperedgeRendering : "Polygons", vertexCoordinates_][edges_] := Module[{
		embeddingWithNoRegions, vertexEmbedding, edgePoints, edgePolygons, edgeEmbedding},
	embeddingWithNoRegions =
		hypergraphEmbedding["Cyclic", edgeType, "Subgraphs", vertexCoordinates][edges];
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

(*** Branes ***)

hypergraphEmbedding[edgeType_, "Branes", vertexCoordinates_][edges_] := {{}, {}}

(** Drawing **)

$edgeColor = Hue[0.6, 0.7, 0.5];
$vertexColor = Hue[0.6, 0.2, 0.8];

$arrowheadShape = Polygon[{
	{-1.10196, -0.289756}, {-1.08585, -0.257073}, {-1.05025, -0.178048}, {-1.03171, -0.130243}, {-1.01512, -0.0824391},
	{-1.0039, -0.037561}, {-1., 0.}, {-1.0039, 0.0341466}, {-1.01512, 0.0780486}, {-1.03171, 0.127805},
	{-1.05025, 0.178538}, {-1.08585, 0.264878}, {-1.10196, 0.301464}, {0., 0.}, {-1.10196, -0.289756}}];

drawEmbedding[vertexLabels_, highlight_, highlightColor_, vertexSize_, arrowheadLength_][embedding_] := Module[{
		highlightCounts, embeddingShapes, vertexPoints, lines, polygons, polygonBoundaries, edgePoints, labels,
		singleVertexEdgeCounts, getSingleVertexEdgeRadius},
	highlightCounts = Counts[highlight];
	embeddingShapes = Map[
		With[{highlightedQ = If[MissingQ[highlightCounts[#[[1]]]], False, highlightCounts[#[[1]]]-- > 0]},
			#[[2]] /. (h : (Point | Line | Polygon))[pts_] :> highlighted[h[pts], highlightedQ]] &,
		embedding,
		{2}];
	If[AnyTrue[highlightCounts, # > 0 &],
		Message[HypergraphPlot::invalidHighlight, highlight];
		Throw[$Failed]];

	vertexPoints = Cases[embeddingShapes[[1]], #, All] & /@ {
		highlighted[Point[p_], h_] :> {
			Directive[If[h, highlightColor, $vertexColor], EdgeForm[Directive[GrayLevel[0], Opacity[0.7]]]],
			Disk[p, vertexSize]}
	};

	singleVertexEdgeCounts = <||>;
	getSingleVertexEdgeRadius[coords_] := (
		singleVertexEdgeCounts[coords] = Lookup[singleVertexEdgeCounts, Key[coords], vertexSize] + vertexSize
	);

	{lines, polygons, polygonBoundaries, edgePoints} = Cases[embeddingShapes[[2]], #, All] & /@ {
		highlighted[Line[pts_], h_] :> {
			If[h,
				Directive[Opacity[1], highlightColor],
				Directive[Opacity[0.7], $edgeColor]
			],
			arrow[$arrowheadShape, arrowheadLength, vertexSize][pts]},
		highlighted[Polygon[pts_], h_] :> {
			Opacity[0.3],
			If[h,
				highlightColor,
				Lighter[$edgeColor, 0.7]
			],
			Polygon[pts]},
		highlighted[Polygon[pts_], h_] :> {
			EdgeForm[White],
			Transparent,
			Polygon[pts]},
		highlighted[Point[p_], h_] :> {
			If[h,
				Directive[Opacity[1], highlightColor],
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
