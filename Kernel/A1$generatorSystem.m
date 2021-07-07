Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["$SetReplaceSystems"]
PackageExport["$SetReplaceGenerators"]
PackageExport["SetReplaceSystemParameters"]

PackageScope["declareSystem"]
PackageScope["declareGenerator"]
PackageScope["autoList"]
PackageScope["initializeSystemGenerators"]

(* System declaration *)

$systemImplementations = <||>;       (* system -> implementationFunction *)
$systemInitPatterns = <||>;          (* system -> pattern *)
$systemParameters = <||>;            (* system -> <|parameter -> {default, pattern}, ...|> *)
$systemParameterDependencies = <||>; (* system -> logical expressions on parameter keys *)

(* Every system implementation needs to call this function in order to be usable through GenerateEventSet and other \
   generators. *)

(* The metadata about parameters has the form {default, pattern} and is used to automatically check the arguments. The
   pattern should not contain any internal symbols as it is displayed to users in error messages. Further, the logical
   expression in the last argument will check if all required parameters are specified. Some parameters may require
   others to be specified, e.g., Implies["MaxDestroyerEvents" || "MaxEvents", "EventOrder"] means that if
   "MaxDestroyerEvents" or "MaxEvents" is specified, "EventOrder" must be specified as well.
   The implementation function can expect all specified parameters present (substituted with defaults if missing) and
   all values satisfying the constraints (substituted with defaults if missing). *)

(* autoList is a special head useful for, e.g., "EventOrder". It takes a pattern as its argument. It allows a list with
   echo element matching that pattern. Alternatively, it can accept a single value matching the pattern, in which case a
   list around it will be created automatically and passed to the system generator. *)

