<|
  "WolframPhysicsProjectStyleData" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];
    ),
    "tests" -> With[{
        themeExample = First @ $WolframPhysicsProjectPlotThemes,
        groupExample = First @ Keys[WolframPhysicsProjectStyleData[]],
        elementExample =
          First @ Keys[WolframPhysicsProjectStyleData[First @ Keys[WolframPhysicsProjectStyleData[]]]],
        secondGroupElementExample =
          First @ Keys[WolframPhysicsProjectStyleData[Keys[WolframPhysicsProjectStyleData[]][[2]]]]}, {
      testSymbolLeak[
        WolframPhysicsProjectStyleData[]
      ],

      testSymbolLeak[
        WolframPhysicsProjectStyleData[groupExample, elementExample]
      ],

      testUnevaluated[
        WolframPhysicsProjectStyleData["$$invalid$$"],
        {WolframPhysicsProjectStyleData::invalidArg}
      ],

      testUnevaluated[
        WolframPhysicsProjectStyleData["$$invalid$$", "$$invalid$$"],
        {WolframPhysicsProjectStyleData::invalidArg}
      ],

      testUnevaluated[
        WolframPhysicsProjectStyleData["$$invalid$$", "$$invalid$$", "$$invalid$$"],
        {WolframPhysicsProjectStyleData::invalidArg}
      ],

      testUnevaluated[
        WolframPhysicsProjectStyleData["$$invalid$$", "$$invalid$$", "$$invalid$$", "$$invalid$$"],
        {WolframPhysicsProjectStyleData::argb}
      ],

      VerificationTest[
        AssociationQ @ WolframPhysicsProjectStyleData[themeExample]
      ],

      testUnevaluated[
        WolframPhysicsProjectStyleData[themeExample, "$$invalid$$"],
        {WolframPhysicsProjectStyleData::invalidArg}
      ],

      testUnevaluated[
        WolframPhysicsProjectStyleData[themeExample, "$$invalid$$", "$$invalid$$"],
        {WolframPhysicsProjectStyleData::invalidArg}
      ],

      testUnevaluated[
        WolframPhysicsProjectStyleData[themeExample, "$$invalid$$", "$$invalid$$", "$$invalid$$"],
        {WolframPhysicsProjectStyleData::argb}
      ],

      VerificationTest[
        AssociationQ @ WolframPhysicsProjectStyleData[groupExample]
      ],

      testUnevaluated[
        WolframPhysicsProjectStyleData[groupExample, "$$invalid$$"],
        {WolframPhysicsProjectStyleData::invalidArg}
      ],

      testUnevaluated[
        WolframPhysicsProjectStyleData[groupExample, "$$invalid$$", "$$invalid$$"],
        {WolframPhysicsProjectStyleData::invalidArg}
      ],

      testUnevaluated[
        WolframPhysicsProjectStyleData[groupExample, "$$invalid$$", "$$invalid$$", "$$invalid$$"],
        {WolframPhysicsProjectStyleData::argb}
      ],

      VerificationTest[
        AssociationQ @ WolframPhysicsProjectStyleData[themeExample, groupExample]
      ],

      testUnevaluated[
        WolframPhysicsProjectStyleData[themeExample, groupExample, "$$invalid$$"],
        {WolframPhysicsProjectStyleData::invalidArg}
      ],

      testUnevaluated[
        WolframPhysicsProjectStyleData[themeExample, groupExample, "$$invalid$$", "$$invalid$$"],
        {WolframPhysicsProjectStyleData::argb}
      ],

      testUnevaluated[
        WolframPhysicsProjectStyleData[
          themeExample,
          groupExample,
          secondGroupElementExample],
        {WolframPhysicsProjectStyleData::invalidArg}
      ],

      VerificationTest[
        WolframPhysicsProjectStyleData[themeExample, groupExample, elementExample],
        _,
        SameTest -> MatchQ
      ],

      testUnevaluated[
        WolframPhysicsProjectStyleData[themeExample, groupExample, elementExample, "$$invalid$$"],
        {WolframPhysicsProjectStyleData::argb}
      ],

      VerificationTest[
        AssociationQ @ WolframPhysicsProjectStyleData[]
      ],

      VerificationTest[
        Equal @@ Map[Keys, WolframPhysicsProjectStyleData /@ $WolframPhysicsProjectPlotThemes, {2}]
      ],

      VerificationTest[
        Head[WolframPhysicsProjectStyleData[
            First @ $WolframPhysicsProjectPlotThemes, groupExample]] =!=
          WolframPhysicsProjectStyleData
      ],

      VerificationTest[
        Head[WolframPhysicsProjectStyleData[groupExample]] =!=
          WolframPhysicsProjectStyleData
      ],

      VerificationTest[
        MemberQ[
          WolframPhysicsProjectStyleData[],
          WolframPhysicsProjectStyleData[groupExample]]
      ],

      VerificationTest[
        MemberQ[
          WolframPhysicsProjectStyleData /@ $WolframPhysicsProjectPlotThemes,
          WolframPhysicsProjectStyleData[]]
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
