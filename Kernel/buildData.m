(* The backtick magic is necessary to prevent it being interpreted as a beginning of a template argument. *)
Package["SetReplace<*"`"*>"]

PackageExport["$SetReplaceGitSHA"]
PackageExport["$SetReplaceBuildTime"]

$SetReplaceGitSHA::usage = usageString[
  "$SetReplaceGitSHA gives the Git SHA of the repository from which SetReplace was built."];

$SetReplaceBuildTime::usage = usageString[
  "$SetReplaceBuildTime gives the date object at which SetReplace was built."];

(* This is a template file. Data is inserted at build time. *)

$SetReplaceGitSHA = <*ToString[gitSHA[], InputForm]*>; (* gitSHA[] is defined in buildInit.wl *)
$SetReplaceBuildTime = <*ToString[DateObject[TimeZone -> "UTC"], InputForm]*>;
