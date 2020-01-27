Package["SetReplace`"]

PackageExport["HypergraphPlot"]
PackageExport["WolframModelPlot"]

PackageScope["correctWolframModelPlotOptionsQ"]
PackageScope["$edgeTypes"]
PackageScope["hypergraphEmbedding"]

(* Documentation *)

WolframModelPlot::usage = usageString[
	"WolframModelPlot[`s`, `opts`] plots a list of vertex lists `s` as a hypergraph."];

SyntaxInformation[WolframModelPlot] = {"ArgumentsPattern" -> {_, _., OptionsPattern[]}};

$plotStyleAutomatic = <|
	$vertexPoint -> Directive[Hue[0.63, 0.26, 0.89], EdgeForm[Directive[Hue[0.63, 0.7, 0.33], Opacity[0.95]]]],
	$edgeLine -> Directive[Hue[0.63, 0.7, 0.5], Opacity[0.7]],
	$edgePoint -> Directive[Hue[0.63, 0.7, 0.5], Opacity[0.7]],
	$edgePolygon -> Directive[Hue[0.63, 0.66, 0.81], Opacity[0.1], EdgeForm[None]]
|>;

(* Automatic style pickes up, and possibly modifies the style it inherits from. *)
Options[WolframModelPlot] = Join[{
	"EdgePolygonStyle" -> Automatic, (* inherits from EdgeStyle, with specified small opacity *)
	EdgeStyle -> Automatic, (* inherits from PlotStyle *)
	GraphHighlight -> {},
	GraphHighlightStyle -> Red,
	"HyperedgeRendering" -> "Polygons",
	PlotStyle -> $plotStyleAutomatic,
	VertexCoordinateRules -> {},
	VertexLabels -> None,
	VertexSize -> 0.06,
	"ArrowheadLength" -> 0.1,
	VertexStyle -> Automatic}, (* inherits from PlotStyle *)
	Options[Graphics]];

$edgeTypes = {"Ordered", "Cyclic"};
$defaultEdgeType = "Ordered";
$graphLayout = "SpringElectricalEmbedding";
$hyperedgeRenderings = {"Subgraphs", "Polygons"};

