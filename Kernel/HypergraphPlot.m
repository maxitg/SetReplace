Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["HypergraphPlot"]
PackageExport["WolframModelPlot"]

PackageScope["hypergraphPlot"]
PackageScope["checkHypergraphPlotOptions"]
PackageScope["$edgeTypes"]
PackageScope["$hyperedgeRenderings"]
PackageScope["hypergraphEmbedding"]

(* Documentation *)

SetUsage @ "
HypergraphPlot[hypergraph$, options$] plots an ordered hypergraph$ represented as a list of vertex lists.
HypergraphPlot[hypergraph$, 'Cyclic', options$] plots a 'Cyclic' hypergraph$ instead.
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
  "ArgumentsPattern" -> {hypergraph_, edgeType_., OptionsPattern[]},
  "OptionNames" -> Options[HypergraphPlot][[All, 1]]};

$edgeTypes = {"Ordered", "Cyclic"};
$defaultEdgeType = "Ordered";
$graphLayout = "SpringElectricalEmbedding";
$hyperedgeRenderings = {"Subgraphs", "Polygons"};

With[{edgeTypes = $edgeTypes},
  FE`Evaluate[FEPrivate`AddSpecialArgCompletion["HypergraphPlot" -> {0, edgeTypes}]]
];

(* for compatibility reasons, we don't care for messages and unevaluated code to preserve WolframModelPlot *)
SetUsage[WolframModelPlot,
         "WolframModelPlot is deprecated. Use HypergraphPlot which takes the same arguments.\n" <>
           StringReplace[HypergraphPlot::usage, "HypergraphPlot" -> "WolframModelPlot"]];
Options[WolframModelPlot] = Options[HypergraphPlot];
SyntaxInformation[WolframModelPlot] = SyntaxInformation[HypergraphPlot];
WolframModelPlot = HypergraphPlot;

(* Evaluation *)

expr : HypergraphPlot[args___] := ModuleScope[
  result = Catch[hypergraphPlot[args], _ ? FailureQ, message[HypergraphPlot, #, <|"expr" -> HoldForm[expr]|>] &];
  result /; !FailureQ[result]
];

(* Arguments parsing *)

hypergraphPlot[args___] /; !Developer`CheckArgumentCount[HypergraphPlot[args], 1, 2] := $Failed;

$hypergraphPattern = _List ? (Function[h, VectorQ[h, (ListQ[#] && (# =!= {})) &]]);

declareMessage[
  General::invalidEdges,
  "First argument of HypergraphPlot must be a hypergraph, i.e., a list of lists, where elements represent vertices."];

hypergraphPlot[Except[$hypergraphPattern], _ : $defaultEdgeType, OptionsPattern[]] :=
  throw[Failure["invalidEdges", <||>]];

declareMessage[General::invalidEdgeType, "Edge type `type` should be one of `allowedTypes`."];

hypergraphPlot[$hypergraphPattern,
               edgeType : Except[Alternatives[Alternatives @@ $edgeTypes, OptionsPattern[]]],
               OptionsPattern[]] :=
  throw[Failure["invalidEdgeType", <|"type" -> edgeType, "allowedTypes" -> $edgeTypes|>]];

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

hypergraphPlot[edges : $hypergraphPattern,
               edgeType : Alternatives @@ $edgeTypes : $defaultEdgeType,
               o : OptionsPattern[]] := ModuleScope[
  checkHypergraphPlotOptions[HypergraphPlot, edges, {o}];
  ScopeVariable[optionValue];
  optionValue[option_] := OptionValue[HypergraphPlot, {o}, option];
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
  hypergraphPlotImplementation[
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

hypergraphPlot[___] := $Failed;

checkHypergraphPlotOptions[head_, edges_, options_] := (
  checkIfKnownOptions[head, options];
  checkEnumOptionValue[head, "HyperedgeRendering", $hyperedgeRenderings, options];
  checkVertexCoordinates[OptionValue[HypergraphPlot, options, VertexCoordinates]];
  checkHighlight[OptionValue[HypergraphPlot, options, GraphHighlight]];
  checkSize["Vertex size", OptionValue[HypergraphPlot, options, VertexSize], {}];
  checkSize["Arrowhead length", OptionValue[HypergraphPlot, options, "ArrowheadLength"], {Automatic}];
  checkPlotStyle[OptionValue[HypergraphPlot, options, PlotStyle]];
  checkStyleLength["vertices", Length[vertexList[edges]], OptionValue[HypergraphPlot, options, VertexStyle]];
  checkStyleLength["edges", Length[edges], OptionValue[HypergraphPlot, options, #]] & /@
    {EdgeStyle, "EdgePolygonStyle"};
);

declareMessage[General::invalidCoordinates,
               "Coordinates `coordinates` should be a list of rules from vertices to pairs of numbers."];

checkVertexCoordinates[vertexCoordinates_] :=
  If[!MatchQ[vertexCoordinates, Automatic | {(_ -> {Repeated[_ ? NumericQ, {2}]})...}],
    throw[Failure["invalidCoordinates", <|"coordinates" -> vertexCoordinates|>]]
  ];

declareMessage[
  HypergraphPlot::invalidHighlight, "GraphHighlight value `highlightValue` should be a list of vertices and edges."];

checkHighlight[highlight_] :=
  If[!ListQ[highlight], throw[Failure["invalidHighlight", <|"highlightValue" -> highlight|>]]];

checkSize[_, size_ ? (# >= 0 &), _] := True;

checkSize[_, size_, allowedSpecialValues_] /; MatchQ[size, Alternatives @@ allowedSpecialValues] := True;

declareMessage[General::invalidSize, "`capitalizedName` `size` should be a non-negative number."];

checkSize[capitalizedName_, size_, _] :=
  throw[Failure["invalidSize", <|"capitalizedName" -> capitalizedName, "size" -> size|>]];

declareMessage[General::invalidPlotStyle,
               "PlotStyle `plotStyle` should be either a style, or an association <|pattern -> style, ...|>."];

checkPlotStyle[style_List] := throw[Failure["invalidPlotStyle", <|"plotStyle" -> style|>]];

declareMessage[General::invalidStyleLength,
               "The list of styles `styles` should have the same length `correctLength` as the number of `name`."];

checkStyleLength[name_, correctLength_, styles_List] /; Length[styles] =!= correctLength :=
  throw[Failure["invalidStyleLength", <|"styles" -> styles, "name" -> name, "correctLength" -> correctLength|>]];

(* Implementation *)

hypergraphPlotImplementation[
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
    graphicsOptions_] := Module[{embedding, graphics, imageSizeScaleFactor, numericArrowheadLength},
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
      ImageSizeRaw -> style[$lightTheme][$hypergraphPlotImageSize] imageSizeScaleFactor
    ,
      ImageSize -> adjustImageSize[maxImageSize, imageSizeScaleFactor]
    ]]
];

vertexEmbeddingRange[{}] := 0;

vertexEmbeddingRange[vertexEmbedding_] := Max[#2 - #1 & @@@ MinMax /@ Transpose[vertexEmbedding[[All, 2, 1, 1]]]];

adjustImageSize[w_ ? NumericQ, {wScale_, hScale_}] := w wScale;

adjustImageSize[dims : {w_ ? NumericQ, h_ ? NumericQ}, scale_] := dims scale;

declareMessage[
  HypergraphPlot::invalidMaxImageSize,
  "MaxImageSize `dims` should either be a single number (width) or a list of two numbers (width and height)"];

adjustImageSize[dims_, _] := throw[Failure["invalidMaxImageSize", <|"dims" -> dims|>]];

(** Embedding **)
(** hypergraphEmbedding produces an embedding of vertices and edges. The format is {vertices, edges},
      where both vertices and edges are associations of the form <|vertex -> {graphicsPrimitive, ...}, ...|>,
      where graphicsPrimitive is either a Point, a Line, or a Polygon. **)

(*** SpringElectricalEmbedding ***)

hypergraphEmbedding[edgeType_, hyperedgeRendering : "Subgraphs", vertexCoordinates_] :=
  hypergraphEmbedding[edgeType, edgeType, hyperedgeRendering, vertexCoordinates];

hypergraphEmbedding[
      vertexLayoutEdgeType_,
      edgeLayoutEdgeType_,
      hyperedgeRendering : "Subgraphs",
      vertexCoordinates_][
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
      vertexCoordinates]]
];

toNormalEdges[edges_, partitionArgs___] := DirectedEdge @@@ Partition[#, partitionArgs] & /@ edges;

toNormalEdges[edges_, "Ordered"] := toNormalEdges[edges, 2, 1];

toNormalEdges[edges_, "Cyclic"] := toNormalEdges[edges, 2, 1, 1];

graphEmbedding[vertices_, vertexEmbeddingEdges_, edgeEmbeddingEdges_, layout_, vertexCoordinates_] := ModuleScope[
  relevantVertexCoordinates = Normal[Merge[Select[MemberQ[vertices, #[[1]]] &][vertexCoordinates], Last]];
  unscaledEmbedding = If[vertexEmbeddingEdges === edgeEmbeddingEdges,
    graphEmbedding[vertices, edgeEmbeddingEdges, layout, relevantVertexCoordinates]
  ,
    With[{ve = vertexEmbedding[vertices, vertexEmbeddingEdges, layout, relevantVertexCoordinates]},
      {ve, edgeEmbedding[vertices, edgeEmbeddingEdges, layout, ve]}
    ]
  ];
  rescaleEmbedding[unscaledEmbedding, relevantVertexCoordinates]
];

vertexEmbedding[vertices_, edges_, layout_, {}] := Thread[vertices -> GraphEmbedding[Graph[vertices, edges], layout]];

vertexEmbedding[vertices_, edges_, layout_, vertexCoordinates_] :=
  graphEmbedding[vertices, edges, layout, vertexCoordinates][[1]];

edgeEmbedding[vertices_, edges_, "SpringElectricalEmbedding", vertexCoordinates_] /;
    SimpleGraphQ[Graph[UndirectedEdge @@@ edges]] := ModuleScope[
  coordinates = Association[vertexCoordinates];
  Thread[edges -> List @@@ Map[coordinates, edges, {2}]]
];

edgeEmbedding[vertices_, edges_, layout_, vertexCoordinates_] :=
  graphEmbedding[vertices, edges, layout, vertexCoordinates][[2]];

graphEmbedding[vertices_, edges_, layout_, vertexCoordinates_] := Replace[
  Reap[
    GraphPlot[
      Graph[vertices, edges],
      GraphLayout -> layout,
      VertexCoordinates -> vertexCoordinates,
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
    2 vertexSize
  ,
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
      Graphics[{}]
    ,
      vertexLabelsGraphics[embedding, vertexSize, vertexLabels]
    ]
  ]
];
