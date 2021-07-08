Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["$SetReplaceSystems"]
PackageExport["$SetReplaceGenerators"]
PackageExport["SetReplaceSystemParameters"]

PackageScope["declareSystem"]
PackageScope["declareSystemGenerator"]
PackageScope["declareSystemParameter"]
PackageScope["autoList"]
PackageScope["initializeSystemGenerators"]

(* System declaration *)

$systemImplementations = <||>;       (* system -> implementationFunction *)
$systemInitPatterns = <||>;          (* system -> pattern *)
$systemParameters = <||>;            (* system -> {parameter, ...} *)
$systemParameterDependencies = <||>; (* system -> logical expressions on parameter keys *)

(* Every system implementation needs to call this function in order to be usable through GenerateMultihistory and other
   generators. *)

(* The third argument is the pattern that the init should satisfy. *)

(* Parameters in the fourth argument should be declared with declareSystemParameter. Their values are guaranteed to
   match the pattern from the declaration. Further, the logical expression in the last argument will check if all
   required parameters are specified. Some parameters may require others to be specified, e.g.,
   Implies["MaxDestroyerEvents" || "MaxEvents", "EventOrder"] means that if "MaxDestroyerEvents" or "MaxEvents" is
   specified, "EventOrder" must be specified as well. The implementation function can expect all specified parameters
   present (substituted with defaults if missing) and all values satisfying the constraints (substituted with defaults
   if missing). *)

(* For example,
   declareSystem[MultisetSubstitutionSystem,
                 generateMultisetSubstitutionSystem,
                 _List,
                 {"MaxGeneration", "MinEventInputs", "MaxDestroyerEvents", "MaxEvents", "EventOrder"},
                 Implies["MaxDestroyerEvents" || "MaxEvents", "EventOrder"]] *)

(* The implementation function is then called as
   generateMultisetSubstitutionSystem[MultisetSubstitutionSystem[rules], init, parameters] *)

declareSystem[systemType_,
              implementationFunction_,
              initPattern_,
              parameters_List,
              dependencies_ ? SatisfiableQ] := (
  $systemImplementations[systemType] = implementationFunction;
  $systemInitPatterns[systemType] = initPattern;
  $systemParameters[systemType] = parameters;
  $systemParameterDependencies[systemType] = dependencies;
);

declareMessage[General::unsatisfiableParameterDependencies,
               "Internal error. Parameter constraints `constraints` for `system` are not satisfyable."];
declareMultihistoryGenerator[systemType_, _, _, _List, dependencies_] :=
  message[SetReplace,
          Failure["unsatisfiableParameterDependencies", <|"constraints" -> dependencies, "system" -> systemType|>]];

declareMessage[General::invalidGeneratorDeclaration,
               "Internal error. Multihistory generator is declared incorrectly with arguments `args`."];
declareMultihistoryGenerator[args___] :=
  message[SetReplace, Failure["invalidGeneratorDeclaration", <|"args" -> {args}|>]];

(* Generator declaration *)

$generatorPackageScopeSymbols = <||>; (* generator (public symbol) -> package-scope symbol *)
$generatorParameters = <||>;          (* generator -> <|parameter -> value, ...|> *)
$generatorProperties = <||>;          (* generator -> property *)

(* Generators are functions that are called to produce EventSet objects. They take the form
   symbol[system, init, params]. They also define a fixed set of parameter values. These parameter values cannot be
   changed in params. Generators can also compute a property at the end of the evaluation. *)

(* For example,

   declareSystemGenerator[EvaluateSingleHistory, evaluateSingleHistory, <|"MaxDestroyerEvents" -> 1|>, FinalState]

   Note that the constraint in the last argument of declareSystemGenerator still needs to be specified, which means
   "EventOrder" is now a required parameter. *)

(* evaluateSingleHistory is a PackageScope symbol that will throw exceptions instead of returning unevaluated.
   It cannot be used in operator form. *)

declareSystemGenerator[publicSymbol_, packageScopeSymbol_, parameterValues_, property_ : Identity] := (
  $generatorPackageScopeSymbols[publicSymbol] = packageScopeSymbol;
  $generatorParameters[publicSymbol] = parameterValues;
  $generatorProperties[publicSymbol] = property;
);

(* Parameter declaration *)

$parameterDefaults = <||>;
$parameterPatterns = <||>;

(* Parameters are like protocols. Systems can declare that they implement them. Some generators require some parameters
   to be supported and define values for them. To declare a new parameter, one needs to specify a default value (which
   usually disables whatever the parameter is doing) and a pattern the parameter value should match. *)

(* declareSystemParameter["MaxGeneration", Infinity, _ ? (GreaterEqualThan[0])] *)

