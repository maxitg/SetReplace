Package["SetReplace`"]

PackageExport["GeneralizedGridGraph"]

(* Documentation *)

GeneralizedGridGraph::usage = usageString[
  "GeneralizedGridGraph[{\*SubscriptBox[`n`, `1`], \*SubscriptBox[`n`, `2`], `...`, \*SubscriptBox[`n`, `k`]}] ",
  "gives the k-dimensional grid graph with \*SubscriptBox[`n`, `1`] \[Times] \*SubscriptBox[`n`, `2`] \[Times] `...` ",
  "\[Times] \*SubscriptBox[`n`, `k`] vertices.\n",

  "GeneralizedGridGraph[{`...`, \*SubscriptBox[`n`, `k`] -> \"Circular\", `...`}] makes the grid wrap around ",
  "in k-th dimension.\n",

  "GeneralizedGridGraph[{`...`, \*SubscriptBox[`n`, `k`] -> \"Directed\", `...`}] makes the edges directed ",
  "in k-th dimension.\n",

  "GeneralizedGridGraph[{`...`, \*SubscriptBox[`n`, `k`] -> {\"Circular\", \"Directed\"}, `...`}] makes the grid both ",
  "circular and directed."];

Options[GeneralizedGridGraph] = Options[Graph];

SyntaxInformation[GeneralizedGridGraph] =
  {"ArgumentsPattern" -> {_, OptionsPattern[]}, "OptionNames" -> Options[GeneralizedGridGraph][[All, 1]]};

GeneralizedGridGraph::dimsNotList = "Dimensions specification `` should be a list.";

GeneralizedGridGraph::invalidDimSpec = "Dimension specification `` is invalid.";

(* Implementation *)

GeneralizedGridGraph[args___] := Module[{result = Catch[generalizedGridGraph[args]]},
  result /; result =!= $Failed
]

generalizedGridGraph[args___] /; !Developer`CheckArgumentCount[GeneralizedGridGraph[args], 1, 1] := Throw[$Failed]

generalizedGridGraph[args_, opts___] /;
    !knownOptionsQ[GeneralizedGridGraph, Defer[GeneralizedGridGraph[args, opts]], {opts}] := Throw[$Failed]

generalizedGridGraph[dimSpecs_List, opts___] := generalizedGridGraphExplicit[toExplicitDimSpec /@ dimSpecs, opts]

generalizedGridGraph[dimSpecs : Except[_List], opts___] := (
  Message[GeneralizedGridGraph::dimsNotList, dimSpecs];
  Throw[$Failed];
)

toExplicitDimSpec[spec_] := toExplicitDimSpec[spec, spec]

toExplicitDimSpec[originalSpec_, n_] := toExplicitDimSpec[originalSpec, n -> {}]

toExplicitDimSpec[originalSpec_, n_ -> spec : Except[_List]] := toExplicitDimSpec[originalSpec, n -> {spec}]

$circularString = "Circular";
$directedString = "Directed";

toExplicitDimSpec[_, n_Integer /; n >= 0 -> spec : {($circularString | $directedString)...}] := {
  n,
  If[MemberQ[spec, $circularString], $$circular, $$linear],
  If[MemberQ[spec, $directedString], $$directed, $$undirected]}

toExplicitDimSpec[originalSpec_, _ -> _List] := (
  Message[GeneralizedGridGraph::invalidDimSpec, originalSpec];
  Throw[$Failed];
)

generalizedGridGraphExplicit[dimSpecs_, opts___] := Module[{edges, directionalEdgeStyle},
  edges = singleDimensionEdges[dimSpecs, #] & /@ Range[Length[dimSpecs]];
  directionalEdgeStyle = EdgeStyle -> If[ListQ[#] && Length[#] == Length[dimSpecs] && AllTrue[#, Head[#] =!= Rule &],
      Catenate @ MapThread[Function[{dirEdges, style}, # -> style & /@ dirEdges], {edges, #}],
      Nothing] & @
    OptionValue[GeneralizedGridGraph, {opts}, EdgeStyle];
  If[GraphQ[#], #, Throw[$Failed]] & @ Graph[
    IndexGraph @ Graph[
      (* Reversal is needed to be consistent with "GridEmbedding" *)
      If[!ListQ[#], {}, #] & @ Flatten[Outer[v @@ Reverse[{##}] &, ##] & @@ Reverse[Range /@ dimSpecs[[All, 1]]]],
      Catenate[edges],
      GraphLayout -> graphLayout[dimSpecs],
      directionalEdgeStyle],
    If[directionalEdgeStyle[[2]] === Nothing, {opts}, FilterRules[{opts}, Except[EdgeStyle]]]]
]

graphLayout[{{n1_, $$linear, _}, {n2_, $$linear, _}}] := {"GridEmbedding", "Dimension" -> {n1, n2}}

graphLayout[_] := "SpringElectricalEmbedding"

singleDimensionEdges[dimSpecs_, k_] := Catenate[
  singleThreadEdges[dimSpecs[[k]], #] & /@
    Flatten[Outer[v, ##] & @@ ReplacePart[Range /@ dimSpecs[[All, 1]], k -> {threadDim}]]]

singleThreadEdges[{n_, wrapSpec_, dirSpec_}, thread_] :=
  Replace[dirSpec, {$$directed -> DirectedEdge, $$undirected -> UndirectedEdge}] @@@
    Partition[thread /. threadDim -> # & /@ Range[n], 2, 1, {1, Replace[wrapSpec, {$$linear -> -1, $$circular -> 1}]}]
