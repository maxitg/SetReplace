#!/usr/bin/env wolframscript

Check[
  Get[FileNameJoin[{DirectoryName[$InputFileName], "buildInit.wl"}]];

  copyWLSourceToBuildDirectory[];
  $version = updateVersion[];
  renameContext[Automatic, $version];
  packPaclet[];,

  If[$internalBuild, AntFail, Print]["Paclet packing failed."];
  Exit[1];
]
