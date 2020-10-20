Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["HypergraphToGraph"]

(* Documentation *)
HypergraphToGraph::usage = usageString[
  "HypergraphToGraph[`hg`, `method`] converts a hypergraph `hg` to a graph by using `method`."];

(* Options *)
Options[HypergraphToGraph] = Join[{}, Options @ Graph];

(* SyntaxInformation *)
SyntaxInformation[HypergraphToGraph] = {
  "ArgumentsPattern" -> {_, _, OptionsPattern[]},
  "OptionNames" -> Options[HypergraphToGraph][All, 1]};

(* Argument count *)
HypergraphToGraph[args___] := 0 /;
  !Developer`CheckArgumentCount[HypergraphToGraph[args], 2, 2] && False

(* main *)
expr : HypergraphToGraph[hgraph_, method_, opts : OptionsPattern[HypergraphToGraph]] := ModuleScope[
  res = Catch[hypergraphToGraph[HoldForm @ expr, hgraph, method, opts]];
  res /; res =!= $Failed
]

(* methods *)
$validMethods = {"DistancePreserving"};

(* error messages *)
HypergraphToGraph::invalidMethod = StringJoin[{
  "The argument at position 2 in `1` is not ",
  Replace[ToString[#, InputForm] & /@ $validMethods, {{a__, b_} :> {Riffle[{a}, ", "], " or ", b}}],
  "."}];

(** Distance matrix preserving **)
hypergraphToGraph[_, hgraph_ ? hypergraphQ, "DistancePreserving", opts : OptionsPattern[]] :=
  Graph[
    vertexList @ hgraph,
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

hypergraphToGraph[expr_, _, method_, ___] /; !MemberQ[$validMethods, method] :=
  (Message[HypergraphToGraph::invalidMethod, HoldForm @ expr];
  Throw[$Failed])
