Package["SetReplace`"]

(* Documentation *)

$newOptions = {
  "EdgeType" -> "Ordered",
  GraphHighlightStyle -> style[$lightTheme][$sharedRuleElementsHighlight],
  "HyperedgeRendering" -> style[$lightTheme][$ruleHyperedgeRendering],
  VertexCoordinateRules -> {},
  VertexLabels -> None,
  "RulePartsAspectRatio" -> style[$lightTheme][$rulePartsAspectRatio],
  PlotStyle -> Automatic,
  VertexStyle -> Automatic,
  EdgeStyle -> Automatic,
  "EdgePolygonStyle" -> Automatic,
  VertexSize -> style[$lightTheme][$ruleVertexSize],
  "ArrowheadLength" -> style[$lightTheme][$ruleArrowheadLength]
};

$defaultBehaviorGraphicsOptions =
  Fold[FilterRules, {Options[RulePlot], Options[Graphics], Except[{Frame, FrameStyle, Background}]}];

$allowedOptions = Join[
  FilterRules[Options[RulePlot], Options[Graphics]][[All, 1]],
  {PlotLegends, Spacings},
  $newOptions[[All, 1]]];

Unprotect[RulePlot];
Options[RulePlot] = Union[Join[Options[RulePlot], $newOptions]];

SyntaxInformation[RulePlot] = Join[
  FilterRules[SyntaxInformation[RulePlot], Except["OptionNames"]],
  {"OptionNames" -> Join[("OptionNames" /. SyntaxInformation[RulePlot]), $newOptions[[All, 1]]]}
];
Protect[RulePlot];

(* Messages *)

RulePlot::patternRules =
  "RulePlot for pattern rules `1` is not implemented.";

RulePlot::notHypergraphRule =
  "Rule `1` should be a rule operating on hyperedges (set elements should be lists).";

RulePlot::invalidSpacings =
  "Spacings `1` should be either a single number, or a two-by-two list.";

RulePlot::invalidAspectRatio =
  "RulePartsAspectRatio `1` should be a positive number.";

