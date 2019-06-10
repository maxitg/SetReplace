#!/usr/bin/env wolframscript
(* ::Package:: *)

(* ::Text:: *)
(*Create build directory*)


buildDirectory = FileNameJoin[{".", "Build"}];
If[FileExistsQ[buildDirectory], DeleteDirectory[buildDirectory, DeleteContents -> True]];
CreateDirectory[buildDirectory];


(* ::Text:: *)
(*Compile C++ code*)


xcodeProjectPath = "SetReplace/SetReplace.xcodeproj/";
xcodeTargetName = "SetReplace";
If[Run["xcodebuild -project " <> xcodeProjectPath <> " -target " <> xcodeTargetName] != 0,
	Print[
		"xcodebuild not successful. ",
		"Install xcode and run ",
		"sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer"
	];
	Quit[];
];


(* ::Text:: *)
(*Copy package files inside*)


files = {"SetReplace.wl", "PacletInfo.m"};
CopyFile[FileNameJoin[{".", #}], FileNameJoin[{buildDirectory, #}]] & /@ files;


(* ::Text:: *)
(*Copy library file inside*)


libraryDirectory =
	FileNameJoin[{buildDirectory, "LibraryResources", "MacOSX-x86-64"}];
If[FileExistsQ[libraryDirectory],
	DeleteDirectory[libraryDirectory, DeleteContents -> True]
];
CreateDirectory[libraryDirectory];
CopyFile[
	FileNameJoin[{".", "SetReplace", "build", "Release", "libSetReplace.dylib"}],
	FileNameJoin[{
		buildDirectory,
		"LibraryResources",
		"MacOSX-x86-64",
		"libSetReplace.dylib"
	}]
];


(* ::Text:: *)
(*Pack paclet*)


PacletManager`PackPaclet[buildDirectory];
