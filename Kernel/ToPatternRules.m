Package["SetReplace`"]

PackageExport["ToPatternRules"]

(* Anonymous rules make it easier to specify rules, especially when they involve creation of new vertices (objects).
   The idea is that in an anonymous rule all symbols on the left-hand side are treated as patterns even if they are
   explicitly named.
   Thus, for example, {{1, 2}} -> {{1, 2, 3}} will get translated to {{a_, b_}} :> Module[{$0}, {{a, b, $0}}].
   The anonymous variant is easier to type, and, more importantly, easier to enumerate. *)

PackageScope["anonymousRulesQ"]
PackageScope["toPatternRules"]

ToPatternRules::usage = usageString[
  "ToPatternRules[`r`] converts a list of anonymous rules `r` to explicit pattern rules."];

SyntaxInformation[ToPatternRules] = {"ArgumentsPattern" -> {_}};

(* Argument Checks *)

(* Argument count *)

ToPatternRules[args___] := 0 /;
  !Developer`CheckArgumentCount[ToPatternRules[args], 1, 1] && False

(* Argument is a list of rules or a single rule *)

anonymousRulesQ[rules_] := MatchQ[rules, {___Rule} | _Rule]

toPatternRules[rules_, caller_] := 0 /;
  !anonymousRulesQ[rules] && makeMessage[caller, "notRules", rules]

(* We are going to find all non-lists in the rules, map them to symbols, and then replace original rules with these
   symbols using patterns and modules accordingly. *)

toPatternRules[rule : _Rule, caller_] := Module[
    {leftSymbols, rightSymbols, symbols, newVertexNames, vertexPatterns,
     newLeft, leftVertices, rightVertices, rightOnlyVertices},
  {leftSymbols, rightSymbols} =
    Union[Cases[#, _ ? AtomQ, {0, 1}], Cases[#, _, {2}]] & /@ List @@ rule;
  symbols = DeleteDuplicates @ Join[leftSymbols, rightSymbols];
  newVertexNames =
    ToHeldExpression /@ StringTemplate["v``"] /@ Range @ Length @ symbols;
  vertexPatterns = Pattern[#, Blank[]] & /@ newVertexNames;
  newLeft = (rule[[1]] /. FilterRules[Thread[symbols -> vertexPatterns], leftSymbols]);
  {leftVertices, rightVertices} =
    {leftSymbols, rightSymbols} /. Thread[symbols -> newVertexNames];
  rightOnlyVertices = Complement[rightVertices, leftVertices];
  With[
      {moduleVariables = rightOnlyVertices,
      moduleExpression = Replace[rule[[2]], Thread[symbols -> newVertexNames], {0, 2}]},
    If[moduleVariables =!= {},
      newLeft :> Module[moduleVariables, moduleExpression],
      newLeft :> moduleExpression
    ]
  ] /. Hold[expr_] :> expr
]

toPatternRules[rules : {___Rule}, caller_] :=
  toPatternRules[#, caller] & /@ rules

ToPatternRules[rules_] := Module[{result},
  result = Check[toPatternRules[rules, ToPatternRules], $Failed];
  result /; result =!= $Failed
]
