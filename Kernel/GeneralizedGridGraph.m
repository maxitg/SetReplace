Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["GeneralizedGridGraph"]

(* Documentation *)

SetUsage @ "
GeneralizedGridGraph[{n$1, n$2, $$, n$k}] gives the k-dimensional grid graph with n$1 \[Times] n$2 \[Times] $$ n$k \
 vertices.
GeneralizedGridGraph[{$$, n$k -> 'Circular', $$}] makes the grid wrap around in k-th dimension.
GeneralizedGridGraph[{$$, n$k -> 'Directed', $$}] makes the edges directed in k-th dimension.
GeneralizedGridGraph[{$$, n$k -> {'Circular', 'Directed'}, $$}] makes the grid both circular and directed.
";

Options[GeneralizedGridGraph] = Join[Options[Graph], {"VertexNamingFunction" -> Automatic}];

$vertexNamingFunctions = {Automatic (* IndexGraph *), "Coordinates"};

SyntaxInformation[GeneralizedGridGraph] =
  {"ArgumentsPattern" -> {dimSpecs_, OptionsPattern[]}, "OptionNames" -> Options[GeneralizedGridGraph][[All, 1]]};

GeneralizedGridGraph::dimsNotList = "Dimensions specification `` should be a list.";

GeneralizedGridGraph::invalidDimSpec = "Dimension specification `` is invalid.";

(* Implementation *)

GeneralizedGridGraph[args___] := ModuleScope[
  result = Catch[generalizedGridGraph[args]];
  result /; result =!= $Failed
];

generalizedGridGraph[args___] /; !Developer`CheckArgumentCount[GeneralizedGridGraph[args], 1, 1] := Throw[$Failed];

generalizedGridGraph[args_, opts___] /;
    !knownOptionsQ[GeneralizedGridGraph, Defer[GeneralizedGridGraph[args, opts]], {opts}] := Throw[$Failed];

generalizedGridGraph[args_, opts___] /;
    !supportedOptionQ[GeneralizedGridGraph, "VertexNamingFunction", $vertexNamingFunctions, {opts}] := Throw[$Failed];

generalizedGridGraph[dimSpecs_List, opts___] := generalizedGridGraphExplicit[toExplicitDimSpec /@ dimSpecs, opts];

generalizedGridGraph[dimSpecs : Except[_List], opts___] := (
  Message[GeneralizedGridGraph::dimsNotList, dimSpecs];
  Throw[$Failed];
);

toExplicitDimSpec[spec_] := toExplicitDimSpec[spec, spec];

toExplicitDimSpec[originalSpec_, n_] := toExplicitDimSpec[originalSpec, n -> {}];

toExplicitDimSpec[originalSpec_, n_ -> spec : Except[_List]] := toExplicitDimSpec[originalSpec, n -> {spec}];

$circularString = "Circular";
$directedString = "Directed";

toExplicitDimSpec[_, n_Integer /; n >= 0 -> spec : {($circularString | $directedString)...}] := {
  n,
  If[MemberQ[spec, $circularString], $$circular, $$linear],
  If[MemberQ[spec, $directedString], $$directed, $$undirected]};

toExplicitDimSpec[originalSpec_, _ -> _List] := (
  Message[GeneralizedGridGraph::invalidDimSpec, originalSpec];
  Throw[$Failed];
);

generalizedGridGraphExplicit[dimSpecs_, opts___] := ModuleScope[
  {edgeStyle, vertexNamingFunction} = OptionValue[GeneralizedGridGraph, {opts}, {EdgeStyle, "VertexNamingFunction"}];
  edges = singleDimensionEdges[dimSpecs, #] & /@ Range[Length[dimSpecs]];
  directionalEdgeStyle = EdgeStyle -> If[
      ListQ[edgeStyle] && Length[edgeStyle] == Length[dimSpecs] && AllTrue[edgeStyle, Head[#] =!= Rule &],
    Catenate @ MapThread[Function[{dirEdges, style}, # -> style & /@ dirEdges], {edges, edgeStyle}],
    Nothing];
  If[GraphQ[#], #, Throw[$Failed]] & @ Graph[
    renameVertices[vertexNamingFunction] @ Graph[
      (* Reversal is needed to be consistent with "GridEmbedding" *)
      If[!ListQ[#], {}, #] & @ Flatten[Outer[v @@ Reverse[{##}] &, ##] & @@ Reverse[Range /@ dimSpecs[[All, 1]]]],
      Catenate[edges],
      GraphLayout -> graphLayout[dimSpecs],
      directionalEdgeStyle],
    If[directionalEdgeStyle[[2]] === Nothing, {opts}, FilterRules[{opts}, Except[EdgeStyle]]]]
];

renameVertices[Automatic][graph_] := IndexGraph[graph];

renameVertices["Coordinates"][graph_] := VertexReplace[graph, v[coords___] :> {coords}];

graphLayout[{{n1_, $$linear, _}, {n2_, $$linear, _}}] := {"GridEmbedding", "Dimension" -> {n1, n2}};

graphLayout[_] := "SpringElectricalEmbedding";

singleDimensionEdges[dimSpecs_, k_] := Catenate[
  singleThreadEdges[dimSpecs[[k]], #] & /@
    Flatten[Outer[v, ##] & @@ ReplacePart[Range /@ dimSpecs[[All, 1]], k -> {threadDim}]]];

singleThreadEdges[{n_, wrapSpec_, dirSpec_}, thread_] :=
  Replace[dirSpec, {$$directed -> DirectedEdge, $$undirected -> UndirectedEdge}] @@@
    Partition[thread /. threadDim -> # & /@ Range[n], 2, 1, {1, Replace[wrapSpec, {$$linear -> -1, $$circular -> 1}]}];
