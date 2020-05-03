#!/usr/bin/env wolframscript

(* Disable messages about outdated cloud. *)
Off[CloudConnect::clver];

<< SetReplace`;
(* Launch kernels preemptively to avoid "Launching kernels..." interrupting test log *)
CloseKernels[];
LaunchKernels[];
ParallelEvaluate[<< SetReplace`];

$successQ = True;

(* Get test files *)

$testFiles = If[Length @ $ScriptCommandLine >= 2,
  FileNameJoin[{".", "Tests", # <> ".wlt"}] & /@ $ScriptCommandLine[[2 ;; ]],
  FileNames[FileNameJoin[{".", "Tests", "*.wlt"}]]
];

If[!FileExistsQ[#],
  Print["Test file ", #, " does not exist."];
  Exit[1];] & /@ $testFiles;

(* Read tests *)

$testGroups = Join @@ (
  KeyMap[ReleaseHold, #] & /@
    ReleaseHold @ Map[Hold, ToExpression[Import[#, "Text"], InputForm, Hold], {5}] & /@ $testFiles);

Attributes[test] = Attributes[constrainedTest] = {HoldAll};

$singleTestTimeConstraint = 300;
$singleTestMemoryConstraint = 1*^9;
constrainedTest[args___] := With[{
    timeConstraintOpt =
      If[FreeQ[Hold[{args}], TimeConstraint], {TimeConstraint -> $singleTestTimeConstraint}, {}],
    memoryConstraintOpt =
      If[FreeQ[Hold[{args}], MemoryConstraint], {MemoryConstraint -> $singleTestMemoryConstraint}, {}]},
  test[args, ##] & @@ Join[timeConstraintOpt, memoryConstraintOpt]
];

removeHoldFormFromInputString[input_String] := StringReplace[
  input,
  StartOfString ~~ "HoldForm[" ~~ expr__ ~~ "]" ~~ EndOfString :> expr
];

$results = Association[KeyValueMap[Function[{testGroupName, testGroup}, Module[{
    testList, testResults, testReport, options, parallelQ, runInit, failedTests},
  (* Notify the user which test group we are running *)
  WriteString["stdout",
    testGroupName,
    StringJoin[ConstantArray[" ", Max[40 - StringLength[testGroupName], 1]]]];

  (* Read options *)
  options = Association[ReleaseHold[Lookup[testGroup, "options", <||>]]];
  parallelQ = Lookup[options, "Parallel", True];

  (* Run init, changing VerificationTest to test in all definitions *)
  runInit[] := ReleaseHold[testGroup["init"] /. VerificationTest -> constrainedTest];
  runInit[];
  If[parallelQ, ParallelEvaluate[runInit[]]];

  (* Make a list of tests, but don't run them yet *)
  testList = Flatten[ReleaseHold[testGroup["tests"] /. VerificationTest -> constrainedTest]];

  (* Run tests in parallel *)
  testResults = If[parallelQ, ParallelMap, Map][# /. test -> VerificationTest &, testList];
  testReport = TestReport[testResults];

  $redColor = "\033[0;31m";
  $greenColor = "\033[0;32m";
  $orangeColor = "\033[0;33m";
  $yellowColor = "\033[1;33m";
  $endColor = "\033[0m";

  (* Print the summery (green if ok, red if failed) *)
  WriteString["stdout", If[testReport["AllTestsSucceeded"],
    $greenColor <> "[ok]" <> $endColor,
    $successQ = False;
    StringJoin[
      $redColor <> "[",
      ToString @ testReport["TestsFailedCount"],
      "/",
      ToString @ Length @ testReport["TestResults"],
      " failed]" <> $endColor]], "\n"];

  (* If tests failed, print why *)
  failedTests = Join @@ testReport["TestsFailed"];
  Switch[#["Outcome"],
    "Failure",
      WriteString["stdout",
        $redColor <> "Input" <> $endColor <> "\n",
        "> ", removeHoldFormFromInputString[ToString[#["Input"], InputForm]], "\n\n",
        $redColor <> "evaluated to" <> $endColor <> "\n",
        "> ", ToString[#["ActualOutput"], OutputForm], "\n\n",
        $redColor <> "instead of expected " <> $endColor <> "\n",
        "> ", ToString[#["ExpectedOutput"], OutputForm], "\n\n\n"],
    "MessagesFailure",
      WriteString["stdout",
        $orangeColor <> "Input" <> $endColor <> "\n",
        "> ", removeHoldFormFromInputString[ToString[#["Input"], InputForm]], "\n\n",
        $orangeColor <> "generated messages" <> $endColor <> "\n",
        "> ", ToString[#["ActualMessages"], OutputForm], "\n\n",
        $orangeColor <> "instead of expected" <> $endColor <> "\n",
        "> ", ToString[#["ExpectedMessages"], OutputForm], "\n\n\n"],
    "Error",
      WriteString["stdout",
        $yellowColor <> "Error while evaluating the test with input" <> $endColor <> "\n",
        "> ", removeHoldFormFromInputString[ToString[#["Input"], InputForm]], "\n\n\n"]
  ] & /@ failedTests[[1 ;; UpTo[3]]];

  (* If too many tests have failed, print how many remain *)
  If[Length[failedTests] > 3,
    WriteString["stdout",
      "Omitting remaining ",
      Length[failedTests] - 3,
      " " <> testGroupName,
      " test failures.\n\n"]
  ];

  (* Return the report, we'll need it later *)
  testGroupName -> testReport
]], $testGroups]];

(* Create a notebook with results *)

$reportFile = UsingFrontEnd @ Export[
  FileNameJoin[Join[FileNameSplit[CreateDirectory[]], {"testReport.nb"}]],
  Notebook @ Catenate @ Prepend[KeyValueMap[
    {Cell[Last @ FileNameSplit @ #1, "Section"],
      Cell[
        BoxData[RowBox[{"TestReport", "[", "\"" <> #1 <> "\"", "]"}]],
        "Input"],
      Cell[BoxData[ToBoxes[#2]], "Output"]} &,
    $results], {Cell["SetReplace Test Report", "Title"]}]];


Print["Report file: ", $reportFile];

If[$MessageList =!= {}, $successQ = False];

If[Environment["STATUS_FILE"] === "1",
  Export["exit_status.txt", If[$successQ, 0, 1]];
];

If[$successQ,
  Print["Tests passed."];
  Exit[0],
  Print["Tests failed."];
  Exit[1]
]
