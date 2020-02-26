Package["SetReplace`"]

PackageExport["WolframPhysicsProjectStyleData"]

(* Documentation *)

WolframPhysicsProjectStyleData::usage = usageString[
  "WolframPhysicsProjectStyleData[] yields an association describing default styles used in Wolfram Physics Project.\n",
  "WolframPhysicsProjectStyleData[`theme`] gives styles for a particular `theme`.\n",
  "WolframPhysicsProjectStyleData[`e`] gives a value for a particular style element `e`.\n",
  "WolframPhysicsProjectStyleData[`theme`, `e`] gives a value for an element `e` of `theme`."];

SyntaxInformation[WolframPhysicsProjectStyleData] = {"ArgumentsPattern" -> {_. _.}};

With[{themesAndElements = Join[$WolframPhysicsProjectPlotThemes, $styleElements], elements = $styleElements},
  FE`Evaluate[FEPrivate`AddSpecialArgCompletion["WolframPhysicsProjectStyleData" -> {themesAndElements, elements}]]];

(* Implementation *)

(* Evaluate needed to get values for PackageScope symbols loaded after style.m *)
WolframPhysicsProjectStyleData[theme : Alternatives @@ $WolframPhysicsProjectPlotThemes : $lightTheme] :=
  Evaluate /@ style[theme]

WolframPhysicsProjectStyleData[
    theme : Alternatives @@ $WolframPhysicsProjectPlotThemes : $lightTheme, element : Alternatives @@ $styleElements] :=
  WolframPhysicsProjectStyleData[theme][element]

WolframPhysicsProjectStyleData[args___] /;
    !Developer`CheckArgumentCount[WolframPhysicsProjectStyleData[args], 0, 2] := (
  0 /; False
)

WolframPhysicsProjectStyleData::invalidArg = "The first argument `1` should be either a plot theme or a style element.";

WolframPhysicsProjectStyleData[
    arg : Except[Alternatives @@ Join[$WolframPhysicsProjectPlotThemes, $styleElements]], ___] := (
  Message[WolframPhysicsProjectStyleData::invalidArg, arg];
  0 /; False
)

WolframPhysicsProjectStyleData::invalidElement = "The second argument `1` should be a style element.";

WolframPhysicsProjectStyleData[
    theme : Alternatives @@ $WolframPhysicsProjectPlotThemes, el : Except[Alternatives @@ $styleElements]] := (
  Message[WolframPhysicsProjectStyleData::invalidElement, el];
  0 /; False
)
