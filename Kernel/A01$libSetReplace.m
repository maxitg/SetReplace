Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageScope["$libSetReplaceAvailable"]
PackageScope["unloadLibrary"]
PackageScope["importLibSetReplaceFunction"]

PackageScope["$maxInt64"]
PackageScope["$maxUInt32"]

(* All functions loaded from C++ should go in this file. This is the counterpart of libSetReplace/SetReplace.hpp *)

(* this function is defined now, but only run the *next* time Kernel/init.m is called, before all symbols
are cleared. *)
unloadLibrary[] := If[StringQ[$libraryFile],
  Scan[LibraryFunctionUnload, $libraryFunctions];
  $libraryFunctions = Null;
  Quiet @ LibraryUnload[$libraryFile];
];

SetReplace::nolibsetreplace = "libSetReplace (``) could not be found, some functionality will not be available.";

$libraryFile = $SetReplaceLibraryPath;

If[!StringQ[$libraryFile] || !FileExistsQ[$libraryFile],
  Message[SetReplace::nolibsetreplace, $libraryFile];
  $libraryFile = $Failed;
];

$libraryFunctions = {};

$cppRedistributableURL =
  "https://support.microsoft.com/en-us/topic/" <>
  "the-latest-supported-visual-c-downloads-2647da03-1eea-4433-9aff-95f26a218cc0";

SetReplace::cppRedistributable =
  "Check that " <>
  "\!\(\*TemplateBox[" <>
    "{\"Microsoft Visual C++ Redistributable\", " <>
    "{URL[\"" <> $cppRedistributableURL <> "\"], None}, " <>
    "\"" <> $cppRedistributableURL <> "\", " <>
    "\"HyperlinkActionRecycled\", " <>
    "{\"HyperlinkActive\"}, " <>
    "BaseStyle -> {\"URL\"}, " <>
    "HyperlinkAction -> \"Recycled\"}, " <>
    "\"HyperlinkTemplate\"]\)" <>
  " is installed.";

importLibSetReplaceFunction[cppFunctionName_ -> symbol_, argumentTypes_, outputType_] := (
  symbol = If[$libraryFile =!= $Failed,
    Check[
      LibraryFunctionLoad[$libraryFile, cppFunctionName, argumentTypes, outputType],
      If[$SystemID === "Windows-x86-64", Message[SetReplace::cppRedistributable]]; $Failed,
      {LibraryFunction::libload}
    ]
  ,
    $Failed
  ];
  AppendTo[$libraryFunctions, symbol];
);

$libSetReplaceAvailable := FreeQ[$libraryFunctions, $Failed];

$maxInt64 = 2^63 - 1;
$maxUInt32 = 2^32 - 1;
