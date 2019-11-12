Package["SetReplace`"]

PackageScope["vertexList"]
PackageScope["fromCounts"]
PackageScope["multisetIntersection"]

vertexList[edges_] := Union[Catenate[edges]]

fromCounts[association_] := Catenate @ KeyValueMap[ConstantArray] @ association

multisetIntersection[sets___] := fromCounts[Merge[KeyIntersection[Counts /@ {sets}], Min]]