RulePlot::elementwiseStyle = "The elementwise style specification `1` is not supported in RulePlot.";

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
    o : OptionsPattern[]},
    {opts : OptionsPattern[]}] /; recognizedOptionsQ[RulePlot[rulesSpec, o], WolframModel, {o}] :=
  rulePlot[
        rulesSpec,
        ##,
        FilterRules[{opts}, $defaultBehaviorGraphicsOptions]] & @@
      OptionValue[
        RulePlot,
        {opts},
        {"EdgeType", GraphHighlightStyle, "HyperedgeRendering", VertexCoordinateRules, VertexLabels, Frame, FrameStyle,
          PlotLegends, Spacings, "RulePartsAspectRatio", PlotStyle, VertexStyle, EdgeStyle, "EdgePolygonStyle",
          VertexSize, "ArrowheadLength", Background}] /;
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
  And @@ (styleNotListQ[OptionValue[RulePlot, {opts}, #]] & /@ {VertexStyle, EdgeStyle, "EdgePolygonStyle"}) &&
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

styleNotListQ[styles_List] := (
  Message[RulePlot::elementwiseStyle, styles];
  False
)

styleNotListQ[styles : Except[_List]] := True

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
    plotStyle_,
    vertexStyle_,
    edgeStyle_,
    edgePolygonStyle_,
    vertexSize_,
    arrowheadLength_,
    background_,
    graphicsOpts_] :=
  If[PlotLegends === None, Identity, Legended[#, Replace[plotLegends, "Text" -> Placed[StandardForm[rules], Below]]] &][
    rulePlot[
      rules, edgeType, graphHighlightStyle, hyperedgeRendering, vertexCoordinateRules, vertexLabels, frameQ, frameStyle,
        spacings, rulePartsAspectRatio, plotStyle, vertexStyle, edgeStyle, edgePolygonStyle, vertexSize,
        arrowheadLength, background, graphicsOpts]
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
    plotStyle_,
    vertexStyle_,
    edgeStyle_,
    edgePolygonStyle_,
    vertexSize_,
    arrowheadLength_,
    background_,
    graphicsOpts_] :=
  rulePlot[
    {rule}, edgeType, graphHighlightStyle, hyperedgeRendering, vertexCoordinateRules, vertexLabels, frameQ, frameStyle,
      spacings, rulePartsAspectRatio, plotStyle, vertexStyle, edgeStyle, edgePolygonStyle, vertexSize, arrowheadLength,
      background, graphicsOpts]

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
    plotStyle_,
    vertexStyle_,
    edgeStyle_,
    edgePolygonStyle_,
    vertexSize_,
    arrowheadLength_,
    background_,
    graphicsOpts_] := Module[{explicitSpacings, explicitAspectRatio, singlePlots, shapes, plotRange},
  explicitSpacings = toListSpacings[Replace[spacings, Automatic -> style[$lightTheme][$ruleSidesSpacing]]];
  hypergraphPlots =
    rulePartsPlots[
      edgeType, graphHighlightStyle, hyperedgeRendering, vertexCoordinateRules, vertexLabels, plotStyle,
        vertexStyle, edgeStyle, edgePolygonStyle, vertexSize, arrowheadLength] /@ rules;
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
    Background -> Replace[background, Automatic -> style[$lightTheme][$ruleBackground]],
    PlotRange -> plotRange,
    ImageSizeRaw -> style[$lightTheme][$ruleImageSizePerPlotRange] (plotRange[[1, 2]] - plotRange[[1, 1]])]
]

aspectRatio[{{xMin_, xMax_}, {yMin_, yMax_}}] := (yMax - yMin) / (xMax - xMin)

aspectRatioFromPlotRanges[plotRanges_] := Module[{
    singleAspectRatios = aspectRatio /@ plotRanges, minMax},
  minMax = MinMax[singleAspectRatios];
  Switch[minMax,
    _ ? (Max[#] < 1 &), Max[minMax, style[$lightTheme][$rulePartsAspectRatioMin]],
    _ ? (Min[#] > 1 &), Min[minMax, style[$lightTheme][$rulePartsAspectRatioMax]],
    _, 1
  ]
]

(* returns {{leftPlot, rightPlot}, plotRange} *)
rulePartsPlots[
      edgeType_,
      graphHighlightStyle_,
      hyperedgeRendering_,
      externalVertexCoordinateRules_,
      vertexLabels_,
      plotStyle_,
      vertexStyle_,
      edgeStyle_,
      edgePolygonStyle_,
      vertexSize_,
      arrowheadLength_][
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
      PlotStyle -> plotStyle,
      VertexStyle -> vertexStyle,
      EdgeStyle -> edgeStyle,
      "EdgePolygonStyle" -> edgePolygonStyle,
      VertexSize -> vertexSize,
      "ArrowheadLength" -> arrowheadLength] & /@
    List @@ rule;
  plotRange = CoordinateBounds[
    Catenate[List @@ (Transpose[PlotRange[#]] & /@ ruleSidePlots)],
    style[$lightTheme][$ruleGraphPadding]];
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
  frame = {style[$lightTheme][$rulePartsFrameStyle], Line[{
    {xRange[[1]], yRange[[1]]},
    {xRange[[2]], yRange[[1]]},
    {xRange[[2]], yRange[[2]]},
    {xRange[[1]], yRange[[2]]},
    {xRange[[1]], yRange[[1]]}}]};
  separator = {style[$lightTheme][$ruleArrowStyle], style[$lightTheme][$ruleArrowShape]};
  graphicsRiffle[
    Append[#, frame] & /@ sides,
    ConstantArray[{xRange, yRange}, 2],
    Min[rulePartsAspectRatio, 1],
    separator,
    {{-1, 1}, {-1, 1}} (1 + style[$lightTheme][$ruleArrowPadding]),
    style[$lightTheme][$ruleArrowLength] (1 + style[$lightTheme][$ruleArrowPadding]),
    spacings,
    None]
]

toListSpacings[spacings_List] := spacings

toListSpacings[spacings : Except[_List]] := ConstantArray[spacings, {2, 2}]

frame[{{xMin_, xMax_}, {yMin_, yMax_}}] := Line[{{xMin, yMin}, {xMax, yMin}, {xMax, yMax}, {xMin, yMax}, {xMin, yMin}}]

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
  explicitGridStyle = Replace[gridStyle, Automatic -> style[$lightTheme][$ruleGridColor]];
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
