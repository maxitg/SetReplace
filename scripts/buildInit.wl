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
        _,
          "-std=c++17"],
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
    tryEnvironment["CONTEXT", "SetReplace"], "Version" -> "SetReplace$" <> StringReplace[$version, "." -> "$"]] <> "`";
  If[context =!= "SetReplace`",
    Print["Building with context ", context];
    renameContext[context];
  ];
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
    GitFetch[gitRepo, "origin"];
    minorVersionNumber = Length[GitRange[
      gitRepo, Except[versionInformation["Checkpoint"]], GitMergeBase[gitRepo, "HEAD", "origin/master"]]];
    pacletInfoFilename = FileNameJoin[{$buildDirectory, "PacletInfo.m"}];
    pacletInfo = Association @@ Import[pacletInfoFilename];
    versionString = pacletInfo[Version] <> "." <> ToString[minorVersionNumber];,

    Return[]];

  Export[pacletInfoFilename, Paclet @@ Normal[Join[pacletInfo, <|Version -> versionString|>]]];
  versionString
];

updateVersion[] /; Names["GitLink`*"] === {} := Message[updateVersion::noGitLink];

packPaclet[] := (
  If[$internalBuildQ,
    Print["$Version: ", $Version];
    Print["$InstallationDirectory: ", $InstallationDirectory];
    Unset[$MessagePrePrint];
  ];
  PackPaclet[$buildDirectory, If[$internalBuildQ, AntProperty["output_directory"], $repoRoot]];
  If[$internalBuildQ,
    SetDirectory[AntProperty["output_directory"]];
    If[TrueQ[FileExistsQ[FileNames["SetReplace*.paclet"][[1]]]],
      Print[FileNames["SetReplace*.paclet"][[1]] <> " ... OK"],
      AntFail["Paclet not produced"]
    ];
  ];
)
