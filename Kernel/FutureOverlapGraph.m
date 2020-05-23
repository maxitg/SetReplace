Package["SetReplace`"]

PackageExport["FutureOverlapGraph"]

(* Documentation *)

FutureOverlapGraph::usage = usageString[
  "FutureOverlapGraph[`cg`, {`{\!\(\*SubscriptBox[\(`vi`\), \(`1`\)]\), `...`}, ",
  "{\!\(\*SubscriptBox[\(`vf`\), \(`1`\)]\), `...`}] generates a graph of equivalence classes of the vertices of a ",
  "causal graph `cg` \!\(\*SubscriptBox[\(`vi`\), \(`k`\)]\) such that two vertices are identified if ",
  "the same subsets of \!\(\*SubscriptBox[\(`vf`\), \(`k`\)]\) (futures) appear in their out components.\n",
  "An undirected edge represents intersecting futures, a directed edge represents one future containing the other."];

Options[FutureOverlapGraph] = Options[Graph];

SyntaxInformation[FutureOverlapGraph] = {
  "ArgumentsPattern" -> {_, _, _, OptionsPattern[]},
  "OptionNames" -> Options[FutureOverlapGraph][[All, 1]]};

(* Arguments handling *)

FutureOverlapGraph[args___] := Module[{result = Catch[futureOverlapGraph[args]]},
  result /; result =!= $Failed
]

futureOverlapGraph[args___] /; !Developer`CheckArgumentCount[FutureOverlapGraph[args], 3, 3] := Throw[$Failed]

futureOverlapGraph[causalGraph_ ? (Not @* GraphQ), args___] := (
  Message[FutureOverlapGraph::graph, Defer[FutureOverlapGraph[causalGraph, args]], 1];
  $Failed
)

futureOverlapGraph[causalGraph_ ? GraphQ, initialVertices : Except[_List], args___] := (
  Message[FutureOverlapGraph::list, Defer[FutureOverlapGraph[causalGraph, initialVertices, args]], 2];
  $Failed
)

futureOverlapGraph[causalGraph_ ? GraphQ, initialVertices_List, futureVertices : Except[_List], args___] := (
  Message[FutureOverlapGraph::list, Defer[FutureOverlapGraph[causalGraph, initialVertices, futureVertices, args]], 3];
  $Failed
)

futureOverlapGraph[causalGraph_ ? GraphQ, initialVertices_List, futureVertices_List, o : OptionsPattern[]] /;
    unrecognizedOptions[FutureOverlapGraph, {o}] =!= {} := (
  Message[
    FutureOverlapGraph::optx,
    First[unrecognizedOptions[FutureOverlapGraph, {o}]],
    Defer[FutureOverlapGraph[causalGraph, initialVertices, futureVertices, o]]];
  $Failed
)

(* Implementation *)

futureOverlapGraph[causalGraph_ ? GraphQ, initialVertices_List, futureVertices_List, o : OptionsPattern[]] /;
  unrecognizedOptions[FutureOverlapGraph, {o}] === {} := Module[{
    pastToFuture, resultGraph, resultWithOptions},
  If[AllTrue[Join[initialVertices, futureVertices], VertexQ[causalGraph, #] &],
    pastToFuture = Association[
      Reverse /@ Normal[GroupBy[initialVertices, Intersection[VertexOutComponent[causalGraph, #], futureVertices] &]]];
    resultGraph = GraphUnion @@ Function[{edgeQ, directedQ},
        RelationGraph[
          edgeQ[pastToFuture[#1], pastToFuture[#2]] &,
          Keys[pastToFuture],
          DirectedEdges -> directedQ]] @@@ {
      {!SameQ[#1, #2] && SubsetQ[#1, #2] && Length[#2] != 0 &, True},
      {!SubsetQ[#1, #2] && !SubsetQ[#2, #1] && IntersectingQ[#1, #2] &, False}};
    resultWithOptions = Graph[
      resultGraph,
      Sequence @@ FilterRules[{o}, Except[{VertexStyle, EdgeStyle}]],
      VertexStyle -> Replace[
        OptionValue[FutureOverlapGraph, {o}, VertexStyle],
        Automatic -> style[$lightTheme][$futureOverlapVertexStyle]],
      EdgeStyle -> Replace[
        OptionValue[FutureOverlapGraph, {o}, EdgeStyle], Automatic -> style[$lightTheme][$futureOverlapEdgeStyle]]];
    If[GraphQ[resultWithOptions], resultWithOptions, $Failed],
  (* else *)
    Message[
      FutureOverlapGraph::inv,
      Defer[FutureOverlapGraph[causalGraph, initialVertices, futureVertices]],
      FirstCase[Join[initialVertices, futureVertices], _ ? (Not[VertexQ[causalGraph, #]] &)],
      "vertex"];
    $Failed
  ]
]
