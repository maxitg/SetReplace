BeginTestSection["HypergraphPlot"]

(* Argument Checks *)

(** Argument count **)

VerificationTest[
  HypergraphPlot[],
  HypergraphPlot[],
  {HypergraphPlot::argx}
]

VerificationTest[
  HypergraphPlot[{{1, 2}}, {{1, 2}}],
  HypergraphPlot[{{1, 2}}, {{1, 2}}],
  {HypergraphPlot::argx}
]

(** Valid edges **)

VerificationTest[
  HypergraphPlot[1],
  HypergraphPlot[1],
  {HypergraphPlot::invalidEdges}
]

VerificationTest[
  HypergraphPlot[{1, 2}],
  HypergraphPlot[{1, 2}],
  {HypergraphPlot::invalidEdges}
]

VerificationTest[
  HypergraphPlot[{{1, 3}, 2}],
  HypergraphPlot[{{1, 3}, 2}],
  {HypergraphPlot::invalidEdges}
]

VerificationTest[
  HypergraphPlot[{{1, 3}, 6, {2, 4}}],
  HypergraphPlot[{{1, 3}, 6, {2, 4}}],
  {HypergraphPlot::invalidEdges}
]

(** Valid PlotStyle **)

VerificationTest[
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, PlotStyle -> Red],
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, PlotStyle -> Red],
  {HypergraphPlot::notColor}
]

VerificationTest[
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, PlotStyle -> 23],
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, PlotStyle -> 23],
  {HypergraphPlot::notColor}
]

VerificationTest[
  FreeQ[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, PlotStyle -> ColorData[1]], ColorData[1, 1]],
  False
]

VerificationTest[
  FreeQ[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, PlotStyle -> ColorData[1]], ColorData[1, 2]],
  False
]

VerificationTest[
  FreeQ[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, PlotStyle -> ColorData[1]], ColorData[1, 3]],
  True
]

(** Valid HyperedgeType **)

VerificationTest[
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "HyperedgeType" -> None],
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "HyperedgeType" -> None],
  {HypergraphPlot::invalidHyperedgeType}
]

VerificationTest[
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "HyperedgeType" -> "$$$Incorrect$$$"],
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "HyperedgeType" -> "$$$Incorrect$$$"],
  {HypergraphPlot::unknownHyperedgeType}
]

VerificationTest[
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "HyperedgeType" -> {"$$$Incorrect$$$"}],
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "HyperedgeType" -> {"$$$Incorrect$$$"}],
  {HypergraphPlot::unknownHyperedgeType}
]

VerificationTest[
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "HyperedgeType" -> {{1, 2, 3} -> "$$$Incorrect$$$"}],
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "HyperedgeType" -> {{1, 2, 3} -> "$$$Incorrect$$$"}],
  {HypergraphPlot::unknownHyperedgeType}
]

VerificationTest[
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "HyperedgeType" -> {None, {1, 2, 3} -> "Ordered"}],
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "HyperedgeType" -> {None, {1, 2, 3} -> "Ordered"}],
  {HypergraphPlot::invalidHyperedgeType}
]

VerificationTest[
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "HyperedgeType" -> {"$$$Incorrect$$$", {1, 2, 3} -> "Ordered"}],
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "HyperedgeType" -> {"$$$Incorrect$$$", {1, 2, 3} -> "Ordered"}],
  {HypergraphPlot::unknownHyperedgeType}
]

VerificationTest[
  HypergraphPlot[
    {{1, 2, 3}, {3, 4, 5}},
    "HyperedgeType" -> {{3, 4, 5} -> "Ordered", {1, 2, 3} -> "$$$Incorrect$$$"}],
  HypergraphPlot[
    {{1, 2, 3}, {3, 4, 5}},
    "HyperedgeType" -> {{3, 4, 5} -> "Ordered", {1, 2, 3} -> "$$$Incorrect$$$"}],
  {HypergraphPlot::unknownHyperedgeType}
]

VerificationTest[
  Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "HyperedgeType" -> "Ordered"]],
  Graphics
]

VerificationTest[
  Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "HyperedgeType" -> "Cyclic"]],
  Graphics
]

VerificationTest[
  Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "HyperedgeType" -> "Unordered"]],
  Graphics
]

VerificationTest[
  Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "HyperedgeType" -> {"Ordered"}]],
  Graphics
]

VerificationTest[
  Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "HyperedgeType" -> {{1, 2, 3} -> "Cyclic"}]],
  Graphics
]

VerificationTest[
  Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "HyperedgeType" -> {"Cyclic", {1, 2, 3} -> "Ordered"}]],
  Graphics
]

VerificationTest[
  Head[HypergraphPlot[
    {{1, 2, 3}, {3, 4, 5}},
    "HyperedgeType" -> {{3, 4, 5} -> "Unordered", {1, 2, 3} -> "Cyclic"}]],
  Graphics
]

VerificationTest[
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "HyperedgeType" -> {"Cyclic", {1, 2, 3} -> 123}],
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "HyperedgeType" -> {"Cyclic", {1, 2, 3} -> 123}],
  {HypergraphPlot::unknownHyperedgeType}
]

