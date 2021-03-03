<|
  "SetReplaceStyleData" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];
    ),
    "tests" -> With[{
        themeExample = First @ $SetReplacePlotThemes,
        groupExample = First @ Keys[SetReplaceStyleData[]],
        elementExample =
          First @ Keys[SetReplaceStyleData[First @ Keys[SetReplaceStyleData[]]]]}, {
      testSymbolLeak[
        SetReplaceStyleData[]
      ],

      testSymbolLeak[
        SetReplaceStyleData[groupExample, elementExample]
      ],

      testUnevaluated[
        SetReplaceStyleData["$$invalid$$"],
        {SetReplaceStyleData::invalidArg}
      ],

      testUnevaluated[
        SetReplaceStyleData["$$invalid$$", "$$invalid$$"],
        {SetReplaceStyleData::invalidArg}
      ],

      testUnevaluated[
        SetReplaceStyleData["$$invalid$$", "$$invalid$$", "$$invalid$$"],
        {SetReplaceStyleData::invalidArg}
      ],

      testUnevaluated[
        SetReplaceStyleData["$$invalid$$", "$$invalid$$", "$$invalid$$", "$$invalid$$"],
        {SetReplaceStyleData::argb}
      ],

      VerificationTest[
        AssociationQ @ SetReplaceStyleData[themeExample]
      ],

      testUnevaluated[
        SetReplaceStyleData[themeExample, "$$invalid$$"],
        {SetReplaceStyleData::invalidArg}
      ],

      testUnevaluated[
        SetReplaceStyleData[themeExample, "$$invalid$$", "$$invalid$$"],
        {SetReplaceStyleData::invalidArg}
      ],

      testUnevaluated[
        SetReplaceStyleData[themeExample, "$$invalid$$", "$$invalid$$", "$$invalid$$"],
        {SetReplaceStyleData::argb}
      ],

      VerificationTest[
        AssociationQ @ SetReplaceStyleData[groupExample]
      ],

      testUnevaluated[
        SetReplaceStyleData[groupExample, "$$invalid$$"],
        {SetReplaceStyleData::invalidArg}
      ],

      testUnevaluated[
        SetReplaceStyleData[groupExample, "$$invalid$$", "$$invalid$$"],
        {SetReplaceStyleData::invalidArg}
      ],

      testUnevaluated[
        SetReplaceStyleData[groupExample, "$$invalid$$", "$$invalid$$", "$$invalid$$"],
        {SetReplaceStyleData::argb}
      ],

      VerificationTest[
        AssociationQ @ SetReplaceStyleData[themeExample, groupExample]
      ],

      testUnevaluated[
        SetReplaceStyleData[themeExample, groupExample, "$$invalid$$"],
        {SetReplaceStyleData::invalidArg}
      ],

      testUnevaluated[
        SetReplaceStyleData[themeExample, groupExample, "$$invalid$$", "$$invalid$$"],
        {SetReplaceStyleData::argb}
      ],

      With[{
          anotherGroupElementExample = First[Complement[
            Union[Catenate[Keys[SetReplaceStyleData[#]] & /@ Keys[SetReplaceStyleData[]]]],
            Keys[SetReplaceStyleData[themeExample, groupExample]]]]},
        testUnevaluated[
          SetReplaceStyleData[
            themeExample,
            groupExample,
            anotherGroupElementExample],
          {SetReplaceStyleData::invalidArg}
        ]],

      VerificationTest[
        SetReplaceStyleData[themeExample, groupExample, elementExample],
        _,
        SameTest -> MatchQ
      ],

      testUnevaluated[
        SetReplaceStyleData[themeExample, groupExample, elementExample, "$$invalid$$"],
        {SetReplaceStyleData::argb}
      ],

      VerificationTest[
        AssociationQ @ SetReplaceStyleData[]
      ],

      VerificationTest[
        Equal @@ Map[Keys, SetReplaceStyleData /@ $SetReplacePlotThemes, {2}]
      ],

      VerificationTest[
        Head[SetReplaceStyleData[
            First @ $SetReplacePlotThemes, groupExample]] =!=
          SetReplaceStyleData
      ],

      VerificationTest[
        Head[SetReplaceStyleData[groupExample]] =!=
          SetReplaceStyleData
      ],

      VerificationTest[
        MemberQ[
          SetReplaceStyleData[],
          SetReplaceStyleData[groupExample]]
      ],

      VerificationTest[
        MemberQ[
          SetReplaceStyleData /@ $SetReplacePlotThemes,
          SetReplaceStyleData[]]
      ],

      VerificationTest[
        Options[
          Graph[{1 -> 2, 2 -> 3, 2 -> 4}, SetReplaceStyleData["CausalGraph", "Options"]],
          {VertexStyle, EdgeStyle}],
        Options[
          SetReplaceStyleData["CausalGraph", "Function"][Graph[{1 -> 2, 2 -> 3, 2 -> 4}]],
          {VertexStyle, EdgeStyle}]
      ],

      (* Backwards compatibility *)
      VerificationTest[
        WolframPhysicsProjectStyleData,
        SetReplaceStyleData
      ]
    }]
  |>,

  "$SetReplacePlotThemes" -> <|
    "tests" -> {
      VerificationTest[
        ListQ @ $SetReplacePlotThemes
      ],

      VerificationTest[
        Length[$SetReplacePlotThemes] > 0
      ],

      (* Backwards compatibility *)
      VerificationTest[
        $WolframPhysicsProjectPlotThemes,
        $SetReplacePlotThemes
      ]
    }
  |>
|>
