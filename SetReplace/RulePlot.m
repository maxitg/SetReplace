Package["SetReplace`"]

(* Documentation *)

$newOptions = {
  "EdgeType" -> "CyclicOpen",
  GraphLayout -> "SpringElectricalPolygons",
  VertexCoordinateRules -> {},
  VertexLabels -> None
};

$allowedOptions = Join[
  FilterRules[Options[RulePlot], Options[Graphics]][[All, 1]], {
  Frame, FrameStyle, PlotLegends, Spacings},
  $newOptions[[All, 1]]];

Unprotect[RulePlot];
Options[RulePlot] = Join[Options[RulePlot], $newOptions];

SyntaxInformation[RulePlot] = Join[
  FilterRules[SyntaxInformation[RulePlot], Except["OptionNames"]],
  {"OptionNames" -> Join[("OptionNames" /. SyntaxInformation[RulePlot]), $newOptions[[All, 1]]]}
]
Protect[RulePlot];

(* Parameters *)

$nodeSizeAmplification = 3;
$graphPadding = Scaled[0.1];
$ruleSidesSpacing = 0.2;

(* Messages *)

RulePlot::patternRules =
  "RulePlot for pattern rules `1` is not implemented.";

RulePlot::notHypergraphRule =
  "Rule `1` should be a rule operating on hyperedges (set elements should be lists)."

(* Evaluation *)

WolframModel /: func : RulePlot[WolframModel[args___], opts___] := Module[{result = rulePlot$parse[{args}, {opts}]},
  If[Head[result] === rulePlot$parse,
    result = $Failed];
  result /; result =!= $Failed
]

(* Arguments parsing *)

rulePlot$parse[{
  rulesSpec_ ? hypergraphRulesSpecQ,
  o : OptionsPattern[] /; unrecognizedOptions[WolframModel, {o}] === {}},
  {opts : OptionsPattern[]}] := Module[{},
    If[AssociationQ[rulesSpec],
      Message[RulePlot::patternRules, rulesSpec];
      Return[$Failed]
    ];
    rulePlot[
          rulesSpec,
          ##,
          FilterRules[{opts}, FilterRules[Options[Graphics], Except[Frame]]]] & @@
        OptionValue[
          RulePlot,
          {opts},
          {"EdgeType", GraphLayout, VertexCoordinateRules, VertexLabels, Frame, FrameStyle, PlotLegends, Spacings}] /;
      correctOptionsQ[{rulesSpec, o}, {opts}]
]

