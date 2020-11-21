Package["SetReplaceDevUtils`"]

PackageImport["GeneralUtilities`"]



PackageExport["CreateSetReplacePaclet"]

Options[CreateSetReplacePaclet] = {
  "RootDirectory" :> $SetReplaceRoot,
  "MasterBranch" -> "master", (* for calculating the minor version *)
  "OutputDirectory" -> Automatic
};


CreateSetReplacePaclet::buildfailed = "Could not build paclet from `` into ``.";
CreateSetReplacePaclet::nogitlink = "GitLink is not installed, so the built paclet version cannot be correctly calculated. Proceed with caution, and consider installing GitLink by running InstallGitLink[]."

SetUsage @ "
CreateSetReplacePaclet[] creates a PacletObject containing the local source and last built library.
* The PacletObject represents a .paclet file created on disk.
* The default location of the .paclet file is within the BuiltPaclets subdirectory of the current repo, \
but can be overriden with the 'OutputDirectory' option.
* The source for the PacletObject is given by the contents of the 'Kernel' and 'LibraryResources' directories \
of the current repo, but can be overridden with the 'RootDirectory' option.
* The minor version is derived from the number of commits since the last checkpoint, which is obtained from \
the 'master' branch, which can be overriden with the 'MasterBranch' option.
"

$gitLinkDownloadCode = "PacletInstall[\"https://www.wolframcloud.com/obj/maxp1/GitLink-2019.11.26.01.paclet\"]";

CreateSetReplacePaclet[OptionsPattern[]] := ModuleScope[
  UnpackOptions[rootDirectory, masterBranch, outputDirectory];
  SetAutomatic[outputDirectory, FileNameJoin[{rootDirectory, "BuiltPaclets"}]];
  EnsureDirectory[outputDirectory];
  If[$GitLinkAvailableQ,
    minorVersionNumber = CalculateMinorVersionNumber[rootDirectory, masterBranch];
    pacletInfoFile = createUpdatedPacletInfo[rootDirectory, minorVersionNumber];
  ,
    Message[CreateSetReplacePaclet::nogitlink];
    pacletInfoFile = FileNameJoin[{rootDirectory, "PacletInfo.m"}]
  ];
  fileTree = Flatten @ List[
    FileNameJoin[{rootDirectory, "Kernel"}],
    FileNameJoin[{rootDirectory, "LibraryResources"}],
    {pacletInfoFile}
  ];
  pacletFileName = CreatePacletArchive[fileTree, outputDirectory];
  If[StringQ[pacletFileName],
    Return[PacletObject[File[pacletFileName]]],
    ReturnFailed["buildfailed", rootDirectory, outputDirectory]
  ]
];

createUpdatedPacletInfo[rootDirectory_, minorVersionNumber_] := ModuleScope[
  pacletInfoFilename = FileNameJoin[{rootDirectory, "PacletInfo.m"}];
  pacletInfo = Association @@ Import[pacletInfoFilename];
  versionString = pacletInfo[Version] <> "." <> ToString[minorVersionNumber];
  tempFilename = FileNameJoin[{$TemporaryDirectory, "PacletInfo.m"}];
  Block[{$ContextPath = {"System`", "PacletManager`"}},
    Export[tempFilename, PacletManager`Paclet @@ Normal[Append[pacletInfo, Version -> versionString]]]
  ];
  tempFilename
];

