<|
  "GenerateMultihistory" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`declareMultihistoryGenerator = SetReplace`PackageScope`declareMultihistoryGenerator;
      Global`initializeGenerators = SetReplace`PackageScope`initializeGenerators;

      SetReplace`PackageScope`declareMultihistoryGenerator[
        testSystemImplementation,
        TestSystem,
        <|"MaxGeneration" -> {Infinity, "NonNegativeIntegerOrInfinity"},
          "MinEventInputs" -> {0, "NonNegativeIntegerOrInfinity"},
          "EventPattern" -> {_, None}|>,
        {"InputCount", "RuleOrdering"},
        <|"MaxEvents" -> {Infinity, "NonNegativeIntegerOrInfinity"},
          "MinCausalDensityDimension" -> {2., None},
          "TokenEventGraphTest" -> {True &, None}|>];

      $originalSetReplaceSystem = $SetReplaceSystems;
      Unprotect[$SetReplaceSystems];
      initializeGenerators[];
      Protect[$SetReplaceSystems];
    ),
    "tests" -> {
      (* It's useful to catch unprocessed declarations early *)
      VerificationTest[declareMultihistoryGenerator[a, b, {}, {}, <||>],
                       _,
                       {SetReplace::invalidGeneratorDeclaration},
                       SameTest -> MatchQ],

      (* GenerateMultihistory *)

      $defaultEventSelection = <|"MaxGeneration" -> Infinity, "MinEventInputs" -> 0, "EventPattern" -> _|>;
      $defaultStoppingConditions =
        <|"MaxEvents" -> Infinity, "MinCausalDensityDimension" -> 2., "TokenEventGraphTest" -> (True &)|>;

      testUnevaluated[GenerateMultihistory[][], GenerateMultihistory::argrx],
      testUnevaluated[GenerateMultihistory[][0], GenerateMultihistory::argrx],
      testUnevaluated[GenerateMultihistory[0][], GenerateMultihistory::argr],
      testUnevaluated[GenerateMultihistory[0, 1, 2, 3, 4, 5][], GenerateMultihistory::argrx],
      testUnevaluated[GenerateMultihistory[0, 1, 2, 3, 4][], GenerateMultihistory::argx],
      testUnevaluated[GenerateMultihistory[0, 1, 2, 3, 4][1, 2], GenerateMultihistory::argx],

      testUnevaluated[GenerateMultihistory[#, 1, 2, 3, 4][0], GenerateMultihistory::unknownSystem] & /@
        {UnknownSystem[], TestSystem, TestSystem[][]},

      testUnevaluated[GenerateMultihistory[TestSystem[], 1, 2, 3, 4][0], GenerateMultihistory::invalidEventSelection],
      testUnevaluated[GenerateMultihistory[TestSystem[], <|"Unknown" -> 0|>, 2, 3, 4][0],
                      GenerateMultihistory::invalidEventSelection],
      testUnevaluated[GenerateMultihistory[TestSystem[], <|"MaxGeneration" -> -1|>, 2, 3, 4][0],
                      GenerateMultihistory::notNonNegativeIntegerOrInfinityParameter],
      VerificationTest[
        GenerateMultihistory[TestSystem[], #, None, {}, <||>][0],
        testSystemImplementation[TestSystem[],
                                 <|"MaxGeneration" -> 2, "MinEventInputs" -> 0, "EventPattern" -> _|>,
                                 None,
                                 {},
                                 $defaultStoppingConditions,
                                 0]] & /@ {<|"MaxGeneration" -> 2|>, {"MaxGeneration" -> 2}, "MaxGeneration" -> 2},

      testUnevaluated[
        GenerateMultihistory[TestSystem[], <||>, 2, 3, 4][0], GenerateMultihistory::invalidTokenDeduplication],
      VerificationTest[
          GenerateMultihistory[TestSystem[], <||>, #, {}, <||>][0],
          testSystemImplementation[TestSystem[], $defaultEventSelection, #, {}, $defaultStoppingConditions, 0]] & /@
        {None, All},

      testUnevaluated[
        GenerateMultihistory[TestSystem[], <||>, None, 3, 4][0], GenerateMultihistory::invalidEventOrdering],
      testUnevaluated[
        GenerateMultihistory[TestSystem[], <||>, None, {"Unknown"}, 4][0], GenerateMultihistory::invalidEventOrdering],
      VerificationTest[
        GenerateMultihistory[TestSystem[], <||>, None, {"RuleOrdering", "InputCount"}, <||>][0],
        testSystemImplementation[
          TestSystem[], $defaultEventSelection, None, {"RuleOrdering", "InputCount"}, $defaultStoppingConditions, 0]],

      testUnevaluated[
        GenerateMultihistory[TestSystem[], <||>, None, {}, 4][0], GenerateMultihistory::invalidStoppingCondition],
      testUnevaluated[GenerateMultihistory[TestSystem[], <||>, None, {}, <|"Unknown" -> 0|>][0],
                      GenerateMultihistory::invalidStoppingCondition],
      testUnevaluated[GenerateMultihistory[TestSystem[], <||>, None, {}, <|"MaxEvents" -> -1|>][0],
                      GenerateMultihistory::notNonNegativeIntegerOrInfinityParameter],
      VerificationTest[
        GenerateMultihistory[TestSystem[], <||>, None, {}, #][0],
        testSystemImplementation[
          TestSystem[],
          $defaultEventSelection,
          None,
          {},
          <|"MaxEvents" -> 2, "MinCausalDensityDimension" -> 2., "TokenEventGraphTest" -> (True &)|>,
          0]] & /@ {<|"MaxEvents" -> 2|>, {"MaxEvents" -> 2}, "MaxEvents" -> 2},

      (* Introspection *)
      VerificationTest[$SetReplaceSystems, Sort @ Join[$originalSetReplaceSystem, {TestSystem}]],

      Function[{introspectionFunction}, {
        testUnevaluated[introspectionFunction[], introspectionFunction::argx],
        testUnevaluated[introspectionFunction[0, 1], introspectionFunction::argx],
        testUnevaluated[introspectionFunction[#], introspectionFunction::unknownSystem] & /@
          {0, UnknownSystem, TestSystem[][]}
      }] /@ {EventSelectionParameters, EventOrderingFunctions, StoppingConditionParameters},

      VerificationTest[EventSelectionParameters[#], {"MaxGeneration", "MinEventInputs", "EventPattern"}] & /@
        {TestSystem, TestSystem[]},
      VerificationTest[EventOrderingFunctions[#], {"InputCount", "RuleOrdering"}] & /@ {TestSystem, TestSystem[]},
      VerificationTest[
          StoppingConditionParameters[#], {"MaxEvents", "MinCausalDensityDimension", "TokenEventGraphTest"}] & /@
        {TestSystem, TestSystem[]}
    }
  |>
|>