hypergraphRulesSpecQ[rulesSpec_List ? wolframModelRulesSpecQ] := Fold[# && hypergraphRulesSpecQ[#2] &, True, rulesSpec]

hypergraphRulesSpecQ[ruleSpec_Rule ? wolframModelRulesSpecQ] := If[
  And @@ (Depth[#] >= 3 & /@ ruleSpec),
  True,
  Message[RulePlot::notHypergraphRule, ruleSpec];
  False
]

hypergraphRulesSpecQ[rulesSpec_] := False

correctOptionsQ[args_, {opts___}] :=
  knownOptionsQ[RulePlot, Defer[RulePlot[WolframModel[args], opts]], {opts}, $allowedOptions] &&
  supportedOptionQ[RulePlot, Frame, {True, False}, {opts}] &&
  correctSpacingsQ[{opts}] &&
  correctHypergraphPlotOptionsQ[
    RulePlot, Defer[RulePlot[WolframModel[args], opts]], Automatic, FilterRules[{opts}, Options[HypergraphPlot]]]

correctSpacingsQ[opts_] := Module[{spacings, correctQ},
  spacings = OptionValue[RulePlot, opts, Spacings];
  correctQ = MatchQ[spacings, Automatic | (_ ? NumericQ) | {Repeated[{Repeated[_ ? NumericQ, {2}]}, {2}]}];
  If[!correctQ, Message[RulePlot::invalidSpacings, spacings]];
  correctQ
]

(* Implementation *)

rulePlot[rule_Rule, args___] := rulePlot[{rule}, args]

rulePlot[
    rules_List,
    edgeType_,
    graphLayout_,
    vertexCoordinateRules_,
    vertexLabels_,
    frameQ_,
    frameStyle_,
    plotLegends_,
    spacings_,
    graphicsOpts_] :=
  If[PlotLegends === None, Identity, Legended[#, Replace[plotLegends, "Text" -> Placed[StandardForm[rules], Below]]] &][
    Graphics[
        First[graphicsRiffle[#[[All, 1]], #[[All, 2]], {}, {{0, 1}, {0, 1}}, 0, 0.01, If[frameQ, frameStyle, None]]],
        graphicsOpts] & @
      (singleRulePlot[edgeType, graphLayout, vertexCoordinateRules, vertexLabels, spacings] /@ rules)
  ]

$vertexSize = 0.1;
$arrowheadsLength = 0.3;

(* returns {shapes, plotRange} *)
singleRulePlot[edgeType_, graphLayout_, externalVertexCoordinateRules_, vertexLabels_, spacings_][rule_] := Module[{
    vertexCoordinateRules, sharedVertices, ruleSidePlots, plotRange},
  vertexCoordinateRules = Join[
    ruleCoordinateRules[edgeType, graphLayout, externalVertexCoordinateRules, rule],
    externalVertexCoordinateRules];
  sharedVertices = sharedRuleVertices[rule];
  ruleSidePlots = hypergraphPlot[
      #,
      edgeType,
      sharedVertices,
      graphLayout,
      vertexCoordinateRules,
      vertexLabels,
      {},
      $vertexSize,
      $arrowheadsLength] & /@
    List @@ rule;
  plotRange =
    CoordinateBounds[Catenate[List @@ (Transpose[completePlotRange[#]] & /@ ruleSidePlots)], $graphPadding];
  combinedRuleParts[ruleSidePlots[[All, 1]], plotRange, spacings]
]

connectedQ[edges_] := ConnectedGraphQ[Graph[UndirectedEdge @@@ Catenate[Partition[#, 2, 1] & /@ edges]]]

layoutReferenceSide[in_, out_] := Module[{inConnectedQ, outConnectedQ},
  {inConnectedQ, outConnectedQ} = connectedQ /@ {in, out};
  If[inConnectedQ && !outConnectedQ, Return[out]];
  If[outConnectedQ && !inConnectedQ, Return[in]];
  If[Length[in] > Length[out], in, out]
]

ruleCoordinateRules[edgeType_, graphLayout_, externalVertexCoordinateRules_, in_ -> out_] :=
  #[[1]] -> #[[2, 1, 1]] & /@
    hypergraphEmbedding[edgeType, graphLayout, externalVertexCoordinateRules][layoutReferenceSide[in, out]][[1]]

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

$ruleArrowShape = {Line[{{-1, 0.7}, {0, 0}, {-1, -0.7}}], Line[{{-1, 0}, {0, 0}}]};

(* returns {shapes, plotRange} *)
combinedRuleParts[sides_, plotRange_, spacings_] := Module[{maxRange, xRange, yRange, xDisplacement, frame, separator},
  maxRange = Max[plotRange[[1, 2]] - plotRange[[1, 1]], plotRange[[2, 2]] - plotRange[[2, 1]], 1];
  {xRange, yRange} = Mean[#] + maxRange * {-0.5, 0.5} & /@ plotRange;
  xDisplacement = 1.5 (xRange[[2]] - xRange[[1]]);
  frame = {Gray, Dotted, Line[{
    {xRange[[1]], yRange[[1]]},
    {xRange[[2]], yRange[[1]]},
    {xRange[[2]], yRange[[2]]},
    {xRange[[1]], yRange[[2]]},
    {xRange[[1]], yRange[[1]]}}]};
  separator = arrow[$ruleArrowShape, 0.15, 0][{{0.15, 0.5}, {0.85, 0.5}}];
  graphicsRiffle[
    Append[#, frame] & /@ sides,
    ConstantArray[{xRange, yRange}, 2],
    separator,
    {{0, 1}, {0, 1}},
    0.5,
    Replace[spacings, Automatic -> $ruleSidesSpacing],
    None]
]

aspectRatio[{{xMin_, xMax_}, {yMin_, yMax_}}] := (yMax - yMin) / (xMax - xMin)

frame[{{xMin_, xMax_}, {yMin_, yMax_}}] := Line[{{xMin, yMin}, {xMax, yMin}, {xMax, yMax}, {xMin, yMax}, {xMin, yMin}}]

$defaultGridColor = GrayLevel[0.8];

(* returns {shapes, plotRange} *)
graphicsRiffle[
      shapeLists_,
      plotRanges_,
      separator_,
      separatorPlotRange_,
      relativeSeparatorWidth_,
      spacings_,
      gridStyle_] := Module[{
    scaledShapes, scaledSeparator, widthWithExtraSeparator, shapesWithExtraSeparator, totalWidth, explicitGridStyle,
    explicitSpacings},
  scaledShapes = MapThread[
    Scale[
      Translate[#1, -#2[[All, 1]]],
      1 / (#2[[2, 2]] - #2[[2, 1]]),
      {0, 0}] &,
    {shapeLists, plotRanges}];
  scaledSeparator = Scale[
    Translate[separator, {0, 0.5} - {#[[1, 1]], (#[[2, 2]] + #[[2, 1]]) / 2} & @ separatorPlotRange],
    relativeSeparatorWidth / (separatorPlotRange[[1, 2]] - separatorPlotRange[[1, 1]]),
    {0, 0.5}];
  explicitGridStyle = Replace[gridStyle, Automatic -> $defaultGridColor];
  {widthWithExtraSeparator, shapesWithExtraSeparator} = Reap[Fold[
    With[{shapeWidth = 1 / aspectRatio[plotRanges[[#2]]]},
      Sow[Translate[scaledShapes[[#2]], {#, 0}]];
      Sow[Translate[scaledSeparator, {# + shapeWidth, 0}]];
      If[gridStyle =!= None,
        Sow[{explicitGridStyle, Line[{{#, 0}, {#, 1}}] & @ (# + shapeWidth + relativeSeparatorWidth / 2)}]];
      # + shapeWidth + relativeSeparatorWidth
    ] &,
    0,
    Range[Length[scaledShapes]]]];
  totalWidth = widthWithExtraSeparator - relativeSeparatorWidth;
  explicitSpacings = If[!ListQ[spacings], ConstantArray[spacings, {2, 2}], spacings];
  {
    {
      Most[shapesWithExtraSeparator[[1]]],
      If[gridStyle =!= None, {explicitGridStyle, frame[{{0, totalWidth}, {0, 1}}]}, Nothing]},
    {
      {-explicitSpacings[[1, 1]], totalWidth + explicitSpacings[[1, 2]]},
      {-explicitSpacings[[2, 1]], 1 + explicitSpacings[[2, 2]]}}
  }
]
