<|
  "generatorSystem" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`declareSystem = SetReplace`PackageScope`declareSystem;
      Global`declareSystemGenerator = SetReplace`PackageScope`declareSystemGenerator;
      Global`declareSystemParameter = SetReplace`PackageScope`declareSystemParameter;
      Global`initializeSystemGenerators = SetReplace`PackageScope`initializeSystemGenerators;

      declareSystemParameter[maxSomething, Infinity, _?(GreaterEqualThan[0]), "is a max param."];
      declareSystemParameter[minSomething, 0, _?(GreaterEqualThan[0]), "is a min param."];
      declareSystemParameter[pickNumber, None, None | 0 | 1 | 2, "is a pick param."];

      declareSystem[echoSystem, List, _Integer, {maxSomething, pickNumber}, True];
      declareSystem[needSomethingForPicking,
                    List,
                    _Integer,
                    {minSomething, maxSomething, pickNumber},
                    Implies[pickNumber, minSomething || maxSomething]];
      declareSystem[minXorMax, List, _Integer, {minSomething, maxSomething}, Xor[minSomething, maxSomething]];
      declareSystem[listInit, List, _List, {minSomething, maxSomething, pickNumber}, True];
      declareSystem[realSystem, List, _, {MaxDestroyerEvents, MaxEvents, MaxGeneration}, True];

      declareSystemGenerator[identityGenerator, internalIdentityGenerator, <||>, Identity, "does nothing."];
      declareSystemGenerator[pick2Generator, internalPick2Generator, <|pickNumber -> 2|>, picked, "picks 2."];

      Unprotect[$SetReplaceSystems, $SetReplaceGenerators, GenerateSingleHistory, GenerateMultihistory];
      initializeSystemGenerators[];
      Protect[$SetReplaceSystems, $SetReplaceGenerators, GenerateSingleHistory, GenerateMultihistory];
    ),
    "tests" -> {
      (* Internal errors *)
      VerificationTest[declareSystem[invalidSystem, List, _, {minSomething}, minSomething && !minSomething],
                       _,
                       {SetReplace::unsatisfiableParameterDependencies},
                       SameTest -> MatchQ],
      VerificationTest[declareSystem[invalidSystem, List, _, {minSomething}],
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
      testUnevaluated[identityGenerator[], {identityGenerator::argm}],

      (* One arg *)
      testUnevaluated[identityGenerator[0], {}],
      testUnevaluated[identityGenerator[echoSystem[0]], {}],

      (* Two args *)
      testUnevaluated[identityGenerator[0, 0], {identityGenerator::unknownSystem}],
      VerificationTest[
        identityGenerator[echoSystem[0], 0], {echoSystem[0], 0, <|maxSomething -> Infinity, pickNumber -> None|>}],
      testUnevaluated[identityGenerator[echoSystem[0], "test"], {}], (* parameters are not yet parsed at this stage *)

      (* Parameters *)
      testUnevaluated[identityGenerator[echoSystem[0], 0, abc], {identityGenerator::invalidGeneratorParameterSpec}],
      testUnevaluated[identityGenerator[echoSystem[0], 0, {abc}], {identityGenerator::invalidGeneratorParameterSpec}],
      testUnevaluated[identityGenerator[echoSystem[0], 0, abc -> 4], {identityGenerator::unknownParameter}],
      testUnevaluated[identityGenerator[echoSystem[0], maxSomething -> 4], {}], (* no init, treated as an operator *)
      VerificationTest[identityGenerator[echoSystem[0], 0, maxSomething -> 4],
                       {echoSystem[0], 0, <|maxSomething -> 4, pickNumber -> None|>}],
      testUnevaluated[identityGenerator[echoSystem[0], 0, maxSomething -> -1], {identityGenerator::invalidParameter}],
      testUnevaluated[identityGenerator[echoSystem[0], 0, minSomething -> 4], {identityGenerator::unknownParameter}],

      VerificationTest[
          identityGenerator[echoSystem[0], 0, ##], {echoSystem[0], 0, <|maxSomething -> 4, pickNumber -> 0|>}] & @@@ {
        {maxSomething -> 4, pickNumber -> 0},
        {{maxSomething -> 4}, pickNumber -> 0},
        {maxSomething -> 4, {pickNumber -> 0}},
        {<|maxSomething -> 4|>, {{pickNumber -> 0}}}
      },

      VerificationTest[identityGenerator[echoSystem[0], 0, pickNumber -> 0, pickNumber -> 1],
                       {echoSystem[0], 0, <|maxSomething -> Infinity, pickNumber -> 1|>}],
      testUnevaluated[identityGenerator[echoSystem[0], 0, pickNumber -> 0, pickNumber -> 1, 3],
                      {identityGenerator::invalidGeneratorParameterSpec}],

      VerificationTest[
        pick2Generator[echoSystem[0], 0], picked[{echoSystem[0], 0, <|maxSomething -> Infinity, pickNumber -> 2|>}]],
      testUnevaluated[pick2Generator[echoSystem[0], 0, pickNumber -> 1], {pick2Generator::forbiddenParameter}],
      VerificationTest[pick2Generator[echoSystem[0], 0, maxSomething -> 2],
                       picked[{echoSystem[0], 0, <|maxSomething -> 2, pickNumber -> 2|>}]],

      VerificationTest[
        identityGenerator[needSomethingForPicking[0], 0],
        {needSomethingForPicking[0], 0, <|minSomething -> 0, maxSomething -> Infinity, pickNumber -> None|>}],
      testUnevaluated[
        identityGenerator[needSomethingForPicking[0], 0, pickNumber -> 2], {identityGenerator::missingParameters}],
      VerificationTest[
        identityGenerator[needSomethingForPicking[0], 0, pickNumber -> 2, minSomething -> 2],
        {needSomethingForPicking[0], 0, <|minSomething -> 2, maxSomething -> Infinity, pickNumber -> 2|>}],
      VerificationTest[
        identityGenerator[needSomethingForPicking[0], 0, pickNumber -> 2, maxSomething -> 2],
        {needSomethingForPicking[0], 0, <|minSomething -> 0, maxSomething -> 2, pickNumber -> 2|>}],

      testUnevaluated[pick2Generator[needSomethingForPicking[0], 0], {pick2Generator::missingParameters}],
      VerificationTest[
        pick2Generator[needSomethingForPicking[0], 0, minSomething -> 2],
        picked[{needSomethingForPicking[0], 0, <|minSomething -> 2, maxSomething -> Infinity, pickNumber -> 2|>}]],

      testUnevaluated[pick2Generator[minXorMax[0], 0], {pick2Generator::incompatibleSystem}],
      testUnevaluated[pick2Generator[minXorMax[0], 0, pickNumber -> 2], {pick2Generator::incompatibleSystem}],
      testUnevaluated[identityGenerator[minXorMax[0], 0], {identityGenerator::missingParameters}],
      VerificationTest[identityGenerator[minXorMax[0], 0, minSomething -> 2],
                       {minXorMax[0], 0, <|minSomething -> 2, maxSomething -> Infinity|>}],
      testUnevaluated[identityGenerator[minXorMax[0], 0, minSomething -> 2, maxSomething -> 3],
                      {identityGenerator::incompatibleParameters}],

      (* Operator form *)
      testUnevaluated[identityGenerator[echoSystem[0]] @ "test", {identityGenerator::argNotInit}],
      testUnevaluated[identityGenerator[echoSystem[0], maxSomething -> 2] @ "test", {identityGenerator::argNotInit}],
      VerificationTest[
        identityGenerator[echoSystem[0]] @ 0, {echoSystem[0], 0, <|maxSomething -> Infinity, pickNumber -> None|>}],
      testUnevaluated[identityGenerator[echoSystem[0]][], {identityGenerator::argx}],
      testUnevaluated[identityGenerator[echoSystem[0]][0, 1], {identityGenerator::argx}],
      VerificationTest[identityGenerator[echoSystem[0], maxSomething -> 2] @ 0,
                       {echoSystem[0], 0, <|maxSomething -> 2, pickNumber -> None|>}],
      VerificationTest[identityGenerator[echoSystem[0], {maxSomething -> 2}] @ 0,
                       {echoSystem[0], 0, <|maxSomething -> 2, pickNumber -> None|>}],
      VerificationTest[identityGenerator[echoSystem[0], <|maxSomething -> 2|>] @ 0,
                       {echoSystem[0], 0, <|maxSomething -> 2, pickNumber -> None|>}],
      VerificationTest[identityGenerator[echoSystem[0], maxSomething -> 2, pickNumber -> 2] @ 0,
                       {echoSystem[0], 0, <|maxSomething -> 2, pickNumber -> 2|>}],
      VerificationTest[
        identityGenerator[listInit[0], {maxSomething -> 2}] @ 0,
        {listInit[0], {maxSomething -> 2}, <|minSomething -> 0, maxSomething -> Infinity, pickNumber -> None|>}[0]],
      VerificationTest[
        identityGenerator[listInit[0], {maxSomething -> 2}, minSomething -> 1] @ {0},
        {listInit[0], {maxSomething -> 2}, <|minSomething -> 1, maxSomething -> Infinity, pickNumber -> None|>}[{0}]],
      VerificationTest[identityGenerator[listInit[0], minSomething -> 1, {maxSomething -> 2}] @ {0},
                       {listInit[0], {0}, <|minSomething -> 1, maxSomething -> 2, pickNumber -> None|>}],

      (* Existing generators *)
      VerificationTest[
        GenerateMultihistory[realSystem[0], 0],
        {realSystem[0], 0, <|MaxDestroyerEvents -> Infinity, MaxEvents -> Infinity, MaxGeneration -> Infinity|>}],
      VerificationTest[
        GenerateSingleHistory[realSystem[0], 0],
        {realSystem[0], 0, <|MaxDestroyerEvents -> 1, MaxEvents -> Infinity, MaxGeneration -> Infinity|>}],

      (* Introspection *)
      VerificationTest[
        SubsetQ[$SetReplaceSystems, {echoSystem, needSomethingForPicking, minXorMax, listInit, realSystem}]],
      VerificationTest[SubsetQ[$SetReplaceGenerators, {identityGenerator, pick2Generator}]],
      VerificationTest[SetReplaceSystemParameters[listInit], {minSomething, maxSomething, pickNumber}]
    }
  |>
|>
