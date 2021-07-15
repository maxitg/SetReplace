Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["$SetReplaceSystems"]
PackageExport["$SetReplaceGenerators"]
PackageExport["SetReplaceSystemParameters"]

PackageScope["declareSystemParameter"]
PackageScope["declareSystem"]
PackageScope["declareSystemGenerator"]
PackageScope["initializeSystemGenerators"]

(* Parameter declaration *)

$parameterDefaults = <||>;
$parameterPatterns = <||>;

(* Both systems and generators use parameters. Systems declare parameters they implement. Generators set fixed values
   for a subset of parameters. To declare a new parameter, one needs to specify a default value (which usually disables
   whatever the parameter is doing) and a pattern the parameter value should match. *)

(* declareSystemParameter[MaxGeneration,
                          Infinity,
                          _ ? (GreaterEqualThan[0]),
                          "is a parameter specifying the maximum generations of tokens that will be created."] *)

declareSystemParameter[name_, defaultValue_, pattern_, usage_] := (
  $parameterDefaults[name] = defaultValue;
  $parameterPatterns[name] = pattern;
  SyntaxInformation[name] = {"ArgumentsPattern" -> {}};
  SetUsage @ Evaluate[ToString[name] <> " " <> usage];
);

declareMessage[General::invalidSystemParameterDeclaration,
               "Internal error. Parameter is declared incorrectly with arguments `args`."];
declareSystemParameter[args___] :=
  message[SetReplace, Failure["invalidSystemParameterDeclaration", <|"args" -> {args}|>]];

(* System declaration *)

$systemImplementations = <||>;       (* system -> implementationFunction *)
$systemInitPatterns = <||>;          (* system -> pattern *)
$systemParameters = <||>;            (* system -> {parameter, ...} *)
$systemParameterDependencies = <||>; (* system -> logical expression on parameter keys *)

(* Every system implementation needs to call this function in order to be usable through GenerateMultihistory and other
   generators. *)

(* The third argument is the pattern that the init should satisfy. *)

(* Parameters in the fourth argument should be declared with declareSystemParameter. Their values are guaranteed to
   match the pattern from that declaration. Further, the logical expression in the last argument will check if all
   required parameters are specified. Some parameters may require others to be specified, e.g.,
   Implies[MaxDestroyerEvents || MaxEvents, EventOrder] means that if MaxDestroyerEvents or MaxEvents is specified,
   EventOrder must be specified as well. The implementation function can expect all specified parameters present
   (substituted with defaults if missing) and all values will satisfy the constraints (substituted with defaults if
   missing). *)

(* declareSystem[MultisetSubstitutionSystem,
                 generateMultisetSubstitutionSystem,
                 _List,
                 {MaxGeneration, MinEventInputs, MaxDestroyerEvents, MaxEvents, EventOrder},
                 Implies[MaxDestroyerEvents || MaxEvents, EventOrder]] *)

(* The implementation function is then called as
   generateMultisetSubstitutionSystem[MultisetSubstitutionSystem[rules], init, <|MaxGeneration -> value, ...|>] *)

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
               "Internal error. Parameter constraints `constraints` for `system` are not satisfiable."];
declareSystem[systemType_, _, _, _List, dependencies_] :=
  message[SetReplace,
          Failure["unsatisfiableParameterDependencies", <|"constraints" -> dependencies, "system" -> systemType|>]];

declareMessage[General::invalidSystemDeclaration,
               "Internal error. System is declared incorrectly with arguments `args`."];
declareSystem[args___] :=
  message[SetReplace, Failure["invalidSystemDeclaration", <|"args" -> {args}|>]];

(* Generator declaration *)

$generatorPackageScopeSymbols = <||>; (* generator (public symbol) -> package-scope symbol *)
$generatorParameters = <||>;          (* generator -> <|parameter -> value, ...|> *)
$generatorProperties = <||>;          (* generator -> property *)

(* Generators are functions that are called to produce Multihistory objects. They take the form
   symbol[system, init, params]. They also define a fixed set of parameter values. These parameter values cannot be
   changed in params. Generators can also compute a property at the end of the evaluation. *)

(* declareSystemGenerator[EvaluateSingleHistory,
                          evaluateSingleHistory,
                          <|MaxDestroyerEvents -> 1|>,
                          FinalState,
                          "yields a single-history object."]

   Note that the constraint in the last argument of declareSystemGenerator still needs to be specified, which means
   EventOrder is now a required parameter. *)

(* evaluateSingleHistory is a PackageScope symbol that will throw exceptions instead of returning unevaluated.
   It cannot be used in operator form. *)

$systemUsage = "* A list of all supported systems can be obtained with $SetReplaceSystems.";
$initUsage = "* init$ is the initial state, the format of which depends on the system$.";
$parametersUsage = "* parameters$ is either a Sequence, a List or an Association of key-value rules. A list of " <>
                   "parameter keys can be obtained with SetReplaceSystemParameters[system$].";

