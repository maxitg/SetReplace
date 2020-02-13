Package["SetReplace`"]

(* Documentation *)

$newOptions = {
  "EdgeType" -> "Ordered",
  GraphHighlightStyle -> RGBColor[0.5, 0.5, 0.95],
  "HyperedgeRendering" -> "Polygons",
  VertexCoordinateRules -> {},
  VertexLabels -> None,
  "RulePartsAspectRatio" -> Automatic
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
];
Protect[RulePlot];

(* Parameters *)

$vertexSize = 0.1;
$arrowheadsLength = 0.3;
$graphPadding = Scaled[0.1];
$ruleSidesSpacing = 0.13;

$arrowStyle = GrayLevel[0.65];
$rulePartsFrameStyle = GrayLevel[0.7];

$imageSizeScale = 128;

(* Messages *)

RulePlot::patternRules =
  "RulePlot for pattern rules `1` is not implemented.";

RulePlot::notHypergraphRule =
  "Rule `1` should be a rule operating on hyperedges (set elements should be lists).";

RulePlot::invalidSpacings =
  "Spacings `1` should be either a single number, or a two-by-two list.";

RulePlot::invalidAspectRatio =
  "RulePartsAspectRatio `1` should be a positive number.";

(* Evaluation *)

WolframModel /: func : RulePlot[wm : WolframModel[args___] /; Quiet[Developer`CheckArgumentCount[wm, 1, 1]], opts___] :=
  Module[{result = rulePlot$parse[{args}, {opts}]},
    If[Head[result] === rulePlot$parse,
      result = $Failed];
    result /; result =!= $Failed
  ]

(* Arguments parsing *)

rulePlot$parse[{
    rulesSpec_ ? hypergraphRulesSpecQ,
    o : OptionsPattern[] /; unrecognizedOptions[WolframModel, {o}] === {}},
    {opts : OptionsPattern[]}] :=
  rulePlot[
        rulesSpec,
        ##,
        FilterRules[{opts}, FilterRules[Options[Graphics], Except[Frame]]]] & @@
      OptionValue[
        RulePlot,
        {opts},
        {"EdgeType", GraphHighlightStyle, "HyperedgeRendering", VertexCoordinateRules, VertexLabels, Frame, FrameStyle,
          PlotLegends, Spacings, "RulePartsAspectRatio"}] /;
    correctOptionsQ[{rulesSpec, o}, {opts}]

hypergraphRulesSpecQ[rulesSpec_List ? wolframModelRulesSpecQ] := Fold[# && hypergraphRulesSpecQ[#2] &, True, rulesSpec]

hypergraphRulesSpecQ[ruleSpec_Rule ? wolframModelRulesSpecQ] := If[
  MatchQ[ruleSpec, {___List} -> {___List}],
  True,
  Message[RulePlot::notHypergraphRule, ruleSpec];
  False
]

hypergraphRulesSpecQ[rulesSpec_Association ? wolframModelRulesSpecQ] := (
  Message[RulePlot::patternRules, rulesSpec];
  False
)

hypergraphRulesSpecQ[rulesSpec_] := (
  Message[RulePlot::invalidRules, rulesSpec];
  False
)

correctOptionsQ[args_, {opts___}] :=
  knownOptionsQ[RulePlot, Defer[RulePlot[WolframModel[args], opts]], {opts}, $allowedOptions] &&
  supportedOptionQ[RulePlot, Frame, {True, False, Automatic}, {opts}] &&
  correctEdgeTypeQ[OptionValue[RulePlot, {opts}, "EdgeType"]] &&
  correctSpacingsQ[{opts}] &&
  correctRulePartsAspectRatioQ[OptionValue[RulePlot, {opts}, "RulePartsAspectRatio"]] &&
  correctWolframModelPlotOptionsQ[
    RulePlot, Defer[RulePlot[WolframModel[args], opts]], Automatic, FilterRules[{opts}, Options[WolframModelPlot]]]

correctEdgeTypeQ[edgeType_] := If[MatchQ[edgeType, Alternatives @@ $edgeTypes],
  True,
  Message[RulePlot::invalidEdgeType, edgeType, $edgeTypes];
  False
]

correctSpacingsQ[opts_] := Module[{spacings, correctQ},
  spacings = OptionValue[RulePlot, opts, Spacings];
  correctQ = MatchQ[spacings, Automatic | (_ ? NumericQ) | {Repeated[{Repeated[_ ? NumericQ, {2}]}, {2}]}];
  If[!correctQ, Message[RulePlot::invalidSpacings, spacings]];
  correctQ
]

correctRulePartsAspectRatioQ[Automatic] := True

correctRulePartsAspectRatioQ[aspectRatio_] :=
  If[NumericQ[aspectRatio] && aspectRatio > 0,
    True,
    Message[RulePlot::invalidAspectRatio, aspectRatio];
    False]

(* Implementation *)

rulePlot[
    rules_,
    edgeType_,
    graphHighlightStyle_,
    hyperedgeRendering_,
    vertexCoordinateRules_,
    vertexLabels_,
    frameQ_,
    frameStyle_,
    plotLegends_,
    spacings_,
    rulePartsAspectRatio_,
    graphicsOpts_] :=
  If[PlotLegends === None, Identity, Legended[#, Replace[plotLegends, "Text" -> Placed[StandardForm[rules], Below]]] &][
    rulePlot[
      rules, edgeType, graphHighlightStyle, hyperedgeRendering, vertexCoordinateRules, vertexLabels, frameQ, frameStyle,
        spacings, rulePartsAspectRatio, graphicsOpts]
  ]

rulePlot[
    rule_Rule,
    edgeType_,
    graphHighlightStyle_,
    hyperedgeRendering_,
    vertexCoordinateRules_,
    vertexLabels_,
    frameQ_,
    frameStyle_,
    spacings_,
    rulePartsAspectRatio_,
    graphicsOpts_] :=
  rulePlot[
    {rule}, edgeType, graphHighlightStyle, hyperedgeRendering, vertexCoordinateRules, vertexLabels, frameQ, frameStyle,
      spacings, rulePartsAspectRatio, graphicsOpts]

rulePlot[
    rules_List,
    edgeType_,
    graphHighlightStyle_,
    hyperedgeRendering_,
    vertexCoordinateRules_,
    vertexLabels_,
    frameQ_,
    frameStyle_,
    spacings_,
    rulePartsAspectRatio_,
    graphicsOpts_] := Module[{explicitSpacings, explicitAspectRatio, singlePlots, shapes, plotRange},
  explicitSpacings = toListSpacings[Replace[spacings, Automatic -> $ruleSidesSpacing]];
  hypergraphPlots =
    rulePartsPlots[edgeType, graphHighlightStyle, hyperedgeRendering, vertexCoordinateRules, vertexLabels] /@ rules;
  explicitAspectRatio =
    Replace[rulePartsAspectRatio, Automatic -> aspectRatioFromPlotRanges[hypergraphPlots[[All, 2]]]];
  singlePlots = combinedRuleParts[#1[[All, 1]], #2, explicitSpacings, explicitAspectRatio] & @@@ hypergraphPlots;
  {shapes, plotRange} = graphicsRiffle[
    singlePlots[[All, 1]],
    singlePlots[[All, 2]],
    Min[explicitAspectRatio, 1] + explicitSpacings[[2, 2]] + explicitSpacings[[2, 1]],
    {},
    {{0, 1}, {0, 1}},
    0,
    {{0.01, 0.01}, {0.01, 0.01}},
    If[frameQ === True || (frameQ === Automatic && Length[rules] > 1), frameStyle, None]];
  Graphics[
    shapes,
    graphicsOpts,
    PlotRange -> plotRange,
    ImageSizeRaw -> $imageSizeScale (plotRange[[1, 2]] - plotRange[[1, 1]])]
]

aspectRatio[{{xMin_, xMax_}, {yMin_, yMax_}}] := (yMax - yMin) / (xMax - xMin)

$minAspectRatio = 0.2;
$maxAspectRatio = 5.0;

aspectRatioFromPlotRanges[plotRanges_] := Module[{
    singleAspectRatios = aspectRatio /@ plotRanges, minMax},
  minMax = MinMax[singleAspectRatios];
  Switch[minMax,
    _ ? (Max[#] < 1 &), Max[minMax, $minAspectRatio],
    _ ? (Min[#] > 1 &), Min[minMax, $maxAspectRatio],
    _, 1
  ]
]

(* returns {{leftPlot, rightPlot}, plotRange} *)
rulePartsPlots[
      edgeType_,
      graphHighlightStyle_,
      hyperedgeRendering_,
      externalVertexCoordinateRules_,
      vertexLabels_][
      rule_] := Module[{
    vertexCoordinateRules, ruleSidePlots, plotRange},
  vertexCoordinateRules = Join[
    ruleCoordinateRules[edgeType, hyperedgeRendering, externalVertexCoordinateRules, rule],
    externalVertexCoordinateRules];
  ruleSidePlots = WolframModelPlot[
      #,
      edgeType,
      GraphHighlight -> sharedRuleElements[rule],
      GraphHighlightStyle -> graphHighlightStyle,
      "HyperedgeRendering" -> hyperedgeRendering,
      VertexCoordinateRules -> vertexCoordinateRules,
      VertexLabels -> vertexLabels,
      VertexSize -> $vertexSize,
      "ArrowheadLength" -> $arrowheadsLength] & /@
    List @@ rule;
  plotRange =
    CoordinateBounds[Catenate[List @@ (Transpose[PlotRange[#]] & /@ ruleSidePlots)], $graphPadding];
  {ruleSidePlots, plotRange}
]

connectedQ[edges_] := ConnectedGraphQ[Graph[UndirectedEdge @@@ Catenate[Partition[#, 2, 1] & /@ edges]]]

layoutReferenceSide[in_, out_] := Module[{inConnectedQ, outConnectedQ},
  {inConnectedQ, outConnectedQ} = connectedQ /@ {in, out};
  If[inConnectedQ && !outConnectedQ, Return[out]];
  If[outConnectedQ && !inConnectedQ, Return[in]];
  If[Length[in] > Length[out], in, out]
]

ruleCoordinateRules[edgeType_, hyperedgeRendering_, externalVertexCoordinateRules_, in_ -> out_] :=
  #[[1]] -> #[[2, 1, 1]] & /@
    hypergraphEmbedding[edgeType, hyperedgeRendering, externalVertexCoordinateRules][layoutReferenceSide[in, out]][[1]]

sharedRuleElements[in_ -> out_] := multisetIntersection @@ (Join[vertexList[#], #] & /@ {in, out})

$arrow = FilledCurve[
  {{{0, 2, 0}, {0, 1, 0}, {0, 1, 0}, {0, 1, 0}, {0, 1, 0}, {0, 1, 0}, {0, 1, 0}, {0, 1, 0}, {0, 1, 0}}},
  {{{-1., 0.1848}, {0.2991, 0.1848}, {-0.1531, 0.6363}, {0.109, 0.8982}, {1., 0.0034}, {0.109, -0.8982},
    {-0.1531, -0.6363}, {0.2991, -0.1848}, {-1., -0.1848}, {-1., 0.1848}}}];
$arrowLength = 0.22;
$arrowPadding = 0.4;

(* returns {shapes, plotRange} *)
combinedRuleParts[sides_, plotRange_, spacings_, rulePartsAspectRatio_] := Module[{
    xScaleFactor, yScaleFactor, maxRange, xRange, yRange, xDisplacement, frame, separator},
  xScaleFactor = Min[1, 1 / rulePartsAspectRatio];
  yScaleFactor = Min[1, rulePartsAspectRatio];
  maxRange = Max[
    1 / xScaleFactor (plotRange[[1, 2]] - plotRange[[1, 1]]),
    1 / yScaleFactor (plotRange[[2, 2]] - plotRange[[2, 1]]),
    1];
  {xRange, yRange} = MapThread[Mean[#] + maxRange * #2 * {-0.5, 0.5} &, {plotRange, {xScaleFactor, yScaleFactor}}];
  xDisplacement = 1.5 (xRange[[2]] - xRange[[1]]);
  frame = {$rulePartsFrameStyle, Line[{
    {xRange[[1]], yRange[[1]]},
    {xRange[[2]], yRange[[1]]},
    {xRange[[2]], yRange[[2]]},
    {xRange[[1]], yRange[[2]]},
    {xRange[[1]], yRange[[1]]}}]};
  separator = {$arrowStyle, $arrow};
  graphicsRiffle[
    Append[#, frame] & /@ sides,
    ConstantArray[{xRange, yRange}, 2],
    Min[rulePartsAspectRatio, 1],
    separator,
    {{-1, 1}, {-1, 1}} (1 + $arrowPadding),
    $arrowLength (1 + $arrowPadding),
    spacings,
    None]
]

toListSpacings[spacings_List] := spacings

toListSpacings[spacings : Except[_List]] := ConstantArray[spacings, {2, 2}]

frame[{{xMin_, xMax_}, {yMin_, yMax_}}] := Line[{{xMin, yMin}, {xMax, yMin}, {xMax, yMax}, {xMin, yMax}, {xMin, yMin}}]

$defaultGridColor = GrayLevel[0.85];

(* returns {shapes, plotRange} *)
graphicsRiffle[
      shapeLists_,
      plotRanges_,
      height_,
      separator_,
      separatorPlotRange_,
      relativeSeparatorWidth_,
      spacings_,
      gridStyle_] := Module[{
    scaledShapes, scaledSeparator, widthWithExtraSeparator, shapesWithExtraSeparator, totalWidth, explicitGridStyle},
  scaledShapes = MapThread[
    Scale[
      Translate[#1, -#2[[All, 1]]],
      height / (#2[[2, 2]] - #2[[2, 1]]),
      {0, 0}] &,
    {shapeLists, plotRanges}];
  scaledSeparator = Scale[
    Translate[separator, {0, 0.5 height} - {#[[1, 1]], (#[[2, 2]] + #[[2, 1]]) / 2} & @ separatorPlotRange],
    relativeSeparatorWidth / (separatorPlotRange[[1, 2]] - separatorPlotRange[[1, 1]]),
    {0, 0.5 height}];
  explicitGridStyle = Replace[gridStyle, Automatic -> $defaultGridColor];
  {widthWithExtraSeparator, shapesWithExtraSeparator} = Reap[Fold[
    With[{shapeWidth = height / aspectRatio[plotRanges[[#2]]]},
      Sow[Translate[scaledShapes[[#2]], {#, 0}]];
      Sow[Translate[scaledSeparator, {# + shapeWidth, 0}]];
      If[gridStyle =!= None,
        Sow[{explicitGridStyle, Line[{{#, 0}, {#, height}}] & @ (# + shapeWidth + relativeSeparatorWidth / 2)}]];
      # + shapeWidth + relativeSeparatorWidth
    ] &,
    0,
    Range[Length[scaledShapes]]]];
  totalWidth = widthWithExtraSeparator - relativeSeparatorWidth;
  {
    {
      Most[shapesWithExtraSeparator[[1]]],
      If[gridStyle =!= None, {explicitGridStyle, frame[{{0, totalWidth}, {0, height}}]}, Nothing]},
    {
      {-spacings[[1, 1]], totalWidth + spacings[[1, 2]]},
      {-spacings[[2, 1]], height + spacings[[2, 2]]}}
  }
]