(*** {1, 2, 4} never appears in the hypergraph, so is never used. ***)
VerificationTest[
  Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "HyperedgeType" -> {"Cyclic", {1, 2, 4} -> 123}]],
  Graphics
]

(* Implementation *)

(** Simple examples **)

VerificationTest[
  Head[HypergraphPlot[{{1, 3}, {2, 4}}]],
  Graphics
]

(** Large graphs **)

VerificationTest[
  Head @ HypergraphPlot @ SetReplace[
    {{0, 1}, {0, 2}, {0, 3}},
    ToPatternRules[
      {{0, 1}, {0, 2}, {0, 3}} ->
      {{4, 5}, {5, 4}, {4, 6}, {6, 4},
        {5, 6}, {6, 5}, {4, 1}, {5, 2}, {6, 3}}],
    #],
  Graphics
] & /@ {10, 5000}

(* Vertices with single-vertex edges colored differently *)

VerificationTest[
  FreeQ[HypergraphPlot[{{1, 2}}], ColorData[97, #]] & /@ {1, 2, 3},
  {False, True, True}]

VerificationTest[
  FreeQ[HypergraphPlot[{{1}}], ColorData[97, #]] & /@ {1, 2, 3},
  {True, False, True}]

VerificationTest[
  FreeQ[HypergraphPlot[{{1}, {1}}], ColorData[97, #]] & /@ {1, 2, 3},
  {True, True, False}]

(* HyperedgeType *)

diskCoordinates[graphics_] := Sort[
  #[[1, 1, Cases[#, Disk[i_, ___] :> i, All]]] & @
    Cases[graphics, GraphicsComplex[___], All]]

$layoutTestHypergraphs = {
  {{1, 2, 3}, {3, 4, 5}},
  {{1, 2, 3, 4, 5}, {5, 6, 7, 8, 9}},
  {{1, 2, 3, 4, 5, 6, 7, 8, 9}, {1, 4, 7}},
  {{1, 2, 3, 4, 5, 6}, {1, 2, 3, 4}},
  {{1, 2, 3}, {3, 4, 5}, {1, 2, 3, 4}}
};

VerificationTest[
  diskCoordinates[HypergraphPlot[#, "HyperedgeType" -> "Ordered"]],
  Sort @ GraphEmbedding[
    Rule @@@ Catenate[Partition[#, 2, 1] & /@ #],
    "SpringElectricalEmbedding"],
  SameTest -> Equal
] & /@ $layoutTestHypergraphs

VerificationTest[
  diskCoordinates[HypergraphPlot[#, "HyperedgeType" -> "Cyclic"]],
  Sort @ GraphEmbedding[
    Rule @@@ Catenate[Append[Partition[#, 2, 1], #[[{-1, 1}]]] & /@ #],
    "SpringElectricalEmbedding"],
  SameTest -> Equal
] & /@ $layoutTestHypergraphs

VerificationTest[
  diskCoordinates[HypergraphPlot[#, "HyperedgeType" -> "Unordered"]],
  Sort @ GraphEmbedding[
    Rule @@@ Catenate[Subsets[#, {2}] & /@ #],
    "SpringElectricalEmbedding"],
  SameTest -> Equal
] & /@ $layoutTestHypergraphs

VerificationTest[
  diskCoordinates[HypergraphPlot[#, "HyperedgeType" -> "Ordered"]],
  diskCoordinates[HypergraphPlot[#, "HyperedgeType" -> "Cyclic"]],
  SameTest -> (Not @* Equal)
] & /@ $layoutTestHypergraphs

VerificationTest[
  diskCoordinates[HypergraphPlot[#, "HyperedgeType" -> "Ordered"]],
  diskCoordinates[HypergraphPlot[#, "HyperedgeType" -> "Unordered"]],
  SameTest -> (Not @* Equal)
] & /@ $layoutTestHypergraphs

VerificationTest[
  diskCoordinates[HypergraphPlot[#, "HyperedgeType" -> "Unordered"]],
  diskCoordinates[HypergraphPlot[#, "HyperedgeType" -> "Cyclic"]],
  SameTest -> (Not @* Equal)
] & /@ $layoutTestHypergraphs

VerificationTest[
  diskCoordinates[HypergraphPlot[
    {{1, 2, 3, 4, 5, 6}, {1, 2, 3, 4}},
    "HyperedgeType" -> {"Ordered", {_, _, _, _} -> "Cyclic"}]],
  Sort @ GraphEmbedding[
    {1 -> 2, 2 -> 3, 3 -> 4, 4 -> 5, 5 -> 6, 1 -> 2, 2 -> 3, 3 -> 4, 4 -> 1},
    "SpringElectricalEmbedding"],
  SameTest -> Equal
]

VerificationTest[
  diskCoordinates[HypergraphPlot[
    {{1, 2, 3, 4, 5, 6}, {1, 2, 3, 4}},
    "HyperedgeType" -> {"Ordered", {_, _, _, _} -> "Cyclic"}]],
  diskCoordinates[HypergraphPlot[
    {{1, 2, 3, 4, 5, 6}, {1, 2, 3, 4}},
    "HyperedgeType" -> {"Ordered"}]],
  SameTest -> (Not @* Equal)
]

EndTestSection[]
