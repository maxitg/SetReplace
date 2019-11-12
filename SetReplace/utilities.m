Package["SetReplace`"]

PackageScope["vertexList"]
PackageScope["fromCounts"]

vertexList[edges_] := Union[Catenate[edges]]

fromCounts[association_] := Catenate @ KeyValueMap[ConstantArray] @ association
