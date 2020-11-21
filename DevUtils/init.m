Package["SetReplaceDevUtils`"]

(* SetReplaceDevUtils is *not* included in paclet builds, so is not visible to users,
but is available for developer workflow purposes, and is used by the build scripts *)

PackageExport["$SetReplaceRoot"]
PackageExport["$DevUtilsRoot"]

$SetReplaceRoot = FileNameDrop[$InputFileName, -2];
$DevUtilsRoot = FileNameDrop[$InputFileName, -1];
