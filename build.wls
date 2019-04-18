#!/usr/bin/env wolframscript
(* ::Package:: *)

(* ::Text:: *)
(*Create build directory*)


buildDirectory = FileNameJoin[{".", "Build"}];
If[FileExistsQ[buildDirectory], DeleteDirectory[buildDirectory, DeleteContents -> True]];
CreateDirectory[buildDirectory];


(* ::Text:: *)
(*Copy packages files inside*)


files = {"SetReplace.wl", "PacletInfo.m"};
CopyFile[FileNameJoin[{".", #}], FileNameJoin[{buildDirectory, #}]] & /@ files;


(* ::Text:: *)
(*Pack paclet*)


PacletManager`PackPaclet[buildDirectory];
