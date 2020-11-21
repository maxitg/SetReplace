Unprotect["SetReplace`*"];

(* this is a no-op the first time round, subsequent loads will unload the C++ library first *)
SetReplace`PackageScope`unloadLibrary[];

ClearAll @@ (# <> "*" & /@ Contexts["SetReplace`*"]);

Block[
  {GeneralUtilities`Control`PackagePrivate`$DesugaringRules = {}},
  Get[FileNameJoin[{FileNameDrop[$InputFileName], "usageString.m"}]];
];

SetAttributes[#, {Protected, ReadProtected}] & /@ Evaluate @ Names @ "SetReplace`*";