declareSystemGenerator[publicSymbol_, packageScopeSymbol_, parameterValues_, property_, usage_] := (
  $generatorPackageScopeSymbols[publicSymbol] = packageScopeSymbol;
  $generatorParameters[publicSymbol] = parameterValues;
  $generatorProperties[publicSymbol] = property;
  SyntaxInformation[publicSymbol] = {"ArgumentsPattern" -> {system_, init_., parameters___}};
  SetUsage @ Evaluate @ StringRiffle[
    {ToString[publicSymbol] <> "[system$, init$, parameters$] " <> usage, $systemUsage, $initUsage, $parametersUsage},
    "\n"];
);

declareMessage[General::invalidSystemGeneratorDeclaration,
               "Internal error. Generator is declared incorrectly with arguments `args`."];
declareSystemGenerator[args___] :=
  message[SetReplace, Failure["invalidSystemGeneratorDeclaration", <|"args" -> {args}|>]];

(* Initialization *)

SetUsage @ "
$SetReplaceSystems gives the list of all computational systems that can be used with GenerateMultihistory and related \
functions.
";

SetUsage @ "
$SetReplaceGenerators gives the list of all generators that can be used to evaluate systems such as \
MultisetSubstitutionSystem.
";

declareMessage[
  General::unknownSystemParameters, "Parameters `parameters` are implemented by `system` but not declared."];
declareMessage[General::unknownGeneratorParameters, "Parameters `parameters` are set by `generator` but not declared."];

initializeSystemGenerators[] := (
  $SetReplaceSystems = Sort @ Keys @ $systemImplementations;
  $SetReplaceGenerators = Sort @ Keys @ $generatorParameters;
  With[{missingParameters = Complement[$systemParameters[#], Keys[$parameterDefaults]]},
    If[missingParameters =!= {},
      message[SetReplace, Failure["unknownSystemParameters", <|"parameters" -> missingParameters, "system" -> #|>]];
    ];
  ] & /@ $SetReplaceSystems;
  With[{missingParameters = Complement[Keys @ $generatorParameters[#], Keys[$parameterDefaults]]},
    If[missingParameters =!= {},
      message[
        SetReplace, Failure["unknownGeneratorParameters", <|"parameters" -> missingParameters, "generator" -> #|>]];
    ];
  ] & /@ $SetReplaceGenerators;
  defineGeneratorImplementation /@ Keys @ $generatorParameters;
);

declareMessage[General::argNotInit, "The init `arg` in `expr` should match `pattern`."];
declareMessage[General::unknownSystem, "`system` is not a recognized SetReplace system."];
declareMessage[General::noRules, "Rules need to be specified as `system`[\[Ellipsis]] in `expr`."];

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
      MatchQ[init, Lookup[$systemInitPatterns, Head[system], _]] := (
    If[MissingQ[$systemImplementations[Head[system]]],
      If[MissingQ[$systemImplementations[system]],
        throw[Failure["unknownSystem", <|"system" -> system|>]]
      ,
        throw[Failure["noRules", <|"system" -> system|>]]
      ];
    ];
    checkSystemGeneratorCompatibility[Head[system], generator];
    $generatorProperties[generator] @
      $systemImplementations[Head[system]][system, init, parseParameters[generator, Head[system]][parameters]]
  );
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

declareMessage[General::incompatibleParameters,
               "Parameters in `expr` are incompatible. Specified parameters should satisfy `condition`."];
checkParameterCompleteness[generator_, system_][keys_] /;
    simplifyParameterCondition[generator, system, keys] === False :=
  throw[Failure["incompatibleParameters", <|"condition" -> $systemParameterDependencies[system]|>]];

simplifyParameterCondition[generator_, system_, specifiedKeys_] :=
  FullSimplify[
    $systemParameterDependencies[system] /.
      Alternatives @@ Join[specifiedKeys, Keys @ $generatorParameters[generator]] -> True];

declareMessage[General::missingParameters, "`missingParameters` should be explicitly specified in `expr`."];
checkParameterCompleteness[generator_, system_][keys_] /; !compatibleParametersQ[generator, system, keys] :=
  throw[Failure["missingParameters", <|"missingParameters" -> simplifyParameterCondition[generator, system, keys]|>]];

compatibleParametersQ[generator_, system_, specifiedKeys_] :=
  FullSimplify[
    $systemParameterDependencies[system] /.
      Alternatives @@ Join[specifiedKeys, Keys @ $generatorParameters[generator]] -> True /.
        Alternatives @@ $systemParameters[system] -> False];
compatibleParametersQ[___] := False;

addMissingParameters[generator_, system_][parameters_] :=
  Join[KeyTake[$parameterDefaults, $systemParameters[system]], parameters, $generatorParameters[generator]];

(* Introspection functions *)

SetUsage @ "SetReplaceSystemParameters[system$] yields the list of parameters supported by the system$.";

SyntaxInformation[SetReplaceSystemParameters] = {"ArgumentsPattern" -> {system_}};

expr : SetReplaceSystemParameters[args___] /; CheckArguments[expr, 1] := ModuleScope[
  result = Catch[setReplaceSystemParameters[args],
                 _ ? FailureQ,
                 message[SetReplaceSystemParameters, #, <|"expr" -> HoldForm[expr]|>] &];
  result /; !FailureQ[result]
];

setReplaceSystemParameters[system_Symbol[___] | system_] :=
  Lookup[$systemParameters, system, throw[Failure["unknownSystem", <|"system" -> system|>]]];
