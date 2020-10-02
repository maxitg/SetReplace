Package["SetReplace`"]

PackageExport["SetReplaceFixedPoint"]

(* Same as SetReplace, but automatically stops replacing when the set no longer changes. *)

SetReplaceFixedPoint::usage = usageString[
  "SetReplaceFixedPoint[`s`, {\!\(\*SubscriptBox[\(`i`\), \(`1`\)]\) \[Rule] ",
  "\!\(\*SubscriptBox[\(`o`\), \(`1`\)]\), ",
  "\!\(\*SubscriptBox[\(`i`\), \(`2`\)]\) \[Rule] ",
  "\!\(\*SubscriptBox[\(`o`\), \(`2`\)]\), \[Ellipsis]}] performs SetReplace repeatedly ",
  "until no further events can be matched, and returns the final set.",
  "\n",
  "Will go into infinite loop if fixed point does not exist."];

SyntaxInformation[SetReplaceFixedPoint] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};

SetReplaceFixedPoint[args___] := 0 /;
  !Developer`CheckArgumentCount[SetReplaceFixedPoint[args], 2, 2] && False

Options[SetReplaceFixedPoint] = {
  Method -> Automatic,
  TimeConstraint -> Infinity,
  "EventOrderingFunction" -> Automatic};

SetReplaceFixedPoint[set_, rules_, o : OptionsPattern[]] /;
    recognizedOptionsQ[expr, SetReplaceFixedPoint, {o}] := Module[{result},
  result = Check[
    setSubstitutionSystem[
      rules, set, <||>, SetReplaceFixedPoint, False, o],
    $Failed];
  If[result === $Aborted, result, result[-1]] /; result =!= $Failed
]
