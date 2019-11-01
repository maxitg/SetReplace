Package["SetReplace`"]

PackageExport["HypergraphPlot"]

(* Documentation *)

HypergraphPlot::usage = usageString[
	"HypergraphPlot[`s`, `opts`] plots a list of vertex lists `s` as a hypergraph."]

SyntaxInformation[HypergraphPlot] = {"ArgumentsPattern" -> {_, OptionsPattern[]}};

Options[HypergraphPlot] = Join[{
	},
	Options[Graphics]];

(* Evaluation *)

HypergraphPlot[args___] := With[{result = hypergraphPlot$dispatch[args]},
	result /; result =!= $Failed
]

(* Messages *)

HypergraphPlot::invalidEdges =
	"First argument of HypergraphPlot must be list of lists, where elements represent vertices.";

HypergraphPlot::optx =
	"Unknown option `1` in `2`.";

(* Arguments parsing *)

hypergraphPlot$dispatch[args___] := Switch[{args},
	{a___} /; !Developer`CheckArgumentCount[HypergraphPlot[a], 1, 1],
		$Failed,
	{edges : Except[{___List}], ___},
		Message[HypergraphPlot::invalidEdges];
		$Failed,
	{edges_, o : OptionsPattern[HypergraphPlot]} /;
			Quiet[Check[OptionValue[HypergraphPlot, {o}, ImageSize]]; False, True],

		$Failed,
	_,
		"evaluated"
]