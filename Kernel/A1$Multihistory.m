Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["Multihistory"]
PackageExport["MultihistoryConvert"]

PackageScope["declareMultihistoryTranslation"]
PackageScope["declareRawMultihistoryProperty"]
PackageScope["declareCompositeMultihistoryProperty"]
PackageScope["multihistoryType"]
PackageScope["throwInvalidPropertyArgumentCount"]

PackageScope["initializeMultihistory"]

SetUsage @ "
Multihistory[$$] is an object containing evaluation of a non-deterministic computational system.
";

SyntaxInformation[Multihistory] = {"ArgumentsPattern" -> {type_, internalData_}};

(* Multihistory can contain an evaluation of any system, such as set/hypergraph substitution, string substitution, etc.
   Internally, it has a type specifying what kind of system it is as the first argument, and any data as the second.
   Generators can create multihistories of any type of their choosing. Properties can take any type as an input.
   This file contains functions that automate conversion between types.
   Note that specific types should never appear in this file, as Multihistory infrastructure is not type specific. *)

multihistoryType[Multihistory[type_, _]] := type;

declareMessage[General::notMultihistory, "The argument `arg` in `expr` is not a multihistory."];

multihistoryType[arg_] := throw[Failure["notMultihistory", <|"arg" -> arg|>]];

multihistoryQ[multihistory_] := Catch[multihistoryType[multihistory]; True, _ ? FailureQ, False &];

(* No declaration is required for a generator to create a new Multihistory type. Its job is to create a consistent
   internal structure. *)

(* The following functions collect the declarations for type conversions and properties. They are not processed
   immediately. Instead, there is a separate function to process them (and define all relevant DownValues), which is
   called from init.m.
   Note that as a result this file should load before the files with any declarations. *)

(* Some types can be convertable from one another. To convert one multihistory type to another, one can use a
   declareMultihistoryTranslation function. *)

(* Multihistory translation functions can throw failure objects, in which case a message will be generated with a name
   corresponding to the Failure's type, and the keys passed to the message template. *)

$translations = {};

declareMultihistoryTranslation[function_, fromType_, toType_] :=
  AppendTo[$translations, {function, type[fromType], type[toType]}];

(* This function is called after all declarations to combine translations to a Graph to allow multi-step conversions. *)

initializeMultihistoryTranslations[] := (
  $typesGraph = Graph[DirectedEdge @@@ Rest /@ $translations];
  $translationFunctions = Association[Thread[EdgeList[$typesGraph] -> (First /@ $translations)]];

  (* Find all strings used in the type names even on deeper levels (e.g., {"HypergraphSubstitutionSystem", 3}). *)
  With[{typeStrings = Cases[VertexList[$typesGraph], _String, All]},
    FE`Evaluate[FEPrivate`AddSpecialArgCompletion["MultihistoryConvert" -> {typeStrings}]];
  ];
);

(* MultihistoryConvert is a public plumbing function that allows one to convert multihistories from one type to another
   for optimization or persistence. *)

SetUsage @ "
MultihistoryConvert[type$][multihistory$] converts a multihistory$ to the requested type$.
";

SyntaxInformation[MultihistoryConvert] = {"ArgumentsPattern" -> {type_}};

