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

(** Valid EdgeType **)

VerificationTest[
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "EdgeType" -> None],
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "EdgeType" -> None],
  {HypergraphPlot::invalidFiniteOption}
]

VerificationTest[
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "EdgeType" -> "$$$Incorrect$$$"],
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "EdgeType" -> "$$$Incorrect$$$"],
  {HypergraphPlot::invalidFiniteOption}
]

VerificationTest[
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "EdgeType" -> {"$$$Incorrect$$$"}],
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "EdgeType" -> {"$$$Incorrect$$$"}],
  {HypergraphPlot::invalidFiniteOption}
]

VerificationTest[
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "EdgeType" -> {{1, 2, 3} -> "$$$Incorrect$$$"}],
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "EdgeType" -> {{1, 2, 3} -> "$$$Incorrect$$$"}],
  {HypergraphPlot::invalidFiniteOption}
]

VerificationTest[
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "EdgeType" -> {None, {1, 2, 3} -> "Ordered"}],
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "EdgeType" -> {None, {1, 2, 3} -> "Ordered"}],
  {HypergraphPlot::invalidFiniteOption}
]

VerificationTest[
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "EdgeType" -> {"$$$Incorrect$$$", {1, 2, 3} -> "Ordered"}],
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "EdgeType" -> {"$$$Incorrect$$$", {1, 2, 3} -> "Ordered"}],
  {HypergraphPlot::invalidFiniteOption}
]

VerificationTest[
  HypergraphPlot[
    {{1, 2, 3}, {3, 4, 5}},
    "EdgeType" -> {{3, 4, 5} -> "Ordered", {1, 2, 3} -> "$$$Incorrect$$$"}],
  HypergraphPlot[
    {{1, 2, 3}, {3, 4, 5}},
    "EdgeType" -> {{3, 4, 5} -> "Ordered", {1, 2, 3} -> "$$$Incorrect$$$"}],
  {HypergraphPlot::invalidFiniteOption}
]

VerificationTest[
  Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "EdgeType" -> "Ordered"]],
  Graphics
]

VerificationTest[
  Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "EdgeType" -> "CyclicOpen"]],
  Graphics
]

VerificationTest[
  Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "EdgeType" -> "CyclicClosed"]],
  Graphics
]

(* Valid options *)

VerificationTest[
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "$$$InvalidOption###" -> True],
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, "$$$InvalidOption###" -> True],
  {HypergraphPlot::optx}
]

(* Implementation *)

(** Simple examples **)

VerificationTest[
  Head[HypergraphPlot[{{1, 3}, {2, 4}}]],
  Graphics
]

VerificationTest[
  Head[HypergraphPlot[{}]],
  Graphics
]

VerificationTest[
  Head[HypergraphPlot[{{}}]],
  Graphics
]

VerificationTest[
  Head[HypergraphPlot[{{1}}]],
  Graphics
]

VerificationTest[
  Head[HypergraphPlot[{{1}, {1}}]],
  Graphics
]

VerificationTest[
  Head[HypergraphPlot[{{1}, {2}}]],
  Graphics
]

VerificationTest[
  Head[HypergraphPlot[{{1}, {1}, {2}}]],
  Graphics
]

VerificationTest[
  Head[HypergraphPlot[{{1, 2}, {1}}]],
  Graphics
]

VerificationTest[
  Head[HypergraphPlot[{{1, 2}, {1}, {}}]],
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

(* EdgeType *)

diskCoordinates[graphics_] := Sort[Cases[graphics, Disk[i_, ___] :> i, All]]

$layoutTestHypergraphs = {
  {{1, 2, 3}, {3, 4, 5}},
  {{1, 2, 3, 4, 5}, {5, 6, 7, 8, 9}},
  {{1, 2, 3, 4, 5, 6, 7, 8, 9}, {1, 4, 7}},
  {{1, 2, 3, 4, 5, 6}, {1, 2, 3, 4}},
  {{1, 2, 3}, {3, 4, 5}, {1, 2, 3, 4}}
};

VerificationTest[
  diskCoordinates[HypergraphPlot[#, "EdgeType" -> "Ordered"]],
  Sort @ GraphEmbedding[
    Rule @@@ Catenate[Partition[#, 2, 1] & /@ #],
    "SpringElectricalEmbedding"],
  SameTest -> Equal
] & /@ $layoutTestHypergraphs

VerificationTest[
  diskCoordinates[HypergraphPlot[#, "EdgeType" -> "CyclicOpen"]],
  Sort @ GraphEmbedding[
    Rule @@@ Catenate[Append[Partition[#, 2, 1], #[[{-1, 1}]]] & /@ #],
    "SpringElectricalEmbedding"],
  SameTest -> Equal
] & /@ $layoutTestHypergraphs

VerificationTest[
  diskCoordinates[HypergraphPlot[#, "EdgeType" -> "CyclicClosed"]],
  Sort @ GraphEmbedding[
    Rule @@@ Catenate[Append[Partition[#, 2, 1], #[[{-1, 1}]]] & /@ #],
    "SpringElectricalEmbedding"],
  SameTest -> Equal
] & /@ $layoutTestHypergraphs

VerificationTest[
  diskCoordinates[HypergraphPlot[#, "EdgeType" -> "Ordered"]],
  diskCoordinates[HypergraphPlot[#, "EdgeType" -> "CyclicOpen"]],
  SameTest -> (Not @* Equal)
] & /@ $layoutTestHypergraphs

VerificationTest[
  diskCoordinates[HypergraphPlot[#, "EdgeType" -> "CyclicOpen"]],
  diskCoordinates[HypergraphPlot[#, "EdgeType" -> "CyclicClosed"]],
  SameTest -> Equal
] & /@ $layoutTestHypergraphs

VerificationTest[
  MissingQ[FirstCase[
    HypergraphPlot[#, GraphLayout -> "SpringElectricalEmbedding"],
    Polygon[___],
    Missing[],
    All]]
] & /@ $layoutTestHypergraphs

VerificationTest[
  !MissingQ[FirstCase[
    HypergraphPlot[#, GraphLayout -> "SpringElectricalPolygons"],
    Polygon[___],
    Missing[],
    All]]
] & /@ $layoutTestHypergraphs

(* VertexLabels *)

VerificationTest[
  MissingQ[FirstCase[
    HypergraphPlot[#, VertexLabels -> None],
    Text[___],
    Missing[],
    All]]
] & /@ $layoutTestHypergraphs

VerificationTest[
  !MissingQ[FirstCase[
    HypergraphPlot[#, VertexLabels -> Automatic],
    Text[___],
    Missing[],
    All]]
] & /@ $layoutTestHypergraphs

EndTestSection[]
