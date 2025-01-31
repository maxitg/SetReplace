#!/usr/bin/env wolframscript

(* Disable messages about outdated cloud. *)
Off[CloudConnect::clver];

$redColor = "\033[0;31m";
$greenColor = "\033[0;32m";
$orangeColor = "\033[0;33m";
$yellowColor = "\033[1;33m";
$cyanColor = "\033[0;36m";
$endColor = "\033[0m";

$commandLineArgs = Rest[$ScriptCommandLine];
tryPopFlag[longFlag_String, shortFlag_String] := If[
  MemberQ[$commandLineArgs, longFlag | shortFlag],
  $commandLineArgs = DeleteCases[$commandLineArgs, longFlag | shortFlag];
  True
,
  False
];

If[tryPopFlag["--load-installed-paclet", "-lip"],
  $localSetReplaceEntryPoint = "SetReplace`";
,
  $localSetReplaceEntryPoint = FileNameJoin[{FileNameDrop[$InputFileName], "Kernel", "init.m"}];
];

Print["Loading SetReplace from ", $yellowColor, FindFile[$localSetReplaceEntryPoint], $endColor];
Check[
  Get[$localSetReplaceEntryPoint];
,
  Print[$redColor, "Messages occurred during loading of SetReplace, aborting tests.", $endColor];
  Exit[1];
];

