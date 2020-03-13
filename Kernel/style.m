Package["SetReplace`"]

PackageExport["$WolframPhysicsProjectPlotThemes"]

PackageScope["style"]
PackageScope["$styleNames"]

PackageScope["$lightTheme"]

PackageScope["$evolutionObjectIcon"]
PackageScope["$destroyedEdgeStyle"]
PackageScope["$createdEdgeStyle"]
PackageScope["$destroyedAndCreatedEdgeStyle"]
PackageScope["$causalGraphVertexStyle"]
PackageScope["$causalGraphInitialVertexStyle"]
PackageScope["$causalGraphFinalVertexStyle"]
PackageScope["$causalGraphEdgeStyle"]
PackageScope["$vertexSize"]
PackageScope["$arrowheadLength"]
PackageScope["$edgeArrowheadShape"]
PackageScope["$vertexStyle"]
PackageScope["$edgeLineStyle"]
PackageScope["$edgePolygonStyle"]
PackageScope["$unaryEdgeStyle"]
PackageScope["$vertexStyleFromPlotStyleDirective"]
PackageScope["$edgeLineStyleFromPlotStyleDirective"]
PackageScope["$edgePolygonStyleFromEdgeStyleDirective"]
PackageScope["$highlightedVertexStyleDirective"]
PackageScope["$highlightedEdgeLineStyleDirective"]
PackageScope["$highlightedUnaryEdgeStyleDirective"]
PackageScope["$highlightedEdgePolygonStyleDirective"]
PackageScope["$highlightStyle"]
PackageScope["$hyperedgeRendering"]
PackageScope["$wolframModelPlotImageSize"]
PackageScope["$sharedRuleElementsHighlight"]
PackageScope["$ruleHyperedgeRendering"]
PackageScope["$ruleVertexSize"]
PackageScope["$ruleArrowheadLength"]
PackageScope["$rulePartsAspectRatio"]
PackageScope["$rulePartsAspectRatioMin"]
PackageScope["$rulePartsAspectRatioMax"]
PackageScope["$ruleGraphPadding"]
PackageScope["$ruleSidesSpacing"]
PackageScope["$rulePartsFrameStyle"]
PackageScope["$ruleArrowShape"]
PackageScope["$ruleArrowLength"]
PackageScope["$ruleArrowPadding"]
PackageScope["$ruleArrowStyle"]
PackageScope["$ruleGridColor"]
PackageScope["$ruleImageSizePerPlotRange"]
PackageScope["$statesGraphVertexStyle"]
PackageScope["$statesGraphEdgeStyle"]
PackageScope["$evolutionCausalGraphEvolutionEdgeStyle"]
PackageScope["$evolutionCausalGraphCausalEdgeStyle"]
PackageScope["$branchialGraphEdgeStyle"]

