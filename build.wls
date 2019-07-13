#!/usr/bin/env wolframscript
(* ::Package:: *)

(* ::Text:: *)
(*Create build directory*)


buildDirectory = FileNameJoin[{".", "Build"}];
If[FileExistsQ[buildDirectory], DeleteDirectory[buildDirectory, DeleteContents -> True]];
CreateDirectory[buildDirectory];


(* ::Text:: *)
(*Copy package files inside*)


files = {"SetReplace.wl", "PacletInfo.m"};
CopyFile[FileNameJoin[{".", "SetReplace", #}], FileNameJoin[{buildDirectory, #}]] & /@
	files;


(* ::Text:: *)
(*Build and copy library file*)


$TryEnvironment[var_, default_] := If[# === $Failed, default, #] & @ Environment[var]


<< CCompilerDriver`
SetDirectory["SetReplace/libSetReplace"];
If[CreateLibrary[
		{"Match.cpp", "Set.cpp", "SetReplace.cpp"},
		"libSetReplace",
		"Language" -> "C++",
		"CompileOptions" -> "-std=c++17",
		"TargetDirectory" -> "../../Build/LibraryResources/" <> $SystemID,
		"Compiler" -> ToExpression @ $TryEnvironment["COMPILER", Automatic],
		"CompilerInstallation" -> $TryEnvironment["COMPILER_INSTALLATION", Automatic]
	] === $Failed,
	Print["Compilation failed. Paclet will be created without C++ implementation."]];
SetDirectory["../.."];


(* ::Text:: *)
(*Pack paclet*)


PackPaclet[buildDirectory];


Print["Done."];
