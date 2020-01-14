Package["SetReplace`"]

PackageScope["vertexList"]
PackageScope["fromCounts"]
PackageScope["multisetIntersection"]
PackageScope["indexHypergraph"]

vertexList[edges_] := Sort[Union[Catenate[edges]]]

fromCounts[association_] := Catenate @ KeyValueMap[ConstantArray] @ association

multisetIntersection[sets___] := fromCounts[Merge[KeyIntersection[Counts /@ {sets}], Min]]

indexHypergraph[e_] := With[{vertices = vertexList[e]}, Replace[e, Thread[vertices -> Range[Length[vertices]]], {2}]]
