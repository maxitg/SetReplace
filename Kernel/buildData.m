Package["SetReplace`"]

PackageImport["GeneralUtilities`"]


PackageExport["$SetReplaceLibraryGitSHA"]
PackageExport["$SetReplaceLibraryBuildTime"]
PackageExport["$SetReplaceLibraryPath"]

SetUsage @ "
$SetReplaceLibraryGitSHA gives the Git SHA of the repository from which the C++ libSetReplace library was built.
"

SetUsage @ "
$SetReplaceLibraryBuildTime gives the date object at which the C++ libSetReplace library was built.
"

SetUsage @ "
$SetReplaceLibraryPath stores the path of the C++ libSetReplace library.
"


PackageScope["$packageRoot"]

$packageRoot = FileNameDrop[$InputFileName, -2];

(* before loading build data, we check if we are running on a developer's machine, indicated by
the presence of the DevUtils sub-package, if so, we load it and do a rebuild, so that we can
get up-to-date versions of the various build properties *)
$devUtilsPath = FileNameJoin[{$packageRoot, "DevUtils", "init.m"}];
If[FileExistsQ[$devUtilsPath], 
  Block[{$ContextPath = {"System`"}, buildLibSetReplace, buildData}, Get[$devUtilsPath]];

  (* try build the C++ code immediately (which will most likely retrieve a cached library) *)
  result = Symbol["SetReplaceDevUtils`BuildLibSetReplace"]["PrintBeforeBuild" -> True];
  If[!AssociationQ[result], Print["Failed to build SetReplace on demand"]];
];

$libraryDirectory = FileNameJoin[{$packageRoot, "LibraryResources", $SystemID}];
$libraryBuildDataPath = FileNameJoin[{$libraryDirectory, "buildData.json"}];
$buildData = Quiet @ Check[Developer`ReadRawJSONFile[$libraryBuildDataPath], $Failed];

If[$buildData === $Failed,
  $SetReplaceLibraryGitSHA = $SetReplaceLibraryBuildTime = $SetReplaceLibraryPath = $Failed;
,
  $SetReplaceLibraryGitSHA = Replace[$buildData["LibraryGitSHA"], Null -> Missing["NotAvailable"]];
  $SetReplaceLibraryBuildTime = DateObject[$buildData["LibraryBuildTime"], TimeZone -> "UTC"];
  $SetReplaceLibraryPath = FileNameJoin[{$libraryDirectory, $buildData["LibraryFileName"]}];
];