(* make it possible to disable parallelization, which for very short tests saves quite a lot of time. *)
If[tryPopFlag["--disable-parallelization", "-dp"],
  $allowParallelization = False;
,
  $allowParallelization = True;

  (* This hack fixes a bug in Mathematica 12.1.1: if any messages or Prints occur in a subkernel, unformatted
     KernelObject is printed, obscuring any relevant information. It has been reported upstream. *)
  LaunchKernels; (* trigger autoload *)
  Unprotect[System`KernelObject];
  System`KernelObject /: StringForm["From `1`:", ko_KernelObject] := $orangeColor <> "From subkernel:" <> $endColor;

  (* Launch kernels preemptively to avoid "Launching kernels..." interrupting test log *)
  CloseKernels[];
  LaunchKernels[];
  With[{entryPoint = $localSetReplaceEntryPoint}, ParallelEvaluate[Get[entryPoint]]];
];

Needs["GeneralUtilities`"];

$successQ = True;

(* Get test files *)

$testFiles = If[Length @ $commandLineArgs >= 1,
  Replace[$commandLineArgs, {
    args : {"-e", ___} :> Select[
      FileNames[FileNameJoin[{AbsoluteFileName["."], "Tests", "*.wlt"}]],
      !MatchQ[FileBaseName @ #, Alternatives @@ Rest[args]] &
    ],
    args_List :> (FileNameJoin[{AbsoluteFileName["."], "Tests", # <> ".wlt"}] & /@ args)}
  ]
,
  FileNames[FileNameJoin[{AbsoluteFileName["."], "Tests", "*.wlt"}]]
];

If[!FileExistsQ[#],
  Print["Test file ", #, " does not exist."];
  Exit[1];
] & /@ $testFiles;

(* Read tests *)

printFileLineError[FileLine[file_, line_] -> error_] := Print[file <> ":" <> IntegerString[line] <> "\t" <> error];

importAsHeldExpression[file_] := Module[{exprs},
  exprs = Quiet @ (DeleteCases[#, Null] &) @ ToExpression[Import[file, "Text"], InputForm, Hold];
  If[!$allowParallelization, exprs = exprs /. HoldPattern[ParallelMap] -> Map];
  If[FailureQ[exprs],
    WriteString["stdout", $redColor <> "There were syntax errors in \"" <> file <> "\"" <> $endColor, ":"];
    (* this will cause a message that will print out the syntax error as Get would, but without evaluating any
       expressions. The Options override is because apparently someone changed Get in the kernel and forget to change
       FullGet, so it is missing an option! *)
    Unprotect[Language`FullGet];
    Options[Language`FullGet] = Options[Get];
    Language`FullGet[file, Null, HoldComplete];
    Exit[1];
  ];
  exprs
];

$testGroups = Join @@ (
  KeyMap[ReleaseHold, #] & /@
    ReleaseHold @ Map[Hold, importAsHeldExpression[#], {5}] & /@ $testFiles);

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
    testList, testResults, testReport, options, parallelQ, runInit, failedTests,
    requiresFrontEnd, probablyRequiresFrontEnd, bodyWrapper},
  (* Notify the user which test group we are running *)
  testGroupNameAndPadding = testGroupName <> StringJoin[ConstantArray[" ", Max[40 - StringLength[testGroupName], 1]]];
  WriteString["stdout", testGroupNameAndPadding];

  probablyRequiresFrontEnd = !FreeQ[testGroup,
    SetReplace`PackageScope`checkGraphics | SetReplace`PackageScope`graphicsQ | UsingFrontEnd];

  (* Read options *)
  options = Association[ReleaseHold[Lookup[testGroup, "options", <||>]]];
  parallelQ = $allowParallelization && Lookup[options, "Parallel", True];
  requiresFrontEnd = Lookup[options, "RequiresFrontEnd", probablyRequiresFrontEnd];

  resetTestStatus = "\r\033[" <> ToString[StringLength[testGroupNameAndPadding]] <> "C\033[K";
  writeTestStatus[status___] := WriteString["stdout", resetTestStatus, status];
  If[parallelQ, SetSharedFunction[writeTestStatus]];

  (* if a frontend is required, better to start it once than again and again in each test *)
  bodyWrapper = If[requiresFrontEnd, UsingFrontEnd, Identity];
  bodyWrapper[
    (* Run init, changing VerificationTest to test in all definitions *)
    runInit[] := ReleaseHold[testGroup["init"] /. VerificationTest -> constrainedTest];
    runCleanup[] := ReleaseHold[testGroup["cleanup"] /. VerificationTest -> constrainedTest];
    runInit[];
    If[parallelQ, ParallelEvaluate[runInit[]]];

    (* Make a list of tests, but don't run them yet *)
    writeTestStatus[$cyanColor, "[0/...]", $endColor];
    testList = Flatten[ReleaseHold[testGroup["tests"] /. VerificationTest -> constrainedTest]];
    testCount = Length[testList];
    writeTestStatus[$cyanColor, "[0/", testCount, "]", $endColor];

    (* Run tests in parallel *)
    testsCompleted = 0;
    If[parallelQ, SetSharedVariable[testsCompleted]];
    testsCompletedLock;

    localTestCounter = 0;
    lastProgressUpdate = 0.0;
    If[parallelQ, ParallelEvaluate, Evaluate][
      localTestCounter = 0;
      lastProgressUpdate = 0.0;
    ];

    If[parallelQ, SetSharedFunction[printProgress]];
    testResults = If[parallelQ, ParallelMap, Map][(
      testResult = (# /. test -> VerificationTest);
      localTestCounter++;
      If[AbsoluteTime[] - lastProgressUpdate > 1,
        CriticalSection[{testsCompletedLock}, testsCompleted += localTestCounter];
        localTestCounter = 0;
        lastProgressUpdate = AbsoluteTime[];
        writeTestStatus[$cyanColor, "[", testsCompleted, "/", testCount, "]", $endColor];
      ];
      testResult
    ) &, testList];

    runCleanup[];
  ];

  testReport = TestReport[testResults];

  (* Print the summery (green if ok, red if failed) *)
  writeTestStatus[
    If[testReport["AllTestsSucceeded"],
      $greenColor <> "[ok]" <> $endColor
    ,
      $successQ = False;
      StringJoin[
        $redColor <> "[",
        ToString @ testReport["TestsFailedCount"],
        "/",
        ToString @ Length @ testReport["TestResults"],
        " failed]" <> $endColor]
    ],
    "\n"];

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

$reportFile = UsingFrontEnd[
  $NotebookInlineStorageLimit = Infinity;
  Export[
    FileNameJoin[Join[FileNameSplit[CreateDirectory[]], {"testReport.nb"}]],
    Notebook @ Catenate @ Prepend[KeyValueMap[
      {Cell[Last @ FileNameSplit @ #1, "Section"],
        Cell[
          BoxData[RowBox[{"TestReport", "[", "\"" <> #1 <> "\"", "]"}]],
          "Input"],
        Cell[BoxData[ToBoxes[#2]], "Output"]} &,
      $results], {Cell["SetReplace Test Report", "Title"]}]
  ]
];

Print["Report file: ", $reportFile];

If[$MessageList =!= {}, $successQ = False];

If[Environment["STATUS_FILE"] === "1",
  Export["exit_status.txt", If[$successQ, 0, 1]];
];

If[$successQ,
  Print["Tests passed."];
  Exit[0]
,
  Print["Tests failed."];
  Exit[1]
]
