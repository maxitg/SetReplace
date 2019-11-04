Package["SetReplace`"]

(* Messages *)

RulePlot::patternRules =
  "RulePlot for pattern rules `1` is not implemented.";

(* Evaluation *)

WolframModel /: func : RulePlot[WolframModel[args___]] := Module[{result = rulePlot$parse[{args}]},
  If[Head[result] === rulePlot$parse,
    result = $Failed];
  result /; result =!= $Failed
]

(* Arguments parsing *)

rulePlot$parse[{
  rulesSpec_ ? wolframModelRulesSpecQ,
  o : OptionsPattern[] /; unrecognizedOptions[WolframModel, {o}] === {}}] := Module[{},
    If[AssociationQ[rulesSpec],
      Message[RulePlot::patternRules, rulesSpec];
      Return[$Failed]];
    rulePlot[rulesSpec]
]

(* Implementation *)

rulePlot[rule_Rule] := rulePlot[{rule}]

rulePlot[rules_List] := Column[singleRulePlot /@ rules]

singleRulePlot[rule_] := Module[{vertexCoordinateRules, ruleSidePlots},
  vertexCoordinateRules = ruleCoordinateRules[rule];
  roughPlotRange = #2 - #1 & @@ MinMax[vertexCoordinateRules[[All, 2]]];
  vertexSize = computeVertexSize[roughPlotRange];
  arrowheadsSize = computeArrowheadsSize[Length[vertexCoordinateRules], roughPlotRange, vertexSize];
  sharedVertices = sharedRuleVertices[rule];
  ruleSidePlots = hypergraphPlot[
      #,
      "CyclicOpen",
      sharedVertices,
      "SpringElectricalPolygons",
      vertexCoordinateRules,
      None,
      {},
      vertexSize,
      arrowheadsSize] & /@
    List @@ rule;
  plotRange =
    CoordinateBounds[Catenate[List @@ (Transpose[completePlotRange[#]] & /@ ruleSidePlots)], Scaled[0.1]];
  Show[#, PlotRange -> plotRange] & /@ (ruleSidePlots[[1]] -> ruleSidePlots[[2]])
]

ruleCoordinateRules[in_ -> out_] :=
  #[[1]] -> #[[2, 1, 1]] & /@
    hypergraphEmbedding["CyclicOpen", "SpringElectricalEmbedding", {}][If[Length[in] > Length[out], in, out]][[1]]

sharedRuleVertices[in_ -> out_] := Intersection @@ (Catenate /@ {in, out})

(* https://mathematica.stackexchange.com/a/18040 *)
completePlotRange[graphics_] := Last @ Last @ Reap[Rasterize[
  Show[
    graphics,
    Axes -> True,
    Frame -> False,
    Ticks -> ((Sow[{##}]; Automatic) &),
    DisplayFunction -> Identity,
    ImageSize -> 0],
  ImageResolution -> 1]]
