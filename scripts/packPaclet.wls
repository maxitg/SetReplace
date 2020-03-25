#!/usr/bin/env wolframscript

Check[
  Get[FileNameJoin[{DirectoryName[$InputFileName], "buildInit.wl"}]];

  copyWLSourceToBuildDirectory[];
  updateVersion[];
  updateBuildData[];
  packPaclet[];,

  If[$internalBuild, AntFail, Print]["Paclet packing failed."];
  Exit[1];
]
