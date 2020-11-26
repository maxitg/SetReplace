#!/usr/bin/env wolframscript

Check[
  Get[FileNameJoin[{DirectoryName[$InputFileName], "DevUtils", "init.m"}]];
  Off[General::stop];
,
  Print["Message occurred during loading of DevUtils. Pack failed."];
  Exit[1];
];

Check[
  InstallGitLink[];

  buildResult = BuildLibSetReplace["Verbose" -> True];
  If[!AssociationQ[buildResult], Exit[1]];

  packResult = PackSetReplace["Verbose" -> True];
  pacletLocation = packResult["Location"];
  If[!StringQ[pacletLocation], Exit[1]];
,
  Print["Message occurred during packing. Pack failed."];
  Exit[1];
];

Print["Pack succeeded."];
Exit[0];
