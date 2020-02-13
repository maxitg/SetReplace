Package["SetReplace`"]

PackageScope["vertexList"]
PackageScope["fromCounts"]
PackageScope["multisetIntersection"]
PackageScope["multisetComplement"]
PackageScope["indexHypergraph"]

vertexList[edges_] := Sort[Union[Catenate[edges]]]

fromCounts[association_] := Catenate @ KeyValueMap[ConstantArray] @ association

multisetIntersection[sets___] := fromCounts[Merge[KeyIntersection[Counts /@ {sets}], Min]]

multisetComplement[set1_, set2_] := fromCounts[Select[# > 0 &][Merge[{Counts[set1], -Counts[set2]}, Total]]]

indexHypergraph[e_] := With[{vertices = vertexList[e]}, Replace[e, Thread[vertices -> Range[Length[vertices]]], {2}]]
