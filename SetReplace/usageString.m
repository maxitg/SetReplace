(* ::Package:: *)

(* ::Title:: *)
(*usageString*)


(* ::Text:: *)
(*A function to create usage strings with correct style for arguments.*)


Package["SetReplace`"]


PackageScope["usageString"]


(* ::Subsection:: *)
(*Argument style definitions*)


argStyle[arg_Integer] := "TR";
argStyle["\[Ellipsis]"] := "TR";
argStyle[str_String] := "TI";


argString[arg_] :=
  "\!\(\*StyleBox[\"" <> ToString[arg] <> "\", \"" <> argStyle[arg] <> "\"]\)"


(* ::Subsection:: *)
(*Implementation*)


usageString[str__] :=
  (StringTemplate[StringJoin[{str}]] /. {TemplateSlot[s_] :> argString[s]})[]
