Package["SetReplaceDevUtils`"]

PackageImport["GeneralUtilities`"]

PackageExport["CreateSetReplacePaclet"]

Options[CreateSetReplacePaclet] = {
  "RootDirectory" :> $SetReplaceRoot,
  "MasterBranch" -> "master", (* for calculating the minor version *)
  "OutputDirectory" -> Automatic
};

CreateSetReplacePaclet::packfailed = "Could not pack paclet from `` into ``.";
CreateSetReplacePaclet::nogitlink = "GitLink is not installed, so the built paclet version cannot be correctly \
calculated. Proceed with caution, and consider installing GitLink by running InstallGitLink[]."

SetUsage @ "
CreateSetReplacePaclet[] creates a PacletObject containing the local source and last built library.
* Note that CreateSetReplacePaclet[] does *not* call BuildLibSetReplace[], unlike the command line scripts.
* The PacletObject represents a .paclet file created on disk.
* The default location of the .paclet file is within the BuiltPaclets subdirectory of the current repo, \
but can be overriden with the 'OutputDirectory' option.
* The source for the PacletObject is given by the contents of the 'Kernel' and 'LibraryResources' directories \
of the current repo, but can be overridden with the 'RootDirectory' option.
* The minor version is derived from the number of commits between the last checkpoint and the 'master' branch,
which can be overriden with the 'MasterBranch' option. The checkpoint is defined in `scripts/version.wl`.
"

CreateSetReplacePaclet[OptionsPattern[]] := ModuleScope[
  UnpackOptions[rootDirectory, masterBranch, outputDirectory];
  SetAutomatic[outputDirectory, FileNameJoin[{rootDirectory, "BuiltPaclets"}]];
  EnsureDirectory[outputDirectory];
  If[$GitLinkAvailableQ,
    minorVersionNumber = CalculateMinorVersionNumber[rootDirectory, masterBranch];
    pacletInfoFile = createUpdatedPacletInfo[rootDirectory, minorVersionNumber];
    gitSHA = GitSHAWithDirtyStar[rootDirectory];
  ,
    Message[CreateSetReplacePaclet::nogitlink];
    pacletInfoFile = FileNameJoin[{rootDirectory, "PacletInfo.m"}];
    gitSHA = Missing["GitLinkNotAvailable"];
  ];

  buildInfo = <|"GitSHA" -> gitSHA, "BuildTime" -> Round[DateList[TimeZone -> "UTC"]]|>;
  tempBuildInfoFile = FileNameJoin[{$DevUtilsTemporaryDirectory, "PacletBuildInfo.json"}];
  Developer`WriteRawJSONFile[tempBuildInfoFile, buildInfo];

  fileTree = {
    FileNameJoin[{rootDirectory, "Kernel"}],
    FileNameJoin[{rootDirectory, "LibraryResources"}],
    pacletInfoFile, tempBuildInfoFile
  };
  pacletFileName = CreatePacletArchive[fileTree, outputDirectory];
  If[StringQ[pacletFileName],
    Return[PacletObject[File[pacletFileName]]],
    ReturnFailed["packfailed", rootDirectory, outputDirectory]
  ]
];

createUpdatedPacletInfo[rootDirectory_, minorVersionNumber_] := ModuleScope[
  pacletInfoFilename = FileNameJoin[{rootDirectory, "PacletInfo.m"}];
  pacletInfo = Association @@ Import[pacletInfoFilename];
  versionString = pacletInfo[Version] <> "." <> ToString[minorVersionNumber];
  tempFilename = FileNameJoin[{$DevUtilsTemporaryDirectory, "PacletInfo.m"}];
  AppendTo[pacletInfo, Version -> versionString];
  Block[{$ContextPath = {"System`", "PacletManager`"}},
    Export[tempFilename, PacletManager`Paclet @@ Normal[pacletInfo]]
  ];
  tempFilename
];

