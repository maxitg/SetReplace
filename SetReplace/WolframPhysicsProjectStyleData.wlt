<|
  "WolframPhysicsProjectStyleData" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];
    ),
    "tests" -> With[{
        themeExample = First @ $WolframPhysicsProjectPlotThemes,
        elementExample = First @ Keys[WolframPhysicsProjectStyleData[]]}, {
      testSymbolLeak[
        WolframPhysicsProjectStyleData[]
      ],

      testSymbolLeak[
        WolframPhysicsProjectStyleData[elementExample]
      ],
      
      testUnevaluated[
        WolframPhysicsProjectStyleData[themeExample, "VertexSize", 1],
        {WolframPhysicsProjectStyleData::argb}
      ],

      testUnevaluated[
        WolframPhysicsProjectStyleData["$$invalid$$"],
        {WolframPhysicsProjectStyleData::invalidArg}
      ],

      testUnevaluated[
        WolframPhysicsProjectStyleData[themeExample, "$$invalid$$"],
        {WolframPhysicsProjectStyleData::invalidElement}
      ],

      VerificationTest[
        AssociationQ @ WolframPhysicsProjectStyleData[]
      ],

      VerificationTest[
        AssociationQ @ WolframPhysicsProjectStyleData[themeExample]
      ],

      VerificationTest[
        Equal @@ Length /@ WolframPhysicsProjectStyleData /@ $WolframPhysicsProjectPlotThemes
      ],

      VerificationTest[
        Head[WolframPhysicsProjectStyleData[
            First @ $WolframPhysicsProjectPlotThemes, elementExample]] =!=
          WolframPhysicsProjectStyleData
      ],

      VerificationTest[
        Head[WolframPhysicsProjectStyleData[elementExample]] =!=
          WolframPhysicsProjectStyleData
      ],

      VerificationTest[
        MemberQ[
          WolframPhysicsProjectStyleData[],
          WolframPhysicsProjectStyleData[elementExample]]
      ]
    }]
  |>,

  "$WolframPhysicsProjectPlotThemes" -> <|
    "tests" -> {
      VerificationTest[
        ListQ @ $WolframPhysicsProjectPlotThemes
      ],

      VerificationTest[
        Length[$WolframPhysicsProjectPlotThemes] > 0
      ]
    }
  |>
|>
