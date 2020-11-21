#!/usr/bin/env wolframscript

Check[
  Get[FileNameJoin[{DirectoryName[$InputFileName], "DevUtils", "init.m"}]];
,
  Print["Message occurred during loading of DevUtils. Build failed."];
  Exit[1];
];

result = ConsoleBuildLibSetReplace[
  "Compiler" -> ToExpression @ ConsoleTryEnvironment["COMPILER", Automatic],
  "CompilerInstallation" -> ConsoleTryEnvironment["COMPILER", Automatic]
];

If[!AssociationQ[result], Exit[1], Exit[0]];
