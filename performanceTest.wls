#!/usr/bin/env wolframscript

Check[
  Needs["GeneralUtilities`"];
  Needs["GitLink`"];

  $setReplaceRoot = FileNameDrop[$InputFileName, -1];
  Get[FileNameJoin[{$setReplaceRoot, "DevUtils", "init.m"}]];
  Get[FileNameJoin[{$setReplaceRoot, "Kernel", "init.m"}]];
,
  Print["Could not get one of the dependencies. Exiting."];
  Exit[1];
];

Check[
  tests = Hold @ <|
    "Single-input rule" -> WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, Automatic, 10],
    "Medium rule" -> WolframModel[
      {{1, 2, 3}, {4, 3, 5}, {3, 6}} -> {{6, 7, 8}, {6, 9, 10}, {11, 8, 10}, {5, 2, 9}, {9, 9}, {1, 9}, {7, 5}, {8, 5}},
      Automatic, 13],
    "Sequential rule" -> WolframModel[{{1, 2, 2}, {3, 2, 4}} -> {{5, 4, 4}, {4, 3, 5}, {3, 5, 1}}, Automatic, 10000],
    "Large rule" -> WolframModel[
      {{1, 2}, {2, 1}, {1, 3}, {2, 3}, {3, 1}, {3, 2}} ->
        {{1, 2}, {2, 1}, {1, 3}, {2, 3}, {3, 1}, {3, 2}, {1, 4}, {2, 4}, {3, 4}, {4, 1}, {4, 2}, {4, 3}},
      Automatic, 4],
    "Exponential-match-count rule" -> WolframModel[{{1}, {1}, {1}} -> {{1}, {1}, {1}, {1}}, Automatic, 10],
    "CA emulator" -> WolframModel[
      {{{18, 18, 3}, {3, 19, 3}, {3, 3, 3, 3, 3}} ->
          {{1, 1, 1, 12}, {1, 1, 14, 1}, {1, 10, 10}, {1, 1, 5}, {5, 5, 5, 5, 5}, {5, 4, 5}, {1, 19, 1}, {1}, {4, 12, 12},
            {4}, {17, 14, 14}, {17}, {18, 18, 17}},
        {{18, 16, 18}, {16, 16, 20}, {16, 16}} ->
          {{1, 1, 14, 1}, {1, 1, 1, 12}, {1, 10, 10}, {1, 6, 1}, {6, 6}, {6, 6, 17}, {1, 1, 20}, {1}, {17, 14, 14}, {17},
            {4, 12, 12}, {4}, {18, 4, 18}},
        {{1, 1, 2}, {2, 11, 11}, {1, 15, 1}, {15, 13, 13}, {1, 1, 1, 12}, {1, 1, 14, 1}, {1, 10, 10}, {1, 1, 1, 1, 1, 1},
            {2, 2, 2, 2, 2, 2}, {15, 15, 15, 15, 15, 15}} ->
          {{10, 10, 11}, {10, 13, 10}, {10, 7, 7}, {10, 10, 10, 8}, {10, 10, 9, 10}, {10}, {12}, {14}, {12, 8, 8},
            {14, 9, 9}},
        {{1, 1, 2}, {2, 11, 11}, {1, 15, 1}, {15, 13, 13}, {1, 1, 1, 12}, {1, 1, 14, 1}, {1, 10, 10}, {1, 1, 1, 1, 1, 1},
            {2, 2, 2, 2, 2, 2}, {15}} ->
          {{10, 10, 11}, {10, 13, 10}, {10, 7, 7}, {10, 10, 10, 8}, {10, 10, 9, 10}, {10, 10, 10, 10, 10, 10},
            {12, 12, 12, 12, 12, 12}, {14, 14, 14, 14, 14, 14}, {12, 8, 8}, {14, 9, 9}},
        {{1, 1, 2}, {2, 11, 11}, {1, 15, 1}, {15, 13, 13}, {1, 1, 1, 12}, {1, 1, 14, 1}, {1, 10, 10}, {1},
            {2, 2, 2, 2, 2, 2}, {15, 15, 15, 15, 15, 15}} ->
          {{10, 10, 11}, {10, 13, 10}, {10, 7, 7}, {10, 10, 10, 8}, {10, 10, 9, 10}, {10, 10, 10, 10, 10, 10},
            {12, 12, 12, 12, 12, 12}, {14, 14, 14, 14, 14, 14}, {12, 8, 8}, {14, 9, 9}},
        {{1, 1, 2}, {2, 11, 11}, {1, 15, 1}, {15, 13, 13}, {1, 1, 1, 12}, {1, 1, 14, 1}, {1, 10, 10}, {1},
            {2, 2, 2, 2, 2, 2}, {15}} ->
          {{10, 10, 11}, {10, 13, 10}, {10, 7, 7}, {10, 10, 10, 8}, {10, 10, 9, 10}, {10}, {12}, {14}, {12, 8, 8},
            {14, 9, 9}},
        {{1, 1, 2}, {2, 11, 11}, {1, 15, 1}, {15, 13, 13}, {1, 1, 1, 12}, {1, 1, 14, 1}, {1, 10, 10}, {1, 1, 1, 1, 1, 1},
            {2}, {15, 15, 15, 15, 15, 15}} ->
          {{10, 10, 11}, {10, 13, 10}, {10, 7, 7}, {10, 10, 10, 8}, {10, 10, 9, 10}, {10, 10, 10, 10, 10, 10},
            {12, 12, 12, 12, 12, 12}, {14, 14, 14, 14, 14, 14}, {12, 8, 8}, {14, 9, 9}},
        {{1, 1, 2}, {2, 11, 11}, {1, 15, 1}, {15, 13, 13}, {1, 1, 1, 12}, {1, 1, 14, 1}, {1, 10, 10}, {1, 1, 1, 1, 1, 1},
            {2}, {15}} ->
          {{10, 10, 11}, {10, 13, 10}, {10, 7, 7}, {10, 10, 10, 8}, {10, 10, 9, 10}, {10, 10, 10, 10, 10, 10},
            {12, 12, 12, 12, 12, 12}, {14, 14, 14, 14, 14, 14}, {12, 8, 8}, {14, 9, 9}},
        {{1, 1, 2}, {2, 11, 11}, {1, 15, 1}, {15, 13, 13}, {1, 1, 1, 12}, {1, 1, 14, 1}, {1, 10, 10}, {1}, {2},
            {15, 15, 15, 15, 15, 15}} ->
          {{10, 10, 11}, {10, 13, 10}, {10, 7, 7}, {10, 10, 10, 8}, {10, 10, 9, 10}, {10, 10, 10, 10, 10, 10},
            {12, 12, 12, 12, 12, 12}, {14, 14, 14, 14, 14, 14}, {12, 8, 8}, {14, 9, 9}},
        {{1, 1, 2}, {2, 11, 11}, {1, 15, 1}, {15, 13, 13}, {1, 1, 1, 12}, {1, 1, 14, 1}, {1, 10, 10}, {1}, {2}, {15}} ->
          {{10, 10, 11}, {10, 13, 10}, {10, 7, 7}, {10, 10, 10, 8}, {10, 10, 9, 10}, {10}, {12}, {14}, {12, 8, 8},
            {14, 9, 9}}},
      {{3, 3, 3, 6}, {3, 3, 7, 3}, {3, 5, 5}, {3, 3, 1}, {3, 2, 3}, {3, 3, 3, 3, 3, 3}, {4, 6, 6}, {4, 4, 4, 4, 4, 4},
        {8, 7, 7}, {8, 8, 8, 8, 8, 8}, {1, 4, 1}, {1, 1, 1, 1, 1}, {2, 2, 8}, {2, 2}},
      64]
  |>;

  $defaultMeasurementsCount = 5;

  $measurementsCount = If[Length @ $ScriptCommandLine >= 4,
    ToExpression[$ScriptCommandLine[[4]]],
    $defaultMeasurementsCount];
  If[!IntegerQ[$measurementsCount] || $measurementsCount < 2,
    Print["The third argument should be an integer measurements count of at least 2."];
    Exit[1];
  ];

  Attributes[meanAroundTiming] = {HoldAll};
  meanAroundTiming[expr_] := MeanAround @ Table[First @ AbsoluteTiming[expr], $measurementsCount];

  runTests[repo_, sha_, tests_] := ModuleScope[
    Print["Testing ", sha];
    GitCheckoutReference[repo, sha];
    CloseKernels[];
    {kernel} = LaunchKernels[1];
    result = ParallelEvaluate[
      Get[FileNameJoin[{$setReplaceRoot, "Kernel", "init.m"}]];
      Check[
        meanAroundTiming @@@ KeyMap[ReleaseHold, ReleaseHold @ Map[Hold, tests, {3}]]
      ,
        $Failed
      ]
    ,
      kernel
    ];
    Print[""];
    result
  ];

  speedupDelta[old_, new_] := (old - new) / old;

  $gitRepo = GitOpen[$SetReplaceRoot];
  $currentSHA = GitSHA[$gitRepo, $gitRepo["HEAD"]];
  $cleanQ = AllTrue[# === {} &] @ GitStatus[$gitRepo];

  If[!$cleanQ,
    Print["Current git tree must be clean."];
    Exit[1];
  ];

  $oldSHA = If[Length @ $ScriptCommandLine >= 2, $ScriptCommandLine[[2]], "master"];
  $newSHA = If[Length @ $ScriptCommandLine >= 3, $ScriptCommandLine[[3]], $currentSHA];

  $symbolicRef = RunProcess[{"git", "symbolic-ref", "--short", "HEAD"}];
  $originalRef = If[$symbolicRef["ExitCode"] === 0, StringExtract[$symbolicRef["StandardOutput"], 1], $currentSHA];

  {$oldResults, $newResults} = runTests[$gitRepo, #, tests] & /@ {$oldSHA, $newSHA};
  RunProcess[{"git", "checkout", "-q", $originalRef}];

  (* We need to return to the original branch before exiting. *)
  If[$oldResults === $Failed || $newResults === $Failed,
    Print["Messages occured while running the tests. Exiting."];
    Exit[1];
  ];

  $speedup = speedupDelta[$oldResults, $newResults];

  $redColor = "\033[0;31m";
  $greenColor = "\033[0;32m";
  $whiteColor = "\033[0;37m";
  $endColor = "\033[0m";

  differenceString[meanAround_] := With[{
      magnitude = QuantityMagnitude[meanAround, "Percent"]},
    If[5 * magnitude[[2]] < Abs[magnitude[[1]]], If[magnitude[[1]] > 0, $greenColor, $redColor], $whiteColor] <>
    FirstCase[
      MakeBoxes[magnitude, StandardForm],
      TemplateBox[{value_, error_}, "Around", ___] :> value <> " \[PlusMinus] " <> error <> " %"] <>
    $endColor
  ];

  KeyValueMap[
    Print[
      #1,
      StringJoin[ConstantArray[" ", Max[40 - StringLength[#1], 1]]],
      differenceString[#2]] &,
    $speedup];
,
  Print["Message occurred while running the script. Exiting."];
  Exit[1];
]
