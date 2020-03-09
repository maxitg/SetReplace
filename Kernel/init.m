(* ::Package:: *)

Unprotect["SetReplace`*"];


ClearAll @@ (# <> "*" & /@ Contexts["SetReplace`*"]);


Get["SetReplace`Kernel`usageString`"];


SetAttributes[#, {Protected, ReadProtected}] & /@
	Evaluate @ Names @ "SetReplace`*";
