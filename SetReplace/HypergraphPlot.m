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
	PlotStyle -> (ColorData[97][# + 1] &),
	DirectedEdges -> True},
	Options[GraphPlot]];


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
(*HypergraphPlot*)


HypergraphPlot[set : {___List}, o : OptionsPattern[]] := Module[{
		failedQ = False, hyperedges, edges, hypoedges, emptyEdges, hyperedgeColors,
		hyperedgeTypes, result, edgesForEmbedding, graphForEmbedding, coordinateRules,
		vertices, vertexColors, edgesWithColors, graphPlotOptions, graphForPlotting},
	hyperedges = Select[Length[#] > 2 &][set];
	edges = Select[Length[#] == 2 &][set];
	hypoedges = Select[Length[#] == 1 &][set];
	emptyEdges = Select[Length[#] == 0 &][set];
	hyperedgeColors = parsePlotStyle[Length[hyperedges], OptionValue[PlotStyle]];
	hyperedgeTypes = parseHyperedgeType[hyperedges, OptionValue["HyperedgeType"]];
	If[hyperedgeTypes === $Failed || hyperedgeColors === $Failed, failedQ = True];
	If[!failedQ,
		edgesForEmbedding = Join[
			DirectedEdge @@@ edges,
			Catenate[hyperedgeToEdges[#1, #2] & @@@
				Transpose[{hyperedges, hyperedgeTypes}]]];
		graphForEmbedding = Graph[edgesForEmbedding];
		coordinateRules = Thread[
			VertexList[graphForEmbedding] ->
				GraphEmbedding[
					graphForEmbedding,
					Replace[
						OptionValue[GraphLayout],
						Automatic -> "SpringElectricalEmbedding"]]];
		
		vertices = Union @ Flatten @ set;
		vertexColors = (# -> ColorData[97, Count[set, {#}] + 1] & /@ vertices);
		edgesWithColors = Annotation[#[[1]], EdgeStyle -> #[[2]]] & /@
			Sort @ Flatten @ MapIndexed[
				Thread[#1 -> hyperedgeColors[[#2[[1]]]]] &,
				DirectedEdge @@@ Partition[#, 2, 1] & /@ hyperedges];
		graphForPlotting = EdgeTaggedGraph[
			vertices,
			Join[
				If[OptionValue[DirectedEdges], DirectedEdge, UndirectedEdge] @@@ edges,
				edgesWithColors]];
	];
	graphPlotOptions =
		FilterRules[FilterRules[{o}, Options[GraphPlot]], Except[PlotStyle]];
	GraphPlot[
		graphForPlotting,
		Join[
			graphPlotOptions, {
			VertexStyle -> vertexColors,
			VertexCoordinates ->
				(VertexList[graphForPlotting] /. coordinateRules)}]] /; !failedQ
]
