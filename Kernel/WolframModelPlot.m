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
	$vertexPoint -> style[$lightTheme][$vertexStyle],
	$edgeLine -> style[$lightTheme][$edgeLineStyle],
	$edgePoint -> style[$lightTheme][$unaryEdgeStyle],
	$edgePolygon -> style[$lightTheme][$edgePolygonStyle]
|>;

(* Automatic style pickes up, and possibly modifies the style it inherits from. *)
Options[WolframModelPlot] = Join[{
	"EdgePolygonStyle" -> Automatic, (* inherits from EdgeStyle, with specified small opacity *)
	EdgeStyle -> Automatic, (* inherits from PlotStyle *)
	GraphHighlight -> {},
	GraphHighlightStyle -> style[$lightTheme][$highlightStyle],
	"HyperedgeRendering" -> style[$lightTheme][$hyperedgeRendering],
	PlotStyle -> Automatic,
	VertexCoordinateRules -> {},
	VertexLabels -> None,
	VertexSize -> style[$lightTheme][$vertexSize],
	"ArrowheadLength" -> Automatic,
	VertexStyle -> Automatic, (* inherits from PlotStyle *)
	"MaxImageSize" -> Automatic},
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
	"First argument of WolframModelPlot must be a hypergraph, i.e., a list of lists, " <>
	"where elements represent vertices, or a list of such hypergraphs.";

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

General::multigraphElementwiseStyle =
	"The elementwise style specification `1` is not supported for lists of hypergraphs.";

(* Evaluation *)

func : WolframModelPlot[args___] := Module[{result = wolframModelPlot$parse[args]},
	result /; result =!= $Failed
]

(* Arguments parsing *)

wolframModelPlot$parse[args___] /; !Developer`CheckArgumentCount[WolframModelPlot[args], 1, 2] := $Failed

(* allow composite vertices, but not list-vertices *)
$hypergraphPattern = _List ? (Function[h, AllTrue[h, ListQ[#] && Length[#] > 0 &] && AllTrue[h, Not @* ListQ, 2]]);
$multiHypergraphPattern = $hypergraphPattern | {$hypergraphPattern...};

wolframModelPlot$parse[edges : Except[$multiHypergraphPattern], edgeType_ : $defaultEdgeType, o : OptionsPattern[]] := (
	Message[WolframModelPlot::invalidEdges];
	$Failed
)

wolframModelPlot$parse[
		edges : $multiHypergraphPattern,
		edgeType : Except[Alternatives[Alternatives @@ $edgeTypes, OptionsPattern[]]],
		o : OptionsPattern[]] := (
	Message[WolframModelPlot::invalidEdgeType, edgeType, $edgeTypes];
	$Failed
)

wolframModelPlot$parse[
	edges : {$hypergraphPattern..}, edgeType : Alternatives @@ $edgeTypes : $defaultEdgeType, o : OptionsPattern[]] /;
		correctWolframModelPlotOptionsQ[WolframModelPlot, Defer[WolframModelPlot[edges, o]], edges, {o}] :=
	wolframModelPlot$parse[#, edgeType, o] & /@ edges

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
				Directive[#, style[$lightTheme][$vertexStyleFromPlotStyleDirective]] &],
			Automatic -> $plotStyleAutomatic[$vertexPoint],
			{1}],
		$edgeLine -> (Replace[
			edgeStyles = parseStyles[
				optionValue[EdgeStyle],
				edges,
				parseStyles[optionValue[PlotStyle], edges, <||>, Identity],
				Directive[#, style[$lightTheme][$edgeLineStyleFromPlotStyleDirective]] &],
			Automatic -> $plotStyleAutomatic[$edgeLine],
			{1}]),
		$edgePoint -> Replace[edgeStyles, Automatic -> $plotStyleAutomatic[$edgePoint], {1}],
		$edgePolygon -> Replace[
			parseStyles[
				optionValue["EdgePolygonStyle"],
				edges,
				edgeStyles,
				Directive[#, style[$lightTheme][$edgePolygonStyleFromEdgeStyleDirective]] &],
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
				"ArrowheadLength",
				"MaxImageSize"})
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
	correctHighlightQ[OptionValue[WolframModelPlot, opts, GraphHighlight]] &&
	correctHighlightStyleQ[head, OptionValue[WolframModelPlot, opts, GraphHighlightStyle]] &&
	correctSizeQ[head, "Vertex size", OptionValue[WolframModelPlot, opts, VertexSize], {}] &&
	correctSizeQ[head, "Arrowhead length", OptionValue[WolframModelPlot, opts, "ArrowheadLength"], {Automatic}] &&
	correctPlotStyleQ[head, OptionValue[WolframModelPlot, opts, PlotStyle]] &&
	correctStyleLengthQ[
		head, "vertices", MatchQ[edges, {$hypergraphPattern...}], Length[vertexList[edges]], OptionValue[WolframModelPlot, opts, VertexStyle]] &&
	And @@ (correctStyleLengthQ[
		head, "edges", MatchQ[edges, {$hypergraphPattern...}], Length[edges], OptionValue[WolframModelPlot, opts, #]] & /@ {EdgeStyle, "EdgePolygonStyle"})

correctCoordinateRulesQ[head_, coordinateRules_] :=
	If[!MatchQ[coordinateRules,
			Automatic |
			{(_ -> {Repeated[_ ? NumericQ, {2}]})...}],
		Message[head::invalidCoordinates, coordinateRules];
		False,
		True
	]

correctHighlightQ[highlight_] := (
	If[!ListQ[highlight], Message[WolframModelPlot::invalidHighlight, highlight]];
	ListQ[highlight]
)

correctHighlightStyleQ[head_, highlightStyle_] :=
	If[ColorQ[highlightStyle], True, Message[head::invalidHighlightStyle, highlightStyle]; False]

correctSizeQ[head_, capitalizedName_, size_ ? (# >= 0 &), _] := True

correctSizeQ[head_, capitalizedName_, size_, allowedSpecialValues_] /;
		MatchQ[size, Alternatives @@ allowedSpecialValues] := True

correctSizeQ[head_, capitalizedName_, size_, _] := (
	Message[head::invalidSize, capitalizedName, size];
	False
)

correctPlotStyleQ[head_, style_List] := (
	Message[head::invalidPlotStyle, style];
	False
)

correctPlotStyleQ[__] := True

(* Single hypergraph *)
correctStyleLengthQ[head_, name_, False, correctLength_, styles_List] /; Length[styles] =!= correctLength := (
	Message[head::invalidStyleLength, styles, name, correctLength];
	False
)

(* Multiple hypergraphs *)
correctStyleLengthQ[head_, name_, True, correctLength_, styles_List] := (
	Message[head::multigraphElementwiseStyle, styles];
	False
)

correctStyleLengthQ[__] := True

(* Implementation *)

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
		maxImageSize_,
		graphicsOptions_] := Catch[Module[{embedding, graphics, imageSizeScaleFactor},
	embedding = hypergraphEmbedding[edgeType, hyperedgeRendering, vertexCoordinates] @ edges;
	numericArrowheadLength = Replace[
		arrowheadLength, Automatic -> style[$lightTheme][$arrowheadLengthFunction][vertexEmbeddingRange[embedding[[1]]]]];
	graphics =
		drawEmbedding[styles, vertexLabels, highlight, highlightColor, vertexSize, numericArrowheadLength] @ embedding;
	imageSizeScaleFactor = Min[1, 0.7 (#[[2]] - #[[1]])] & /@ PlotRange[graphics];
	Show[
		graphics,
		graphicsOptions,
		If[maxImageSize === Automatic,
			ImageSizeRaw -> style[$lightTheme][$wolframModelPlotImageSize] imageSizeScaleFactor,
			ImageSize -> adjustImageSize[maxImageSize, imageSizeScaleFactor]]]
]]

vertexEmbeddingRange[{}] := 0

vertexEmbeddingRange[vertexEmbedding_] := Max[#2 - #1 & @@@ MinMax /@ Transpose[vertexEmbedding[[All, 2, 1, 1]]]]

adjustImageSize[w_ ? NumericQ, {wScale_, hScale_}] := w wScale

adjustImageSize[dims : {w_ ? NumericQ, h_ ? NumericQ}, scale_] := dims scale

WolframModelPlot::invalidMaxImageSize =
	"MaxImageSize `1` should either be a single number (width) or a list of two numbers (width and height)";

adjustImageSize[dims_, _] := (Message[WolframModelPlot::invalidMaxImageSize, dims]; Throw[$Failed])

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

	vertexPoints = MapIndexed[
		With[{vertexStyle = styles[$vertexPoint][[#2[[1]]]]},
			# /. {
				highlighted[Point[p_], h_] :> {
					If[h, Directive[highlightColor, style[$lightTheme][$highlightedVertexStyleDirective]], vertexStyle],
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
					If[h, Directive[style[$lightTheme][$highlightedEdgeLineStyleDirective], highlightColor], lineStyle],
					arrow[style[$lightTheme][$edgeArrowheadShape], arrowheadLength, vertexSize][pts]}, $edgeLine],
				highlighted[Polygon[pts_], h_] :> Sow[{
					If[h, Directive[style[$lightTheme][$highlightedEdgePolygonStyleDirective], highlightColor], polygonStyle],
					Polygon[pts]}, $edgePolygon],
				highlighted[Point[p_], h_] :> Sow[{
					If[h, Directive[style[$lightTheme][$highlightedUnaryEdgeStyleDirective], highlightColor], pointStyle],
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
