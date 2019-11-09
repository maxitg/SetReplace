BeginTestSection["RulePlot"]

(* Rule correctness checking *)

VerificationTest[
  RulePlot[WolframModel[1]],
  RulePlot[WolframModel[1]],
  {RulePlot::invalidRules}
]

VerificationTest[
  RulePlot[WolframModel[1 -> 2]],
  RulePlot[WolframModel[1 -> 2]],
  {RulePlot::notHypergraphRule}
]

VerificationTest[
  RulePlot[WolframModel[{1} -> {2}]],
  RulePlot[WolframModel[{1} -> {2}]],
  {RulePlot::notHypergraphRule}
]

VerificationTest[
  RulePlot[WolframModel[{{1}} -> {2}]],
  RulePlot[WolframModel[{{1}} -> {2}]],
  {RulePlot::notHypergraphRule}
]

VerificationTest[
  Head[RulePlot[WolframModel[{{1}} -> {{2}}]]],
  Graphics
]

VerificationTest[
  RulePlot[WolframModel[<|"PatternRules" -> {{1}} -> {{2}}|>]],
  RulePlot[WolframModel[<|"PatternRules" -> {{1}} -> {{2}}|>]],
  {RulePlot::patternRules}
]

VerificationTest[
  Head[RulePlot[WolframModel[{{1}} -> {{2}}, Method -> "$$$AnyMethod$$$"]]],
  Graphics
]

VerificationTest[
  RulePlot[WolframModel[{{{1}} -> {{2}}, 1}]],
  RulePlot[WolframModel[{{{1}} -> {{2}}, 1}]],
  {RulePlot::invalidRules}
]

VerificationTest[
  RulePlot[WolframModel[{{{1}} -> {{2}}, 1 -> 2}]],
  RulePlot[WolframModel[{{{1}} -> {{2}}, 1 -> 2}]],
  {RulePlot::notHypergraphRule}
]

VerificationTest[
  Head[RulePlot[WolframModel[{{{1}} -> {{2}}, {{1}} -> {{2}}}]]],
  Graphics
]

(* Options *)

(** EdgeType **)

VerificationTest[
  Not[
    Or @@ SameQ @@@ Subsets[
      Rasterize[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], "EdgeType" -> #]] & /@
        {"Ordered", "CyclicOpen", "CyclicClosed"},
      {2}]]
]

VerificationTest[
  RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], "EdgeType" -> "Invalid"],
  RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], "EdgeType" -> "Invalid"],
  {RulePlot::invalidFiniteOption}
]

VerificationTest[
  RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], "EdgeType" -> 3],
  RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], "EdgeType" -> 3],
  {RulePlot::invalidFiniteOption}
]

(** GraphLayout **)

VerificationTest[
  Not[
    Or @@ SameQ @@@ Subsets[
      Rasterize[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], GraphLayout -> #]] & /@
        {"SpringElectricalEmbedding", "SpringElectricalPolygons"},
      {2}]]
]

VerificationTest[
  RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], GraphLayout -> "Invalid"],
  RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], GraphLayout -> "Invalid"],
  {RulePlot::invalidFiniteOption}
]

VerificationTest[
  RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], GraphLayout -> 3],
  RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], GraphLayout -> 3],
  {RulePlot::invalidFiniteOption}
]

(** VertexCoordinateRules **)

VerificationTest[
  SameQ @@
    Cases[
      RulePlot[
        WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}],
        VertexCoordinateRules -> {1 -> {0, 0}, 2 -> {1, 0}, 3 -> {2, 0}, 4 -> {3, 0}, 5 -> {4, 0}}],
      Disk[p_, _] :> p,
      All][[All, 2]]
]

(*** Due to scaling and translation being computed in the frontend instead of ahead of time,
      coordinates on both sides of the rule might be the same. ***)
VerificationTest[
  Length[
      Union[
        Cases[
          RulePlot[
            WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}],
            VertexCoordinateRules -> {1 -> {0, 0}, 2 -> {0, 0}, 3 -> {0, 0}, 4 -> {0, 0}, 5 -> {0, 0}}],
          Disk[p_, _] :> p,
          All]]]
    <= 2
]

VerificationTest[
  Head[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], VertexCoordinateRules -> {}]],
  Graphics
]

