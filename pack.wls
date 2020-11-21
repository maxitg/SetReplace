#!/usr/bin/env wolframscript

Check[
  Get[FileNameJoin[{DirectoryName[$InputFileName], "DevUtils", "init.m"}]];
,
  Print["Message occurred during loading of DevUtils. Pack failed."];
  Exit[1];
];

result = ConsoleCreateSetReplacePaclet[];

If[!StringQ[result], Exit[1], Exit[0]];