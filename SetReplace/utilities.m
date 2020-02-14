Package["SetReplace`"]

PackageScope["vertexList"]
PackageScope["fromCounts"]
PackageScope["multisetIntersection"]
PackageScope["multisetComplement"]
PackageScope["multisetFilterRules"]
PackageScope["indexHypergraph"]

vertexList[edges_] := Sort[Union[Catenate[edges]]]

fromCounts[association_] := Catenate @ KeyValueMap[ConstantArray] @ association

multisetIntersection[sets___] := fromCounts[Merge[KeyIntersection[Counts /@ {sets}], Min]]

multisetComplement[set1_, set2_] := fromCounts[Select[# > 0 &][Merge[{Counts[set1], -Counts[set2]}, Total]]]

multisetFilterRules[rules_, filter_] := Catenate @ MapThread[
  Function[{keyValues, count}, keyValues[[1]] -> # & /@ Take[keyValues[[2]], UpTo[count]]],
  {Normal @ KeySort @ KeyTake[Merge[Association /@ Join[rules, # -> Nothing & /@ filter], # &], filter],
    Values @ KeySort @ Counts[filter]}]

indexHypergraph[e_] := With[{vertices = vertexList[e]}, Replace[e, Thread[vertices -> Range[Length[vertices]]], {2}]]
