#!/usr/bin/env wolframscript

Needs["CCompilerDriver`"];

$successQ = True;

$internalBuildQ = StringQ[AntProperty["system_id"]];

(* If any messages are produced, fail with non-zero exit code. *)
Check[
	(*Create build directory*)
	$buildDirectory = FileNameJoin[{DirectoryName[$InputFileName], "Build"}];
	If[!$internalBuildQ,
		If[FileExistsQ[$buildDirectory], DeleteDirectory[$buildDirectory, DeleteContents -> True]];
		CreateDirectory[$buildDirectory];

		(*Copy package files inside*)
		files = Select[StringMatchQ[#, __ ~~ (".wl" | ".m")] &] @ Import["SetReplace/"];
		CreateDirectory /@
			Function[FileNameJoin[Join[{$buildDirectory}, #]]] /@
			Most /@
			Select[Length[#] > 1 &][FileNameSplit /@ files];
		CopyFile[FileNameJoin[{".", "SetReplace", #}], FileNameJoin[{$buildDirectory, #}]] & /@
			files;
	];
	
	(*Build and copy library file*)
	$TryEnvironment[var_, default_] := If[# === $Failed, default, #] & @ Environment[var];
	
	$libSetReplaceSource = FileNameJoin[{DirectoryName[$InputFileName], "SetReplace", "libSetReplace"}];
	If[FailureQ[CreateLibrary[
			FileNames["*.cpp", {$libSetReplaceSource}],
			"libSetReplace",
			"CleanIntermediate" -> True,
			"CompileOptions" -> Switch[$OperatingSystem,
				"Windows",
					{"/std:c++17", "/EHsc"},
				_,
					"-std=c++17"],
			"Compiler" -> ToExpression @ $TryEnvironment["COMPILER", Automatic],
			"CompilerInstallation" -> $TryEnvironment["COMPILER_INSTALLATION", Automatic],
			"Language" -> "C++",
			"ShellCommandFunction" -> If[$internalBuildQ, Global`AntLog, None],
			"ShellOutputFunction" -> If[$internalBuildQ, Global`AntLog, None],
			"TargetDirectory" -> If[$internalBuildQ,
				FileNameJoin[{
					AntProperty["files_directory"], AntProperty["component"], "LibraryResources", AntProperty["system_id"]}],
				FileNameJoin[{$buildDirectory, "LibraryResources", $SystemID}]],
			"TargetSystemID" -> If[$internalBuildQ, AntProperty["system_id"], $SystemID],
			"WorkingDirectory" -> If[$internalBuildQ, AntProperty["scratch_directory"], Automatic]
		]],
		$successQ = False;
		If[$internalBuildQ, AntFail, Print]["Compilation failed. Paclet will be created without low level implementation."]
	];

	If[!$internalBuildQ,
		(*Pack paclet*)
		SetDirectory[DirectoryName[$InputFileName]];
		PackPaclet[$buildDirectory];
	],

	$successQ = False;
];

If[$successQ && !$internalBuildQ,
	Print["Build done."];
	Exit[0],
	Print["Build failed."];
	Exit[1]
]