(* for compatibility reasons, we don't care for messages and unevaluated code to preserve HypergraphPlot *)
HypergraphPlot::usage = usageString["HypergraphPlot is deprecated. Use WolframModelPlot."];
SyntaxInformation[HypergraphPlot] = SyntaxInformation[WolframModelPlot];
Options[HypergraphPlot] = Options[WolframModelPlot];
HypergraphPlot = WolframModelPlot;

(* Messages *)

General::invalidEdges =
	"First argument of WolframModelPlot must be list of lists, where elements represent vertices.";

General::invalidEdgeType =
	"Edge type `1` should be one of `2`.";

General::invalidCoordinates =
	"Coordinates `1` should be a list of rules from vertices to pairs of numbers.";

WolframModelPlot::invalidHighlight =
	"GraphHighlight value `1` should be a list of vertices and edges.";

General::invalidHighlightStyle =
	"GraphHighlightStyle `1` should be a color.";

General::invalidSize =
	"`1` `2` should be a non-negative number.";

General::invalidPlotStyle =
	"PlotStyle `1` should be either a style, or an association <|pattern -> style, ...|>.";

General::invalidStyleLength =
	"The list of styles `1` should have the same length as the number of `2` `3`.";

(* Evaluation *)

func : WolframModelPlot[args___] := Module[{result = wolframModelPlot$parse[args]},
	result /; result =!= $Failed
]

(* Arguments parsing *)

wolframModelPlot$parse[args___] /; !Developer`CheckArgumentCount[WolframModelPlot[args], 1, 2] := $Failed

(* allow composite vertices, but not list-vertices *)
$hypergraphPattern = h_List /; AllTrue[h, ListQ[#] && Length[#] > 0 &] && AllTrue[h, Not @* ListQ, 2];

wolframModelPlot$parse[edges : Except[$hypergraphPattern], edgeType_ : $defaultEdgeType, o : OptionsPattern[]] := (
	Message[WolframModelPlot::invalidEdges];
	$Failed
)

wolframModelPlot$parse[
		edges : $hypergraphPattern,
		edgeType : Except[Alternatives[Alternatives @@ $edgeTypes, OptionsPattern[]]],
		o : OptionsPattern[]] := (
	Message[WolframModelPlot::invalidEdgeType, edgeType, $edgeTypes];
	$Failed
)

wolframModelPlot$parse[
			edges : $hypergraphPattern, edgeType : Alternatives @@ $edgeTypes : $defaultEdgeType, o : OptionsPattern[]] /;
				correctWolframModelPlotOptionsQ[WolframModelPlot, Defer[WolframModelPlot[edges, o]], edges, {o}] := Module[{
		optionValue, plotStyles, edgeStyle, styles},
	optionValue[opt_] := OptionValue[WolframModelPlot, {o}, opt];
	vertices = vertexList[edges];
	(* these are lists, one style for each vertex element *)
	styles = <|
		$vertexPoint -> Replace[
			parseStyles[
				optionValue[VertexStyle],
				vertices,
				parseStyles[optionValue[PlotStyle], vertices, <||>, Identity],
				Directive[#, EdgeForm[Directive[GrayLevel[0], Opacity[0.95]]]] &],
			Automatic -> $plotStyleAutomatic[$vertexPoint],
			{1}],
		$edgeLine -> (Replace[
			edgeStyles = parseStyles[
				optionValue[EdgeStyle],
				edges,
				parseStyles[optionValue[PlotStyle], edges, <||>, Identity],
				Directive[#, Opacity[0.7]] &],
			Automatic -> $plotStyleAutomatic[$edgeLine],
			{1}]),
		$edgePoint -> Replace[edgeStyles, Automatic -> $plotStyleAutomatic[$edgePoint], {1}],
		$edgePolygon -> Replace[
			parseStyles[
				optionValue["EdgePolygonStyle"], edges, edgeStyles, Directive[#, Opacity[0.1], EdgeForm[None]] &],
			Automatic -> $plotStyleAutomatic[$edgePolygon],
			{1}]|>;
	wolframModelPlot[edges, edgeType, styles, ##, FilterRules[{o}, Options[Graphics]]] & @@
			(optionValue /@ {
				GraphHighlight,
				GraphHighlightStyle,
				"HyperedgeRendering",
				VertexCoordinateRules,
				VertexLabels,
				VertexSize,
				"ArrowheadLength"})
]

toListStyleSpec[Automatic, elements_] := toListStyleSpec[<||>, elements]

toListStyleSpec[spec : Except[_List | _Association], elements_] := toListStyleSpec[<|_ -> spec|>, elements]

toListStyleSpec[spec_Association, elements_] := Replace[elements, Reverse[Join[{_ -> Automatic}, Normal[spec]]], {1}]

toListStyleSpec[spec_List, _] := spec

parseStyles[newSpec_, elements_, oldSpec_, oldToNewTransform_] :=
	MapThread[
		If[#2 === Automatic, #1, Replace[#1, Automatic -> oldToNewTransform[#2]]] &,
		toListStyleSpec[#, elements] & /@ {newSpec, oldSpec}]

wolframModelPlot$parse[___] := $Failed

correctWolframModelPlotOptionsQ[head_, expr_, edges_, opts_] :=
	knownOptionsQ[head, expr, opts] &&
	(And @@ (supportedOptionQ[head, ##, opts] & @@@ {
			{"HyperedgeRendering", $hyperedgeRenderings}})) &&
	correctCoordinateRulesQ[head, OptionValue[WolframModelPlot, opts, VertexCoordinateRules]] &&
	correctHighlightQ[edges, OptionValue[WolframModelPlot, opts, GraphHighlight]] &&
	correctHighlightStyleQ[head, OptionValue[WolframModelPlot, opts, GraphHighlightStyle]] &&
	correctSizeQ[head, "Vertex size", OptionValue[WolframModelPlot, opts, VertexSize]] &&
	correctSizeQ[head, "Arrowhead length", OptionValue[WolframModelPlot, opts, "ArrowheadLength"]] &&
	correctPlotStyleQ[head, OptionValue[WolframModelPlot, opts, PlotStyle]] &&
	correctStyleLengthQ[
		head, "vertices", Length[vertexList[edges]], OptionValue[WolframModelPlot, opts, VertexStyle]] &&
	And @@ (correctStyleLengthQ[
		head, "edges", Length[edges], OptionValue[WolframModelPlot, opts, #]] & /@ {EdgeStyle, "EdgePolygonStyle"})

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
	If[!validQ, Message[WolframModelPlot::invalidHighlight, highlight]];
	validQ
]

correctHighlightQ[Automatic, _] := True

correctHighlightStyleQ[head_, highlightStyle_] :=
	If[ColorQ[highlightStyle], True, Message[head::invalidHighlightStyle, highlightStyle]; False]

correctSizeQ[head_, capitalizedName_, size_ ? (# >= 0 &)] := True

correctSizeQ[head_, capitalizedName_, size_] := (
	Message[head::invalidSize, capitalizedName, size];
	False
)

correctPlotStyleQ[head_, style_List] := (
	Message[head::invalidPlotStyle, style];
	False
)

correctPlotStyleQ[__] := True

correctStyleLengthQ[head_, name_, correctLength_, styles_List] /; Length[styles] =!= correctLength := (
	Message[head::invalidStyleLength, styles, name, correctLength];
	False
)

correctStyleLengthQ[__] := True

(* Implementation *)

$imageSizeDefault = {{360}, {420}};

wolframModelPlot[
		edges_,
		edgeType_,
		styles_,
		highlight_,
		highlightColor_,
		hyperedgeRendering_,
		vertexCoordinates_,
		vertexLabels_,
		vertexSize_,
		arrowheadLength_,
		graphicsOptions_] := Catch[With[{
	graphics = drawEmbedding[styles, vertexLabels, highlight, highlightColor, vertexSize, arrowheadLength] @
		hypergraphEmbedding[edgeType, hyperedgeRendering, vertexCoordinates] @
		edges},
	Show[graphics, graphicsOptions, ImageSizeRaw -> $imageSizeDefault (Min[1, #[[2]] - #[[1]]] & /@ PlotRange[graphics])]
]]

(** Embedding **)
(** hypergraphEmbedding produces an embedding of vertices and edges. The format is {vertices, edges},
			where both vertices and edges are associations of the form <|vertex -> {graphicsPrimitive, ...}, ...|>,
			where graphicsPrimitive is either a Point, a Line, or a Polygon. **)

(*** SpringElectricalEmbedding ***)

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
		indexedHyperedgesToLineSegments, indexedEdgeEmbedding, indexedSingleVertexEdges, indexedSingleVertexEdgeEmbedding},
	vertexEmbedding = Sort[#[[1]] -> {Point[#[[2]]]} & /@ normalEmbedding[[1]]];

	indexedHyperedges = MapIndexed[{#, #2[[1]]} &, edges];
	(* vertices in the normalEdges should already be sorted by now. *)
	normalEdgeToIndexedHyperedge = Sort[Catenate[MapThread[Thread[#2 -> Defer[#]] &, {indexedHyperedges, normalEdges}]]];

	normalEdgeToLinePoints = Sort[If[Head[#] === DirectedEdge, #, Sort[#]] & /@ normalEmbedding[[2]]];
	lineSegments = Line /@ normalEdgeToLinePoints[[All, 2]];

	indexedHyperedgesToLineSegments =
		#[[1, 1]] -> #[[2]] & /@
			Normal[Merge[Thread[normalEdgeToIndexedHyperedge[[All, 2]] -> lineSegments], Identity]];
	indexedEdgeEmbedding = #[[1]] -> #[[2]] & /@ indexedHyperedgesToLineSegments;

	indexedSingleVertexEdges =
		With[{
				indices = Position[normalEdges, {}, 1][[All, 1]]},
			Cases[Transpose[{edges[[indices]], indices}], Except[{{}, _}], 1]];
	indexedSingleVertexEdgeEmbedding = (# -> (#[[1, 1]] /. vertexEmbedding)) & /@ indexedSingleVertexEdges;

	{vertexEmbedding,
		#[[1, 1]] -> #[[2]] & /@ SortBy[Join[indexedEdgeEmbedding, indexedSingleVertexEdgeEmbedding], #[[1, 2]] &]}
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

(*** SpringElectricalPolygons ***)

hypergraphEmbedding[edgeType_, hyperedgeRendering : "Polygons", vertexCoordinates_][edges_] := Module[{
		embeddingWithNoRegions, vertexEmbedding, edgeEmbedding},
	embeddingWithNoRegions =
		hypergraphEmbedding["Cyclic", edgeType, "Subgraphs", vertexCoordinates][edges];
	vertexEmbedding = embeddingWithNoRegions[[1]];
	edgeEmbedding = addConvexPolygons[edgeType] @@@ embeddingWithNoRegions[[2]];
	{vertexEmbedding, edgeEmbedding}
]

addConvexPolygons["Ordered"][edge : {_, _.}, subgraphsShapes_] := edge -> subgraphsShapes

addConvexPolygons[edgeType_][edge_, subgraphsShapes_] := Module[{points, region, convexPolygons, polygon},
	points = Flatten[#, 2] & @ (subgraphsShapes /. {Line[pts_] :> {pts}, Point[pts_] :> {{pts}}});
	region = ConvexHullMesh[Map[# + RandomReal[1.*^-10] &, points, {2}]];
	convexPolygons = Polygon /@ Table[MeshCoordinates[region][[polygon]], {polygon, MeshCells[region, 2][[All, 1]]}];
	edge -> Join[subgraphsShapes, convexPolygons]
]

(** Drawing **)

$arrowheadShape = Polygon[{
	{-1.10196, -0.289756}, {-1.08585, -0.257073}, {-1.05025, -0.178048}, {-1.03171, -0.130243}, {-1.01512, -0.0824391},
	{-1.0039, -0.037561}, {-1., 0.}, {-1.0039, 0.0341466}, {-1.01512, 0.0780486}, {-1.03171, 0.127805},
	{-1.05025, 0.178538}, {-1.08585, 0.264878}, {-1.10196, 0.301464}, {0., 0.}, {-1.10196, -0.289756}}];

drawEmbedding[
			styles_,
			vertexLabels_,
			highlight_,
			highlightColor_,
			vertexSize_,
			arrowheadLength_][
			embedding_] := Module[{
		highlightCounts, embeddingShapes, vertexPoints, lines, polygons, edgePoints, labels,
		singleVertexEdgeCounts, getSingleVertexEdgeRadius},
	highlightCounts = Counts[highlight];
	embeddingShapes = Map[
		With[{highlightedQ = If[MissingQ[highlightCounts[#[[1]]]], False, highlightCounts[#[[1]]]-- > 0]},
			#[[2]] /. (h : (Point | Line | Polygon))[pts_] :> highlighted[h[pts], highlightedQ]] &,
		embedding,
		{2}];
	If[AnyTrue[highlightCounts, # > 0 &],
		Message[WolframModelPlot::invalidHighlight, highlight];
		Throw[$Failed]];

	vertexPoints = MapIndexed[
		With[{style = styles[$vertexPoint][[#2[[1]]]]},
			# /. {
				highlighted[Point[p_], h_] :> {
					If[h, Directive[highlightColor, EdgeForm[Directive[GrayLevel[0], Opacity[0.7]]]], style],
					Disk[p, vertexSize]}}] &,
		embeddingShapes[[1]]];

	singleVertexEdgeCounts = <||>;
	getSingleVertexEdgeRadius[coords_] := (
		singleVertexEdgeCounts[coords] = Lookup[singleVertexEdgeCounts, Key[coords], vertexSize] + vertexSize
	);

	{lines, polygons, edgePoints} = Reap[MapIndexed[
		With[{
				lineStyle = styles[$edgeLine][[#2[[1]]]],
				polygonStyle = styles[$edgePolygon][[#2[[1]]]],
				pointStyle = styles[$edgePoint][[#2[[1]]]]},
			# /. {
				highlighted[Line[pts_], h_] :> Sow[{
					If[h, Directive[Opacity[1], highlightColor], lineStyle],
					arrow[$arrowheadShape, arrowheadLength, vertexSize][pts]}, $edgeLine],
				highlighted[Polygon[pts_], h_] :> Sow[{
					If[h, Directive[Opacity[0.3], highlightColor], polygonStyle],
					Polygon[pts]}, $edgePolygon],
				highlighted[Point[p_], h_] :> Sow[{
					If[h, Directive[Opacity[1], highlightColor], pointStyle],
					Circle[p, getSingleVertexEdgeRadius[p]]}, $edgePoint]}] &,
		embeddingShapes[[2]]], {$edgeLine, $edgePolygon, $edgePoint}][[2, All]];

	(* would only work if coordinates consist of a single point *)
	labels = If[VertexLabels === None,
		Nothing,
		GraphPlot[
			Graph[embedding[[1, All, 1]], {}],
			VertexCoordinates -> embedding[[1, All, 2, 1, 1]],
			VertexLabels -> vertexLabels,
			VertexShapeFunction -> None,
			EdgeShapeFunction -> None]];
	Show[Graphics[{polygons, lines, vertexPoints, edgePoints}], labels]
]
