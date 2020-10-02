Package["SetReplace`"]

PackageScope["usageString"]

(* A function to create usage strings with correct style for arguments. *)

argStyle[arg_Integer] := "TR";
argStyle["\[Ellipsis]"] := "TR";
argStyle[str_String] := "TI";

argString[arg_] :=
  "\!\(\*StyleBox[\"" <> ToString[arg] <> "\", \"" <> argStyle[arg] <> "\"]\)"

usageString[str__] :=
  (StringTemplate[StringJoin[{str}]] /. {TemplateSlot[s_] :> argString[s]})[]
