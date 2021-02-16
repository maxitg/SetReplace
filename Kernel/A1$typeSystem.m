Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["TypeConvert"]

PackageScope["declareTypeTranslation"]
PackageScope["declareRawProperty"]
PackageScope["declareCompositeProperty"]
PackageScope["objectType"]
PackageScope["throwInvalidPropertyArgumentCount"]

PackageScope["initializeTypeSystem"]

declareMessage[General::unknownObject, "The argument `arg` in `expr` is not a known typed object."];

(* Object classes (like Multihistory) are expected to define their own objectType[...] implementation. This one is
   triggered if no other is found. *)

objectType[arg_] := throw[Failure["unknownObject", <|"arg" -> arg|>]];

objectQ[object_] := Catch[objectType[object]; True, _ ? FailureQ, False &];

(* No declaration is required for a generator to create a new object type. Its job is to create a consistent internal
   structure. *)

(* The following functions collect the declarations for type conversions and properties. They are not processed
   immediately. Instead, there is a separate function to process them (and define all relevant DownValues), which is
   called from init.m. Note that as a result this file should load before the files with any declarations. *)

(* Some types can be convertable from one another. To convert an object from one type to another, one can use a
   declareTypeTranslation function. *)

(* Type translation functions can throw failure objects, in which case a message will be generated with a name
   corresponding to the Failure's type, and the keys passed to the message template. *)

$translations = {};

declareTypeTranslation[function_, fromType_, toType_] :=
  AppendTo[$translations, {function, type[fromType], type[toType]}];

(* This function is called after all declarations to combine translations to a Graph to allow multi-step conversions. *)

initializeTypeSystemTranslations[] := (
  $typesGraph = Graph[DirectedEdge @@@ Rest /@ $translations];
  $translationFunctions = Association[Thread[EdgeList[$typesGraph] -> (First /@ $translations)]];

  (* Find all strings used in the type names even on deeper levels (e.g., {"HypergraphSubstitutionSystem", 3}). *)
  With[{typeStrings = Cases[VertexList[$typesGraph], _String, All]},
    FE`Evaluate[FEPrivate`AddSpecialArgCompletion["TypeConvert" -> {typeStrings}]];
  ];
);

(* TypeConvert is a public plumbing function that allows one to convert objects from one type to another for
   optimization or persistence. *)

SetUsage @ "
TypeConvert[type$][object$] converts an object$ to the requested type$.
";

SyntaxInformation[TypeConvert] = {"ArgumentsPattern" -> {type_}};

