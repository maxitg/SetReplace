#!/usr/bin/env wolframscript
(* ::Package:: *)

<< SetReplace`


(* ::Text:: *)
(*Launch kernels preemptively to avoid "Launching kernels..." interrupting test log*)


CloseKernels[];
LaunchKernels[];
ParallelEvaluate[<< SetReplace`]


(* ::Text:: *)
(*Find all test files*)


testFiles = If[Length @ $ScriptCommandLine >= 2,
	FileNameJoin[{".", "SetReplace", # <> ".wlt"}] & /@ $ScriptCommandLine[[2 ;; ]],
	FileNames[FileNameJoin[{".", "SetReplace", "*.wlt"}]]
];


If[!FileExistsQ[#],
	Print["Test file ", #, " does not exist."];
	Quit[];] & /@ testFiles


(* ::Text:: *)
(*Run tests in each file*)


results = AssociationMap[Module[{report, filename},
	WriteString["stdout",
		filename = Last @ FileNameSplit[#],
		StringJoin[ConstantArray[" ", Max[40 - StringLength[filename], 1]]]];
	report = TestReport[#, TimeConstraint -> 60];
	WriteString["stdout", If[report["AllTestsSucceeded"],
		"\033[0;32m[ok]\033[0m",
		StringJoin[
			"\033[0;31m[",
			ToString @ report["TestsFailedCount"],
			"/",
			ToString @ Length @ report["TestResults"],
			" failed]\033[0m"]], "\n"];
	report
] &, testFiles]


(* ::Text:: *)
(*Create a notebook with results*)


reportFile = UsingFrontEnd @ Export[
	FileNameJoin[Join[FileNameSplit[CreateDirectory[]], {"testReport.nb"}]],
	Notebook @ Catenate @ Prepend[KeyValueMap[
		{Cell[Last @ FileNameSplit @ #1, "Section"],
			Cell[
				BoxData[RowBox[{"TestReport", "[", "\"" <> #1 <> "\"", "]"}]],
				"Input"],
			Cell[BoxData[ToBoxes[#2]], "Output"]} &,
		results], {Cell["SetReplace Test Report", "Title"]}]];


Print["Report file: ", reportFile];
