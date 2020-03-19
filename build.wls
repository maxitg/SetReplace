#!/usr/bin/env wolframscript

Check[
	Get[FileNameJoin[{DirectoryName[$InputFileName], "scripts", "buildInit.wl"}]];
	deleteBuildDirectory[];,

	Exit[1];
];

$success = True;

Check[
	buildLibSetReplace[];,

	$success = False;
];

Check[
  copyWLSourceToBuildDirectory[];
  $version = updateVersion[];
  renameContext[Automatic, $version];
  packPaclet[];
  deleteBuildDirectory[];,

  Exit[1];
];

If[$success,
	Print["Build done."];
	Exit[0];,

  Print["Build failed."];
	Exit[1];
];
