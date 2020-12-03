#!/usr/bin/env wolframscript

$thisDir = FileNameDrop[$InputFileName, -1];
$rootDir = FileNameDrop[$InputFileName, -2];

$redColor = "\033[0;31m";
$greenColor = "\033[0;32m";
$orangeColor = "\033[0;33m";
$yellowColor = "\033[1;33m";
$endColor = "\033[0m";

Unprotect[Exit];
$wrap = True;

(* we'll disable Exit[0], since we want don't want our *own* script to end *)
Exit[0] /; $wrap := Print[$greenColor, "Exit[0]", $endColor];

(* Exit[1] will just print so we know what happened *)
Exit[1] /; $wrap := Block[{$wrap}, Print[$redColor, "Exit[1]", $endColor]; Exit[1]];

(* we'll put the final .paclet file in here *)
$rePacletDir = FileNameJoin[{$rootDir, "BuiltPaclets", "RE-scripts-test"}];
If[FileExistsQ[$rePacletDir], DeleteDirectory[$rePacletDir, DeleteContents -> True]];

(* provide values for expected AntProperties *)
AntProperty["scratch_directory"] = Automatic
AntProperty["files_directory"] = $rootDir;
AntProperty["component"] = "";
AntProperty["output_directory"] = $rePacletDir;
AntProperty["system_id"] = $SystemID;

(* stubs for AntLog and AntFail *)
Global`AntLog[args___] := Print[$orangeColor, "AntLog: ", args, $endColor];
AntFail[args___] := Print[$redColor, "AntFail: ", args, $endColor];

(* First run the build script *)
Print[$yellowColor, "Running re_build_library.wls", $endColor];
Get[FileNameJoin[{$thisDir, "re_build_library.wls"}]];

(* Then run the pack script *)
Print[$yellowColor, "\nRunning re_pack_paclet.wls", $endColor];
Get[FileNameJoin[{$thisDir, "re_pack_paclet.wls"}]];

Print["\nScripts complete, testing for presence of final .paclet."];

$pacletFiles = FileNames["*.paclet", $rePacletDir];

Clear[$wrap];
If[$pacletFiles === {},
  Print[$redColor, "Final .paclet file was not produced in ", $rePacletDir, $endColor];
  Exit[1]
,
  Print[$greenColor, "Final .paclet file was produced: ", First[$pacletFiles], $endColor];
  Exit[0];
];