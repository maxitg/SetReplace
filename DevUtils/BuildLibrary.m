Package["SetReplaceDevUtils`"]

PackageImport["GeneralUtilities`"]



PackageExport["BuildLibSetReplace"]

Options[BuildLibSetReplace] = {
  "RootDirectory" :> $SetReplaceRoot,
  "LibrarySourceDirectory" -> Automatic,
  "LibraryTargetDirectory" -> Automatic,
  "SystemID" -> $SystemID,
  "Compiler" -> Automatic,
  "CompilerInstallation" -> Automatic,
  "WorkingDirectory" -> Automatic,
  "LoggingFunction" -> None,
  "PrintBeforeBuild" -> False,
  "Caching" -> True
};

SetUsage @ "
BuildLibSetReplace[] builds the libSetReplace library from source, and returns an association of metadata \
on completion, or $Failed if the library could not be built.
* By default, the resulting library is placed within the appropriate system-specific subdirectory of the \
'LibraryResources' directory of the current repo, but this location can be overriden with the \
'LibraryTargetDirectory' option.
* By default, the sources are obtained from the 'libSetReplace' subdirectory of the current repo, but this \
location can be overriden with the 'LibrarySourceDirectory' option.
* The meaning of 'current repo' for the above two options is set by the 'RootDirectory' option, which \
defaults to the root of the repo containing the DevUtils package.
* Additional metadata is written to 'LibraryTargetDirectory' in a file called 'buildData.json'.
* The library file name includes a hash based on the library and build utility sources.
* If the library target directory fills up with more than 128 files, the least recently generated files \
will be automatically deleted.
* If a library file with the appropriate hashes already exists, the build step is skipped, but the build \
metadata is still written to a json file in the 'LibraryTargetDirectory'.
* Various compiler options can be specified with 'Compiler', 'CompilerInstallation', 'WorkingDirectory', \
and 'LoggingFunction'.
* Setting 'PrintBeforeBuild' to True will enable a simple message, but only when a build is actually needed.
* Setting 'Caching' to False can be used to prevent the caching mechanism from being applied.
"

BuildLibSetReplace::compfail = "Compilation of C++ code at `` failed.";
BuildLibSetReplace::badsourcedir = "Source directory `` did not exist.";

