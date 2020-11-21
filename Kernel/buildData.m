Package["SetReplace`"]

PackageImport["GeneralUtilities`"]


PackageScope["$packageRoot"]

$packageRoot = FileNameDrop[$InputFileName, -2];

SetReplace::jitbuildfail = "Failed to (re)build libSetReplace. The existing library, if any, will be used instead.";

(* before loading build data, we check if we are running on a developer's machine, indicated by
the presence of the DevUtils sub-package, if so, we load it and do a rebuild, so that we can
get up-to-date versions of the various build properties *)
$devUtilsPath = FileNameJoin[{$packageRoot, "DevUtils", "init.m"}];
If[FileExistsQ[$devUtilsPath],
  Block[{$ContextPath = {"System`"}}, Get[$devUtilsPath]];

  (* forwarders for the functions we want from DevUtils. This is done so
  we don't create the SetReplaceDevUtils context for ordinary users (when DevUtils *isn't* available) *)
  $buildLibSetReplace = Symbol["SetReplaceDevUtils`BuildLibSetReplace"];
  $gitSHAWithDirtyStar = Symbol["SetReplaceDevUtils`GitSHAWithDirtyStar"];

  (* try build the C++ code immediately (which will most likely retrieve a cached library) *)
  (* if there is a frontend, then give a temporary progress panel, otherwise just Print *)
  If[TrueQ @ $Notebooks,
    Internal`WithLocalSettings[
      $progCell = None;
    ,
      $buildResult = $buildLibSetReplace["PreBuildCallback" -> Function[
        $progCell = PrintTemporary @ Panel[
          "Building libSetReplace from sources in " <> #LibrarySourceDirectory,
          Background -> LightOrange]]];
    ,
      NotebookDelete[$progCell];
      $progCell = None;
    ];
  ,
    $buildResult = $buildLibSetReplace["PreBuildCallback" -> "Print"];
  ];

  If[!AssociationQ[$buildResult],
    Message[SetReplace::jitbuildfail];
  ];
];


readJSONFile[file_] := Quiet @ Check[Developer`ReadRawJSONFile[file], $Failed];


PackageExport["$SetReplaceLibraryBuildTime"]
PackageExport["$SetReplaceLibraryPath"]

SetUsage @ "
$SetReplaceLibraryBuildTime gives the date object at which this C++ libSetReplace library was built.
"

SetUsage @ "
$SetReplaceLibraryPath stores the path of the C++ libSetReplace library.
"

$libraryDirectory = FileNameJoin[{$packageRoot, "LibraryResources", $SystemID}];
$libraryBuildDataPath = FileNameJoin[{$libraryDirectory, "libSetReplaceBuildInfo.json"}];

$buildData = readJSONFile[$libraryBuildDataPath];
If[$buildData === $Failed,
  $SetReplaceLibraryBuildTime = $SetReplaceLibraryPath = Missing["LibraryBuildDataNotFound"];
,
  $SetReplaceLibraryBuildTime = DateObject[$buildData["LibraryBuildTime"], TimeZone -> "UTC"];
  $SetReplaceLibraryPath = FileNameJoin[{$libraryDirectory, $buildData["LibraryFileName"]}];
];


PackageExport["$SetReplaceBuildTime"]
PackageExport["$SetReplaceGitSHA"]

SetUsage @ "
$SetReplaceBuildTime gives the time at which this SetReplace paclet was built.
* When evaluated for an in-place build, this time is Now.
"

SetUsage @ "
$SetReplaceGitSHA gives the Git SHA of the repository from which this SetRepace paclet was built.
* When evaluated for an in-place build, this is simply the current HEAD of the git repository.
"

$pacletBuildInfoPath = FileNameJoin[{$packageRoot, "PacletBuildInfo.json"}];

If[FileExistsQ[$pacletBuildInfoPath] && AssociationQ[$pacletBuildInfo = readJSONFile[$pacletBuildInfoPath]],
  $SetReplaceBuildTime = DateObject[$pacletBuildInfo["BuildTime"], TimeZone -> "UTC"];
  $SetReplaceGitSHA = $pacletBuildInfo["GitSHA"];
,
  $SetReplaceGitSHA = $gitSHAWithDirtyStar[$packageRoot];
  If[!StringQ[$SetReplaceGitSHA], Missing["GitLinkNotAvailable"]];
  $SetReplaceBuildTime = DateObject[TimeZone -> "UTC"];
];
