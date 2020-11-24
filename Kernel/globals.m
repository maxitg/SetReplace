Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

(* Note: this is actually set in Kernel/init.m, but it needs to be exported from a new-style package so that
the new-style package loader understands that this is a global symbol *)
PackageExport["$SetReplaceRootDirectory"]

SetUsage @ "
$SetReplaceRootDirectory contains the path of the root of the SetReplace package that was loaded. \
This corresponds to the directory that containts the Kernel/ directory.
"
