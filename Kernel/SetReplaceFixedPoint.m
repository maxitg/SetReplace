Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["SetReplaceFixedPoint"]

(* Same as SetReplace, but automatically stops replacing when the set no longer changes. *)

SetUsage @ "
SetReplaceFixedPoint[s$, {i$1 -> o$1, i$2 -> o$2, $$}] performs SetReplace repeatedly until \
no further events can be matched, and returns the final set.
Will go into infinite loop if fixed point does not exist.
";

Options[SetReplaceFixedPoint] = {
  Method -> Automatic,
  TimeConstraint -> Infinity,
  "EventOrderingFunction" -> Automatic};

SyntaxInformation[SetReplaceFixedPoint] = {
  "ArgumentsPattern" -> {_, _, OptionsPattern[]},
  "OptionNames" -> Options[SetReplaceFixedPoint][[All, 1]]};

SetReplaceFixedPoint[args___] := 0 /;
  !Developer`CheckArgumentCount[SetReplaceFixedPoint[args], 2, 2] && False;

SetReplaceFixedPoint[set_, rules_, o : OptionsPattern[]] /;
    recognizedOptionsQ[expr, SetReplaceFixedPoint, {o}] := ModuleScope[
  result = Check[
    setSubstitutionSystem[
      rules, set, <||>, SetReplaceFixedPoint, False, o],
    $Failed];
  If[result === $Aborted, result, result[-1]] /; result =!= $Failed
];
