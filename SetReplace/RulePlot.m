Package["SetReplace`"]

(* Parameters *)

$nodeSizeAmplification = 3;
$padding = Scaled[0.1];

(* Messages *)

RulePlot::patternRules =
  "RulePlot for pattern rules `1` is not implemented.";

(* Evaluation *)

WolframModel /: func : RulePlot[WolframModel[args___]] := Module[{result = rulePlot$parse[{args}]},
  If[Head[result] === rulePlot$parse,
    result = $Failed];
  result /; result =!= $Failed
]

(* Arguments parsing *)

rulePlot$parse[{
  rulesSpec_ ? wolframModelRulesSpecQ,
  o : OptionsPattern[] /; unrecognizedOptions[WolframModel, {o}] === {}}] := Module[{},
    If[AssociationQ[rulesSpec],
      Message[RulePlot::patternRules, rulesSpec];
      Return[$Failed]];
    rulePlot[rulesSpec]
]

(* Implementation *)

rulePlot[rule_Rule] := rulePlot[{rule}]

rulePlot[rules_List] := GraphicsRow[singleRulePlot /@ rules, Frame -> All, FrameStyle -> GrayLevel[0.8]]

$vertexSize = 0.1;
$arrowheadsLength = 0.3;

singleRulePlot[rule_] := Module[{vertexCoordinateRules, sharedVertices, ruleSidePlots, plotRange},
  vertexCoordinateRules = ruleCoordinateRules[rule];
  sharedVertices = sharedRuleVertices[rule];
  ruleSidePlots = hypergraphPlot[
      #,
      "CyclicOpen",
      sharedVertices,
      "SpringElectricalPolygons",
      vertexCoordinateRules,
      None,
      {},
      $vertexSize,
      $arrowheadsLength] & /@
    List @@ rule;
  plotRange =
    CoordinateBounds[Catenate[List @@ (Transpose[completePlotRange[#]] & /@ ruleSidePlots)], $padding];
  combinedRuleParts[ruleSidePlots, plotRange]
]

ruleCoordinateRules[in_ -> out_] :=
  #[[1]] -> #[[2, 1, 1]] & /@
    hypergraphEmbedding["CyclicOpen", "SpringElectricalEmbedding", {}][If[Length[in] > Length[out], in, out]][[1]]

sharedRuleVertices[in_ -> out_] := Intersection @@ (Catenate /@ {in, out})

(* https://mathematica.stackexchange.com/a/18040 *)
completePlotRange[graphics_] := Last @ Last @ Reap[Rasterize[
  Show[
    graphics,
    Axes -> True,
    Frame -> False,
    Ticks -> ((Sow[{##}]; Automatic) &),
    DisplayFunction -> Identity,
    ImageSize -> 0],
  ImageResolution -> 1]]

$openArrowhead = Graphics[{Dashing[None], Line[{{-1, 1/3}, {0, 0}, {-1, -1/3}}]}];
arrow[pts_] = Graphics[{Arrowheads[{{0.03, 1, {$openArrowhead, 1}}}], GrayLevel[0.2], Dotted, Arrow[pts]}];

combinedRuleParts[sides_, plotRange_] := Module[{xRange},
  maxRange = Max[plotRange[[1, 2]] - plotRange[[1, 1]], plotRange[[2, 2]] - plotRange[[2, 1]]];
  {xRange, yRange} = Mean[#] + maxRange * {-0.5, 0.5} & /@ plotRange;
  xDisplacement = 1.5 (xRange[[2]] - xRange[[1]]);
  frame = Graphics[{Gray, Dotted, Line[{
    {xRange[[1]], yRange[[1]]},
    {xRange[[2]], yRange[[1]]},
    {xRange[[2]], yRange[[2]]},
    {xRange[[1]], yRange[[2]]},
    {xRange[[1]], yRange[[1]]}}]}];
  Show[
    sides[[1]],
    frame,
    Graphics[Translate[frame[[1]], {xDisplacement, 0}]],
    arrow[{
      {xRange[[2]] + 0.05 xDisplacement, Mean[yRange]},
      {xRange[[1]] + 0.95 xDisplacement, Mean[yRange]}}],
    Graphics[Translate[sides[[2, 1]], {xDisplacement, 0}]],
    PlotRange -> {{xRange[[1]] - 0.01 xDisplacement, xRange[[2]] + 1.01 xDisplacement}, {yRange[[1]] - 0.01 xDisplacement, yRange[[2]] + 0.01 xDisplacement}},
    ImageSize -> 300 {1, 1 / 2.5}]
]
