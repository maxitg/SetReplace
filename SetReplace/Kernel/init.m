(* ::Package:: *)

Unprotect["SetReplace`*"];


ClearAll @@ (# <> "*" & /@ Contexts["SetReplace`*"]);


With[{
	libraryDirectory =
		FileNameJoin[{DirectoryName[$InputFileName], "LibraryResources", $SystemID}]},
	If[Not @ MemberQ[$LibraryPath, libraryDirectory],
		PrependTo[$LibraryPath, libraryDirectory]]];


Get["SetReplace`usageString`"]


SetAttributes[#, {Protected, ReadProtected}] & /@
	Evaluate @ Names @ "SetReplace`*";
