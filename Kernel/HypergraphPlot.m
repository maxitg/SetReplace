Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["HypergraphPlot"]
PackageExport["WolframModelPlot"]

PackageScope["correctHypergraphPlotOptionsQ"]
PackageScope["$edgeTypes"]
PackageScope["hypergraphEmbedding"]

(* Documentation *)

SetUsage @ "
HypergraphPlot[s$, opts$] plots a list of vertex lists s$ as a hypergraph.
";

$plotStyleAutomatic = <|
  $vertexPoint -> style[$lightTheme][$vertexStyle],
  $edgeLine -> style[$lightTheme][$edgeLineStyle],
  $edgePoint -> style[$lightTheme][$unaryEdgeStyle],
  $edgePolygon -> style[$lightTheme][$edgePolygonStyle]
|>;

(* Automatic style pickes up, and possibly modifies the style it inherits from. *)
$newOptions = {
  "EdgePolygonStyle" -> Automatic, (* inherits from EdgeStyle, with specified small opacity *)
  EdgeStyle -> Automatic, (* inherits from PlotStyle *)
  GraphHighlight -> {},
  GraphHighlightStyle -> style[$lightTheme][$highlightStyle],
  "HyperedgeRendering" -> style[$lightTheme][$hyperedgeRendering],
  PlotStyle -> Automatic,
  VertexCoordinates -> {},
  VertexLabels -> None,
  VertexSize -> style[$lightTheme][$vertexSize],
  "ArrowheadLength" -> Automatic,
  VertexStyle -> Automatic, (* inherits from PlotStyle *)
  "MaxImageSize" -> Automatic,
  Background -> Automatic};

$defaultGraphicsOptions = FilterRules[Options[Graphics], Except[$newOptions]];

Options[HypergraphPlot] = Join[$newOptions, $defaultGraphicsOptions];

SyntaxInformation[HypergraphPlot] = {
  "ArgumentsPattern" -> {_, _., OptionsPattern[]},
  "OptionNames" -> Options[HypergraphPlot][[All, 1]]};

$edgeTypes = {"Ordered", "Cyclic"};
$defaultEdgeType = "Ordered";
$graphLayout = "SpringElectricalEmbedding";
$hyperedgeRenderings = {"Subgraphs", "Polygons"};

