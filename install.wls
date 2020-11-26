#!/usr/bin/env wolframscript

Check[
  Get[FileNameJoin[{DirectoryName[$InputFileName], "DevUtils", "init.m"}]];
  Off[General::stop];
  If[$VersionNumber < 12.1, Needs["PacletManager`"]];
,
  Print["Message occurred during loading of DevUtils. Build failed."];
  Exit[1];
];

Check[
  InstallGitLink[];

  buildResult = BuildLibSetReplace["Verbose" -> True];
  If[!AssociationQ[buildResult], Exit[1]];

  packResult = PackSetReplace["Verbose" -> True];
  pacletLocation = packResult["Location"];
  If[!StringQ[pacletLocation], Exit[1]];

  previousPaclets = PacletFind["SetReplace"];
  If[previousPaclets =!= {},
    Print["Uninstalling previous SetReplace at ", First[previousPaclets]["Location"]];
    If[FailureQ[PacletUninstall["SetReplace"]],
      Print["Could not uninstall old paclet."];
      Exit[1];
    ];
  ];

  Print["Installing paclet at ", pacletLocation];
  installedPaclet = PacletInstall[pacletLocation];
  If[FailureQ[installedPaclet],
    Print["Could not install new paclet."];
    Exit[1];
  ];

  Print["Paclet installed to ", installedPaclet["Location"]];
,
  Print["Message occurred during installing. Install failed."];
  Exit[1];
];

Print["Install succeeded."];
Exit[0];