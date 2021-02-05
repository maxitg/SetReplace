Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["GraphDimension"]

$dimensionMethods = {
  "FlatCausalDiamondRelationProbability"
};

With[{
    methods = $dimensionMethods
  },
  FE`Evaluate[FEPrivate`AddSpecialArgCompletion["GraphDimension" -> {0, methods, 0}]];
];

(* Documentation *)
SetUsage @ "
GraphDimension[gr$, mth$, vrts$] gives an estimate of the dimension of a subgraph of the graph gr$ \
between the vertices vrts$, using the method mth$.
";

(* SyntaxInformation *)
SyntaxInformation[GraphDimension] =
  {"ArgumentsPattern" -> {causalGraph_, method_, vertices_}};

(* Argument count *)
GraphDimension[args___] := 0 /;
  !Developer`CheckArgumentCount[GraphDimension[args], 3, 3] && False;

(* main *)
expr : GraphDimension[causalGraph_, method_, vertices_] := ModuleScope[
  res = Catch[graphDimension[causalGraph, method, vertices]];
  If[FailureQ[res], Switch[res[[1]],
    "invalidGraph", Message[GraphDimension::invalidGraph, 1, HoldForm @ expr],
    "invalidVertexList", Message[GraphDimension::invalidVertexList, 3, HoldForm @ expr],
    "invalidVertex", Message[GraphDimension::invalidVertex, res[[2, "vertex"]], HoldForm @ expr],
    "invalidMethod", Message[GraphDimension::invalidMethod, res[[2, "method"]]]
  ]];
  res /; !FailureQ[res]
];

(* Normal form *)
graphDimension[causalGraph_, "FlatCausalDiamondRelationProbability", vertices_] := ModuleScope[
    With[{
        diamond = TransitiveClosureGraph[acyclicGraphTake[causalGraph, vertices]]},
      If[EmptyGraphQ[diamond], Infinity, 
        Replace[d, FindRoot[
          {EdgeCount[diamond]/((VertexCount[diamond])^2) == (Gamma[d + 1]*Gamma[d/2])/(4 Gamma[3 d/2])},
   	      {d, 1, 0, Infinity}]]]
    ]
]

(* Incorrect arguments messages *)
GraphDimension::invalidMethod = "The method `1` is not supported."
graphDimension[causalGraph_, method_, _] :=
  Throw[Failure["invalidMethod", <|"method" -> method|>]];
