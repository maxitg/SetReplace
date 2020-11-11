Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageScope["evolutionVideo"]

(* TODO: use a timescale that will appropriately scale all parameters automatically *)

$initialStateDurationSec = 1;
$stateDurationScalingFunction = 1 / Sqrt[#] &;
$finalStateDurationSec = 5; (* TODO: change to auto-determine stabilization *)
$arrowheadLength = 0.15;
$frameRate = 60;
$newAtomPlacementStandardDeviation = 0.01;
$minElectricalDistance = 0.3; (* the force at smaller distances is the same as for this distance *)
$springStrength = 100;
$electricalStrength = 100;
$frictionStrength = 10;
$plotRangePadding = 0.05;

Options[evolutionVideo] = Join[
  FilterRules[Options[WolframModelPlot], Except[{"HyperedgeRendering", VertexCoordinateRules, "ArrowheadLength"}]],
  "ArrowheadLength" -> $arrowheadLength];

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

(* ModuleScope breaks derivatives (' and Derivative[...]) *)
forceEquations[coordinate_, time_][vertexPairs_, func_] := Module[{directedVertexPairs, equationParts},
  directedVertexPairs = Join[#, Reverse /@ #] & @ vertexPairs;
  equationParts = Catenate[Function[{vertices},
      Thread[coordinate[vertices[[1]]][#]''[time] & /@ {1, 2} ->
             func[coordinate[vertices[[1]]][#][time] & /@ {1, 2}, coordinate[vertices[[2]]][#][time] & /@ {1, 2}]]] /@
    directedVertexPairs];
  Merge[equationParts, Total]
]

springEquationsForState[coordinate_, time_][springStrength_, state_] :=
  forceEquations[coordinate, time][
    (* every part of every hyperedge *)
    Catenate[Partition[#, 2, 1, If[Length[#] > 2, -1, {1, -1}]] & /@ state],
    - springStrength (#1 - #2) &]

(* TODO: the force below is not scaled correctly at small distances *)

electricalEquationsForState[coordinate_, time_][electricalStrength_, state_] :=
  forceEquations[coordinate, time][
    (* all pairs *)
    Subsets[vertexList[state], {2}],
    electricalStrength (#1 - #2) / Max[EuclideanDistance[#1, #2], $minElectricalDistance]^3 &]

frictionEquationsForState[coordinate_, time_][frictionStrength_, state_] :=
  Function[{vertex},
      Thread[coordinate[vertex][#]''[time] & /@ {1, 2} ->
             (- frictionStrength coordinate[vertex][#]'[time] & /@ {1, 2})]] /@ vertexList[state]

springElectricalEquationsForState[coordinate_, time_][
    springStrength_, electricalStrength_, frictionStrength_, state_] := KeyValueMap[Equal, Merge[
  {springEquationsForState[coordinate, time][springStrength, state],
   electricalEquationsForState[coordinate, time][electricalStrength, state],
   frictionEquationsForState[coordinate, time][frictionStrength, state]},
  Total]]

initialConditionEquations[coordinate_, time_][initialCoordinates_, initialVelocities_, initialTime_] :=
  Catenate[Function[{vertex}, Thread[Catenate @ {
      coordinate[vertex][#][initialTime] == initialCoordinates[vertex][[#]] & /@ {1, 2},
      coordinate[vertex][#]'[initialTime] == initialVelocities[vertex][[#]] & /@ {1, 2}}]] /@
    Keys[initialCoordinates]]

vertexTrajectoryVariables[coordinate_, time_][state_] :=
  Catenate[Function[{vertex}, coordinate[vertex][#] & /@ {1, 2}] /@ vertexList[state]]

frameCoordinatesForState[
      frameRate_, springStrength_, electricalStrength_, frictionStrength_][
      {previousCoordinates_, previousVelocities_},
      {state_, inputVertices_, createdVertices_, {startTime_, endTime_}}] := Module[{
    initialCoordinates, initialVelocities, coordinate, time, equationsForDynamics, equationsForInit, variables,
    trajectories, frameTimes, vertices, coordinateLists, finalCoordinates, finalVelocities},
  {initialCoordinates, initialVelocities} =
    initConditionsForStateAnimation[vertexList[state], #, inputVertices, createdVertices] & /@
      {previousCoordinates, previousVelocities};
  equationsForDynamics = springElectricalEquationsForState[
    coordinate, time][springStrength, electricalStrength, frictionStrength, state];
  equationsForInit = initialConditionEquations[coordinate, time][initialCoordinates, initialVelocities, startTime];
  variables = vertexTrajectoryVariables[coordinate, time][state];
  trajectories =
    Association @ First @ NDSolve[{equationsForDynamics, equationsForInit},
                                  variables,
                                  {time, startTime, endTime},
                                  Method -> {"EquationSimplification" -> "Solve"}];
  frameTimes = Range[Ceiling[startTime, 1 / frameRate], Floor[endTime, 1 / frameRate], 1 / frameRate];
  vertices = Keys[initialCoordinates];
  coordinateLists = Function[{time},
      Association[Function[{vertex}, vertex -> (trajectories[coordinate[vertex][#]][time] & /@ {1, 2})] /@ vertices]] /@
    frameTimes;

  (* TODO: These two can be combined into one. *)
  finalCoordinates = Association[
    Function[{vertex}, vertex -> (trajectories[coordinate[vertex][#]][Last[frameTimes]] & /@ {1, 2})] /@ vertices];
  finalVelocities = Association[
    Function[{vertex}, vertex -> (trajectories[coordinate[vertex][#]]'[Last[frameTimes]] & /@ {1, 2})] /@ vertices];
  {coordinateLists (* output *), {finalCoordinates, finalVelocities} (* init for the next step *)}
]

exprToCell[expr_] := Cell[BoxData[ToBoxes[expr]], "Output"]

cellToExportPacket[cell_] := ExportPacket[cell,
                                          "BitmapPacket",
                                          ColorSpace -> RGBColor,
                                          Verbose -> False,
                                          "AlphaChannel" -> False,
                                          "DataCompression" -> True,
                                          ImageResolution -> 144]

exprToExportPacket[expr_] := cellToExportPacket[exprToCell[expr]]

resultToImage[System`ConvertersDump`Bitmap[rawString_, {width_, height_, depth_}, ___]] := ModuleScope[
  bytes = NumericArray[Developer`RawUncompress @ rawString, "Byte"];
  Internal`ArrayReshapeTo[bytes, {height, width, depth}];
  Image[Image`ReverseNumericArray[bytes, False], Interleaving -> True, Magnification -> 0.5]
]

rasterizeList[expr_List] := Map[resultToImage, MathLink`CallFrontEnd @ Map[exprToExportPacket, expr]];

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
  PrintTemporary["WolframModelPlotting..."];

  frames = Catenate[Function[{state, coordinateLists},
      WolframModelPlot[state, VertexCoordinateRules -> Normal[#]] & /@ coordinateLists] @@@
    Transpose[{states, frameCoordinates}]];

  plotRange = CoordinateBounds[Catenate[Transpose /@ PlotRange /@ frames], $plotRangePadding];

  Print["WolframModelPlotting: ", AbsoluteTime[] - startTime, " s"];
  startTime = AbsoluteTime[];
  PrintTemporary["Rasterizing..."];

  rasterizedFrames = rasterizeList[Show[#, PlotRange -> plotRange] & /@ frames];

  Print["Rasterizing: ", AbsoluteTime[] - startTime, " s"];
  startTime = AbsoluteTime[];
  PrintTemporary["Making video..."];

  videosDirectory = FileNameJoin[{$TemporaryDirectory, "SetReplace", "evolutionVideo"}];
  If[!DirectoryQ[videosDirectory], CreateDirectory[videosDirectory]];
  videoHash = Hash[{obj, caller, boundary, o}, "Expression", "Base36String"];
  result = Video @ Export[FileNameJoin[{videosDirectory, videoHash <> ".mp4"}],
                 rasterizedFrames,
                 FrameRate -> $frameRate];

  Print["Making video: ", AbsoluteTime[] - startTime, " s"];
  result,
  RandomSeeding -> {"evolutionVideo"}
]]
