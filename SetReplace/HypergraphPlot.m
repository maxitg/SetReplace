(* ::Package:: *)

(* ::Title:: *)
(*HypergraphPlot*)


(* ::Text:: *)
(*We might want to visualize the list-elements of the set as directed hyperedges. We can do that by drawing each hyperedge as sequences of same-color normal 2-edges.*)


(* ::Text:: *)
(*We will have to work around the bug in Wolfram Language that prevents multi-edges appear in different colors regardless of their different styles.*)


Package["SetReplace`"]


PackageExport["HypergraphPlot"]


(* ::Section:: *)
(*Documentation*)


HypergraphPlot::usage = usageString[
	"HypergraphPlot[`s`, `opts`] plots a list of vertex lists `s` as a ",
	"hypergraph."];


(* ::Section:: *)
(*Syntax Information*)


SyntaxInformation[HypergraphPlot] = {"ArgumentsPattern" -> {_, OptionsPattern[]}};


(* ::Section:: *)
(*Argument Checks*)


(* ::Subsection:: *)
(*Argument count*)


HypergraphPlot[args___] := 0 /;
	!Developer`CheckArgumentCount[HypergraphPlot[args], 1, 1] && False


(* ::Subsection:: *)
(*Valid edges*)


HypergraphPlot::invalidEdges =
	"First argument of HypergraphPlot must be list of lists, where elements " ~~
	"represent vertices."; 


HypergraphPlot[edges_, o : OptionsPattern[]] := 0 /;
	!MatchQ[edges, {___List}] && Message[HypergraphPlot::invalidEdges]


(* ::Section:: *)
(*Options*)


(* ::Text:: *)
(*"HyperedgeType" can be set to: "Unordered" (sequence of edges), "Cyclic" (same, but last vertex connected to the first), and "Ordered" (all vertices connected in a complete graph).*)


Options[HypergraphPlot] = Join[{
	"HyperedgeType" -> "Ordered",
	PlotStyle -> ColorData[97],
	DataRange -> Automatic,
	GraphLayout -> Automatic,
	VertexCoordinates -> Automatic,
	VertexLabels -> Automatic,
	VertexShapeFunction -> Automatic,
	VertexSize -> Automatic,
	VertexStyle -> Automatic},
	Options[Graphics]];


(* ::Section:: *)
(*Implementation*)


(* ::Subsection:: *)
(*parsePlotStyle*)


HypergraphPlot::notColor =
	"PlotStyle `1` at index `2` should return a color instead of `3`.";


parsePlotStyle[hyperedgeCount_, style_] := Module[{result, failedQ = False},
	result = If[!failedQ,
		Module[{color},
			color = style[#];
			If[!ColorQ[color],
				Message[HypergraphPlot::notColor, style, #, color];
				failedQ = True];
				color
		]
	] & /@ Range[hyperedgeCount];
	If[failedQ, $Failed, result]
]


(* ::Subsection:: *)
(*parseHyperedgeType*)


$hyperedgeTypes = {"Ordered", "Cyclic", "Unordered"};


HypergraphPlot::unknownHyperedgeType = "HyperedgeType `1` should be one of `2`.";


parseHyperedgeType[hyperedges_, opt : _String | _Rule] :=
	parseHyperedgeType[hyperedges, {opt}]


parseHyperedgeType[hyperedges_, opt : {(_String | _Rule)...}] := Module[{
		result, incorrectCase},
	result = Replace[
		hyperedges,
		Reverse @ Prepend[
			Replace[opt, s_String :> _ -> s, {1}],
			_ -> OptionValue[HypergraphPlot, "HyperedgeType"]],
		{1}];
	If[!MissingQ[incorrectCase = FirstCase[
			result, Except[Alternatives @@ $hyperedgeTypes], Missing[], {1}]],
		Message[HypergraphPlot::unknownHyperedgeType,
			incorrectCase, $hyperedgeTypes];
		$Failed,
		result
	]
]


HypergraphPlot::invalidHyperedgeType =
	"HyperedgeType `1` should be a string or a list of rules.";


parseHyperedgeType[hyperedges_, opt_] := (
	Message[HypergraphPlot::invalidHyperedgeType, opt];
	$Failed)


(* ::Subsection:: *)
(*hyperedgeToEdges*)


hyperedgeToEdges[hyperedge_, "Ordered"] := DirectedEdge @@@ Partition[hyperedge, 2, 1]


hyperedgeToEdges[hyperedge_, "Cyclic"] :=
	DirectedEdge @@@ Append[Partition[hyperedge, 2, 1], hyperedge[[{-1, 1}]]]


hyperedgeToEdges[hyperedge_, "Unordered"] := UndirectedEdge @@@ Subsets[hyperedge, {2}]


(* ::Subsection:: *)
(*parseGraphLayout*)


$graphLayoutStages = {"VertexLayout", "EdgeLayout", "PackingLayout"};


parseGraphLayout[Automatic] := {Automatic, Automatic, Automatic}


parseGraphLayout[vertexLayout_String] := {vertexLayout, Automatic, Automatic}


parseGraphLayout[rules_List] /;
		SubsetQ[$graphLayoutStages, Keys[Association[rules]]] :=
	Lookup[Association[rules], #, Automatic] & /@ $graphLayoutStages


HypergraphPlot::invalidGraphLayout =
	"GraphLayout `1` should be Automatic, a string, or a list of rules with keys `2`.";


parseGraphLayout[opt_] := (
	Message[HypergraphPlot::invalidGraphLayout, opt, $graphLayoutStages];
	ConstantArray[$Failed, 3])


(* ::Subsection:: *)
(*embedEdges*)


embedEdges[
			edgeLayout :
				"Normal" | "DividedEdgeBundling" |
				"HierarchicalEdgeBundling" | "StraightLine",
			set_,
			hyperedgeTypes_,
			vertexCoordinateRules_] := Module[{
		vertices, normalEdges, normalEdgeCoordinateRules, normalEdgeIndices,
		indexedSegments},
	vertices = vertexCoordinateRules[[All, 1]];
	normalEdges =
		hyperedgeToEdges[#1, #2] & @@@ Transpose[{set, hyperedgeTypes}];
	normalEdgeCoordinateRules = Reap[GraphPlot[
		Graph[
			vertices,
			Catenate @ normalEdges],
		GraphLayout -> {"EdgeLayout" -> Replace[edgeLayout, "Normal" -> Automatic]},
		EdgeShapeFunction -> (Sow[#2 -> #] &),
		VertexCoordinates -> vertexCoordinateRules[[All, 2]]]][[2, 1]];
	normalEdgeIndices = Sort @ Catenate @ MapIndexed[# -> #2 &, normalEdges, {2}];
	indexedSegments = Association[Rule @@@ Sort @ Transpose[{
		normalEdgeIndices[[All, 2]],
		normalEdgeCoordinateRules[[All, 2]]}]];
	Thread[{
		MapIndexed[indexedSegments[#2] &, Range /@ Length /@ normalEdges, {2}],
		set}]
]


(* ::Subsection:: *)
(*drawEdges*)


drawEdges[edgeEmbedding_, shapeFunction_, style_] :=
	Map[Line, edgeEmbedding[[All, 1]], {2}]


(* ::Subsection:: *)
(*drawVertices*)


(* ::Subsection:: *)
(*HypergraphPlot*)


HypergraphPlot[set : {___List}, o : OptionsPattern[]] := Module[{
		failedQ = False, hyperedgeColors, vertexLayout, edgeLayout, packingLayout,
		hyperedgeTypes, graphForEmbedding, embedding, vertexCoordinateRules,
		vertices, vertexColors, graphPlotOptions, graphForPlotting,
		edgeEmbedding, edgeGraphics, result},
	hyperedgeTypes = parseHyperedgeType[set, OptionValue["HyperedgeType"]];
	hyperedgeColors = parsePlotStyle[Length[set], OptionValue[PlotStyle]];
	{vertexLayout, edgeLayout, packingLayout} =
		parseGraphLayout[OptionValue[GraphLayout]];
	If[hyperedgeTypes === $Failed ||
			hyperedgeColors === $Failed ||
			vertexLayout === $Failed,
		failedQ = True];
	
	If[!failedQ,
		graphForEmbedding = Graph[
			Catenate[hyperedgeToEdges[#1, #2] & @@@
				Transpose[{set, hyperedgeTypes}]]];
		embedding = If[OptionValue[VertexCoordinates] === Automatic,
			GraphEmbedding[
				graphForEmbedding,
				Replace[vertexLayout, Automatic -> "SpringElectricalEmbedding"]],
			OptionValue[VertexCoordinates]];
		If[MatchQ[
				embedding,
				{Repeated[
					{Repeated[_ ? NumericQ, {2}]},
					{VertexCount[graphForEmbedding]}]}],
			vertexCoordinateRules = Thread[VertexList[graphForEmbedding] -> embedding];
			edgeEmbedding = embedEdges[
				Replace[edgeLayout, Automatic -> "Normal"],
				set,
				hyperedgeTypes,
				vertexCoordinateRules];
			edgeGraphics = drawEdges[edgeEmbedding, shapeFunction, style];
			
			vertices = Union @ Flatten @ set;
			vertexColors = (# -> ColorData[97, Count[set, {#}] + 1] & /@ vertices);
			
			graphForPlotting = Graph[vertices, {}];
			graphPlotOptions = FilterRules[
				FilterRules[{o}, Options[GraphPlot]],
				Except[GraphLayout | VertexCoordinates]];
			result = Show[
				Graphics[edgeGraphics],
				GraphPlot[
					graphForPlotting,
					Join[
						graphPlotOptions, {
						VertexStyle -> vertexColors,
						GraphLayout -> {"PackingLayout" -> packingLayout},
						VertexCoordinates ->
							(VertexList[graphForPlotting] /.
								vertexCoordinateRules)}]]];,
			
			failedQ = True
		];
	];
	result /; !failedQ && Head[result] =!= GraphPlot
]
