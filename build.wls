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
  $context = Replace[
    tryEnvironment["CONTEXT", "SetReplace"], "Version" -> "SetReplace$" <> StringReplace[$version, "." -> "$"]] <> "`";
  If[$context =!= "SetReplace`",
    Print["Building with context ", $context];
    renameContext[$context];
  ];
  updateBuildData[];
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
