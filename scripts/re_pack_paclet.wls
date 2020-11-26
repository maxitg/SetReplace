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

$repoDir = FileNameDrop[$InputFileName, -2];
$buildDir = FileNameJoin[{AntProperty["files_directory"], AntProperty["component"]}];
$outputDir = AntProperty["output_directory"];

$opts = {
  "RepositoryDirectory" -> $repoDir,
  "LibraryDirectory" -> $buildDir,
  "MasterBranch" -> "origin/master",
  "OutputDirectory" -> $outputDir,
  "Verbose" -> True
};

Print["Calling PackSetReplace with the following options:"];
ConsolePrintList[$opts];

$builtPaclet = PackSetReplace @@ $opts;

If[Head[$builtPaclet] =!= PacletObject,
  AntFail["Paclet not produced"];
  Exit[1];
];

Print["Built paclet to ", $builtPaclet["Location"]];
