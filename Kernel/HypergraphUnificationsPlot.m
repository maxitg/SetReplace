Package["SetReplace`"]

PackageExport["HypergraphUnificationsPlot"]

(* Documentation *)

HypergraphUnificationsPlot::usage = usageString[
  "HypergraphUnificationsPlot[`e1`, `e2`] yields a list of plots of all ways to unify hypergraphs `e1` and `e2`."];

SyntaxInformation[HypergraphUnificationsPlot] = {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};

Options[HypergraphUnificationsPlot] := Options[WolframModelPlot];

(* Implementation *)

HypergraphUnificationsPlot[args___] := Module[{result = Catch[hypergraphUnificationsPlot[args]]},
  result /; result =!= $Failed
]

hypergraphUnificationsPlot[args___] /; !Developer`CheckArgumentCount[HypergraphUnificationsPlot[args], 2, 2] :=
  Throw[$Failed]

$color1 = Red;
$color2 = Blue;

HypergraphUnificationsPlot::emptyEdge = "Empty edges are not supported.";

hypergraphUnificationsPlot[e1_List, e2_List, opts : OptionsPattern[]] := Module[{
    unifications, automaticVertexLabelsList},
  If[Length[Cases[Join[e1, e2], {}]] > 0,
    Message[HypergraphUnificationsPlot::emptyEdge];
    Throw[$Failed];
  ];
  unifications = Check[HypergraphUnifications[e1, e2], Throw[$Failed]];
  automaticVertexLabelsList = unificationVertexLabels[e1, e2] @@@ unifications;
  MapThread[
    Check[WolframModelPlot[
      #1,
      VertexLabels -> Replace[OptionValue[HypergraphUnificationsPlot, {opts}, VertexLabels], Automatic -> #4],
      EdgeStyle -> ReplacePart[
        Table[Automatic, Length[#]],
        Join[
          Thread[Intersection[Values[#2], Values[#3]] -> Blend[{$color1, $color2}]],
          Thread[Values[#2] -> $color1], Thread[Values[#3] -> $color2]]],
      opts], Throw[$Failed]] &,
    {unifications[[All, 1]], unifications[[All, 2]], unifications[[All, 3]], automaticVertexLabelsList}]
]

unificationVertexLabels[e1_, e2_][unification_, edgeMapping1_, edgeMapping2_] := Module[{labels1, labels2},
  {labels1, labels2} =
    Merge[Reverse /@ Union[Catenate[Thread /@ Thread[#1[[Keys[#2]]] -> unification[[Values[#2]]]]]], Identity] & @@@
      {{e1, edgeMapping1}, {e2, edgeMapping2}};
  Normal @ AssociationMap[
    Row[
      Catenate[
        Function[{unif, color}, Style[#, color] & /@ Lookup[unif, #, {}]] @@@ {{labels1, $color1}, {labels2, $color2}}],
      ","] &,
    vertexList[unification]]
]