declareSystemParameter[name_, defaultValue_, pattern_] := (
  $parameterDefaults[name] = defaultValue;
  $parameterPatterns[name] = pattern;
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

declareMessage[
  General::unknownSystemParameters, "Parameters `parameters` are implemented by `system` but is not declared."];
declareMessage[
  General::unknownGeneratorParameters, "Parameters `parameters` are set by `generator` but is not declared."];

initializeSystemGenerators[] := Module[{parameterKeys, maxParameterCount},
  $SetReplaceSystems = Sort @ Keys @ $systemImplementations;
  $SetReplaceGenerators = Sort @ Keys @ $generatorParameters;
  parameterKeys = Keys[$parameterDefaults];
  With[{missingParameters = Complement[$systemParameters[#], parameterKeys]},
    If[missingParameters =!= {},
      message[SetReplace, Failure["unknownSystemParameters", <|"parameters" -> missingParameters, "system" -> #|>]];
    ];
  ] & /@ $SetReplaceSystems;
  With[{missingParameters = Complement[Keys @ $generatorParameters[#], parameterKeys]},
    If[missingParameters =!= {},
      message[
        SetReplace, Failure["unknownGeneratorParameters", <|"parameters" -> missingParameters, "generator" -> #|>]];
    ];
  ] & /@ $SetReplaceGenerators;
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

defineGeneratorImplementation[generator_] := With[{packageScopeGenerator = $generatorPackageScopeSymbols[generator]},
  expr : generator[system_, init_, parameters___] /;
      MatchQ[init, Lookup[$systemInitPatterns, Head[system], _]] := ModuleScope[
    result = Catch[packageScopeGenerator[system, init, parameters],
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

  packageScopeGenerator[system_, init_, parameters___] /;
      MatchQ[init, Lookup[$systemInitPatterns, Head[system], _]] := ModuleScope[
    implementation = $systemImplementations[Head[system]];
    If[MissingQ[implementation], throw[Failure["unknownSystem", <|"system" -> system|>]]];
    checkSystemGeneratorCompatibility[Head[system], generator];
    $generatorProperties[generator] @
      $systemImplementations[Head[system]][system, init, parseParameters[generator, Head[system]][parameters]]
  ];
  packageScopeGenerator[___] := throw[Failure[None, <||>]];

  implementationOperator[generator][system_][init_] /; MatchQ[init, $systemInitPatterns[Head[system]]] :=
    packageScopeGenerator[system, init, <||>];
  implementationOperator[generator][system_, parameters_, moreParameters___][init_] /;
      MatchQ[init, $systemInitPatterns[Head[system]]] && !MatchQ[parameters, $systemInitPatterns[Head[system]]] :=
    packageScopeGenerator[system, init, parameters, moreParameters];
  implementationOperator[generator][system_, ___][arg_] :=
    throw[Failure["argNotInit", <|"arg" -> arg, "pattern" -> $systemInitPatterns[Head[system]]|>]];
];

declareMessage[
  General::incompatibleSystem, "`generator` requires `parameters` parameters, which `system` does not implement."];
checkSystemGeneratorCompatibility[system_, generator_] := With[{
    missingParameters = Complement[Keys @ $generatorParameters[generator], $systemParameters[system]]},
  If[missingParameters =!= {},
    throw[Failure[
      "incompatibleSystem", <|"generator" -> generator, "parameters" -> missingParameters, "system" -> system|>]];
  ];
];

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
  checkParameterValueMatchesPattern[key, value];
);

declareMessage[General::unknownParameter, "`system` in `expr` does not support `parameter` parameter."];
checkParameterKeyIsRecognized[system_][key_] /; !MemberQ[$systemParameters[system], key] :=
  throw[Failure["unknownParameter", <|"system" -> system, "parameter" -> key|>]];

declareMessage[General::forbiddenParameter, "`parameter` in `expr` cannot be used with `generator`."];
checkParameterKeyIsNotForbidden[generator_][key_] /; KeyExistsQ[$generatorParameters[generator], key] :=
  throw[Failure["forbiddenParameter", <|"generator" -> generator, "parameter" -> key|>]];

declareMessage[
  General::invalidParameter, "`parameter` value `value` in `expr` should match `pattern`."];
checkParameterValueMatchesPattern[key_, value_] /; !MatchQ[value, $parameterPatterns[key]] :=
  throw[Failure[
    "invalidParameter", <|"parameter" -> key, "value" -> value, "pattern" -> $parameterPatterns[key]|>]];

simplifyParameterCondition[generator_, system_, specifiedKeys_] :=
  FullSimplify[
    $systemParameterDependencies[system] /.
      Alternatives @@ Join[specifiedKeys, Keys @ $generatorParameters[generator]] -> True];
compatibleParametersQ[generator_, system_, specifiedKeys_] :=
  FullSimplify[
    $systemParameterDependencies[system] /.
      Alternatives @@ Join[specifiedKeys, Keys @ $generatorParameters[generator]] -> True /.
        Alternatives @@ $systemParameters[system] -> False]
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
  Join[KeyTake[$parameterDefaults, $systemParameters[system]], parameters, $generatorParameters[generator]];

(* Introspection functions *)

SetUsage @ "SetReplaceSystemParameters[system$] yields the list of parameters supported by system$.";

SyntaxInformation[SetReplaceSystemParameters] = {"ArgumentsPattern" -> {system_}};

expr : SetReplaceSystemParameters[args___] /; CheckArguments[expr, 1] := ModuleScope[
  result = Catch[setReplaceSystemParameters[args],
                 _ ? FailureQ,
                 message[SetReplaceSystemParameters, #, <|"expr" -> HoldForm[expr]|>] &];
  result /; !FailureQ[result]
];

setReplaceSystemParameters[system_Symbol[___] | system_] :=
  Lookup[$systemParameters, system, throw[Failure["unknownSystem", <|"system" -> system|>]]];
