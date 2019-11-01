Package["SetReplace`"]

PackageExport["HypergraphPlot"]

(* Documentation *)

HypergraphPlot::usage = usageString[
	"HypergraphPlot[`s`, `opts`] plots a list of vertex lists `s` as a hypergraph."]

SyntaxInformation[HypergraphPlot] = {"ArgumentsPattern" -> {_, OptionsPattern[]}};

Options[HypergraphPlot] = Join[{
	GraphLayout -> "SpringElectricalEmbedding"},
	Options[Show]];

$graphLayouts = {"SpringElectricalEmbedding"};

(* Messages *)

HypergraphPlot::notImplemented =
	"Not implemented: `1`.";

HypergraphPlot::invalidEdges =
	"First argument of HypergraphPlot must be list of lists, where elements represent vertices.";

HypergraphPlot::unknownLayout =
	"Graph layout `1` should be one of `2`.";

(* Evaluation *)

func : HypergraphPlot[args___] := Module[{result = hypergraphPlot$parse[args]},
	If[Head[result] === hypergraphPlot$failing,
		Message[HypergraphPlot::notImplemented, Defer[func]];
		result = $Failed];
	result /; Head[result] =!= $Failed
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

hypergraphPlot$parse[edges_, o : OptionsPattern[]] := Module[{graphLayout, recognizedQ},
	graphLayout = OptionValue[HypergraphPlot, {o}, GraphLayout];
	recognizedQ = MemberQ[$graphLayouts, graphLayout];
	If[!recognizedQ,
		Message[HypergraphPlot::unknownLayout, graphLayout, $graphLayouts]
	];
	$Failed /; !recognizedQ
]

hypergraphPlot$parse[edges : {___List}, o : OptionsPattern[]] :=
	hypergraphPlot[edges, OptionValue[HypergraphPlot, {o}, GraphLayout], {o}]

(* Implementation *)

hypergraphPlot[edges_, layout_, showOptions_] :=
	Show[drawEmbedding @ hypergraphEmbedding[layout] @ edges, showOptions]

(** hypergraphEmbedding produces an embedding of vertices and edges. The format is {vertices, edges},
			where both vertices and edges are associations of the form <|vertex -> {graphicsPrimitive, ...}, ...|>,
			where graphicsPrimitive is either a Point, a Line, or a Polygon. **)

hypergraphEmbedding["SpringElectricalEmbedding"][edges_] := Module[{vertices},
	vertices = Union[Flatten[edges]];
	{
		# -> {Point[RandomReal[1, 2]]} & /@ vertices,
		# -> {Line[RandomReal[1, {2, 2}]], Polygon[RandomReal[1, {3, 2}]]} & /@ edges
	}
]

drawEmbedding[embedding_] := Graphics[embedding[[{2, 1}, All, 2]] /. {
	Point[p_] :> {Opacity[.7], Disk[p, 0.03]},
	Polygon[pts_] :> {Opacity[.3], Polygon[pts]}
}]
