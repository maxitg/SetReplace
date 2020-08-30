#!/usr/bin/env wolframscript

$successQ = True;

(* If any messages are produced, fail with non-zero exit code. *)
Check[
  $repoRoot = DirectoryName[$InputFileName];
  $latestPacletFiles = MaximalBy[
    FileNames[FileNameJoin[{$repoRoot, "SetReplace-*.paclet"}]], FileInformation[#, "LastModificationDate"] &];
  
  If[Length[$latestPacletFiles] == 0,
    Print[
      "No paclet files SetReplace-*.paclet were found. ",
      "Run ./build.wls."];
    Exit[1];
  ];

  previousPaclets = PacletFind["SetReplace"];
  If[previousPaclets =!= {},
    Print["Uninstalling previous SetReplace at ", First[previousPaclets]["Location"]];
    PacletUninstall["SetReplace"];
  ];
  
  (* This works in both 12.0 and 12.1. *)
  pacletObjectQ[p_] := PacletObjectQ[p] || Head[p] === PacletManager`Paclet;

  installedPaclet = PacletInstall[First[$latestPacletFiles], "IgnoreVersion" -> True];
  If[pacletObjectQ[installedPaclet],
    Print["Installed to ", installedPaclet["Location"]];
    Print["Restart running kernels to complete installation."],
    Print["Install failed."];
    $successQ = False];,

  $successQ = False;
];

Exit[If[$successQ, 0, 1]]
