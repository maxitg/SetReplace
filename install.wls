#!/usr/bin/env wolframscript

$successQ = True;

(* If any messages are produced, fail with non-zero exit code. *)
Check[
  pacletInfo = Association @@ Import[FileNameJoin[{".", "SetReplace", "PacletInfo.m"}]];
    
  filename = pacletInfo[Name] <> "-" <> pacletInfo[Version] <> ".paclet";
  
  If[!FileExistsQ[filename],
  	Print[
  		"The paclet file ", filename, " was not found. ",
  		"Run ./build.wls."];
  	Exit[1];
  ];
  
  (* This works in both 12.0 and 12.1. *)
  pacletObjectQ[p_] := PacletObjectQ[p] || Head[p] === PacletManager`Paclet;

  If[pacletObjectQ[PacletInstall[filename, "IgnoreVersion" -> True]],
  	Print["Installed. Restart running kernels to complete installation."],
    Print["Install failed."];
    $successQ = False];,

  $successQ = False;
];

Exit[If[$successQ, 0, 1]]