$styleNames = KeySort /@ KeySort @ <|
  "EvolutionObject" -> <|"Icon" -> $evolutionObjectIcon|>,
  "SpatialGraph" -> <|
    "DestroyedEdgeStyle" -> $destroyedEdgeStyle,
    "CreatedEdgeStyle" -> $destroyedEdgeStyle,
    "DestroyedAndCreatedEdgeStyle" -> $destroyedAndCreatedEdgeStyle,
    "VertexSize" -> $vertexSize,
    "ArrowheadLength" -> $arrowheadLength,
    "EdgeArrowheadShape" -> $edgeArrowheadShape,
    "VertexStyle" -> $vertexStyle,
    "EdgeLineStyle" -> $edgeLineStyle,
    "EdgePolygonStyle" -> $edgePolygonStyle,
    "UnaryEdgeStyle" -> $unaryEdgeStyle,
    "VertexStyleFromPlotStyleDirective" -> $vertexStyleFromPlotStyleDirective,
    "EdgeLineStyleFromPlotStyleDirective" -> $edgeLineStyleFromPlotStyleDirective,
    "EdgePolygonStyleFromEdgeStyleDirective" -> $edgePolygonStyleFromEdgeStyleDirective,
    "HighlightedVertexStyleDirective" -> $highlightedVertexStyleDirective,
    "HighlightedEdgeLineStyleDirective" -> $highlightedEdgeLineStyleDirective,
    "HighlightedUnaryEdgeStyleDirective" -> $highlightedUnaryEdgeStyleDirective,
    "HighlightedEdgePolygonStyleDirective" -> $highlightedEdgePolygonStyleDirective,
    "HighlightStyle" -> $highlightStyle,
    "HyperedgeRendering" -> $hyperedgeRendering,
    "DefaultImageSize" -> $wolframModelPlotImageSize
  |>,
  "CausalGraph" -> <|
    "VertexStyle" -> $causalGraphVertexStyle,
    "InitialVertexStyle" -> $causalGraphInitialVertexStyle,
    "FinalVertexStyle" -> $causalGraphFinalVertexStyle,
    "EdgeStyle" -> $causalGraphEdgeStyle
  |>,
  "Rule" -> <|
    "SharedElementHighlight" -> $sharedRuleElementsHighlight,
    "HyperedgeRendering" -> $ruleHyperedgeRendering,
    "VertexSize" -> $ruleVertexSize,
    "ArrowheadLength" -> $ruleArrowheadLength,
    "PartsAspectRatio" -> $rulePartsAspectRatio,
    "PartsAspectRatioMin" -> $rulePartsAspectRatioMin,
    "PartsAspectRatioMax" -> $rulePartsAspectRatioMax,
    "GraphPadding" -> $ruleGraphPadding,
    "SidesSpacing" -> $ruleSidesSpacing,
    "PartsFrameStyle" -> $rulePartsFrameStyle,
    "ArrowShape" -> $ruleArrowShape,
    "ArrowLength" -> $ruleArrowLength,
    "ArrowPadding" -> $ruleArrowPadding,
    "ArrowStyle" -> $ruleArrowStyle,
    "GridColor" -> $ruleGridColor,
    "ImageSizePerPlotRange" -> $ruleImageSizePerPlotRange
  |>,

  (* MultiwaySystem styles *)
  
  "StatesGraph" -> <|
    "VertexStyle" -> $statesGraphVertexStyle,
    "EdgeStyle" -> $statesGraphEdgeStyle
  |>,
  "EvolutionCausalGraph" -> <|
    "EvolutionVertexStyle" -> $statesGraphVertexStyle,
    "EvolutionEdgeStyle" -> $evolutionCausalGraphEvolutionEdgeStyle,
    "CausalVertexStyle" -> $causalGraphVertexStyle,
    "CausalEdgeStyle" -> $evolutionCausalGraphCausalEdgeStyle
  |>,
  "BranchialGraph" -> <|
    "VertexStyle" -> $statesGraphVertexStyle,
    "EdgeStyle" -> $branchialGraphEdgeStyle
  |>
|>;

$lightTheme = "Light";

$WolframPhysicsProjectPlotThemes::usage = usageString[
  "$WolframPhysicsProjectPlotThemes gives the list of plot themes available for the Wolfram Physics Project."
];

$WolframPhysicsProjectPlotThemes = {$lightTheme};

