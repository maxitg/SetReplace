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
	"hypergraph with each hyperedge represented as a sequence of same-color arrows. ",
	"Graph options `opts` can be used."];


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


(* ::Subsection:: *)
(*PlotStyle is an indexed ColorDataFunction*)


HypergraphPlot::unsupportedPlotStyle =
	"Only indexed ColorDataFunction, i.e., ColorData[n] is supported as a plot style.";


correctOptionsQ[o___] := Module[
		{plotStyle = OptionValue[HypergraphPlot, {o}, PlotStyle]},
	Head[plotStyle] === ColorDataFunction &&
	plotStyle[[2]] === "Indexed"
]


HypergraphPlot[edges : {___List}, o : OptionsPattern[]] := 0 /;
	!correctOptionsQ[o] &&
	Message[HypergraphPlot::unsupportedPlotStyle]


(* ::Section:: *)
(*Options*)


Options[HypergraphPlot] = Join[Options[Graph], {PlotStyle -> ColorData[97]}];


(* ::Section:: *)
(*Implementation*)


(* ::Text:: *)
(*The idea here is that we are going to draw Graph first while substituting EdgeShapeFunction with a function that collects edge shapes, and produces edge -> hash mapping.*)


(* ::Text:: *)
(*We can then use that to produce hash -> color association, which we use to properly color the edges.*)


HypergraphPlot[edges : {___List}, o : OptionsPattern[]] /;
	correctOptionsQ[o] := Module[
		{normalEdges, vertices, edgeColors, shapeHashes, hashesToColors,
		 graphEdges, graphOptions, graphBoxes, arrowheads, arrowheadOffset,
		 vertexColors},
	normalEdges = Partition[#, 2, 1] & /@ edges;
	vertices = Union @ Flatten @ edges;
	vertexColors = (# -> ColorData[97, Count[edges, {#}] + 1] & /@ vertices);
	edgeColors = Sort @ Flatten @ MapIndexed[
		Thread[DirectedEdge @@@ #1 -> OptionValue[PlotStyle][#2[[1]]]] &, normalEdges];
	graphEdges = DirectedEdge @@@ Flatten[normalEdges, 1];
	graphOptions = FilterRules[{o}, Options[Graph]];
	shapeHashes = Sort @ (If[# == {}, {}, #[[1]]] &) @ Last @ Reap @ Rasterize @
		GraphPlot[Graph[vertices, graphEdges, Join[{
			EdgeShapeFunction -> (Sow[#2 -> Hash[#1]] &)},
			graphOptions]]];
	graphBoxes = ToBoxes[Graph[graphEdges, DirectedEdges -> True]];
	arrowheads =
		If[Length[#] == 0, {}, #[[1]]] & @ Cases[graphBoxes, _Arrowheads, All];
	arrowheadOffset = If[Length[#] == 0, 0, #[[1]]] & @
		Cases[graphBoxes, ArrowBox[x_, offset_] :> offset, All];
	hashesToColors =
		Association @ Thread[shapeHashes[[All, 2]] -> edgeColors[[All, 2]]];
	GraphPlot[Graph[vertices, graphEdges, Join[
		graphOptions,
		{EdgeShapeFunction -> ({
			arrowheads,
			hashesToColors[Hash[#1]],
			Arrow[#1, arrowheadOffset]} &),
		 VertexStyle -> vertexColors}]]]
]