VerificationTest[
  RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], VertexCoordinateRules -> {1}],
  RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], VertexCoordinateRules -> {1}],
  {RulePlot::invalidCoordinates}
]

(** VertexLabels **)

VerificationTest[
  Sort[Cases[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], VertexLabels -> Automatic], Text[i_, ___] :> i, All]],
  {1, 2, 3, 3, 4, 5}
]

VerificationTest[
  Length[Cases[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], VertexLabels -> x], Text[x, ___], All]],
  6
]

(** Graphics **)

VerificationTest[
  Background /. AbsoluteOptions[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], Background -> Black], Background],
  Black,
  SameTest -> Equal
]

(** Frame **)

VerificationTest[
  Not[
    Or @@ SameQ @@@ Subsets[
      Rasterize[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], Frame -> #]] & /@ {False, True}, {2}]]
]

VerificationTest[
  RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], Frame -> "Invalid"],
  RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], Frame -> "Invalid"],
  {RulePlot::invalidFiniteOption}
]

(** FrameStyle **)

VerificationTest[
  MemberQ[
    Cases[
      RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], FrameStyle -> RGBColor[0.33, 0.66, 0.77]][[1]],
      _ ? ColorQ,
      All],
    RGBColor[0.33, 0.66, 0.77]]
]

VerificationTest[
  Not @ MemberQ[
    Cases[
      RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], FrameStyle -> RGBColor[0.33, 0.66, 0.77], Frame -> False][[1]],
      _ ? ColorQ,
      All],
    RGBColor[0.33, 0.66, 0.77]]
]

(** PlotLegends **)

VerificationTest[
  MatchQ[
    RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], PlotLegends -> "Text"],
    Legended[_, Placed[StandardForm[{{1, 2, 3}} -> {{3, 4, 5}}], Below]]]
]

VerificationTest[
  MatchQ[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], PlotLegends -> "test"], Legended[_, "test"]]
]

VerificationTest[
  Not @ MatchQ[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}]], Legended[___]]
]

(** Spacings **)

VerificationTest[
  Not[Or @@ SameQ @@@ Subsets[
    Rasterize[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], Spacings -> #]] & /@
      {0, 1, {{1, 0}, {0, 0}}, {{0, 1}, {0, 0}}, {{0, 0}, {1, 0}}, {{0, 0}, {0, 1}}},
    {2}]]
]

VerificationTest[
  And @@ SameQ @@
    (Rasterize[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], Spacings -> #]] & /@ {1, {{1, 1}, {1, 1}}})
]

VerificationTest[
  RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], Spacings -> #],
  RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}], Spacings -> #],
  {RulePlot::invalidSpacings}
] & /@ {
  "Incorrect",
  {1, 1},
  {{1, 2}, 1},
  {1, {1, 2}},
  {{1, 2, 3}, {1, 2}},
  {{1, {2, 3}}, {1, 2}}
}

(* Scaling consistency *)

(** Vertex amplification **)

VerificationTest[
  First[Cases[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}]], Disk[_, r_] :> r, All]] > 
    First[Cases[HypergraphPlot[{{1, 2, 3}}], Disk[_, r_] :> r, All]]
]

(** Consistent vertex sizes **)

$rules = {
  {{1}} -> {{1}},
  {{1}} -> {{2}},
  {{1, 2}} -> {{1}},
  {{1, 2}} -> {{1, 2}},
  {{1, 2, 3}} -> {{1}},
  {{1, 2, 3}} -> {{1, 2}},
  {{1}, {2}} -> {{2}, {3}},
  {{1}, {2}, {3}} -> {{2}, {3}, {4}},
  {{1, 2, 3}} -> {{3, 4, 5}},
  {{1, 2, 3}} -> {{1, 2}, {2, 3}},
  {{1, 2, 3}} -> {{2, 3}, {3, 4}}};

VerificationTest[
  And @@ (SameQ @@ Cases[RulePlot[WolframModel[#]], Disk[_, r_] :> r, All] & /@ $rules)
]

(** Shared vertices are colored **)

VerificationTest[
  Length[Union[Cases[RulePlot[WolframModel[{{1, 2, 3}} -> {{3, 4, 5}}]], _ ? ColorQ, All]]] > 
    Length[Union[Cases[RulePlot[WolframModel[{{1, 2, 3}} -> {{4, 5, 6}}]], _ ? ColorQ, All]]]
]

EndTestSection[]