style[$lightTheme] = <|
  (* Evolution object *)
  $evolutionObjectIcon -> $graphIcon,

  (* Hypergraph diffs *)
  $destroyedEdgeStyle -> Directive[Hue[0.08, 0, 0.42], AbsoluteDashing[{1, 2}]],
  $createdEdgeStyle -> Directive[Hue[0.02, 0.94, 0.83], Thick],
  $destroyedAndCreatedEdgeStyle -> Directive[Hue[0.02, 0.94, 0.83], Thick, AbsoluteDashing[{1, 3}]],

  (* Causal graph *)
  $causalGraphVertexStyle -> Directive[Hue[0.11, 1, 0.97], EdgeForm[{Hue[0.11, 1, 0.97], Opacity[1]}]],
  $causalGraphInitialVertexStyle ->
    Directive[RGBColor[{0.259, 0.576, 1}], EdgeForm[{RGBColor[{0.259, 0.576, 1}], Opacity[1]}]],
  $causalGraphFinalVertexStyle -> Directive[White, EdgeForm[{Hue[0.11, 1, 0.97], Opacity[1]}]],
  $causalGraphEdgeStyle -> Hue[0, 1, 0.56],

  (* WolframModelPlot *)
  $vertexSize -> 0.06,
  $arrowheadLength -> 0.1,
  $edgeArrowheadShape -> Polygon[{
    {-1.10196, -0.289756}, {-1.08585, -0.257073}, {-1.05025, -0.178048}, {-1.03171, -0.130243}, {-1.01512, -0.0824391},
    {-1.0039, -0.037561}, {-1., 0.}, {-1.0039, 0.0341466}, {-1.01512, 0.0780486}, {-1.03171, 0.127805},
    {-1.05025, 0.178538}, {-1.08585, 0.264878}, {-1.10196, 0.301464}, {0., 0.}, {-1.10196, -0.289756}}],
  $vertexStyle -> Directive[Hue[0.63, 0.26, 0.89], EdgeForm[Directive[Hue[0.63, 0.7, 0.33], Opacity[0.95]]]],
  $edgeLineStyle -> Directive[Hue[0.63, 0.7, 0.5], Opacity[0.7]],
  $edgePolygonStyle -> Directive[Hue[0.63, 0.66, 0.81], Opacity[0.1], EdgeForm[None]],
  $unaryEdgeStyle -> Directive[Hue[0.63, 0.7, 0.5], Opacity[0.7]],
  $vertexStyleFromPlotStyleDirective -> EdgeForm[Directive[GrayLevel[0], Opacity[0.95]]],
  $edgeLineStyleFromPlotStyleDirective -> Opacity[0.7],
  $edgePolygonStyleFromEdgeStyleDirective -> Directive[Opacity[0.1], EdgeForm[None]],
  $highlightedVertexStyleDirective -> EdgeForm[Directive[GrayLevel[0], Opacity[0.7]]],
  $highlightedEdgeLineStyleDirective -> Opacity[1],
  $highlightedUnaryEdgeStyleDirective -> Opacity[1],
  $highlightedEdgePolygonStyleDirective -> Opacity[0.3],
  $highlightStyle -> Red,
  $hyperedgeRendering -> "Polygons",
  $wolframModelPlotImageSize -> {{360}, {420}},

  (* RulePlot *)
  $sharedRuleElementsHighlight -> RGBColor[0.5, 0.5, 0.95],
  $ruleHyperedgeRendering -> "Polygons",
  $ruleVertexSize -> 0.1,
  $ruleArrowheadLength -> 0.3,
  $rulePartsAspectRatio -> Automatic,
  $rulePartsAspectRatioMin -> 0.2,
  $rulePartsAspectRatioMax -> 5.0,
  $ruleGraphPadding -> Scaled[0.1],
  $ruleSidesSpacing -> 0.13,
  $rulePartsFrameStyle -> GrayLevel[0.7],
  $ruleArrowShape -> FilledCurve[
    {{{0, 2, 0}, {0, 1, 0}, {0, 1, 0}, {0, 1, 0}, {0, 1, 0}, {0, 1, 0}, {0, 1, 0}, {0, 1, 0}, {0, 1, 0}}},
    {{{-1., 0.1848}, {0.2991, 0.1848}, {-0.1531, 0.6363}, {0.109, 0.8982}, {1., 0.0034}, {0.109, -0.8982},
      {-0.1531, -0.6363}, {0.2991, -0.1848}, {-1., -0.1848}, {-1., 0.1848}}}],
  $ruleArrowLength -> 0.15,
  $ruleArrowPadding -> 0.4,
  $ruleArrowStyle -> GrayLevel[0.65],
  $ruleGridColor -> GrayLevel[0.85],
  $ruleImageSizePerPlotRange -> 128,
  
  (* MultiwaySystem styles *)
  
  (* States graph *)
  $statesGraphVertexStyle -> Directive[Opacity[0.7], Hue[0.62, 0.45, 0.87]],
  $statesGraphEdgeStyle -> Directive[{Hue[0.75, 0, 0.35]}],

  (* Evolution causal graph *)
  $evolutionCausalGraphEvolutionEdgeStyle -> Directive[{Hue[0.75, 0, 0.24]}],
  $evolutionCausalGraphCausalEdgeStyle -> Directive[{Hue[0.07, 0.78, 1]}],

  (* Branchial graph *)
  $branchialGraphEdgeStyle -> Hue[0.89, 0.97, 0.71]
|>;
