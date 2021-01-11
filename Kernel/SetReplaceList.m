Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["SetReplaceList"]

(* Same as SetReplace, but returns all intermediate steps in a List. *)

SetUsage @ "
SetReplaceList[s$, r$, n$] performs SetReplace n$ times and returns the list of all intermediate results.
";

Options[SetReplaceList] = {
  Method -> Automatic,
  TimeConstraint -> Infinity,
  "EventOrderingFunction" -> Automatic};

SyntaxInformation[SetReplaceList] = {
  "ArgumentsPattern" -> {_, _, _, OptionsPattern[]},
  "OptionNames" -> Options[SetReplaceList][[All, 1]]};

SetReplaceList[args___] := 0 /;
  !Developer`CheckArgumentCount[SetReplaceList[args], 2, 3] && False;

SetReplaceList[set_, rules_, events : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] /;
    recognizedOptionsQ[expr, SetReplaceList, {o}] :=
  ModuleScope[
    result = Check[
      setSubstitutionSystem[rules, set, <|$maxEvents -> events|>, SetReplaceList, False, o],
      $Failed];
    If[result === $Aborted, result, result["SetAfterEvent", #] & /@ Range[0, result["EventsCount"]]] /;
      result =!= $Failed
  ];
