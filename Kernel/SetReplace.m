Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["SetReplace"]

(* This function behaves similarly to StringReplace. The implementation is done with WolframModel, which is a more
   general function. *)

SetUsage @ "
SetReplace[s$, {i$1 -> o$1, i$2 -> o$2, $$}] attempts to replace a subset i$1 of list s$ with o$1. \
If not found, replaces i$1 with o$2, etc. Elements of i$k can appear in s$ in any order, however the elements \
closest to the beginning of s$ will be replaced, and the elements of o$k will be put at the end.
SetReplace[s$, {i$1 -> o$1, i$2 -> o$2, $$}, n$] performs replacement n$ times and returns the result.
";

Options[SetReplace] = {
  Method -> Automatic,
  TimeConstraint -> Infinity,
  "EventOrderingFunction" -> Automatic};

SyntaxInformation[SetReplace] = {
  "ArgumentsPattern" -> {set_, rules_, eventCount_., OptionsPattern[]},
  "OptionNames" -> Options[SetReplace][[All, 1]]};

SetReplace[args___] := 0 /;
  !Developer`CheckArgumentCount[SetReplace[args], 2, 3] && False;

expr : SetReplace[set_, rules_, events : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] /;
    recognizedOptionsQ[expr, SetReplace, {o}] :=
  ModuleScope[
    result = Check[
      setSubstitutionSystem[rules, set, <|$maxEvents -> events|>, SetReplace, False, o],
      $Failed];
    If[result === $Aborted, result, result[-1]] /; result =!= $Failed
  ];
