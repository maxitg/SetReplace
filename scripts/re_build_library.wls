#!/usr/bin/env wolframscript

Check[
  Get @ FileNameJoin[{FileNameDrop[$InputFileName, -2], "DevUtils", "init.m"}]
,
  Print["Cannot load DevUtils`"];
  Exit[1]
];

InstallGitLink[];

Print["$Version: ", $Version];
Print["$InstallationDirectory: ", $InstallationDirectory];
Unset[$MessagePrePrint];

$systemID = AntProperty["system_id"];
$targetDirectory = FileNameJoin[
  {AntProperty["files_directory"], AntProperty["component"], "LibraryResources", $systemID}];

$opts = {
  "LibraryTargetDirectory" -> $targetDirectory,
  "SystemID" -> $systemID,
  "Compiler" -> ToExpression @ ConsoleTryEnvironment["COMPILER", Automatic],
  "CompilerInstallation" -> ConsoleTryEnvironment["COMPILER_INSTALLATION", Automatic],
  "LoggingFunction" -> Global`AntLog,
  "WorkingDirectory" -> Replace[AntProperty["scratch_directory"], Except[_String] -> Automatic],
  "Caching" -> False,
  "Verbose" -> True
}

Print["Calling BuildLibSetReplace with the following options:"];
ConsolePrintList[$opts];

$result = BuildLibSetReplace @@ $opts;

If[!AssociationQ[$result],
  AntFail["Library not produced, returned: ", $result];
  Exit[1];
];

Print["Built library to ", $result["LibraryPath"]];
