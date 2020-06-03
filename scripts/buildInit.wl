Needs["CCompilerDriver`"];
Needs["PacletManager`"];

$internalBuildQ = AntProperty["build_target"] === "internal";

If[PacletFind["GitLink", "Internal" -> All] === {},
  If[$internalBuildQ,
    PacletInstall["GitLink", "Site" -> "http://paclet-int.wolfram.com:8080/PacletServerInternal"],
    PacletInstall["https://www.wolframcloud.com/obj/maxp1/GitLink-2019.11.26.01.paclet"]];
];
Needs["GitLink`"];

$repoRoot = FileNameJoin[{DirectoryName[$InputFileName], ".."}];
$buildDirectory = If[$internalBuildQ,
  FileNameJoin[{AntProperty["files_directory"], AntProperty["component"]}],
  FileNameJoin[{$repoRoot, "Build"}]];

tryEnvironment[var_, default_] := If[# === $Failed, default, #] & @ Environment[var];

buildLibSetReplace::fail = "Compilation failed. Paclet will be created without low level implementation.";

$warningsFlags = {
  "-Wall", "-Wextra", "-Werror", "-pedantic", "-Wcast-align", "-Wcast-qual", "-Wctor-dtor-privacy",
  "-Wdisabled-optimization", "-Wformat=2", "-Winit-self", "-Wmissing-include-dirs", "-Wold-style-cast",
  "-Woverloaded-virtual", "-Wredundant-decls", "-Wshadow", "-Wsign-promo", "-Wswitch-default", "-Wundef",
  "-Wno-unused"};

buildLibSetReplace[] := With[{
    libSetReplaceSource = FileNameJoin[{$repoRoot, "libSetReplace"}],
    systemID = If[$internalBuildQ, AntProperty["system_id"], $SystemID]},
  If[$internalBuildQ, Off[CreateLibrary::wddirty]];
  If[!StringQ[CreateLibrary[
      FileNames["*.cpp", {libSetReplaceSource}],
      "libSetReplace",
      "CleanIntermediate" -> True,
      "CompileOptions" -> Switch[$OperatingSystem,
        "Windows",
          {"/std:c++17", "/EHsc"},
        "MacOSX",
          Join[{"-std=c++17"}, $warningsFlags, {"-mmacosx-version-min=10.12"}],
        "Unix",
          Join[{"-std=c++17"}, $warningsFlags]],
      "Compiler" -> ToExpression @ tryEnvironment["COMPILER", Automatic],
      "CompilerInstallation" -> tryEnvironment["COMPILER_INSTALLATION", Automatic],
      "Language" -> "C++",
      "ShellCommandFunction" -> If[$internalBuildQ, Global`AntLog, None],
      "ShellOutputFunction" -> If[$internalBuildQ, Global`AntLog, None],
      "TargetDirectory" -> FileNameJoin[{$buildDirectory, "LibraryResources", systemID}],
      "TargetSystemID" -> systemID,
      "WorkingDirectory" -> If[$internalBuildQ, AntProperty["scratch_directory"], Automatic]
    ]],
    If[$internalBuildQ, AntFail, Message][buildLibSetReplace::fail];
  ];
];

deleteBuildDirectory[] /; !$internalBuildQ :=
  If[FileExistsQ[$buildDirectory], DeleteDirectory[$buildDirectory, DeleteContents -> True]];

copyWLSourceToBuildDirectory[] /; !$internalBuildQ := With[{
    files = Append[Import[FileNameJoin[{$repoRoot, "Kernel"}]], FileNameJoin[{"..", "PacletInfo.m"}]]},
  If[!FileExistsQ[#], CreateDirectory[#]] & /@ {$buildDirectory, FileNameJoin[{$buildDirectory, "Kernel"}]};
  CopyFile[FileNameJoin[{$repoRoot, "Kernel", #}], FileNameJoin[{$buildDirectory, "Kernel", #}]] & /@ files;
];

fileStringReplace[file_, rules_] := Export[file, StringReplace[Import[file, "Text"], rules], "Text"]

renameContext[Automatic, version_] := Module[{context},
  context = Replace[
    If[$internalBuildQ, AntProperty["context"], tryEnvironment["CONTEXT", "SetReplace"]],
    "Version" -> "SetReplace$" <> StringReplace[version, "." -> "$"]] <> "`";
  If[context =!= "SetReplace`",
    Print["Building with context ", context];
    renameContext[context];
  ];
  context
]

renameContext[newContext_] := fileStringReplace[#, "SetReplace`" -> newContext] & /@
  (FileNameJoin[{$buildDirectory, #}] &) /@
  Select[MatchQ[FileExtension[#], "m" | "wl"] &] @ Import[$buildDirectory]

$baseVersionPacletMessage = "Will create paclet with the base version number.";
updateVersion::noGitLink = "Could not find GitLink. " <> $baseVersionPacletMessage;

updateVersion[] /; Names["GitLink`*"] =!= {} := Module[{
    versionInformation, gitRepo, minorVersionNumber, versionString, pacletInfoFilename, pacletInfo},
  Check[
    versionInformation = Import[FileNameJoin[{$repoRoot, "scripts", "version.wl"}]];
    gitRepo = GitOpen[$repoRoot];
    If[$internalBuildQ, GitFetch[gitRepo, "origin"]];
    minorVersionNumber = Max[0, Length[GitRange[
      gitRepo,
      Except[versionInformation["Checkpoint"]],
      GitMergeBase[gitRepo, "HEAD", If[$internalBuildQ, "origin/master", "master"]]]] - 1];
    pacletInfoFilename = FileNameJoin[{$buildDirectory, "PacletInfo.m"}];
    pacletInfo = Association @@ Import[pacletInfoFilename];
    versionString = pacletInfo[Version] <> "." <> ToString[minorVersionNumber];,

    Return[]];

  Export[pacletInfoFilename, Paclet @@ Normal[Join[pacletInfo, <|Version -> versionString|>]]];
  versionString
];

updateVersion[] /; Names["GitLink`*"] === {} := Message[updateVersion::noGitLink];

gitSHA[] /; Names["GitLink`*"] =!= {} := Module[{gitRepo, sha, cleanQ},
  gitRepo = GitOpen[$repoRoot];
  sha = GitSHA[gitRepo, gitRepo["HEAD"]];
  cleanQ = AllTrue[# === {} &]@GitStatus[gitRepo];
  If[cleanQ, sha, sha <> "*"]
]

gitSHA::noGitLink = "Could not find GitLink. $SetReplaceGitSHA will not be available.";

gitSHA[] /; Names["GitLink`*"] === {} := (
  Message[gitSHA::noGitLink];
  Missing["NotAvailable"]
)

updateBuildData[] := With[{
    buildDataFile = File[FileNameJoin[{$buildDirectory, "Kernel", "buildData.m"}]]},
  FileTemplateApply[buildDataFile, buildDataFile];
]

addModifiedContextFlag[fileName_] := FileNameJoin[Append[
  Most[FileNameSplit[fileName]],
  StringJoin[StringRiffle[Most[StringSplit[Last[FileNameSplit[fileName]], "."]], "."], "-C.paclet"]]]

packPaclet[context_] := Module[{pacletFileName},
  If[$internalBuildQ,
    Print["$Version: ", $Version];
    Print["$InstallationDirectory: ", $InstallationDirectory];
    Unset[$MessagePrePrint];
  ];
  pacletFileName = PackPaclet[$buildDirectory, If[$internalBuildQ, AntProperty["output_directory"], $repoRoot]];
  If[context =!= "SetReplace`", RenameFile[pacletFileName, addModifiedContextFlag[pacletFileName]]];
  If[$internalBuildQ,
    SetDirectory[AntProperty["output_directory"]];
    If[TrueQ[FileExistsQ[FileNames["SetReplace*.paclet"][[1]]]],
      Print[FileNames["SetReplace*.paclet"][[1]] <> " ... OK"],
      AntFail["Paclet not produced"]
    ];
  ];
]
