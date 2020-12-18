#!/usr/bin/env wolframscript

Check[
  Get[FileNameJoin[{DirectoryName[$InputFileName], "DevUtils", "init.m"}]];
  Off[General::stop];
,
  Print["Message occurred during loading of DevUtils. Build failed."];
  Exit[1];
];

Check[
  result = BuildLibSetReplace["Verbose" -> True];
  If[!AssociationQ[result], Exit[1]];
,
  Print["Message occurred during building. Build failed."];
  Exit[1];
];

Print["Build succeeded."];
Exit[0];
