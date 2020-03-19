#!/usr/bin/env wolframscript

Check[
  Get[FileNameJoin[{DirectoryName[$InputFileName], "buildInit.wl"}]];

  copyWLSourceToBuildDirectory[];
  $version = updateVersion[];
  $context = renameContext[Automatic, $version];
  packPaclet[$context];,

  If[$internalBuild, AntFail, Print]["Paclet packing failed."];
  Exit[1];
]
