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
  
  If[Head[PacletInstall[filename, IgnoreVersion -> True]] == Paclet,
  	Print["Installed. Restart running kernels to complete installation."],
    $successQ = False];,

  $successQ = False;
];

Exit[If[$successQ, 0, 1]]
