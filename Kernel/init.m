Unprotect["SetReplace`*"];

ClearAll @@ (# <> "*" & /@ Contexts["SetReplace`*"]);

SetReplace`$SetReplaceBaseDirectory = FileNameDrop[$InputFileName, -2];

Block[
  {GeneralUtilities`Control`PackagePrivate`$DesugaringRules = {	
      HoldPattern[$Unreachable] :> Unreachable[$LHSHead],
	    HoldPattern[ReturnFailed[msg_String, args___]] :> ReturnFailed[MessageName[$LHSHead, msg], args],
	    HoldPattern[ReturnFailure[msg_String, args___]] :> ReturnFailure[MessageName[$LHSHead, msg], args]
  }},
  Get[FileNameJoin[{SetReplace`$SetReplaceBaseDirectory, "Kernel", "usageString.m"}]];
];

SetAttributes[#, {Protected, ReadProtected}] & /@ Evaluate @ Names @ "SetReplace`*";
