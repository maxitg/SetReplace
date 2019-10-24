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

(** PlotStyle is an indexed ColorDataFunction **)

VerificationTest[
  HypergraphPlot[{{1, 2}, {2, 3}, {3, 1}}, PlotStyle -> Red],
  HypergraphPlot[{{1, 2}, {2, 3}, {3, 1}}, PlotStyle -> Red],
  {HypergraphPlot::unsupportedPlotStyle}
]

VerificationTest[
  HypergraphPlot[{{1, 2}, {2, 3}, {3, 1}}, PlotStyle -> 23],
  HypergraphPlot[{{1, 2}, {2, 3}, {3, 1}}, PlotStyle -> 23],
  {HypergraphPlot::unsupportedPlotStyle}
]

VerificationTest[
  HypergraphPlot[{{1, 2}, {2, 3}, {3, 1}}, PlotStyle -> ColorData["DarkRainbow"]],
  HypergraphPlot[{{1, 2}, {2, 3}, {3, 1}}, PlotStyle -> ColorData["DarkRainbow"]],
  {HypergraphPlot::unsupportedPlotStyle}
]

VerificationTest[
  Head[HypergraphPlot[{{1, 2}, {2, 3}, {3, 1}}, PlotStyle -> ColorData[1]]],
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

EndTestSection[]