(* For example,
   declareMultihistoryGenerator[
     MultisetSubstitutionSystem,
     generateMultisetSubstitutionSystem,
     <|"MaxGeneration" -> {Infinity, _ ? (# >= 0 &)},
       "MinEventInputs" -> {0, _ ? (# >= 0 &)},
       "MaxDestroyerEvents" -> {Infinity, _ ? (# >= 0 &)}
       "MaxEvents" -> {Infinity, _ ? (# >= 0 &)},
       "EventOrder" -> {{"Any"}, autoList["Any" | "Random" | "InputCount" | "SortedInputTokenIndices" | "RuleIndex"]}|>,
     Implies["MaxDestroyerEvents" || "MaxEvents", "EventOrder"]] *)

(* The implementation function is then called as
   generateMultisetSubstitutionSystem[MultisetSubstitutionSystem[rules], init, parameters] *)

declareSystem[systemType_,
              implementationFunction_,
              initPattern_,
              parameters_Association /; AllTrue[Values @ parameters, MatchQ[{_, _}]],
              dependencies_ ? SatisfiableQ] := (
  $systemImplementations[systemType] = implementationFunction;
  $systemInitPatterns[systemType] = initPattern;
  $systemParameters[systemType] = parameters;
  $systemParameterDependencies[systemType] = dependencies;
);

declareMessage[General::invalidGeneratorDeclaration,
               "Internal error. Multihistory generator is declared incorrectly with arguments `args`."];
declareMultihistoryGenerator[args___] :=
  message[SetReplace, Failure["invalidGeneratorDeclaration", <|"args" -> {args}|>]];

(* Generator declaration *)

$generatorParameters = <||>; (* generator -> <|parameter -> value, ...|> *)
$generatorProperties = <||>; (* generator -> property *)

(* Generators are functions that are called to produce EventSet objects. They take the form
   symbol[system, init, params]. They also define a fixed set of parameter values. These parameter values cannot be
   changed in params. Generators can also compute a property at the end of the evaluation. *)

(* For example,

   declareGenerator[EvaluateSingleHistory, <|"MaxDestroyerEvents" -> 1|>, FinalState]

   Note that the constraint in the last argument of declareMultihistoryGenerator still needs to be specified, which
   means "EventOrder" is now a required parameter. *)

declareGenerator[symbol_, parameterValues_, property_ : Identity] := (
  $generatorParameters[symbol] = parameterValues;
  $generatorProperties[symbol] = property;
);

(* Initialization *)

(* It would be best to only show autocompletions for specific-system keys, but it does not seem to be possible because
   dependent argument completions are only supported in WL if the main argument is a string. *)

SetUsage @ "
$SetReplaceSystems gives the list of all computational systems that can be used with GenerateEventSet and related \
functions.
";

SetUsage @ "
$SetReplaceGenerators gives the list of all generators that can be used to evaluate systems such as \
MultisetSubstitutionSystem.
";

initializeSystemGenerators[] := Module[{parameterKeys, maxParameterCount},
  $SetReplaceSystems = Sort @ Keys @ $systemImplementations;
  $SetReplaceGenerators = Sort @ Keys @ $generatorParameters;
  parameterKeys = Union @ Catenate[Keys /@ Values[$systemParameters]];
  maxParameterCount = Length @ parameterKeys;
  (* This has quadratic complexity in parameter count. But it does not seem to be possible to define the same set of
     completion strings for a range of arguments. *)
  With[{
      completionSpec = Join[{0}, Table[parameterKeys, maxParameterCount + 1]]},
    FE`Evaluate[FEPrivate`AddSpecialArgCompletion[# -> completionSpec]] & /@ ToString /@ $SetReplaceGenerators;
  ];
  Scan[(SyntaxInformation[#] = {"ArgumentsPattern" -> {system_, init_., parameters___}}) &, $SetReplaceGenerators];
  defineGeneratorImplementation /@ Keys @ $generatorParameters;
];

declareMessage[General::argNotInit, "The init `arg` in `expr` should match `pattern`."];
declareMessage[General::unknownSystem, "`system` is not a recognized SetReplace system."];

defineGeneratorImplementation[generator_] := (
  expr : generator[system_, init_, parameters___] /;
      MatchQ[init, Lookup[$systemInitPatterns, Head[system], _]] := ModuleScope[
    result = Catch[implementation[generator][system, init, parameters],
                   _ ? FailureQ,
                   message[generator, #, <|"expr" -> HoldForm[expr]|>] &];
    result /; !FailureQ[result]
  ];

  expr : generator[args1___][args2___] /; CheckArguments[expr, {1, 1}] := ModuleScope[
    result = Catch[implementationOperator[generator][args1][args2],
                   _ ? FailureQ,
                   message[generator, #, <|"expr" -> HoldForm[expr]|>] &];
    result /; !FailureQ[result]
  ];

  expr : generator[] /; CheckArguments[expr, {1, Infinity}] := $Failed;

  implementation[generator][system_, init_, parameters___] /;
      MatchQ[init, Lookup[$systemInitPatterns, Head[system], _]] := ModuleScope[
    implementation = $systemImplementations[Head[system]];
    If[MissingQ[implementation], throw[Failure["unknownSystem", <|"system" -> system|>]]];
    $generatorProperties[generator] @
      $systemImplementations[Head[system]][system, init, parseParameters[generator, Head[system]][parameters]]
  ];
  implementation[generator][___] := throw[Failure[None, <||>]];

  implementationOperator[generator][system_][init_] /; MatchQ[init, $systemInitPatterns[Head[system]]] :=
    implementation[generator][system, init, <||>];
  implementationOperator[generator][system_, parameters_, moreParameters___][init_] /;
      MatchQ[init, $systemInitPatterns[Head[system]]] && !MatchQ[parameters, $systemInitPatterns[Head[system]]] :=
    implementation[generator][system, init, parameters, moreParameters];
  implementationOperator[generator][system_, ___][arg_] :=
    throw[Failure["argNotInit", <|"arg" -> arg, "pattern" -> $systemInitPatterns[Head[system]]|>]];
);

parseParameters[generator_, system_][parameters___] :=
  addMissingParameters[generator, system] @
    checkParameters[generator, system] @ Association[Join @@ collectParameters /@ {parameters}];

collectParameters[key_ -> value_] := <|key -> value|>;
collectParameters[key_ :> value_] := <|key -> value|>;
collectParameters[list_List] := Association[Join @@ collectParameters /@ list];
collectParameters[association_Association] := association;
declareMessage[General::invalidGeneratorParameterSpec, "Parameter specification `spec` in `expr` should be a Rule."];
collectParameters[spec_] := throw[Failure["invalidGeneratorParameterSpec", <|"spec" -> spec|>]];

checkParameters[generator_, system_][parameters_] := (
  KeyValueMap[checkParameter[generator, system][##] &, parameters];
  checkParameterCompleteness[generator, system][Keys[parameters]];
  parameters
);
checkParameter[generator_, system_][key_, value_] := (
  checkParameterKeyIsRecognized[system][key];
  checkParameterKeyIsNotForbidden[generator][key];
  checkParameterValueMatchesPattern[system][key, value];
);

declareMessage[General::unknownParameter, "`system` in `expr` does not support `parameter` parameter."];
checkParameterKeyIsRecognized[system_][key_] /; !KeyExistsQ[$systemParameters[system], key] :=
  throw[Failure["unknownParameter", <|"system" -> system, "parameter" -> key|>]];

declareMessage[General::forbiddenParameter, "`parameter` in `expr` cannot be used with `generator`."];
checkParameterKeyIsNotForbidden[generator_][key_] /; KeyExistsQ[$generatorParameters[generator], key] :=
  throw[Failure["forbiddenParameter", <|"generator" -> generator, "parameter" -> key|>]];

declareMessage[
  General::invalidParameter, "`parameter` value `value` in `expr` should match `pattern`."];
checkParameterValueMatchesPattern[system_][key_, value_] /; !MatchQ[value, $systemParameters[system][key][[2]]] :=
  throw[Failure[
    "invalidParameter", <|"parameter" -> key, "value" -> value, "pattern" -> $systemParameters[system][key][[2]]|>]];

simplifyParameterCondition[generator_, system_, specifiedKeys_] :=
  FullSimplify[
    $systemParameterDependencies[system] /.
      Alternatives @@ Join[specifiedKeys, Keys @ $generatorParameters[generator]] -> True];
compatibleParametersQ[generator_, system_, specifiedKeys_] :=
  FullSimplify[
    $systemParameterDependencies[system] /.
      Alternatives @@ Join[specifiedKeys, Keys @ $generatorParameters[generator]] -> True /.
        Alternatives @@ Keys[$systemParameters[system]] -> False]
compatibleParametersQ[___] := False

declareMessage[General::incompatibleParameters,
               "Parameters in `expr` are incompatible. Specified parameters should satisfy `condition`."];
checkParameterCompleteness[generator_, system_][keys_] /;
    simplifyParameterCondition[generator, system, keys] === False :=
  throw[Failure["incompatibleParameters", <|"condition" -> $systemParameterDependencies[system]|>]];

declareMessage[General::missingParameters, "`missingParameters` should be explicitly specified in `expr`."];
checkParameterCompleteness[generator_, system_][keys_] /; !compatibleParametersQ[generator, system, keys] :=
  throw[Failure["missingParameters", <|"missingParameters" -> simplifyParameterCondition[generator, system, keys]|>]];

addMissingParameters[generator_, system_][parameters_] :=
  Join[$systemParameters[system][[All, 1]], parameters, $generatorParameters[generator]];

(* Introspection functions *)

SetUsage @ "SetReplaceSystemParameters[system$] yields the list of parameters supported by system$.";

SyntaxInformation[SetReplaceSystemParameters] = {"ArgumentsPattern" -> {system_}};

expr : SetReplaceSystemParameters[args___] /; CheckArguments[expr, 1] := ModuleScope[
  result = Catch[setReplaceSystemParameters[args],
                 _ ? FailureQ,
                 message[SetReplaceSystemParameters, #, <|"expr" -> HoldForm[expr]|>] &];
  result /; !FailureQ[result]
];

setReplaceSystemParameters[system_Symbol | system_Symbol[___]] /; KeyExistsQ[$systemParameters, system] :=
  Keys @ $systemParameters[system];

setReplaceSystemParameters[system_] := throw[Failure["unknownSystem", <|"system" -> system|>]];
