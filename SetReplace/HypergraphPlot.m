Package["SetReplace`"]

PackageExport["HypergraphPlot"]

(* Documentation *)

HypergraphPlot::usage = usageString[
	"HypergraphPlot[`s`, `opts`] plots a list of vertex lists `s` as a hypergraph."]

SyntaxInformation[HypergraphPlot] = {"ArgumentsPattern" -> {_, OptionsPattern[]}};

Options[HypergraphPlot] = Join[{
	"EdgeType" -> "Ordered",
	GraphLayout -> "SpringElectricalEmbedding"},
	Options[Show]];

$edgeTypes = {"Ordered"};
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

supportedFiniteOptionQ[func_, optionToCheck_, validValues_, opts_] := Module[{value, recognizedQ},
	value = OptionValue[func, {opts}, optionToCheck];
	recognizedQ = MemberQ[validValues, value];
	If[!recognizedQ,
		Message[Message[func, "invalidFiniteOption"], optionToCheck, value, validValues]
	];
	recognizedQ
]

hypergraphPlot$parse[edges_, o : OptionsPattern[]] /; (
		!supportedFiniteOptionQ[HypergraphPlot, ##, {o}] & @@@ {
			{"EdgeType", $edgeTypes},
			{GraphLayout, $graphLayouts}}) :=
	$Failed

hypergraphPlot$parse[edges : {___List}, o : OptionsPattern[]] :=
	hypergraphPlot[edges, ##, FilterRules[{o}, Options[Show]]] & @@
		(OptionValue[HypergraphPlot, {o}, #] & /@ {"EdgeType", GraphLayout})

(* Implementation *)

hypergraphPlot[edges_, edgeType_, layout_, showOptions_] :=
	Show[drawEmbedding @ hypergraphEmbedding[edgeType, layout] @ edges, showOptions]

(** hypergraphEmbedding produces an embedding of vertices and edges. The format is {vertices, edges},
			where both vertices and edges are associations of the form <|vertex -> {graphicsPrimitive, ...}, ...|>,
			where graphicsPrimitive is either a Point, a Line, or a Polygon. **)

hypergraphEmbedding[edgeType_, layout : "SpringElectricalEmbedding"][edges_] := Module[{vertices},
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