expr : MultihistoryConvert[args1___][args2___] := ModuleScope[
  result = Catch[
    multihistoryConvert[args1][args2], _ ? FailureQ, message[MultihistoryConvert, #, <|"expr" -> HoldForm[expr]|>] &];
  result /; !FailureQ[result]
];

declareMessage[General::unknownType, "The type `type` in `expr` is not recognized."];

declareMessage[General::noConversionPath, "Cannot convert a Multihistory from `from` to `to` in `expr`."];

multihistoryConvert[toType_][multihistory_] := ModuleScope[
  fromType = multihistoryType[multihistory];
  If[!VertexQ[$typesGraph, type[#]], throw[Failure["unknownType", <|"type" -> #|>]]] & /@ {fromType, toType};
  path = FindShortestPath[$typesGraph, type[fromType], type[toType]];
  If[path === {} && toType =!= fromType,
    throw[Failure["noConversionPath", <|"from" -> fromType, "to" -> toType|>]];
  ];
  edges = DirectedEdge @@@ Partition[path, 2, 1];
  functions = $translationFunctions /@ edges;
  Fold[#2[#1] &, multihistory, functions]
];

(* declareRawMultihistoryProperty declares an implementation for a property for a particular Multihistory type.
   If requested for another type, an attempt will be made to convert to a type for which an implementation is
   available. *)

(* Implementation has the form: implementationFunction[args___][multihistory_] where multihistory is always of the
   requested type.

   propertySymbol will need to be called as propertySymbol[args___][multihistory_] where multihistory can be of any
   type convertable to the implemented one.
   propertySymbol[][multihistory_] can also be called as propertySymbol[multihistory]. *)

$rawProperties = {};

declareRawMultihistoryProperty[implementationFunction_, fromType_, toProperty_Symbol] :=
  AppendTo[$rawProperties, {implementationFunction, type[fromType], property[toProperty]}];

(* This function is called after all declarations to combine implementations to a Graph to allow multi-step conversions
   and to define DownValues for all property symbols. *)

initializeRawMultihistoryProperties[] := Module[{newEdges},
  newEdges = DirectedEdge @@@ Rest /@ $rawProperties;
  $typesGraph = EdgeAdd[$typesGraph, newEdges];
  $propertyEvaluationFunctions = Association[Thread[newEdges -> (First /@ $rawProperties)]];

  defineDownValuesForProperty /@ Cases[VertexList[$typesGraph], property[name_] :> name, {1}];
];

(* declareMultihistoryPropertyFromOtherProperties declares an implementation for a property that takes other properties
   as arguments. The relevant properties will be given to implementationFunction as functions. *)

(* Implementation has the form: implementationFunction[args___][propertyFunction$1_, propertyFunction$2_, ...] where
   propertyFunction$i should be called as propertyFunction$i[args], i.e., without a Multihistory argument. Correct
   multihistory will be used automatically.

   propertySymbol will be possible to use the same way as in declareRawMultihistoryProperty and will work as long as
   all requested properties are implemented with either approach. *)

declareCompositeMultihistoryProperty[implementationFunction_, fromProperties_List, toProperty_Symbol] := ModuleScope[
  Null; (* TODO: implement *)
];

(* This function is called after all declarations to combine implementations to a Graph to allow multi-step conversions
   and to define DownValues for all property symbols. *)

initializeCompositeMultihistoryProperties[] := (
  Null; (* TODO: implement *)
);

(* This function is called in init.m after all other files are loaded. *)

initializeMultihistory[] := (
  initializeMultihistoryTranslations[];
  initializeRawMultihistoryProperties[];
  initializeCompositeMultihistoryProperties[];
);

(* defineDownValuesForProperty defines both the operator form and the normal form for a property symbol.
   The down values it defines first search for the best path to compute a property and then evaluate the corresponding
   property implementation/translation functions. *)

declareMessage[General::noPropertyPath,
               "Cannot compute the property `property` for Multihistory type `type` in `expr`."];

(* invalidPropertyArgumentCount message is not thrown here, but is defined here because it needs to be intercepted in
   case a property is used not as an operator form (in which case expected and actual argument counts should be
   incremented by one). *)

declareMessage[
  General::invalidPropertyArgumentCount,
  "`expectedCount` argument`expectedCountPluralWordEnding` expected in `expr` instead of given `actualCount`."];

throwInvalidPropertyArgumentCount[expectedCount_, actualCount_] :=
  throw[Failure["invalidPropertyArgumentCount", <|"expectedCount" -> expectedCount,
                                                  "expectedCountPluralWordEnding" -> If[expectedCount == 1, "", "s"],
                                                  "actualCount" -> actualCount|>]];

incrementArgumentCounts[Failure[name : "invalidPropertyArgumentCount", args_]] :=
  Failure[name, ReplacePart[args, {"expectedCount" -> args["expectedCount"] + 1,
                                   "actualCount" -> args["actualCount"] + 1,
                                   "expectedCountPluralWordEnding" -> If[args["expectedCount"] == 0, "", "s"]}]];

incrementArgumentCounts[arg_] := arg;

(* Note that it's not possible to have another Multihistory as a first argument to the property, i.e.,
   property[auxiliaryMultihistory][mainMultihistoryArgument], because in that case it's impossible to distinguish
   for which multihistory the property should be evaluated. *)

declareMessage[General::invalidPropertyOperatorArgument,
               "A single multihistory argument is expected to the operator form `expr`."];

Attributes[defineDownValuesForProperty] = {HoldFirst};
defineDownValuesForProperty[publicProperty_] := (
  expr : publicProperty[args___][multihistory___] := ModuleScope[
    result = Catch[propertyImplementation[publicProperty][args][multihistory],
                   _ ? FailureQ,
                   message[publicProperty, #, <|"expr" -> HoldForm[expr], "head" -> publicProperty|>] &];
    result /; !FailureQ[result]
  ];

  expr : publicProperty[multihistory_ ? multihistoryQ, args___] := ModuleScope[
    result = Catch[propertyImplementation[publicProperty][args][multihistory],
                   _ ? FailureQ,
                   message[publicProperty,
                           incrementArgumentCounts[#],
                           <|"expr" -> HoldForm[expr], "head" -> publicProperty|>] &];
    result /; !FailureQ[result]
  ];

  propertyImplementation[publicProperty][args___][multihistory_] := ModuleScope[
    fromType = multihistoryType[multihistory];
    If[!VertexQ[$typesGraph, type[fromType]], throw[Failure["unknownType", <|"type" -> fromType|>]]];
    path = FindShortestPath[$typesGraph, type[fromType], property[publicProperty]];
    If[path === {},
      throw[Failure["noPropertyPath", <|"type" -> fromType, "property" -> publicProperty|>]];
    ];
    expectedTypeMultihistory = multihistoryConvert[path[[-2, 1]]][multihistory];
    propertyFunction = $propertyEvaluationFunctions[DirectedEdge[path[[-2]], path[[-1]]]];
    propertyFunction[args][expectedTypeMultihistory]
  ];

  propertyImplementation[publicProperty][args1___][args2___] := throw[Failure["invalidPropertyOperatorArgument", <||>]];
);
