Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["SetReplaceStyleData"]
PackageExport["WolframPhysicsProjectStyleData"]

(* Documentation *)

SetUsage @ "
SetReplaceStyleData[] yields an association describing default styles used in SetReplace.
SetReplaceStyleData[theme$] gives styles for a particular theme$.
SetReplaceStyleData[plotType$] gives styles for a particular plotType$.
SetReplaceStyleData[plotType$, element$] gives a value for a particular element$ of plotType$.
SetReplaceStyleData[theme$, plotType$, element$] gives a value for the element$ of plotType$ in theme$.
";

SyntaxInformation[SetReplaceStyleData] = {"ArgumentsPattern" -> {theme_., group_., element_.}};

$styleGroupNames = Keys[$styleNames];
$styleElementNames = Catenate[Keys /@ Values @ $styleNames];

With[{
    themesAndGroups = Join[$SetReplacePlotThemes, $styleGroupNames],
    groupsAndElements = Join[$styleGroupNames, $styleElementNames],
    elements = $styleElementNames},
  FE`Evaluate[FEPrivate`AddSpecialArgCompletion[
    "SetReplaceStyleData" -> {themesAndGroups, groupsAndElements, elements}]]];

(* Implementation *)

(* Evaluate needed to get values for PackageScope symbols loaded after style.m *)
SetReplaceStyleData[theme : Alternatives @@ $SetReplacePlotThemes : $lightTheme] :=
  Map[Evaluate, $styleNames /. style[theme], {2}];

SetReplaceStyleData[
    theme : Alternatives @@ $SetReplacePlotThemes : $lightTheme,
    group : Alternatives @@ $styleGroupNames] :=
  Evaluate /@ ($styleNames[group] /. style[theme]);

SetReplaceStyleData[
    theme : Alternatives @@ $SetReplacePlotThemes : $lightTheme,
    group : Alternatives @@ $styleGroupNames,
    element_] /; MemberQ[Keys[$styleNames[group]], element] :=
  $styleNames[group][element] /. style[theme];

SetReplaceStyleData[args___] /;
    !Developer`CheckArgumentCount[SetReplaceStyleData[args], 0, 3] := (
  0 /; False
);

SetReplaceStyleData::invalidArg =
  "The arguments in `1` should be a style theme (optional), a style group, and a style element (optional).";

expr : SetReplaceStyleData[RepeatedNull[_, 3]] := (
  Message[SetReplaceStyleData::invalidArg, Defer[expr]];
  0 /; False
);

(* for compatibility reasons we preserve WolframPhysicsProjectStyleData *)
SetUsage[WolframPhysicsProjectStyleData, "WolframPhysicsProjectStyleData is deprecated. Use SetReplaceStyleData."];
SyntaxInformation[WolframPhysicsProjectStyleData] = SyntaxInformation[SetReplaceStyleData];
Options[WolframPhysicsProjectStyleData] = Options[SetReplaceStyleData];
WolframPhysicsProjectStyleData = SetReplaceStyleData;
