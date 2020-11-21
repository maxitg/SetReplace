#!/usr/bin/env wolframscript

$repoRoot = FileNameDrop[$InputFileName];

Check[
  Get[FileNameJoin[{$repoRoot, "scripts", "buildInit.wl"}]];,
  Exit[1];
];

$success = True;

Check[
  $buildDirectory = $repoRoot;
  $builtLibSetReplaceHash = builtLibSetReplaceHash[];
  $libSetReplaceSourceHash = libSetReplaceSourceHash[];
  If[$builtLibSetReplaceHash =!= $libSetReplaceSourceHash,
    buildLibSetReplace[];
    saveBuiltLibSetReplaceHash[$libSetReplaceSourceHash];,

    Print["Using cached libSetReplace: ", $builtLibSetReplaceHash];
  ],

  $success = False;
];

updateBuildData[];

If[$success,
  Print["Build done."];
  Exit[0];,

  Print["Build failed."];
  Exit[1];
];
