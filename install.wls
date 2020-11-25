#!/usr/bin/env wolframscript

Check[
  Get[FileNameJoin[{DirectoryName[$InputFileName], "DevUtils", "init.m"}]];
,
  Print["Message occurred during loading of DevUtils. Build failed."];
  Exit[1];
];

If[$VersionNumber < 12.1,
  Needs["PacletManager`"];
];

Check[
  InstallGitLink[];

  paclet = ConsoleCreateSetReplacePaclet[];

  If[!StringQ[paclet],
    Print["Could not create paclet, so cannot install it."];
    Exit[1]
  ];

  previousPaclets = PacletFind["SetReplace"];
  If[previousPaclets =!= {},
    Print["Uninstalling previous SetReplace at ", First[previousPaclets]["Location"]];
    If[FailureQ[PacletUninstall["SetReplace"]],
      Print["Could not uninstall old paclet"];
      Exit[1];
    ];
  ];

  Print["Installing paclet at ", paclet];
  installedPaclet = PacletInstall[paclet];
  If[FailureQ[installedPaclet],
    Print["Could not install new paclet."];
    Exit[1];
  ];

  Print["Paclet installed to ", installedPaclet["Location"]];
,
  Print["Message occurred during loading of DevUtils. Build failed."];
  Exit[1];
];

Exit[0];