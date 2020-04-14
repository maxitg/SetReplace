Package["SetReplace`"]

PackageExport["WolframPhysicsProjectStyleData"]

(* Documentation *)

WolframPhysicsProjectStyleData::usage = usageString[
  "WolframPhysicsProjectStyleData[] yields an association describing default styles used in Wolfram Physics Project.\n",
  "WolframPhysicsProjectStyleData[`theme`] gives styles for a particular `theme`.\n",
  "WolframPhysicsProjectStyleData[`t`] gives styles for a particular plot type `t`.\n",
  "WolframPhysicsProjectStyleData[`t`, `e`] gives a value for a particular style element `e` of plot type `t`.\n",
  "WolframPhysicsProjectStyleData[`theme`, `t`, `e`] gives a value for an element `e` of plot type `t` for `theme`."];

SyntaxInformation[WolframPhysicsProjectStyleData] = {"ArgumentsPattern" -> {_., _., _.}};

$styleGroupNames = Keys[$styleNames];
$styleElementNames = Catenate[Keys /@ Values @ $styleNames];

With[{
    themesAndGroups = Join[$WolframPhysicsProjectPlotThemes, $styleGroupNames],
    groupsAndElements = Join[$styleGroupNames, $styleElementNames],
    elements = $styleElementNames},
  FE`Evaluate[FEPrivate`AddSpecialArgCompletion[
    "WolframPhysicsProjectStyleData" -> {themesAndGroups, groupsAndElements, elements}]]];

(* Implementation *)

(* Evaluate needed to get values for PackageScope symbols loaded after style.m *)
WolframPhysicsProjectStyleData[theme : Alternatives @@ $WolframPhysicsProjectPlotThemes : $lightTheme] :=
  Map[Evaluate, $styleNames /. style[theme], {2}]

WolframPhysicsProjectStyleData[
    theme : Alternatives @@ $WolframPhysicsProjectPlotThemes : $lightTheme,
    group : Alternatives @@ $styleGroupNames] :=
  Evaluate /@ ($styleNames[group] /. style[theme])

WolframPhysicsProjectStyleData[
    theme : Alternatives @@ $WolframPhysicsProjectPlotThemes : $lightTheme,
    group : Alternatives @@ $styleGroupNames,
    element_] /; MemberQ[Keys[$styleNames[group]], element] :=
  $styleNames[group][element] /. style[theme]

WolframPhysicsProjectStyleData[args___] /;
    !Developer`CheckArgumentCount[WolframPhysicsProjectStyleData[args], 0, 3] := (
  0 /; False
)

WolframPhysicsProjectStyleData::invalidArg =
  "The arguments in `1` should be a style theme (optional), a style group, and a style element (optional).";

expr : WolframPhysicsProjectStyleData[RepeatedNull[_, 3]] := (
  Message[WolframPhysicsProjectStyleData::invalidArg, Defer[expr]];
  0 /; False
)
