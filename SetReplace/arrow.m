Package["SetReplace`"]

PackageScope["arrow"]

arrow[shape_, arrowheadLength_, vertexSize_][pts_] := Module[{ptsStartToArrowEnd, ptsStartToLineEnd},
  ptsStartToArrowEnd = lineTake[pts, vertexSize ;; - vertexSize];
  ptsStartToLineEnd = lineTake[ptsStartToArrowEnd, 0 ;; - arrowheadLength];
  {
    Line[ptsStartToLineEnd],
    If[Length[ptsStartToArrowEnd] > 1,
      arrowhead[
        shape,
        Last[ptsStartToArrowEnd],
        Normalize[ptsStartToArrowEnd[[-1]] - ptsStartToLineEnd[[-1]]],
        arrowheadLength],
      Nothing]
  }
]

arrowhead[shape_, endPt_, {0 | 0., 0 | 0.}, length_] := {}

arrowhead[shape_, endPt_, direction_, length_] :=
  (Translate[#, endPt] &) @
  (Rotate[#, {{1, 0}, direction}] &) @
  (Scale[#, length, {0, 0}] &) @
  shape

lineTake[pts_, start_ ;; end_] := Reverse[lineDrop[Reverse[lineDrop[pts, start]], -end]]

lineDrop[pts_, length_] /; Length[pts] > 2 := With[{
    firstSegmentLength = EuclideanDistance @@ pts[[{1, 2}]]},
  If[firstSegmentLength <= length,
    lineDrop[Rest[pts], length - firstSegmentLength],
    Join[lineDrop[pts[[{1, 2}]], length], Drop[pts, 2]]
  ]
]

lineDrop[{pt1_, pt2_}, length_] := {pt1 + Normalize[pt2 - pt1] * length, pt2}

lineDrop[pts : ({_} | {}), _] := pts
