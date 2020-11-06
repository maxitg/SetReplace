#!/usr/bin/env wolframscript

Check[
  Get[FileNameJoin[{DirectoryName[$InputFileName], "scripts", "buildInit.wl"}]];,

  Exit[1];
];

$success = True;

Check[
  Print["Temporary build directory is ", $buildDirectory];
  $builtLibSetReplaceHash = builtLibSetReplaceHash[];
  $libSetReplaceSourceHash = libSetReplaceSourceHash[];
  If[$builtLibSetReplaceHash =!= $libSetReplaceSourceHash,
    buildLibSetReplace[];
    saveBuiltLibSetReplaceHash[$libSetReplaceSourceHash];,

    Print["Using cached libSetReplace: ", $builtLibSetReplaceHash];
  ],

  $success = False;
];

Check[
  copyWLSourceToBuildDirectory[];
  $version = updateVersion[];
  $context = renameContext[Automatic, $version];
  updateBuildData[];
  packPaclet[$context];,
  Print["Message occurred during build."];
  Exit[1];
];

If[$success,
  Print["Build done."];
  Exit[0];,

  Print["Build failed."];
  Exit[1];
];
