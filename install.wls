#!/usr/bin/env wolframscript
(* ::Package:: *)

pacletInfo = (Association @@ Import["PacletInfo.m"]);


filename = pacletInfo[Name] <> "-" <> pacletInfo[Version] <> ".paclet";


If[!FileExistsQ[filename],
	Print[
		"The paclet file ", filename, " was not found. ",
		"Run ./build.wls."];
	Quit[];
]


If[PacletInformation["SetReplace"] != {}, PacletUninstall["SetReplace"]];


If[Head[PacletInstall[filename]] == Paclet,
	Print["Done. Restart running kernels to complete installation."]];
