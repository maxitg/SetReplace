Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageScope["evolutionVideo"]

(* TODO: use a timescale that will appropriately scale all parameters automatically *)

$initialStateDurationSec = 1;
$stateDurationScalingFunction = 1 / Sqrt[#] &;
$finalStateDurationSec = 5; (* TODO: change to auto-determine stabilization *)
$arrowheadLength = 0.15;
$frameRate = 60;
$newAtomPlacementStandardDeviation = 0.1;
$minElectricalDistance = 0.001; (* the force at smaller distances is the same as for this distance *)
$springStrength = 100;
$electricalStrength = 100;
$frictionStrength = 10;
$plotRangePadding = 0.05;

Options[evolutionVideo] = Join[
  FilterRules[Options[HypergraphPlot], Except[{"HyperedgeRendering", VertexCoordinateRules, "ArrowheadLength"}]],
  {"ArrowheadLength" -> $arrowheadLength}];

getEventTimes[obj_, boundary_] := ModuleScope[
  statesCount = obj["EventsCount", "IncludeBoundaryEvents" -> boundary] + 1;
  eventIndices = Range[statesCount];
  Join[{0},  (* video starts *)
       $initialStateDurationSec $stateDurationScalingFunction[N[Range[statesCount - 1]]],
       {$finalStateDurationSec}]  (* video ends *)
]

(* TODO: make sure momentum is conserved *)

(* the same function is used for both coordinates and velocities, referred here as values *)
initConditionsForStateAnimation[
    currentStateVertices_, previousValues_, inputVertices_, createdVertices_] := ModuleScope[
  inputVertexValues = previousValues /@ inputVertices;
  eventValues = Mean @ If[Length[inputVertexValues] >= 1,
    inputVertexValues,
    previousValues (* {} -> something rule, we need to put the new vertices somewhere *)
  ];
  createdVertexValues = Association[Thread[createdVertices -> Table[
    eventValues + $newAtomPlacementStandardDeviation RandomVariate[NormalDistribution[0, 1], 2],
    Length[createdVertices]]]];
  Join[KeyTake[previousValues, currentStateVertices], createdVertexValues]
]

diagonalMatrix[{}] := {}
diagonalMatrix[arg_] := DiagonalMatrix[arg]

springConnectivityMatrix[state_] := ModuleScope[
  dimensions = ConstantArray[Length[vertexList[state]], 2];
  fixedDimensionSparseArray = (SparseArray[#, dimensions] &);
  (# - fixedDimensionSparseArray @ diagonalMatrix[Total /@ #]) & @
    fixedDimensionSparseArray @ Normal @ Counts @ (Join[#, Reverse /@ #] &) @ DeleteCases[{v_, v_}] @
      Catenate[If[Length[#] > 2, Partition[#, 2, 1, 1], Partition[#, 2, 1]] & /@ IndexHypergraph @ state]
]

(* TODO: Talk to Rob Knap *)

electricalForceUnscaledFunction = Compile[{{targetCoordinates, _Real, 1}, {x, _Real, 1}, {y, _Real, 1}},
  Total /@ (Outer[# - #2 &, targetCoordinates, targetCoordinates] *
    (1 / ((Outer[# - #2 &, x, x]^2 + Outer[# - #2 &, y, y]^2)^(3/2) + $minElectricalDistance)))
]

electricalForceUnscaled[targetCoordinates_List, x_List, y_List] :=
  electricalForceUnscaledFunction[targetCoordinates, x, y]

springElectricalEquationsForState[x_, y_, vx_, vy_, t_][
    springStrength_, electricalStrength_, frictionStrength_, springMatrix_] := Catenate[{
  #2'[t] == springStrength * springMatrix . #1[t]
          + electricalStrength * electricalForceUnscaled[#1[t], x[t], y[t]]
          - frictionStrength * #2[t],
  #1'[t] == #2[t]
} & @@@ {{x, vx}, {y, vy}}]

initialConditionEquations[x_, y_, vx_, vy_][initialCoordinates_, initialVelocities_, initialTime_] := Catenate[{
  #1[initialTime] == Values[initialCoordinates][[All, #3]],
  #2[initialTime] == Values[initialVelocities][[All, #3]]
} & @@@ {{x, vx, 1}, {y, vy, 2}}]

frameCoordinatesForState[
      frameRate_, springStrength_, electricalStrength_, frictionStrength_][
      {previousCoordinates_, previousVelocities_},
      {state_, inputVertices_, createdVertices_, {startTime_, endTime_}}] := ModuleScope[
  {initialCoordinates, initialVelocities} =
    initConditionsForStateAnimation[vertexList[state], #, inputVertices, createdVertices] & /@
      {previousCoordinates, previousVelocities};
  ScopeVariable[x, y, vx, vy, t];
  equationsForDynamics = springElectricalEquationsForState[x, y, vx, vy, t][
    springStrength, electricalStrength, frictionStrength, springConnectivityMatrix[state]];
  equationsForInit = initialConditionEquations[x, y, vx, vy][initialCoordinates, initialVelocities, startTime];
  variables = {x, y, vx, vy};
  trajectories =
    Association @ First @ NDSolve[
      Join[equationsForDynamics, equationsForInit], variables, {t, startTime, endTime}, AccuracyGoal -> 0.1];
  frameTimes = Range[Ceiling[startTime, 1 / frameRate], Floor[endTime, 1 / frameRate], 1 / frameRate];
  vertices = Keys[initialCoordinates];
  coordinateLists =
    Association[Thread[vertices -> #]] & /@ Transpose[trajectories[#] /@ frameTimes & /@ {x, y}, {3, 1, 2}];

  (* TODO: These two can be combined into one. *)
  finalCoordinates = Association[Thread[vertices -> #]] & @ Transpose[trajectories[#][endTime] & /@ {x, y}];
  finalVelocities = Association[Thread[vertices -> #]] & @ Transpose[trajectories[#][endTime] & /@ {vx, vy}];
  {coordinateLists (* output *), {finalCoordinates, finalVelocities} (* init for the next step *)}
]

evolutionVideo[obj_, caller_, boundary_, o : OptionsPattern[]] := ModuleScope[BlockRandom[
  startTime = AbsoluteTime[];

  eventTimes = getEventTimes[obj, boundary];
  stateTimeIntervals = Partition[Accumulate[eventTimes], 2, 1];
  states = obj["AllEventsStatesList", "IncludeBoundaryEvents" -> boundary];
  stateVertices = vertexList /@ states;
  createdVertices = Join[{{}}, Complement @@@ Reverse /@ Partition[stateVertices, 2, 1]];
  inputVertices = Join[{{}}, vertexList /@ (obj["AllExpressions"][[#]] &) /@
    obj["EventsList", "IncludeBoundaryEvents" -> boundary][[All, 2, 1]]];

  initialCoordinates = Association[hypergraphEmbedding["Ordered", "Polygons", {}][First @ states][[1]]][[All, 1, 1]];
  initialVelocities = 0 initialCoordinates;

  Print["Init: ", AbsoluteTime[] - startTime, " s"];
  startTime = AbsoluteTime[];
  PrintTemporary["Solving equations..."];

  frameCoordinates = FoldPairList[
    frameCoordinatesForState[$frameRate, $springStrength, $electricalStrength, $frictionStrength][#, #2] &,
    {initialCoordinates, initialVelocities},
    Transpose[{states, inputVertices, createdVertices, stateTimeIntervals}]];

  Print["Solving equations: ", AbsoluteTime[] - startTime, " s"];
  startTime = AbsoluteTime[];
  PrintTemporary["HypergraphPlotting..."];

  frames = Catenate[Function[{state, coordinateLists},
      {state, Normal[#], Transpose[PlotRange[HypergraphPlot[state, VertexCoordinateRules -> Normal[#]]]]} & /@
        coordinateLists] @@@
    Transpose[{states, frameCoordinates}]];

  plotRange = CoordinateBounds[Catenate[frames[[All, 3]]], $plotRangePadding];

  Print["HypergraphPlotting: ", AbsoluteTime[] - startTime, " s"];
  startTime = AbsoluteTime[];
  PrintTemporary["Making video..."];

  result = VideoGenerator[
    With[{
        index = Max[1, Round[# $frameRate]]},
      HypergraphPlot[frames[[index, 1]], VertexCoordinateRules -> frames[[index, 2]], PlotRange -> plotRange]] &,
    N[Length[frames] / $frameRate], FrameRate -> $frameRate];

  (* result = VideoGenerator[
    Show[frames[[Max[1, Round[# $frameRate]]]], PlotRange -> plotRange] &,
    N[Length[frames] / $frameRate], FrameRate -> $frameRate]; *)

  Print["Making video: ", AbsoluteTime[] - startTime, " s"];
  result,
  RandomSeeding -> {"evolutionVideo"}
]]
