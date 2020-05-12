#!/usr/bin/env wolframscript

Get["scripts/buildInit.wl"];
<< SetReplace`;

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
  "Exponential-match-count rule" -> WolframModel[{{1}, {1}, {1}} -> {{1}, {1}, {1}, {1}}, Automatic, 10]
|>;

$defaultMeasurementsCount = 5;

$measurementsCount = If[Length @ $ScriptCommandLine >= 4,
  ToExpression[$ScriptCommandLine[[4]]],
  $defaultMeasurementsCount];
If[!IntegerQ[$measurementsCount],
  Print["The third argument should be an integer measurements count."];
  Exit[1];
];

Attributes[meanAroundTiming] = {HoldAll};
meanAroundTiming[expr_] := MeanAround @ Table[First @ AbsoluteTiming[expr], $measurementsCount]

runTests[tests_] := Module[{result, kernel},
  Print["Testing ", GitSHA[$gitRepo, $gitRepo["HEAD"]]];
  Run["./build.wls"];
  Run["./install.wls"];
  CloseKernels[];
  {kernel} = LaunchKernels[1];
  result = ParallelEvaluate[
    << SetReplace`; meanAroundTiming @@@ KeyMap[ReleaseHold, ReleaseHold @ Map[Hold, tests, {3}]],
    kernel
  ];
  Print[""];
  result
]

speedupDelta[old_, new_] := (old - new) / old

$gitRepo = GitOpen[$repoRoot];
$currentSHA = GitSHA[$gitRepo, $gitRepo["HEAD"]];
$cleanQ = AllTrue[# === {} &] @ GitStatus[$gitRepo];

If[!$cleanQ,
  Print["Current git tree must be clean."];
  Exit[1];
];

$oldSHA = If[Length @ $ScriptCommandLine >= 2, $ScriptCommandLine[[2]], GitMergeBase[$gitRepo, "HEAD", "master"]];
$newSHA = If[Length @ $ScriptCommandLine >= 3, $ScriptCommandLine[[3]], $currentSHA];

GitCheckoutReference[$gitRepo, $oldSHA];
$oldResults = runTests[tests];
GitCheckoutReference[$gitRepo, $newSHA];
$newResults = runTests[tests];
GitCheckoutReference[$gitRepo, "@{-2}"];

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
    TemplateBox[{value_, error_}, "Around"] :> value <> " \[PlusMinus] " <> error <> " %"] <>
  $endColor
]

KeyValueMap[
  Print[
    #1,
    StringJoin[ConstantArray[" ", Max[40 - StringLength[#1], 1]]],
    differenceString[#2]] &,
  $speedup];
