Package["SetReplace`"]

PackageScope["vertexList"]

vertexList[edges_] := Union[Catenate[edges]]

fromCounts[association_] := Catenate @ KeyValueMap[ConstantArray] @ association
