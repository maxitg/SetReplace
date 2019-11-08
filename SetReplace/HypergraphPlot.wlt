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

(* Valid coordinates *)

VerificationTest[
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, VertexCoordinateRules -> $$$invalid$$$],
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, VertexCoordinateRules -> $$$invalid$$$],
  {HypergraphPlot::invalidCoordinates}
]

VerificationTest[
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, VertexCoordinateRules -> {{0, 0}}],
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, VertexCoordinateRules -> {{0, 0}}],
  {HypergraphPlot::invalidCoordinates}
]

VerificationTest[
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, VertexCoordinateRules -> {1 -> {0}}],
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, VertexCoordinateRules -> {1 -> {0}}],
  {HypergraphPlot::invalidCoordinates}
]

VerificationTest[
  Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, VertexCoordinateRules -> {1 -> {0, 0}}]],
  Graphics
]

(* Valid GraphHighlight *)

VerificationTest[
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> $$$invalid$$$],
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> $$$invalid$$$],
  {HypergraphPlot::invalidHighlight}
]

VerificationTest[
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {6}],
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {6}],
  {HypergraphPlot::invalidHighlight}
]

VerificationTest[
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {{1, 2}}],
  HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {{1, 2}}],
  {HypergraphPlot::invalidHighlight}
]

VerificationTest[
  Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {1}]],
  Graphics
]

VerificationTest[
  Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {{1, 2, 3}}]],
  Graphics
]

VerificationTest[
  Head[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {4, {1, 2, 3}}]],
  Graphics
]

(* Implementation *)

(** Simple examples **)

$edgeTypes = {"Ordered", "CyclicOpen", "CyclicClosed"};

$simpleHypergraphs = {
  {{1, 3}, {2, 4}},
  {},
  {{}},
  {{1}},
  {{1}, {1}},
  {{1}, {2}},
  {{1}, {1}, {2}},
  {{1, 2}, {1}},
  {{1, 2}, {1}, {}}
};

Table[VerificationTest[
  Head[HypergraphPlot[hypergraph, "EdgeType" -> #]],
  Graphics
] & /@ $edgeTypes, {hypergraph, $simpleHypergraphs}]

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
  diskCoordinates[HypergraphPlot[#, "EdgeType" -> "CyclicOpen"]],
  SameTest -> (Not @* Equal)
] & /@ $layoutTestHypergraphs

VerificationTest[
  Length[Union[Cases[
    HypergraphPlot[#, GraphLayout -> "SpringElectricalEmbedding"],
    Polygon[___],
    All]]],
  1
] & /@ $layoutTestHypergraphs

VerificationTest[
  Length[Union[Cases[
    HypergraphPlot[#, GraphLayout -> "SpringElectricalPolygons"],
    Polygon[___],
    All]]],
  1 + Length[#]
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

(* Single-vertex edges *)

VerificationTest[
  HypergraphPlot[{{1}, {1, 2}}],
  HypergraphPlot[{{1, 2}}],
  SameTest -> (Not @* SameQ)
]

VerificationTest[
  MissingQ[FirstCase[
    HypergraphPlot[{{1, 2}}, VertexLabels -> None],
    Circle[___],
    Missing[],
    All]]
]

VerificationTest[
  !MissingQ[FirstCase[
    HypergraphPlot[{{1}, {1, 2}}, VertexLabels -> Automatic],
    Circle[___],
    Missing[],
    All]]
]

(* VertexCoordinateRules *)

VerificationTest[
  And @@ (MemberQ[
      diskCoordinates[HypergraphPlot[
        {{1, 2, 3}, {3, 4, 5}, {3, 3}},
        VertexCoordinateRules -> {1 -> {0, 0}, 2 -> {1, 0}}]],
      #] & /@
    {{0., 0.}, {1., 0.}})
]

VerificationTest[
  Chop @ diskCoordinates[HypergraphPlot[
    {{1, 2, 3}, {3, 4, 5}},
    VertexCoordinateRules -> {3 -> {0, 0}}]],
  Table[{0, 0}, 5],
  SameTest -> (Not @* Equal)
]

VerificationTest[
  Chop @ diskCoordinates[HypergraphPlot[
    {{1, 2, 3}, {3, 4, 5}},
    VertexCoordinateRules -> {3 -> {1, 0}, 3 -> {0, 0}}]],
  Table[{0, 0}, 5],
  SameTest -> (Not @* Equal)
]

(** Same coordinates should not produce any messages **)
VerificationTest[
  And @@ Cases[
    HypergraphPlot[{{1, 2, 3}}, VertexCoordinateRules -> {1 -> {1, 0}, 2 -> {1, 0}}],
    Rotate[_, {v1_, v2_}] :> v1 != {0, 0} && v2 != {0, 0},
    All]
]

(* GraphHighlight *)

VerificationTest[
  Length[Union @ Cases[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}, GraphHighlight -> {#}], _ ? ColorQ, All]] >
    Length[Union @ Cases[HypergraphPlot[{{1, 2, 3}, {3, 4, 5}}], _ ? ColorQ, All]]
] & /@ {4, {1, 2, 3}}

(* Scaling consistency *)
(* Vertex sizes, arrow sizes, average edge lengths, and loop lengths should always be the same. *)

VerificationTest[
  SameQ @@ (
    Union[Cases[HypergraphPlot[#], Disk[_, r_] :> r, All]] & /@
      {{{1}}, {{1, 2, 3}}, {{1, 2, 3}, {3, 4, 5}}, RandomInteger[10, {5, 5}]})
]

VerificationTest[
  SameQ @@ (
    Union[Cases[HypergraphPlot[#, GraphLayout -> "SpringElectricalEmbedding"], p : Polygon[___] :> Area[p], All]] & /@
      {{{1, 2}}, {{1, 2, 3}}, {{1, 2, 3}, {3, 4, 5}}, RandomInteger[10, {5, 5}]})
]

VerificationTest[
  Equal @@ (
    Mean[Cases[
        HypergraphPlot[#, GraphLayout -> "SpringElectricalEmbedding"],
        Line[pts_] :> EuclideanDistance @@ pts,
        All]] & /@
      {{{1, 2}}, {{1, 2, 3}}, {{1, 2, 3}, {3, 4, 5}}, {{1, 2, 3}, {3, 4, 5}, {5, 6, 1}}, {{1, 2, 3, 4, 5, 1}}})
]

$selfLoopLength = FirstCase[
  HypergraphPlot[{{1, 1}}, GraphLayout -> "SpringElectricalEmbedding"],
  Line[pts_] :> RegionMeasure[Line[pts]],
  Missing[],
  All];

VerificationTest[
  And @@ (
    MemberQ[
        Cases[
          HypergraphPlot[#, GraphLayout -> "SpringElectricalEmbedding"],
          Line[pts_] :> RegionMeasure[Line[pts]],
          All],
        $selfLoopLength] & /@ {
      {{1, 1}},
      {{1, 2, 3}, {1, 1}},
      {{1, 2, 3}, {3, 4, 5}, {5, 5}},
      {{1, 2, 3}, {3, 4, 5}, {5, 6, 1, 1}},
      {{1, 2, 3, 4, 5, 5, 1}}})
]

EndTestSection[]
