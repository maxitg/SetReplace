Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["SetReplaceFixedPoint"]

(* Same as SetReplace, but automatically stops replacing when the set no longer changes. *)

SetUsage @ "
SetReplaceFixedPoint[set$, {input$1 -> output$1, input$2 -> output$2, $$}] performs SetReplace repeatedly until \
no further events can be matched, and returns the final set.
It will go into an infinite loop if a fixed point does not exist.
";

Options[SetReplaceFixedPoint] = {
  Method -> Automatic,
  TimeConstraint -> Infinity,
  "EventOrderingFunction" -> Automatic};

SyntaxInformation[SetReplaceFixedPoint] = {
  "ArgumentsPattern" -> {set_, rules_, OptionsPattern[]},
  "OptionNames" -> Options[SetReplaceFixedPoint][[All, 1]]};

SetReplaceFixedPoint[args___] := 0 /;
  !Developer`CheckArgumentCount[SetReplaceFixedPoint[args], 2, 2] && False;

SetReplaceFixedPoint[set_, rules_, o : OptionsPattern[]] /;
    recognizedOptionsQ[expr, SetReplaceFixedPoint, {o}] := ModuleScope[
  result = Check[
    setSubstitutionSystem[rules, rules, set, <||>, SetReplaceFixedPoint, False, o]
  ,
    $Failed
  ];
  If[result === $Aborted, result, result[-1]] /; result =!= $Failed
];
