Package["SetReplace`"]

PackageScope["convexHullPolygon"]

(* Graham scan algorithm, https://en.wikipedia.org/wiki/Graham_scan *)

polarAngle = ArcTan @@ # &;

peekNextToTop[stack_] := With[{
    top = stack["Pop"],
    nextToTop = stack["Peek"]},
  stack["Push", top];
  nextToTop
]

(* Returns a positive value for counterclockwise direction, negative for clockwise, and zero otherwise *)
rotationDirection[pt1_, pt2_, pt3_] :=
  (pt2[[1]] - pt1[[1]]) (pt3[[2]] - pt2[[2]]) - (pt2[[2]] - pt1[[2]]) (pt3[[1]] - pt2[[1]])

convexHullPolygon[points_] := Module[{
    (* Sort is broken for symbolic values in Wolfram Language 12.2 *)
    numericPoints = N[points],
    stack = CreateDataStructure["Stack"],
    center, centeredPoints, counterClockwisePoints, deduplicatedPoints},
  (* find a bottommost point, if multiple, find the leftmost one *)
  center = First[MinimalBy[MinimalBy[numericPoints, Last], First]];
  centeredPoints = # - center & /@ DeleteCases[numericPoints, center, {1}];
  counterClockwisePoints = SortBy[centeredPoints, polarAngle];
  (* if there are multiple points with the same polar angle, pick the farthest *)
  deduplicatedPoints = Values[First /@ MaximalBy[Norm] /@ GroupBy[counterClockwisePoints, polarAngle]];

  Scan[(
    (* pop the last point from the stack if we turn clockwise to reach this point *)
    While[stack["Length"] > 1 && rotationDirection[peekNextToTop[stack], stack["Peek"], #] <= 0, stack["Pop"]];
    stack["Push", #]
  ) &, deduplicatedPoints];

  Polygon[Join[{center}, # + center & /@ Normal[stack]]]
]
