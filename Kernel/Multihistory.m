Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["Multihistory"]

SetUsage @ "
Multihistory[$$] is an object containing evaluation of a possibly nondeterministic computational system.
";

SyntaxInformation[Multihistory] = {"ArgumentsPattern" -> {type_, internalData_}};

(* Multihistory can contain an evaluation of any substitution system, such as multiset, hypergraph, string, etc.
   Internally, it has a type specifying what kind of system it is as the first argument (including the version), and any
   data as the second.
   Note that specific types should never appear in this file, as Multihistory implementation is not type specific. *)

objectType[Multihistory[type_, _]] := type;

(* This is temporary and will need to be updated to use a composite property to automatically extract data from a
   Multihistory. Using a composite property will also allow objects to implement custom boxes for themselves. *)

$genericMultihistoryIcon = GraphPlot[
  {DirectedEdge[0, 1], DirectedEdge[1, 2], DirectedEdge[1, 3]},
  GraphLayout -> "LayeredDigraphEmbedding",
  VertexStyle -> {1 -> style[$lightTheme][$expressionVertexStyle], style[$lightTheme][$causalGraphVertexStyle]},
  EdgeStyle -> Directive[style[$lightTheme][$causalGraphEdgeStyle], Arrowheads[0]],
  VertexCoordinates -> {{0, 1}, {0, 0}, {0, -1} . RotationMatrix[Pi / 4], {0, -1} . RotationMatrix[-Pi / 4]},
  VertexSize -> 0.5,
  PlotRange -> {{-1.3, 1.3}, {-1.3, 1.3}},
  Background -> style[$lightTheme][$causalGraphBackground]];

Multihistory /: MakeBoxes[object : Multihistory[_, _], format_] := ModuleScope[
  type = objectType[object];
  BoxForm`ArrangeSummaryBox[
    Multihistory,
    object,
    $genericMultihistoryIcon,
    (* Always displayed *)
    {{BoxForm`SummaryItem[{TraditionalForm[type]}]}},
    (* Displayed on request *)
    {},
    format,
    "Interpretable" -> Automatic
  ]
];

declareMessage[
  Multihistory::invalid,
  "Multihistory object `expr` is invalid. Use GenerateMultihistory, GenerateAllHistories or GenerateSingleHistory " <>
  "to construct Multihistory objects."];

expr : Multihistory[args___] /; Length[{args}] =!= 2 := ModuleScope[
  message[Multihistory::invalid, <|"expr" -> HoldForm[expr]|>];
  None /; False
];