BuildLibSetReplace[OptionsPattern[]] := ModuleScope[

  (* options processing *)
  UnpackOptions[
    rootDirectory, librarySourceDirectory, libraryTargetDirectory,
    systemID, compiler, compilerInstallation, workingDirectory, loggingFunction,
    printBeforeBuild, caching
  ];

  SetAutomatic[librarySourceDirectory, FileNameJoin[{rootDirectory, "libSetReplace"}]];
  SetAutomatic[libraryTargetDirectory, FileNameJoin[{rootDirectory, "LibraryResources", systemID}]];

  (* path processing *)
  buildDataPath = FileNameJoin[{libraryTargetDirectory, "buildData.json"}];
  librarySourceDirectory = AbsoluteFileName[librarySourceDirectory];
  If[FailureQ[librarySourceDirectory], ReturnFailed["badsourcedir", librarySourceDirectory]];

  (* derive hashes *)
  sourceHashes = Join[
    FileTreeHashes[librarySourceDirectory, {"*.cpp", "*.hpp"}, 1],
    FileTreeHashes[$DevUtilsRoot, {"*.m"}, 1]
  ];
  hashedOptions = {compiler, compilerInstallation, systemID};
  finalHash = Base36Hash[{sourceHashes, hashedOptions}];

  (* derive final paths *)
  libraryFileName = StringJoin["libSetReplace-", finalHash, ".", System`Dump`LibraryExtension[]];
  libraryPath = FileNameJoin[{libraryTargetDirectory, libraryFileName}];

  calculateBuildData[] := Association[
    "LibraryPath" -> libraryPath,
    "LibraryFileName" -> libraryFileName,
    "LibraryBuildTime" -> DateList[FileDate[libraryPath], TimeZone -> "UTC"],
    "LibraryGitSHA" -> Replace[GitSHAWithDirtyStar @ FileNameDrop @ librarySourceDirectory, _Missing -> Null],
    "LibrarySourceHash" -> Hash[sourceHashes]
  ];

  (* if a cached library exists with the right name, we can skip the compilation step, and need
  only write the JSON file *)
  If[caching && FileExistsQ[libraryPath] && FileExistsQ[buildDataPath],
    buildData = readBuildData[buildDataPath];
    (* the JSON file might already be correct, so check this to avoid calling GitSHAWithDirtyStar *)
    If[buildData["LibraryFileName"] === libraryFileName,
      PrependTo[buildData, "LibraryPath" -> libraryPath];
    ,
      buildData = calculateBuildData[];
      writeBuildData[buildDataPath, buildData];
    ];
    buildData["FromCache"] = True;
    Return[buildData];
  ];

  (* prevent too many libraries from building up in the cache *)
  If[caching, flushLibrariesIfFull[libraryTargetDirectory]];

  If[printBeforeBuild, Print["Building libSetReplace from sources in ", librarySourceDirectory]];
  fileNames = FileNames["*.cpp", librarySourceDirectory];
  libraryPath = wrappedCreateLibrary[
      fileNames,
      libraryFileName,
      "CleanIntermediate" -> True,
      "CompileOptions" -> $compileOptions,
      "Compiler" -> compiler,
      "CompilerInstallation" -> compilerInstallation,
      "Language" -> "C++",
      "ShellCommandFunction" -> loggingFunction,
      "ShellOutputFunction" -> loggingFunction,
      "TargetDirectory" -> libraryTargetDirectory,
      "TargetSystemID" -> systemID,
      "WorkingDirectory" -> workingDirectory
  ];
  If[!StringQ[libraryPath],
    ReturnFailed["compfail", librarySourceDirectory];
  ];
  buildData = calculateBuildData[];
  writeBuildData[buildDataPath, buildData];
  buildData["FromCache"] = False;
  buildData
];

readBuildData[jsonFile_] :=
  Developer`ReadRawJSONFile[jsonFile];

writeBuildData[jsonFile_, buildData_] :=
  Developer`WriteRawJSONFile[
    jsonFile,
    KeyDrop[buildData, {"LibraryPath", "FromCache"}],
    "Compact" -> 1
  ];

(* avoids loading CCompilerDriver until it is actually used *)
wrappedCreateLibrary[args___] := Block[{$ContextPath},
  Needs["CCompilerDriver`"];
  CCompilerDriver`CreateLibrary[args]
];

$warningsFlags = {
  "-Wall", "-Wextra", "-Werror", "-pedantic", "-Wcast-align", "-Wcast-qual", "-Wctor-dtor-privacy",
  "-Wdisabled-optimization", "-Wformat=2", "-Winit-self", "-Wmissing-include-dirs", "-Wold-style-cast",
  "-Woverloaded-virtual", "-Wredundant-decls", "-Wshadow", "-Wsign-promo", "-Wswitch-default", "-Wundef",
  "-Wno-unused"
};

$compileOptions = Switch[$OperatingSystem,
  "Windows",
    {"/std:c++17", "/EHsc"},
  "MacOSX",
    Join[{"-std=c++17"}, $warningsFlags, {"-mmacosx-version-min=10.12"}], (* for std::shared_mutex support *)
  "Unix",
    Join[{"-std=c++17"}, $warningsFlags]
];


flushLibrariesIfFull[libraryDirectory_] := Scope[
  files = FileNames["lib*", libraryDirectory];
  If[Length[files] > 128,
    oldestFile = MinimalBy[files, FileDate, 8];
    Scan[DeleteFile, oldestFile]
  ]
];
