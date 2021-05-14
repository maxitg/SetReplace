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

importLibSetReplaceFunction[cppFunctionName_ -> symbol_, argumentTypes_, outputType_] := (
  symbol = If[$libraryFile =!= $Failed,
    LibraryFunctionLoad[$libraryFile, cppFunctionName, argumentTypes, outputType]
  ,
    $Failed
  ];
  AppendTo[$libraryFunctions, symbol];
);

$libSetReplaceAvailable := FreeQ[$libraryFunctions, $Failed];

$maxInt64 = 2^63 - 1;
$maxUInt32 = 2^32 - 1;
