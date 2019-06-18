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
CopyFile[FileNameJoin[{".", #}], FileNameJoin[{buildDirectory, #}]] & /@ files;


(* ::Text:: *)
(*Build and copy library file*)


<< CCompilerDriver`
SetDirectory["SetReplace/SetReplace"];
CreateLibrary[
	{"Match.cpp", "Set.cpp", "SetReplace.cpp"},
	"libSetReplace",
	"Language" -> "C++",
	"CompileOptions" -> "-std=c++17",
	"TargetDirectory" -> "../../Build/LibraryResources/" <> $SystemID];
SetDirectory["../.."];


(* ::Text:: *)
(*Pack paclet*)


PackPaclet[buildDirectory];
