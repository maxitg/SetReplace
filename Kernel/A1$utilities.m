Package["SetReplace`"]

(* Some utility functions are used for, e.g., constructing messages, and thus this file should be loaded early.
   (Files are loaded lexicographically.) *)

PackageScope["fromCounts"]
PackageScope["multisetIntersection"]
PackageScope["multisetUnion"]
PackageScope["multisetComplement"]
PackageScope["multisetFilterRules"]
PackageScope["toCanonicalHypergraphForm"]
PackageScope["vertexList"]
PackageScope["connectedHypergraphQ"]
PackageScope["mapHold"]
PackageScope["heldPart"]
PackageScope["hypergraphQ"]
PackageScope["listToSentence"]
PackageScope["recognizedOptionsQ"]

fromCounts[association_] := Catenate @ KeyValueMap[ConstantArray] @ association;

multisetIntersection[sets___] := fromCounts[Merge[KeyIntersection[Counts /@ {sets}], Min]];

multisetUnion[sets___] := fromCounts[Merge[Counts /@ {sets}, Max]];

multisetComplement[set1_, set2_] := fromCounts[Select[# > 0 &][Merge[{Counts[set1], -Counts[set2]}, Total]]];

multisetFilterRules[rules_, filter_] := Catenate @ MapThread[
  Function[{keyValues, count}, keyValues[[1]] -> # & /@ Take[keyValues[[2]], UpTo[count]]],
  {Normal @ KeySort @ KeyTake[Merge[Association /@ Join[rules, # -> Nothing & /@ filter], # &], filter],
    Values @ KeySort @ Counts[filter]}];

toCanonicalHypergraphForm[edge : Except[_List]] := toCanonicalHypergraphForm[{edge}];

toCanonicalHypergraphForm[edges_List] := toCanonicalEdgeForm /@ edges;

toCanonicalEdgeForm[edge : Except[_List]] := {edge};

toCanonicalEdgeForm[edge_List] := edge;

vertexList[canonicalHypergraph_ ? hypergraphQ] := Sort @ Union @ Catenate @ canonicalHypergraph;

vertexList[edges_] := vertexList[toCanonicalHypergraphForm @ edges];

connectedHypergraphQ[edges_] := ConnectedGraphQ[Graph[Catenate[toNormalEdges /@ toCanonicalHypergraphForm[edges]]]];

toNormalEdges[edge_] := UndirectedEdge @@@ Partition[edge, 2, 1, 1];

SetAttributes[mapHold, HoldFirst];

mapHold[expr_, level_ : {1}] := Map[Hold, Unevaluated[expr], level];

SetAttributes[heldPart, HoldFirst];

heldPart[expr_, part__Integer] := Extract[Unevaluated[expr], {part}, Hold];

hypergraphQ = MatchQ[#, {___List}] &;

declareMessage[General::invalidHypergraph,
               "The argument at position `pos` in `expr` should be a Hypergraph object or a list of lists."];

listToSentence[list_List] :=
  StringJoin @ Replace[ToString[#, InputForm] & /@ list, {{a__, b_} :> {Riffle[{a}, ", "], " or ", b}}];

Attributes[recognizedOptionsQ] = {HoldFirst};
recognizedOptionsQ[expr_, func_, opts_] := With[{unrecognizedOptions = FilterRules[opts, Except[Options[func]]]},
  If[unrecognizedOptions === {},
    True
  ,(* else, some options are not recognized *)
    Message[func::optx, unrecognizedOptions[[1]], Defer[expr]];
    False
  ]
];
