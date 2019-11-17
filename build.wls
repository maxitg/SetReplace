#!/usr/bin/env wolframscript

<< CCompilerDriver`;

$successQ = True;

(* If any messages are produced, fail with non-zero exit code. *)
Check[
	(*Create build directory*)
	buildDirectory = FileNameJoin[{".", "Build"}];
	If[FileExistsQ[buildDirectory], DeleteDirectory[buildDirectory, DeleteContents -> True]];
	CreateDirectory[buildDirectory];
	
	(*Copy package files inside*)
	files = Select[StringMatchQ[#, __ ~~ (".wl" | ".m")] &] @ Import["SetReplace/"];
	CreateDirectory /@
		Function[FileNameJoin[Join[{buildDirectory}, #]]] /@
		Most /@
		Select[Length[#] > 1 &][FileNameSplit /@ files];
	CopyFile[FileNameJoin[{".", "SetReplace", #}], FileNameJoin[{buildDirectory, #}]] & /@
		files;
	
	(*Build and copy library file*)
	$TryEnvironment[var_, default_] := If[# === $Failed, default, #] & @ Environment[var];
	
	SetDirectory["SetReplace/libSetReplace"];
	If[CreateLibrary[
			{"Expression.cpp", "Match.cpp", "Set.cpp", "SetReplace.cpp"},
			"libSetReplace",
			"Language" -> "C++",
			"CompileOptions" -> "-std=c++17",
			"TargetDirectory" -> "../../Build/LibraryResources/" <> $SystemID,
			"Compiler" -> ToExpression @ $TryEnvironment["COMPILER", Automatic],
			"CompilerInstallation" -> $TryEnvironment["COMPILER_INSTALLATION", Automatic]
		] === $Failed,
		$successQ = False;
		Print["Compilation failed. Paclet will be created without low level implementation."]];
	SetDirectory["../.."];
	
	(*Pack paclet*)
	PackPaclet[buildDirectory];,

	$successQ = False;
];

If[$successQ,
	Print["Build done."];
	Exit[0],
	Print["Build failed."];
	Exit[1]
]
