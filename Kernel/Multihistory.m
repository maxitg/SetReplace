Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["Multihistory"]

SetUsage @ "
Multihistory[$$] is an object containing evaluation of a possibly non-deterministic computational system.
";

SyntaxInformation[Multihistory] = {"ArgumentsPattern" -> {type_, internalData_}};

(* Multihistory can contain an evaluation of any system, such as set/hypergraph substitution, string substitution, etc.
   Internally, it has a type specifying what kind of system it is as the first argument, and any data as the second.
   Generators can create multihistories of any type of their choosing. Properties can take any type as an input.
   This file contains functions that automate conversion between types.
   Note that specific types should never appear in this file, as Multihistory infrastructure is not type specific. *)

objectType[Multihistory[type_, _]] := type;

(* This is temporary and will need to be updated to use a composite property to automatically extract data from a
   Multihistory. Using a composite property will also allow objects to implement custom boxes for themselves. *)

Multihistory /: MakeBoxes[object_Multihistory, format_] := ModuleScope[
  type = objectType[object];
  BoxForm`ArrangeSummaryBox[
    Multihistory,
    object,
    GraphPlot[{0 -> 1, 1 -> 2, 1 -> 3},
              GraphLayout -> "LayeredDigraphEmbedding",
              VertexStyle -> {1 -> SetReplaceStyleData["ExpressionsEventsGraph", "ExpressionVertexStyle"],
                              SetReplaceStyleData["ExpressionsEventsGraph", "EventVertexStyle"]},
              EdgeStyle -> SetReplaceStyleData["ExpressionsEventsGraph", "EdgeStyle"],
              VertexCoordinates ->
                {{0, 1}, {0, 0}, {0, -1} . RotationMatrix[Pi / 4], {0, -1} . RotationMatrix[-Pi / 4]},
              VertexSize -> 0.5,
              PlotRange -> {{-1.3, 1.3}, {-1.3, 1.3}}],
    (* Always displayed *)
    {{BoxForm`SummaryItem[{"Type: ", type}]}},
    (* Displayed on request *)
    {},
    format,
    "Interpretable" -> Automatic
  ]
];
