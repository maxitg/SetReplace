Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["CausalDensityDimension"]

(* Documentation *)
SetUsage @ "
CausalDensityDimension[graph$, vertices$] gives an estimate of the dimension of a subgraph of the graph graph$ \
between the vertices vertices$, using the Myrheim-Meyer dimension estimation algorithm.
";

(* SyntaxInformation *)
SyntaxInformation[CausalDensityDimension] =
  {"ArgumentsPattern" -> {causalGraph_, vertices_}};

(* Argument count *)
CausalDensityDimension[args___] := 0 /;
  !Developer`CheckArgumentCount[CausalDensityDimension[args], 2, 2] && False;

(* main *)
expr : CausalDensityDimension[causalGraph_, vertices_] := ModuleScope[
  res = Catch[causalDensityDimension[causalGraph, vertices]];
  If[FailureQ[res], Switch[res[[1]],
    "invalidGraph", Message[CausalDensityDimension::invalidGraph, 1, HoldForm @ expr],
    "invalidVertexList", Message[CausalDensityDimension::invalidVertexList, 2, HoldForm @ expr],
    "invalidVertex", Message[CausalDensityDimension::invalidVertex, res[[2, "vertex"]], HoldForm @ expr]
  ]];
  res /; !FailureQ[res]
];

(* Normal form *)
causalDensityDimension[causalGraph_, vertices_] := Module[{d},
  With[{
    diamond = TransitiveClosureGraph[acyclicGraphTake[causalGraph, vertices]]},
    If[EmptyGraphQ[diamond],
      Infinity
    ,
      Replace[d, FindRoot[
        {EdgeCount[diamond] / ((VertexCount[diamond])^2) == (Gamma[d + 1] * Gamma[d / 2])/(4 Gamma[3 d / 2])},
        {d, 1, 0, Infinity}]]]
  ]
]
