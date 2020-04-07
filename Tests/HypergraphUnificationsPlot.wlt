<|
  "HypergraphUnificationsPlot" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];
      Global`checkGraphics[args___] := SetReplace`PackageScope`checkGraphics[args];
      Global`graphicsQ[args___] := SetReplace`PackageScope`graphicsQ[args];
    ),
    "tests" -> {
      testSymbolLeak[
        HypergraphUnificationsPlot[{{1, 2}, {2, 3}, {3, 4, 5}}, {{a, b}, {b, c}, {c, d, e}}]
      ],
      
      testUnevaluated[
        HypergraphUnificationsPlot[],
        {HypergraphUnificationsPlot::argrx}
      ],

      testUnevaluated[
        HypergraphUnificationsPlot[1],
        {HypergraphUnificationsPlot::argr}
      ],

      testUnevaluated[
        HypergraphUnificationsPlot[1, 2, 3],
        {HypergraphUnificationsPlot::argrx}
      ],

      testUnevaluated[
        HypergraphUnificationsPlot[{1}, 2],
        {HypergraphUnifications::hypergraphNotList}
      ],

      testUnevaluated[
        HypergraphUnificationsPlot[{1}, {2}],
        {HypergraphUnifications::edgeNotList}
      ],

      testUnevaluated[
        HypergraphUnificationsPlot[{{1, 2, 3}}, {{a, b, c}}, "$$invalid$$" -> 0],
        {OptionValue::nodef}
      ],

      VerificationTest[
        graphicsQ /@ HypergraphUnificationsPlot[{{1}}, {{2}}],
        ConstantArray[True, Length[HypergraphUnifications[{{1}}, {{2}}]]]
      ],

      VerificationTest[
        HypergraphUnificationsPlot[{}, {}, VertexLabels -> Automatic],
        {}
      ],

      testUnevaluated[
        HypergraphUnificationsPlot[{{}}, {{1}}, VertexLabels -> Automatic],
        {HypergraphUnificationsPlot::emptyEdge}
      ],

      testUnevaluated[
        HypergraphUnificationsPlot[{{}}, {{}}, VertexLabels -> Automatic],
        {HypergraphUnificationsPlot::emptyEdge}
      ],

      VerificationTest[
        graphicsQ /@ HypergraphUnificationsPlot[{{1, 2, 3}, {3, 4, 5}}, {{a, b, c}}, VertexSize -> 0.3],
        {True, True}
      ],

      testUnevaluated[
        HypergraphUnificationsPlot[{{1, 2, 3}, {3, 4, 5}}, {{a, b, c}}, VertexSize -> -1],
        {WolframModelPlot::invalidSize}
      ],

      VerificationTest[
        0 < Length @ Cases[
          Cases[
            checkGraphics @ HypergraphUnificationsPlot[{{x, y}, {x, z}}, {{a, b}, {b, c}}, VertexLabels -> Automatic],
            _Text,
            All],
          #,
          All]
      ] & /@ {_Style, _Row, ","},

      VerificationTest[
        Cases[
          Cases[
            checkGraphics @ HypergraphUnificationsPlot[{{x, y}, {x, z}}, {{a, b}, {b, c}}, VertexLabels -> 1],
            _Text,
            All],
          _Style,
          All],
        {}
      ],

      With[{color = RGBColor[0.76, 0.65, 0.73]},
        VerificationTest[
          Length @ Cases[
            checkGraphics @
              HypergraphUnificationsPlot[{{x, y}, {x, z}}, {{a, b}, {b, c}}, EdgeStyle -> color],
            color,
            All] > 0
        ]
      ],

      VerificationTest[
        Greater @@ (
          Length @ Union @ Cases[
              checkGraphics @ HypergraphUnificationsPlot[{{x, y}, {x, z}}, {{a, b}, {b, c}}, EdgeStyle -> #],
              _ ? ColorQ,
              All] & /@
            {Automatic, RGBColor[0.252, 0.351, 0.143]})
      ]
    },
     "options" -> {
       "Parallel" -> False
     }
  |>
|>
