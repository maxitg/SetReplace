Package["SetReplace`"]

PackageExport["HypergraphPlot"]

(* Documentation *)

HypergraphPlot::usage = usageString[
	"HypergraphPlot[`s`, `opts`] plots a list of vertex lists `s` as a hypergraph."]

SyntaxInformation[HypergraphPlot] = {"ArgumentsPattern" -> {_, OptionsPattern[]}};

Options[HypergraphPlot] = Options[Graphics];

(* Messages *)

HypergraphPlot::notImplemented = "Not implemented: `1`.";

HypergraphPlot::invalidEdges =
	"First argument of HypergraphPlot must be list of lists, where elements represent vertices.";

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

hypergraphPlot$parse[edges : {___List}, o : OptionsPattern[]] := hypergraphPlot[edges, {o}]

(* Implementation *)

hypergraphPlot[edges_, graphicsOptions_] :=
	Graphics[(styleShapes @ embeddingShapes @ hypergraphEmbedding @ edges)[[All, All, 2]], graphicsOptions]

(** hypergraphEmbedding produces an embedding of vertices and edges. The format is {vertices, edges},
			where both vertices and edges are associations of the form <|vertex -> {graphicsPrimitive, ...}, ...|>,
			where graphicsPrimitive is either a Point, a Line, or a Polygon. **)

hypergraphEmbedding[edges_] := Module[{vertices},
	vertices = Union[Flatten[edges]];
	{
		# -> {Point[RandomReal[1, 2]]} & /@ vertices,
		# -> {Line[RandomReal[1, {2, 2}]], Polygon[RandomReal[1, {3, 2}]]} & /@ edges
	}
]

embeddingShapes[embedding_] := embedding

styleShapes[shapes_] := shapes