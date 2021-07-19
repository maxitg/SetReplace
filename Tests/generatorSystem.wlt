<|
  "generatorSystem" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`declareSystem = SetReplace`PackageScope`declareSystem;
      Global`declareSystemGenerator = SetReplace`PackageScope`declareSystemGenerator;
      Global`declareSystemParameter = SetReplace`PackageScope`declareSystemParameter;
      Global`initializeSystemGenerators = SetReplace`PackageScope`initializeSystemGenerators;

      declareSystemParameter[maxEventSize, Infinity, _ ? (GreaterEqualThan[0]), "is a max parameter for a test value."];
      declareSystemParameter[minEventSize, 0, _ ? (GreaterEqualThan[0]), "is a min parameter for a test value."];
      declareSystemParameter[eventType, None, None | 0 | 1 | 2, "is a choice parameter between None, 0, 1, and 2."];

      declareSystem[genericSystem, List, _Integer, {maxEventSize, eventType}, True];
      declareSystem[systemWithParameterDependencies,
                    List,
                    _Integer,
                    {minEventSize, maxEventSize, eventType},
                    Implies[eventType, minEventSize || maxEventSize]];
      declareSystem[minXorMaxSystem, List, _Integer, {minEventSize, maxEventSize}, Xor[minEventSize, maxEventSize]];
      declareSystem[listStateSystem, List, _List, {minEventSize, maxEventSize, eventType}, True];
      declareSystem[realParameterSystem, List, _, {MaxDestroyerEvents, MaxEvents, MaxGeneration}, True];

      declareSystemGenerator[genericGenerator, internalGenericGenerator, <||>, Identity, "does nothing."];
      declareSystemGenerator[typeTwoGenerator, internalTypeTwoGenerator, <|eventType -> 2|>, property, "picks 2."];

      Unprotect[$SetReplaceSystems, $SetReplaceGenerators, GenerateSingleHistory, GenerateMultihistory];
      initializeSystemGenerators[];
      Protect[$SetReplaceSystems, $SetReplaceGenerators, GenerateSingleHistory, GenerateMultihistory];
    ),
    "tests" -> {
      (* Declaration errors *)
      VerificationTest[declareSystem[invalidSystem, List, _, {minEventSize}, minEventSize && !minEventSize],
                       _,
                       {SetReplace::unsatisfiableParameterDependencies},
                       SameTest -> MatchQ],
      VerificationTest[declareSystem[invalidSystem, List, _, {minEventSize}],
                       _,
                       {SetReplace::invalidSystemDeclaration},
                       SameTest -> MatchQ],
      VerificationTest[declareSystemGenerator[invalidGenerator, internalInvalidGenerator, <||>, Identity],
                       _,
                       {SetReplace::invalidSystemGeneratorDeclaration},
                       SameTest -> MatchQ],
      VerificationTest[declareSystemParameter[invalidParameter, 0, _],
                       _,
                       {SetReplace::invalidSystemParameterDeclaration},
                       SameTest -> MatchQ],

      (* Zero args *)
      testUnevaluated[genericGenerator[], {}], (* nothing is evaluated until the init is given *)

      (* One arg *)
      testUnevaluated[genericGenerator[0], {}],
      testUnevaluated[genericGenerator[genericSystem[]], {}],

      (* Two args *)
      testUnevaluated[genericGenerator[0, 0][0], {genericGenerator::unknownSystem}],
      testUnevaluated[genericGenerator[genericSystem, 0][0], {genericGenerator::noRules}],
      testUnevaluated[genericGenerator[genericSystem[], "test"][0], {genericGenerator::invalidGeneratorParameterSpec}],
      VerificationTest[
        genericGenerator[genericSystem[]][0], {genericSystem[], 0, <|maxEventSize -> Infinity, eventType -> None|>}],

      (* Operator args *)
      testUnevaluated[genericGenerator[genericSystem[]][##], {genericGenerator::argx}] & @@@ {{0, 1}, {}},

      (* Parameters spec *)
      testUnevaluated[genericGenerator[genericSystem[], abc][0], {genericGenerator::invalidGeneratorParameterSpec}],
      testUnevaluated[genericGenerator[genericSystem[], {abc}][0], {genericGenerator::invalidGeneratorParameterSpec}],
      testUnevaluated[genericGenerator[genericSystem[], abc -> 4][0], {genericGenerator::unknownParameter}],
      testUnevaluated[genericGenerator[genericSystem[], maxEventSize -> 4], {}],
      VerificationTest[genericGenerator[genericSystem[], maxEventSize -> 4][0],
                       {genericSystem[], 0, <|maxEventSize -> 4, eventType -> None|>}],
      testUnevaluated[genericGenerator[genericSystem[], maxEventSize -> -1][0], {genericGenerator::invalidParameter}],
      testUnevaluated[genericGenerator[genericSystem[], minEventSize -> 4][0], {genericGenerator::unknownParameter}],

      VerificationTest[
          genericGenerator[genericSystem[], ##][0], {genericSystem[], 0, <|maxEventSize -> 4, eventType -> 0|>}] & @@@ {
        {maxEventSize -> 4, eventType -> 0},
        {{maxEventSize -> 4}, eventType -> 0},
        {maxEventSize -> 4, {eventType -> 0}},
        {<|maxEventSize -> 4|>, {{eventType -> 0}}}
      },

      VerificationTest[genericGenerator[genericSystem[], eventType -> 0, eventType -> 1][0],
                       {genericSystem[], 0, <|maxEventSize -> Infinity, eventType -> 1|>}],
      testUnevaluated[genericGenerator[genericSystem[], eventType -> 0, eventType -> 1, 3][0],
                      {genericGenerator::invalidGeneratorParameterSpec}],

      (* Generator with predefined parameters *)
      VerificationTest[typeTwoGenerator[genericSystem[]][0],
                       property[{genericSystem[], 0, <|maxEventSize -> Infinity, eventType -> 2|>}]],
      testUnevaluated[typeTwoGenerator[genericSystem[], eventType -> 1][0], {typeTwoGenerator::forbiddenParameter}],
      VerificationTest[typeTwoGenerator[genericSystem[], maxEventSize -> 2][0],
                       property[{genericSystem[], 0, <|maxEventSize -> 2, eventType -> 2|>}]],

      (* Parameter dependencies *)
      VerificationTest[
        genericGenerator[systemWithParameterDependencies[]][0],
        {systemWithParameterDependencies[], 0, <|minEventSize -> 0, maxEventSize -> Infinity, eventType -> None|>}],
      testUnevaluated[
        genericGenerator[systemWithParameterDependencies[], eventType -> 2][0], {genericGenerator::missingParameters}],
      VerificationTest[
        genericGenerator[systemWithParameterDependencies[], eventType -> 2, minEventSize -> 2][0],
        {systemWithParameterDependencies[], 0, <|minEventSize -> 2, maxEventSize -> Infinity, eventType -> 2|>}],
      VerificationTest[
        genericGenerator[systemWithParameterDependencies[], eventType -> 2, maxEventSize -> 2][0],
        {systemWithParameterDependencies[], 0, <|minEventSize -> 0, maxEventSize -> 2, eventType -> 2|>}],

      testUnevaluated[typeTwoGenerator[systemWithParameterDependencies[]][0], {typeTwoGenerator::missingParameters}],
      VerificationTest[
        typeTwoGenerator[systemWithParameterDependencies[], minEventSize -> 2][0],
        property[
          {systemWithParameterDependencies[], 0, <|minEventSize -> 2, maxEventSize -> Infinity, eventType -> 2|>}]],

      testUnevaluated[typeTwoGenerator[minXorMaxSystem[]][0], {typeTwoGenerator::incompatibleSystem}],
      testUnevaluated[typeTwoGenerator[minXorMaxSystem[], eventType -> 2][0], {typeTwoGenerator::incompatibleSystem}],
      testUnevaluated[genericGenerator[minXorMaxSystem[]][0], {genericGenerator::missingParameters}],
      VerificationTest[genericGenerator[minXorMaxSystem[], minEventSize -> 2][0],
                       {minXorMaxSystem[], 0, <|minEventSize -> 2, maxEventSize -> Infinity|>}],
      testUnevaluated[genericGenerator[minXorMaxSystem[], minEventSize -> 2, maxEventSize -> 3][0],
                      {genericGenerator::incompatibleParameters}],

      (* Existing generators *)
      VerificationTest[
        GenerateMultihistory[realParameterSystem[]][0],
        {realParameterSystem[],
         0,
         <|MaxDestroyerEvents -> Infinity, MaxEvents -> Infinity, MaxGeneration -> Infinity|>}],
      VerificationTest[
        GenerateSingleHistory[realParameterSystem[]][0],
        {realParameterSystem[], 0, <|MaxDestroyerEvents -> 1, MaxEvents -> Infinity, MaxGeneration -> Infinity|>}],

      (* Introspection *)
      VerificationTest[
        SubsetQ[
          $SetReplaceSystems,
          {genericSystem, systemWithParameterDependencies, minXorMaxSystem, listStateSystem, realParameterSystem}]],
      VerificationTest[SubsetQ[$SetReplaceGenerators, {genericGenerator, typeTwoGenerator}]],
      VerificationTest[SetReplaceSystemParameters[listStateSystem], {minEventSize, maxEventSize, eventType}]
    }
  |>
|>
