Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["SetReplace"]

(* This function behaves similarly to StringReplace. The implementation is done with WolframModel, which is a more
   general function. *)

SetUsage @ "
SetReplace[set$, {input$1 -> output$1, input$2 -> output$2, $$}] attempts to replace a subset input$1 of set$ with \
output$1. If not found, replaces input$2 with output$2, etc. Elements of input$k can appear in set$ in any order, \
however the elements closest to the beginning of set$ will be replaced, and the elements of output$k will be put at \
the end.
SetReplace[set$, {input$1 -> output$1, input$2 -> output$2, $$}, eventCount$] performs replacement eventCount$ times \
and returns the result.
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

expr : SetReplace[set_, rules_, eventCount : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] /;
    recognizedOptionsQ[expr, SetReplace, {o}] :=
  ModuleScope[
    result = Check[
      setSubstitutionSystem[rules, set, <|$maxEvents -> eventCount|>, SetReplace, False, o]
    ,
      $Failed
    ];
    If[result === $Aborted, result, result[-1]] /; result =!= $Failed
  ];
