Unprotect["SetReplace`*"];

ClearAll @@ (# <> "*" & /@ Contexts["SetReplace`*"]);

Block[
    {GeneralUtilities`Control`PackagePrivate`$DesugaringRules = {}},
	Get[FileNameJoin[{FileNameDrop[$InputFileName], "usageString.m"}]];
];

SetAttributes[#, {Protected, ReadProtected}] & /@ Evaluate @ Names @ "SetReplace`*";