expr : TypeConvert[args1___][args2___] := ModuleScope[
  result = Catch[
    typeConvert[args1][args2], _ ? FailureQ, message[TypeConvert, #, <|"expr" -> HoldForm[expr]|>] &];
  result /; !FailureQ[result]
];

declareMessage[General::unconvertibleType, "The type `type` in `expr` can not be used for type conversions."];

declareMessage[General::noConversionPath, "Cannot convert an object from `from` to `to` in `expr`."];

typeConvert[toType_][object_] := ModuleScope[
  fromType = objectType[object];
  If[!VertexQ[$typesGraph, type[#]], throw[Failure["unconvertibleType", <|"type" -> #|>]]] & /@ {fromType, toType};
  path = FindShortestPath[$typesGraph, type[fromType], type[toType]];
  If[path === {} && toType =!= fromType,
    throw[Failure["noConversionPath", <|"from" -> fromType, "to" -> toType|>]];
  ];
  edges = DirectedEdge @@@ Partition[path, 2, 1];
  functions = $translationFunctions /@ edges;
  Fold[#2[#1] &, object, functions]
];

(* declareRawProperty declares an implementation for a property for a particular object type. If requested for another
  type, an attempt will be made to convert to a type for which an implementation is available. *)

(* Implementation has the form: implementationFunction[args___][object_] where object is always of the requested type.
   toProperty will need to be called as toProperty[args___][object_] or toProperty[object_, args___] where object can be
   of any type convertable to the implemented one. *)

$rawProperties = {};

declareRawProperty[implementationFunction_, fromType_, toProperty_Symbol] :=
  AppendTo[$rawProperties, {implementationFunction, type[fromType], property[toProperty]}];

(* This function is called after all declarations to combine implementations to a Graph to allow multi-step conversions
   and to define DownValues for all property symbols. *)

initializeRawProperties[] := Module[{newEdges},
  newEdges = DirectedEdge @@@ Rest /@ $rawProperties;
  $typesGraph = EdgeAdd[$typesGraph, newEdges];
  $propertyEvaluationFunctions = Association[Thread[newEdges -> (First /@ $rawProperties)]];

  defineDownValuesForProperty /@ Cases[VertexList[$typesGraph], property[name_] :> name, {1}];
];

(* declareCompositeProperty declares an implementation for a property that takes other properties as arguments. The
  relevant properties will be given to implementationFunction as functions. *)

(* Implementation has the form: implementationFunction[args___][propertyFunction$1_, propertyFunction$2_, ...] where
   propertyFunction$i should be called as propertyFunction$i[args], i.e., without an object argument. Correct object
   will be used automatically. *)

(* toProperty will be possible to use the same way as in declareRawProperty and will work as long as all requested
   properties are implemented with either approach. *)

declareCompositeProperty[implementationFunction_, fromProperties_List, toProperty_Symbol] := ModuleScope[
  Null; (* TODO: implement *)
];

(* This function is called after all declarations to combine implementations to a Graph to allow multi-step conversions
   and to define DownValues for all property symbols. *)

initializeCompositeProperties[] := (
  Null; (* TODO: implement *)
);

(* This function is called in init.m after all other files are loaded. *)

initializeTypeSystem[] := (
  initializeTypeSystemTranslations[];
  initializeRawProperties[];
  initializeCompositeProperties[];
);

(* defineDownValuesForProperty defines both the operator form and the normal form for a property symbol. The DownValues
   it defines first search for the best path to compute a property and then evaluate the corresponding property
   implementation/translation functions. *)

declareMessage[General::noPropertyPath, "Cannot compute the property `property` for type `type` in `expr`."];

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

(* Note that it's not possible to have another object as a first argument to the property, i.e.,
   property[auxiliaryObject][mainObjectArgument], because in that case it's impossible to distinguish for which object
   the property should be evaluated. *)

declareMessage[General::invalidPropertyOperatorArgument,
               "A single object argument is expected to the operator form `expr`."];

Attributes[defineDownValuesForProperty] = {HoldFirst};
defineDownValuesForProperty[publicProperty_] := (
  expr : publicProperty[args___][object___] := ModuleScope[
    result = Catch[propertyImplementation[publicProperty][args][object],
                   _ ? FailureQ,
                   message[publicProperty, #, <|"expr" -> HoldForm[expr], "head" -> publicProperty|>] &];
    result /; !FailureQ[result]
  ];

  expr : publicProperty[object_ ? objectQ, args___] := ModuleScope[
    result = Catch[propertyImplementation[publicProperty][args][object],
                   _ ? FailureQ,
                   message[publicProperty,
                           incrementArgumentCounts[#],
                           <|"expr" -> HoldForm[expr], "head" -> publicProperty|>] &];
    result /; !FailureQ[result]
  ];

  propertyImplementation[publicProperty][args___][object_] := ModuleScope[
    fromType = objectType[object];
    If[!VertexQ[$typesGraph, type[fromType]], throw[Failure["unknownType", <|"type" -> fromType|>]]];
    path = FindShortestPath[$typesGraph, type[fromType], property[publicProperty]];
    If[path === {},
      throw[Failure["noPropertyPath", <|"type" -> fromType, "property" -> publicProperty|>]];
    ];
    expectedTypeObject = typeConvert[path[[-2, 1]]][object];
    propertyFunction = $propertyEvaluationFunctions[DirectedEdge[path[[-2]], path[[-1]]]];
    propertyFunction[args][expectedTypeObject]
  ];

  propertyImplementation[publicProperty][args1___][args2___] := throw[Failure["invalidPropertyOperatorArgument", <||>]];
);
