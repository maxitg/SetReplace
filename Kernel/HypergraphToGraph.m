Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["HypergraphToGraph"]

(* Documentation *)
HypergraphToGraph::usage = usageString[
  "HypergraphToGraph[`hg`] convert a hypergraph `hg` to a graph.",
  "\n",
  "HypergraphToGraph[`hg`, Method -> `method`] uses `method` for the conversion."];

(* Options *)
Options[HypergraphToGraph] = Join[{Method -> Automatic}, Options @ Graph];

(* SyntaxInformation *)
SyntaxInformation[HypergraphToGraph] = {
  "ArgumentsPattern" -> {_, OptionsPattern[]},
  "OptionNames" -> Options[HypergraphToGraph][All, 1]};

(* Argument count *)
HypergraphToGraph[args___] := 0 /;
  !Developer`CheckArgumentCount[HypergraphToGraph[args], 1, 1] && False

(* main *)
expr : HypergraphToGraph[hgraph_, opts : OptionsPattern[HypergraphToGraph]] := ModuleScope[
  res = Catch[hypergraphToGraph[HoldForm @ expr, hgraph, opts]];
  res /; res =!= $Failed
]

(* methods *)
$automaticMethod = "DistanceMatrix";
$validMethods = {"DistanceMatrix", "Structure"};

(* error messages *)
HypergraphToGraph::bdmtd = StringJoin[{
  "Value of option Method -> `1` is not",
  Replace[ToString[#, InputForm] & /@ $validMethods, {a___, b_} :> {Riffle[{a}, ", "], " or ", b}],
  "."}];

(* internal *)
hypergraphToGraph[_, hgraph_ ? hypergraphQ, opts : OptionsPattern[]] := ModuleScope[
  method = OptionValue[HypergraphToGraph, {opts}, Method];
  If[method =!= Automatic && !MemberQ[$validMethods, method],
    Message[hypergraphToGraph::bdmtd, method];
    Throw[$Failed],
    method = Replace[method, Automatic -> $automaticMethod]
  ];
  toGraph[method, hgraph, opts]
]

(** Distance matrix preserving **)
toGraph["DistanceMatrix", hgraph_, opts : OptionsPattern[]] :=
  Graph[
    {},
    Flatten[
      Table[
        DirectedEdge[edge[[j]], edge[[i]]],
        {edge, hgraph},
        {i, Length @ edge},
        {j, i - 1}],
      2],
    FilterRules[{opts}, Options @ Graph]]

(** Structure preserving **)

(* Incorrect arguments messages *)
hypergraphToGraph[expr_, hgraph_ ? (Not @* hypergraphQ), ___] :=
  (Message[HypergraphToGraph::invalidHypergraph, 1, HoldForm @ expr];
  Throw[$Failed])