(* for compatibility reasons, we don't care for messages and unevaluated code to preserve WolframModelPlot *)
SetUsage[WolframModelPlot, "WolframModelPlot is deprecated. Use HypergraphPlot."];
SyntaxInformation[WolframModelPlot] = SyntaxInformation[HypergraphPlot];
Options[WolframModelPlot] = Options[HypergraphPlot];
WolframModelPlot = HypergraphPlot;

(* Messages *)

General::invalidEdges =
  "First argument of HypergraphPlot must be a hypergraph, i.e., a list of lists, " <>
  "where elements represent vertices, or a list of such hypergraphs.";

General::invalidEdgeType =
  "Edge type `1` should be one of `2`.";

General::invalidCoordinates =
  "Coordinates `1` should be a list of rules from vertices to pairs of numbers.";

HypergraphPlot::invalidHighlight =
  "GraphHighlight value `1` should be a list of vertices and edges.";

General::invalidSize =
  "`1` `2` should be a non-negative number.";

General::invalidPlotStyle =
  "PlotStyle `1` should be either a style, or an association <|pattern -> style, ...|>.";

General::invalidStyleLength =
  "The list of styles `1` should have the same length as the number of `2` `3`.";

General::multigraphElementwiseStyle =
  "The elementwise style specification `1` is not supported for lists of hypergraphs.";

(* Evaluation *)

func : HypergraphPlot[args___] := ModuleScope[
  result = hypergraphPlot$parse[args];
  result /; result =!= $Failed
];

(* Arguments parsing *)

hypergraphPlot$parse[args___] /; !Developer`CheckArgumentCount[HypergraphPlot[args], 1, 2] := $Failed;

(* allow composite vertices, but not list-vertices *)
$hypergraphPattern = _List ? (Function[h, AllTrue[h, ListQ[#] && Length[#] > 0 &] && AllTrue[h, Not @* ListQ, 2]]);
$multiHypergraphPattern = $hypergraphPattern | {$hypergraphPattern...};

hypergraphPlot$parse[edges : Except[$multiHypergraphPattern], edgeType_ : $defaultEdgeType, o : OptionsPattern[]] := (
  Message[HypergraphPlot::invalidEdges];
  $Failed
);

hypergraphPlot$parse[
    edges : $multiHypergraphPattern,
    edgeType : Except[Alternatives[Alternatives @@ $edgeTypes, OptionsPattern[]]],
    o : OptionsPattern[]] := (
  Message[HypergraphPlot::invalidEdgeType, edgeType, $edgeTypes];
  $Failed
);

hypergraphPlot$parse[
  edges : {$hypergraphPattern..}, edgeType : Alternatives @@ $edgeTypes : $defaultEdgeType, o : OptionsPattern[]] /;
    correctHypergraphPlotOptionsQ[HypergraphPlot, Defer[HypergraphPlot[edges, o]], edges, {o}] :=
  hypergraphPlot$parse[#, edgeType, o] & /@ edges;

parseHighlight[_, _, {}, _] := ConstantArray[Automatic, 3];

parseHighlight[vertices_, edges_, highlightList_, highlightStyle_] := ModuleScope[
  highlightCounts = Counts[highlightList];
  {vertexHighlightFlags, edgeHighlightFlags} = Map[
    With[{highlightedQ = If[MissingQ[highlightCounts[#]], False, highlightCounts[#]-- > 0]},
      Replace[highlightedQ, False -> Automatic]] &,
    {vertices, edges},
    {2}];
  {Replace[
      vertexHighlightFlags,
      True -> Directive[highlightStyle, style[$lightTheme][$highlightedVertexStyleDirective]], {1}],
    Replace[
      edgeHighlightFlags,
      True -> Directive[highlightStyle, style[$lightTheme][$highlightedEdgeLineStyleDirective]], {1}],
    Replace[
      edgeHighlightFlags,
      True -> Directive[highlightStyle, style[$lightTheme][$highlightedEdgePolygonStyleDirective]], {1}]}
];

hypergraphPlot$parse[
      edges : $hypergraphPattern, edgeType : Alternatives @@ $edgeTypes : $defaultEdgeType, o : OptionsPattern[]] /;
        correctHypergraphPlotOptionsQ[HypergraphPlot, Defer[HypergraphPlot[edges, o]], edges, {o}] := ModuleScope[
  ScopeVariable[optionValue];
  optionValue[opt_] := OptionValue[HypergraphPlot, {o}, opt];
  vertices = vertexList[edges];
  (* these are either single styles or lists, one style for each element *)
  {highlightedVertexStyles, highlightedEdgeLineStyles, highlightedEdgePolygonStyles} =
    parseHighlight[vertices, edges, optionValue[GraphHighlight], optionValue[GraphHighlightStyle]];
  styles = <|
    $vertexPoint -> Replace[
      parseStyles[
        highlightedVertexStyles,
        vertices,
        parseStyles[
          optionValue[VertexStyle],
          vertices,
          parseStyles[optionValue[PlotStyle], vertices, Automatic, Identity],
          Directive[#, style[$lightTheme][$vertexStyleFromPlotStyleDirective]] &],
        Identity],
      Automatic -> $plotStyleAutomatic[$vertexPoint],
      {0, 1}],
    $edgeLine -> Replace[
      edgeStyles = parseStyles[
        highlightedEdgeLineStyles,
        edges,
        parseStyles[
          optionValue[EdgeStyle],
          edges,
          parseStyles[optionValue[PlotStyle], edges, Automatic, Identity],
          Directive[#, style[$lightTheme][$edgeLineStyleFromPlotStyleDirective]] &],
        Identity],
      Automatic -> $plotStyleAutomatic[$edgeLine],
      {0, 1}],
    $edgePoint -> Replace[edgeStyles, Automatic -> $plotStyleAutomatic[$edgePoint], {0, 1}],
    $edgePolygon -> Replace[
      parseStyles[
        highlightedEdgePolygonStyles,
        edges,
        parseStyles[
          optionValue["EdgePolygonStyle"],
          edges,
          edgeStyles,
          Directive[#, style[$lightTheme][$edgePolygonStyleFromEdgeStyleDirective]] &],
        Identity],
      Automatic -> $plotStyleAutomatic[$edgePolygon],
      {0, 1}]|>;
  hypergraphPlot[
    edges, edgeType, styles, ##, FilterRules[{o}, $defaultGraphicsOptions]] & @@
      (optionValue /@ {
        "HyperedgeRendering",
        VertexCoordinates,
        VertexLabels,
        VertexSize,
        "ArrowheadLength",
        "MaxImageSize",
        Background})
];

toListStyleSpec[Automatic, elements_] := toListStyleSpec[<||>, elements];

toListStyleSpec[spec : Except[_List | _Association], elements_] := toListStyleSpec[<|_ -> spec|>, elements];

toListStyleSpec[spec_Association, elements_] := Replace[elements, Reverse[Join[{_ -> Automatic}, Normal[spec]]], {1}];

toListStyleSpec[spec_List, _] := spec;

parseStyles[newSpec_, elements_, oldSpec_, oldToNewTransform_] /;
    AnyTrue[{oldSpec, newSpec}, MatchQ[#, _List | _Association] &] :=
  MapThread[
    If[#2 === Automatic, #1, Replace[#1, Automatic -> oldToNewTransform[#2]]] &,
    toListStyleSpec[#, elements] & /@ {newSpec, oldSpec}];

parseStyles[newSpec_, elements_, oldSpec_, oldToNewTransform_] /;
    AllTrue[{oldSpec, newSpec}, MatchQ[#, Except[_List | _Association]] &] :=
  First[parseStyles[{newSpec}, {}, {oldSpec}, oldToNewTransform]];

hypergraphPlot$parse[___] := $Failed;

correctHypergraphPlotOptionsQ[head_, expr_, edges_, opts_] :=
  knownOptionsQ[head, expr, opts] &&
  (And @@ (supportedOptionQ[head, ##, opts] & @@@ {
      {"HyperedgeRendering", $hyperedgeRenderings}})) &&
  correctCoordinateRulesQ[head, OptionValue[HypergraphPlot, opts, VertexCoordinates]] &&
  correctHighlightQ[OptionValue[HypergraphPlot, opts, GraphHighlight]] &&
  correctSizeQ[head, "Vertex size", OptionValue[HypergraphPlot, opts, VertexSize], {}] &&
  correctSizeQ[head, "Arrowhead length", OptionValue[HypergraphPlot, opts, "ArrowheadLength"], {Automatic}] &&
  correctPlotStyleQ[head, OptionValue[HypergraphPlot, opts, PlotStyle]] &&
  correctStyleLengthQ[
    head,
    "vertices",
    MatchQ[edges, {$hypergraphPattern..}],
    Length[vertexList[edges]],
    OptionValue[HypergraphPlot, opts, VertexStyle]] &&
  And @@ (correctStyleLengthQ[
    head,
    "edges",
    MatchQ[edges, {$hypergraphPattern..}],
    Length[edges],
    OptionValue[HypergraphPlot, opts, #]] & /@ {EdgeStyle, "EdgePolygonStyle"});

correctCoordinateRulesQ[head_, coordinateRules_] :=
  If[!MatchQ[coordinateRules,
      Automatic |
      {(_ -> {Repeated[_ ? NumericQ, {2}]})...}],
    Message[head::invalidCoordinates, coordinateRules];
    False,
    True
  ];

correctHighlightQ[highlight_] := (
  If[!ListQ[highlight], Message[HypergraphPlot::invalidHighlight, highlight]];
  ListQ[highlight]
);

correctSizeQ[head_, capitalizedName_, size_ ? (# >= 0 &), _] := True;

correctSizeQ[head_, capitalizedName_, size_, allowedSpecialValues_] /;
    MatchQ[size, Alternatives @@ allowedSpecialValues] := True;

correctSizeQ[head_, capitalizedName_, size_, _] := (
  Message[head::invalidSize, capitalizedName, size];
  False
);

correctPlotStyleQ[head_, style_List] := (
  Message[head::invalidPlotStyle, style];
  False
);

correctPlotStyleQ[__] := True;

(* Single hypergraph *)
correctStyleLengthQ[head_, name_, False, correctLength_, styles_List] /; Length[styles] =!= correctLength := (
  Message[head::invalidStyleLength, styles, name, correctLength];
  False
);

(* Multiple hypergraphs *)
correctStyleLengthQ[head_, name_, True, correctLength_, styles_List] := (
  Message[head::multigraphElementwiseStyle, styles];
  False
);

correctStyleLengthQ[__] := True;

(* Implementation *)

hypergraphPlot[
    edges_,
    edgeType_,
    styles_,
    hyperedgeRendering_,
    vertexCoordinates_,
    vertexLabels_,
    vertexSize_,
    arrowheadLength_,
    maxImageSize_,
    background_,
    graphicsOptions_] := Catch[Module[{embedding, graphics, imageSizeScaleFactor, numericArrowheadLength},
  embedding = hypergraphEmbedding[edgeType, hyperedgeRendering, vertexCoordinates] @ edges;
  numericArrowheadLength = Replace[
    arrowheadLength,
    Automatic -> style[$lightTheme][$arrowheadLengthFunction][<|"PlotRange" -> vertexEmbeddingRange[embedding[[1]]]|>]];
  graphics =
    drawEmbedding[styles, vertexLabels, vertexSize, numericArrowheadLength] @ embedding;
  imageSizeScaleFactor = Min[1, 0.7 (#[[2]] - #[[1]])] & /@ PlotRange[graphics];
  Show[
    graphics,
    graphicsOptions,
    Background -> Replace[background, Automatic -> style[$lightTheme][$spatialGraphBackground]],
    If[maxImageSize === Automatic,
      ImageSizeRaw -> style[$lightTheme][$hypergraphPlotImageSize] imageSizeScaleFactor,
      ImageSize -> adjustImageSize[maxImageSize, imageSizeScaleFactor]]]
]];

vertexEmbeddingRange[{}] := 0;

vertexEmbeddingRange[vertexEmbedding_] := Max[#2 - #1 & @@@ MinMax /@ Transpose[vertexEmbedding[[All, 2, 1, 1]]]];

adjustImageSize[w_ ? NumericQ, {wScale_, hScale_}] := w wScale;

adjustImageSize[dims : {w_ ? NumericQ, h_ ? NumericQ}, scale_] := dims scale;

HypergraphPlot::invalidMaxImageSize =
  "MaxImageSize `1` should either be a single number (width) or a list of two numbers (width and height)";

adjustImageSize[dims_, _] := (Message[HypergraphPlot::invalidMaxImageSize, dims]; Throw[$Failed]);

(** Embedding **)
(** hypergraphEmbedding produces an embedding of vertices and edges. The format is {vertices, edges},
      where both vertices and edges are associations of the form <|vertex -> {graphicsPrimitive, ...}, ...|>,
      where graphicsPrimitive is either a Point, a Line, or a Polygon. **)

(*** SpringElectricalEmbedding ***)

hypergraphEmbedding[edgeType_, hyperedgeRendering : "Subgraphs", coordinateRules_] :=
  hypergraphEmbedding[edgeType, edgeType, hyperedgeRendering, coordinateRules];

hypergraphEmbedding[
      vertexLayoutEdgeType_,
      edgeLayoutEdgeType_,
      hyperedgeRendering : "Subgraphs",
      coordinateRules_][
      edges_] := ModuleScope[
  vertices = vertexList[edges];
  {vertexEmbeddingNormalEdges, edgeEmbeddingNormalEdges} =
    toNormalEdges[edges, #] & /@ {vertexLayoutEdgeType, edgeLayoutEdgeType};
  normalToHypergraphEmbedding[
    edges,
    edgeEmbeddingNormalEdges,
    graphEmbedding[
      vertices,
      Catenate[vertexEmbeddingNormalEdges],
      Catenate[edgeEmbeddingNormalEdges],
      $graphLayout,
      coordinateRules]]
];

toNormalEdges[edges_, partitionArgs___] := DirectedEdge @@@ Partition[#, partitionArgs] & /@ edges;

toNormalEdges[edges_, "Ordered"] := toNormalEdges[edges, 2, 1];

toNormalEdges[edges_, "Cyclic"] := toNormalEdges[edges, 2, 1, 1];

graphEmbedding[vertices_, vertexEmbeddingEdges_, edgeEmbeddingEdges_, layout_, coordinateRules_] := ModuleScope[
  relevantCoordinateRules = Normal[Merge[Select[MemberQ[vertices, #[[1]]] &][coordinateRules], Last]];
  unscaledEmbedding = If[vertexEmbeddingEdges === edgeEmbeddingEdges,
    graphEmbedding[vertices, edgeEmbeddingEdges, layout, relevantCoordinateRules],
    With[{ve = vertexEmbedding[vertices, vertexEmbeddingEdges, layout, relevantCoordinateRules]},
      {ve, edgeEmbedding[vertices, edgeEmbeddingEdges, layout, ve]}
    ]
  ];
  rescaleEmbedding[unscaledEmbedding, relevantCoordinateRules]
];

vertexEmbedding[vertices_, edges_, layout_, {}] := Thread[vertices -> GraphEmbedding[Graph[vertices, edges], layout]];

vertexEmbedding[vertices_, edges_, layout_, coordinateRules_] :=
  graphEmbedding[vertices, edges, layout, coordinateRules][[1]];

edgeEmbedding[vertices_, edges_, "SpringElectricalEmbedding", vertexCoordinates_] /;
    SimpleGraphQ[Graph[UndirectedEdge @@@ edges]] := ModuleScope[
  coordinates = Association[vertexCoordinates];
  Thread[edges -> List @@@ Map[coordinates, edges, {2}]]
];

edgeEmbedding[vertices_, edges_, layout_, vertexCoordinates_] :=
  graphEmbedding[vertices, edges, layout, vertexCoordinates][[2]];

graphEmbedding[vertices_, edges_, layout_, coordinateRules_] := Replace[
  Reap[
    GraphPlot[
      Graph[vertices, edges],
      GraphLayout -> layout,
      VertexCoordinates -> coordinateRules,
      VertexShapeFunction -> (Sow[#2 -> #, "v"] &),
      EdgeShapeFunction -> (Sow[#2 -> #, "e"] &)],
    {"v", "e"}][[2]],
  el : Except[{}] :> el[[1]],
  {1}
];

normalToHypergraphEmbedding[edges_, normalEdges_, normalEmbedding_] := ModuleScope[
  vertexEmbedding = Sort[#[[1]] -> {Point[#[[2]]]} & /@ normalEmbedding[[1]]];

  indexedHyperedges = MapIndexed[{#, #2[[1]]} &, edges];
  (* vertices in the normalEdges should already be sorted by now. *)
  normalEdgeToIndexedHyperedge = Sort[Catenate[MapThread[Thread[#2 -> Defer[#]] &, {indexedHyperedges, normalEdges}]]];

  normalEdgeToLinePoints = Sort[If[Head[#] === DirectedEdge, #, Sort[#]] & /@ normalEmbedding[[2]]];
  lineSegments = Line /@ normalEdgeToLinePoints[[All, 2]];

  indexedHyperedgesToLineSegments =
    #[[1, 1]] -> #[[2]] & /@
      Normal[Merge[Thread[normalEdgeToIndexedHyperedge[[All, 2]] -> lineSegments], Identity]];
  indexedEdgeEmbedding = #[[1]] -> #[[2]] & /@ indexedHyperedgesToLineSegments;

  indexedSingleVertexEdges =
    With[{
        indices = Position[normalEdges, {}, 1][[All, 1]]},
      Cases[Transpose[{edges[[indices]], indices}], Except[{{}, _}], 1]];
  indexedSingleVertexEdgeEmbedding = (# -> (#[[1, 1]] /. vertexEmbedding)) & /@ indexedSingleVertexEdges;

  {vertexEmbedding,
    #[[1, 1]] -> #[[2]] & /@ SortBy[Join[indexedEdgeEmbedding, indexedSingleVertexEdgeEmbedding], #[[1, 2]] &]}
];

rescaleEmbedding[unscaledEmbedding_, {_, __}] := unscaledEmbedding;

rescaleEmbedding[unscaledEmbedding_, {v_ -> pivotPoint_}] :=
  rescaleEmbedding[unscaledEmbedding, pivotPoint, 1 / edgeScale[unscaledEmbedding]];

rescaleEmbedding[unscaledEmbedding_, {}] := rescaleEmbedding[unscaledEmbedding, {0 -> {0.0, 0.0}}];

lineLength[pts_] := Total[EuclideanDistance @@@ Partition[pts, 2, 1]];

$selfLoopsScale = 0.7;
edgeScale[{vertexEmbedding_, edgeEmbedding : Except[{}]}] := ModuleScope[
  selfLoops = Select[#[[1, 1]] == #[[1, 2]] &][edgeEmbedding][[All, 2]];
  Mean[lineLength /@ N /@ If[selfLoops =!= {}, $selfLoopsScale * selfLoops, edgeEmbedding[[All, 2]]]]
];

edgeScale[{{} | {_ -> _}, _}] := 1;

edgeScale[{vertexEmbedding_, {}}] :=
  lineLength[Transpose[MinMax /@ Transpose[vertexEmbedding[[All, 2]]]]] /
    (Sqrt[N[Length[vertexEmbedding]] / 2]);

rescaleEmbedding[embedding_, center_, factor_] := Map[
  (#[[1]] -> (#[[2]] /. coords : {Repeated[_Real, {2}]} :> (coords - center) * factor + center)) &,
  embedding,
  {2}
];

(*** SpringElectricalPolygons ***)

hypergraphEmbedding[edgeType_, hyperedgeRendering : "Polygons", vertexCoordinates_][edges_] := ModuleScope[
  embeddingWithNoRegions =
    hypergraphEmbedding["Cyclic", edgeType, "Subgraphs", vertexCoordinates][edges];
  vertexEmbedding = embeddingWithNoRegions[[1]];
  edgeEmbedding = addConvexPolygons[edgeType] @@@ embeddingWithNoRegions[[2]];
  {vertexEmbedding, edgeEmbedding}
];

addConvexPolygons["Ordered"][edge : {_, _.}, subgraphsShapes_] := edge -> subgraphsShapes;

addConvexPolygons[edgeType_][edge_, subgraphsShapes_] := ModuleScope[
  points = Flatten[#, 2] & @ (subgraphsShapes /. {Line[pts_] :> {pts}, Point[pts_] :> {{pts}}});
  edge -> If[Length[points] > 2, Append[subgraphsShapes, convexHullPolygon[points]], subgraphsShapes]
];

(** Drawing **)

applyStyle[style : Except[_List], shapes_] := With[{trimmedShapes = DeleteCases[shapes, {}]},
  If[trimmedShapes === {}, Nothing, {style, trimmedShapes}]
];

applyStyle[style_List, shapes_] := Replace[DeleteCases[Transpose[{style, shapes}], {_, {}}], {} -> Nothing];

vertexLabelsGraphics[embedding_, vertexSize_, vertexLabels_] := ModuleScope[
  pointsToVertices =
    Association[Reverse /@ Catenate[Function[{v, pts}, v -> # & /@ Cases[pts, _Point]] @@@ embedding[[1]]]];
  edges =
    Cases[embedding[[2]], Line[{pt1_, ___, pt2_}] :> UndirectedEdge @@ pointsToVertices /@ Point /@ {pt1, pt2}, All];
  vertexCoordinatesDiagonal = EuclideanDistance @@ Transpose[CoordinateBounds[First /@ Keys[pointsToVertices]]];
  graphPlotVertexSize = If[vertexCoordinatesDiagonal == 0,
    2 vertexSize,
    {"Scaled", 2 vertexSize / vertexCoordinatesDiagonal}
  ];
  GraphPlot[
    Graph[Values[pointsToVertices], edges],
    VertexCoordinates -> Thread[Values[pointsToVertices] -> First /@ Keys[pointsToVertices]],
    VertexLabels -> vertexLabels,
    GraphLayout -> "SpringElectricalEmbedding", (* smart vertex placement does not seem to work otherwise *)
    VertexSize -> graphPlotVertexSize,
    VertexShapeFunction -> None,
    EdgeShapeFunction -> None]
];

drawEmbedding[
      styles_,
      vertexLabels_,
      vertexSize_,
      arrowheadLength_][
      embedding_] := ModuleScope[
  singleVertexEdgeCounts = <||>;
  ScopeVariable[getSingleVertexEdgeRadius];
  getSingleVertexEdgeRadius[coords_] := (
    singleVertexEdgeCounts[coords] = Lookup[singleVertexEdgeCounts, Key[coords], vertexSize] + vertexSize
  );
  Show[
    Graphics[{
      applyStyle[styles[$edgePolygon], Cases[#, _Polygon, All] & /@ embedding[[2, All, 2]]],
      applyStyle[styles[$edgeLine],
        Cases[
            #, Line[pts_] :> arrow[style[$lightTheme][$edgeArrowheadShape], arrowheadLength, vertexSize][pts], All] & /@
          embedding[[2, All, 2]]],
      applyStyle[styles[$vertexPoint], Cases[#, Point[pts_] :> Disk[pts, vertexSize], All] & /@ embedding[[1, All, 2]]],
      applyStyle[styles[$edgePoint],
          Cases[#, Point[pts_] :> Circle[pts, getSingleVertexEdgeRadius[pts]], All] & /@ embedding[[2, All, 2]]]}],
    If[vertexLabels === None,
      Graphics[{}],
      vertexLabelsGraphics[embedding, vertexSize, vertexLabels]
    ]
  ]
];
