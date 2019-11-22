<|
  "WolframModel" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];

      $namingTestModel = {
        {{0, 1}, {0, 2}, {0, 3}} ->
          {{4, 5}, {5, 4}, {4, 6}, {6, 4}, {5, 6},
            {6, 5}, {4, 1}, {5, 2}, {6, 3}, {1, 6}, {3, 4}},
        {{0, 0},
        {0, 0}, {0, 0}},
        5,
        "FinalState"};

      $timeConstraintRule = {{1, 2}} -> {{1, 3}, {3, 2}};
      $timeConstraintInit = {{0, 0}};
    ),
    "tests" -> {
      (* Argument checks *)

      (** Argument counts, simple rule and inits **)

      testUnevaluated[
        WolframModel,
        {}
      ],

      testUnevaluated[
        WolframModel[],
        {WolframModel::argb}
      ],

      testUnevaluated[
        WolframModel[x],
        {}
      ],

      testUnevaluated[
        WolframModel[x, y],
        {WolframModel::invalidRules}
      ],

      testUnevaluated[
        WolframModel[x, y, z],
        {WolframModel::invalidRules}
      ],

      testUnevaluated[
        WolframModel[x, y, z, w],
        {WolframModel::invalidRules}
      ],

      testUnevaluated[
        WolframModel[x, y, z, w, a],
        {WolframModel::argb}
      ],

      testUnevaluated[
        WolframModel[x, y, z, w, a, b],
        {WolframModel::argb}
      ],

      testUnevaluated[
        WolframModel[f -> 3],
        {WolframModel::argb}
      ],

      testUnevaluated[
        WolframModel[x, f -> 3],
        {}
      ],

      testUnevaluated[
        WolframModel[x, y, f -> 3],
        {WolframModel::invalidRules}
      ],

      testUnevaluated[
        WolframModel[x, y, z, f -> 3],
        {WolframModel::invalidRules}
      ],

      testUnevaluated[
        WolframModel[x, y, z, w, f -> 3],
        {WolframModel::invalidRules}
      ],

      testUnevaluated[
        WolframModel[x, y, z, w, a, f -> 3],
        {WolframModel::argb}
      ],

      testUnevaluated[
        WolframModel[x, y, z, w, a, b, f -> 3],
        {WolframModel::argb}
      ],

      testUnevaluated[
        WolframModel[1 -> 2],
        {}
      ],

      testUnevaluated[
        WolframModel[1 -> 2, f -> 2],
        {WolframModel::optx}
      ],

      testUnevaluated[
        WolframModel[1 -> 2, f -> 2][1],
        {WolframModel::optx}
      ],

      testUnevaluated[
        WolframModel[1 -> 2, f -> 2][{1}],
        {WolframModel::optx}
      ],

      testUnevaluated[
        WolframModel[1 -> 2, Method -> "LowLevel"][{1}],
        {WolframModel::lowLevelNotImplemented}
      ],

      testUnevaluated[
        WolframModel[1 -> 2, Method -> "$$$InvalidMethod$$$"][{1}],
        {WolframModel::invalidMethod}
      ],

      testUnevaluated[
        WolframModel[1 -> 2, 4],
        {WolframModel::invalidState}
      ],

      testUnevaluated[
        WolframModel[1 -> 2, 4, g -> 2],
        {WolframModel::invalidState}
      ],

      testUnevaluated[
        WolframModel[1 -> 2][4],
        {WolframModel::invalidState}
      ],

      testUnevaluated[
        WolframModel[1 -> 2, g -> 2][4],
        {WolframModel::optx}
      ],

      testUnevaluated[
        WolframModel[1 -> 2][4, g -> 2],
        {WolframModel::argx}
      ],

      VerificationTest[
        WolframModel[1 -> 2][{1}],
        {_ ? AtomQ},
        SameTest -> MatchQ
      ],

      VerificationTest[
        WolframModel[1 -> 2, {1}],
        _WolframModelEvolutionObject,
        SameTest -> MatchQ
      ],

      testUnevaluated[
        WolframModel[1 -> 2, f -> 2][{1}],
        {WolframModel::optx}
      ],

      testUnevaluated[
        WolframModel[1 -> 2][{1}, f -> 2],
        {WolframModel::argx}
      ],

      testUnevaluated[
        WolframModel[1 -> 2][{1}, x],
        {WolframModel::argx}
      ],

      testUnevaluated[
        WolframModel[1 -> 2, x][{1}],
        {WolframModel::invalidState}
      ],

      testUnevaluated[
        WolframModel[1 -> 2, Method -> "$$$InvalidMethod$$$"][{1}],
        {WolframModel::invalidMethod}
      ],

      VerificationTest[
        WolframModel[1 -> 2, Method -> "Symbolic"][{1}],
        {_ ? AtomQ},
        SameTest -> MatchQ
      ],

      testUnevaluated[
        WolframModel[1 -> 2][{1}, Method -> "Symbolic"],
        {WolframModel::argx}
      ],

      testUnevaluated[
        WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{0, 0}}, 100, TimeConstraint -> #],
        {WolframModel::timc}
      ] & /@ {0, -1, "x"},

      (** PatternRules **)

      VerificationTest[
        WolframModel[<|"PatternRules" -> 1 -> 2|>][{1}],
        {2}
      ],

      testUnevaluated[
        WolframModel[<|"PatternRule" -> 1 -> 2|>],
        {}
      ],

      testUnevaluated[
        WolframModel[<|"PatternRule" -> 1 -> 2|>][{1}],
        {}
      ],

      testUnevaluated[
        WolframModel[<|"PatternRules" -> 1 -> 2, "f" -> 2|>],
        {}
      ],

      testUnevaluated[
        WolframModel[<|"PatternRules" -> 1 -> 2, "f" -> 2|>][{1}],
        {}
      ],

      testUnevaluated[
        WolframModel[<|"PatternRules" -> 1 -> 2|>],
        {}
      ],

      VerificationTest[
        WolframModel[<|"PatternRules" -> {1 -> 2, a_ :> Module[{b}, b]}|>][{1}],
        {2}
      ],

      VerificationTest[
        WolframModel[<|"PatternRules" -> {1 -> 2, a_ :> Module[{b}, b]}|>][{2}],
        {_ ? AtomQ},
        SameTest -> MatchQ
      ],

      VerificationTest[
        WolframModel[<|"PatternRules" -> {1 -> 2, a_ :> Module[{b}, b]}|>, {1}],
        _WolframModelEvolutionObject,
        SameTest -> MatchQ
      ],

      testUnevaluated[
        WolframModel[<|"PatternRules" -> {1 -> 2, a_ :> Module[{b}, b]}|>, {1}, x],
        {WolframModel::invalidSteps}
      ],

      (** Steps **)

      (*** Generations and Events ***)

      VerificationTest[
        WolframModel[1 -> 2, {1}, 2]["GenerationsCount"],
        2
      ],

      testUnevaluated[
        WolframModel[1 -> 2, {1}, 2, x],
        {WolframModel::invalidProperty}
      ],

      testUnevaluated[
        WolframModel[1 -> 2, {1}, 2.2],
        {WolframModel::invalidSteps}
      ],

      testUnevaluated[
        WolframModel[1 -> 2, {1}, "sdfsdf"],
        {WolframModel::invalidSteps}
      ],

      VerificationTest[
        WolframModel[1 -> 2, {1}, 0]["EventsCount"],
        0
      ],

      testUnevaluated[
        WolframModel[1 -> 2, {1}, -1],
        {WolframModel::invalidSteps}
      ],

      VerificationTest[
        WolframModel[{{0, 1}} -> {{0, 2}, {2, 1}}, {{0, 1}}, 3] /@ {"GenerationsCount", "EventsCount"},
        {3, 7}
      ],

      VerificationTest[
        WolframModel[{{0, 1}} -> {{0, 2}, {2, 1}}, {{0, 1}}, <|"MaxGenerations" -> 3|>] /@
          {"GenerationsCount", "EventsCount"},
        {3, 7}
      ],

      VerificationTest[
        WolframModel[{{0, 1}} -> {{0, 2}, {2, 1}}, {{0, 1}}, <|"MaxEvents" -> 6|>] /@
          {"GenerationsCount", "EventsCount"},
        {3, 6}
      ],

      VerificationTest[
        WolframModel[{{0, 1}} -> {{0, 2}, {2, 1}}, {{0, 1}}, <|"MaxGenerations" -> 3, "MaxEvents" -> 6|>] /@
          {"GenerationsCount", "EventsCount"},
        {3, 6}
      ],

      VerificationTest[
        WolframModel[{{0, 1}} -> {{0, 2}, {2, 1}}, {{0, 1}}, <|"MaxGenerations" -> 2, "MaxEvents" -> 6|>] /@
          {"GenerationsCount", "EventsCount"},
        {2, 3}
      ],

      VerificationTest[
        WolframModel[{{0, 1}, {1, 2}} -> {{0, 2}}, {{0, 1}, {1, 2}, {2, 3}, {3, 4}}, <||>] /@
          {"GenerationsCount", "EventsCount"},
        {2, 3}
      ],

      testUnevaluated[
        WolframModel[{{0, 1}, {1, 2}} -> {{0, 2}}, {{0, 1}, {1, 2}, {2, 3}, {3, 4}}, <|"x" -> 2|>],
        {WolframModel::invalidSteps}
      ],

      testUnevaluated[
        WolframModel[
          {{0, 1}, {1, 2}} -> {{0, 2}},
          {{0, 1}, {1, 2}, {2, 3}, {3, 4}},
          <|"x" -> 2, "MaxGenerations" -> 2|>],
        {WolframModel::invalidSteps}
      ],

      VerificationTest[
        WolframModel[{{0, 1}} -> {{0, 2}, {2, 1}}, {{0, 1}}, <|"MaxGenerations" -> \[Infinity], "MaxEvents" -> 12|>] /@
          {"GenerationsCount", "EventsCount"},
        {4, 12}
      ],

      (*** MaxVertices ***)

      Table[With[{method = method, $simpleGrowingRule = {{1, 2}} -> {{1, 3}, {3, 2}}, $simpleGrowingInit = {{1, 1}}}, {
        testUnevaluated[
          WolframModel[$simpleGrowingRule, $simpleGrowingInit, <|"MaxVertices" -> x|>, Method -> method],
          {WolframModel::invalidSteps}
        ],

        testUnevaluated[
          WolframModel[$simpleGrowingRule, $simpleGrowingInit, <|"MaxVertices" -> 0|>, Method -> method],
          {WolframModel::tooSmallStepLimit}
        ],

        VerificationTest[
          WolframModel[$simpleGrowingRule, $simpleGrowingInit, <|"MaxVertices" -> #1|>, "FinalState", Method -> method],
          #2
        ] & @@@ {{1, {{1, 1}}}, {2, {{1, 2}, {2, 1}}}, {3, {{2, 1}, {1, 3}, {3, 2}}}},

        VerificationTest[
          WolframModel[
            $simpleGrowingRule,
            $simpleGrowingInit,
            <|"MaxVertices" -> Infinity, "MaxEvents" -> 100|>,
            "EventsCount",
            Method -> method],
          100
        ],

        testUnevaluated[
          WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, #1, <|"MaxVertices" -> #2|>, "FinalState", Method -> method],
          {WolframModel::tooSmallStepLimit}
        ] & @@@ {{{{1, 2}}, 1}, {{{1, 2}, {2, 3}}, 2}},

        VerificationTest[
          WolframModel[
            {{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 2}, {2, 3}}, <|"MaxVertices" -> 3|>, "FinalState", Method -> method],
          {{1, 2}, {2, 3}}
        ],

        VerificationTest[
          WolframModel[
            {{1, 2}} -> {{1, 2}, {2, 2}},
            {{1, 2}, {2, 3}},
            <|"MaxVertices" -> 3, "MaxEvents" -> 100|>,
            "EventsCount",
            Method -> method],
          100
        ],

        VerificationTest[
          WolframModel[
            {{1, 2}} -> {{1, 2}, {2, 3}, {3, 4}},
            {{1, 1}},
            <|"MaxVertices" -> #|>,
            "AtomsCountFinal",
            Method -> method] & /@ Range[20],
          {1, 1, 3, 3, 5, 5, 7, 7, 9, 9, 11, 11, 13, 13, 15, 15, 17, 17, 19, 19}
        ],

        VerificationTest[
          WolframModel[
            {{1, 2}} -> {{1, 3}}, {{1, 2}},
            <|"MaxVertices" -> 2, "MaxEvents" -> 100|>,
            "EventsCount",
            Method -> method],
          100
        ],

        VerificationTest[
          WolframModel[
            {{{1, 2}} -> {{1, 2, 3, 4, 5, 6}}, {{1, 2, 3, 4, 5, 6}} -> {{1, 2}, {2, 6}}},
            {{1, 2}},
            <|"MaxVertices" -> #|>,
            "EventsCount",
            Method -> method] & /@ Range[2, 11],
          {0, 0, 0, 0, 2, 3, 3, 3, 3, 7}
        ],

        testUnevaluated[
          WolframModel[{1, 2} -> {1, 3, 3, 2}, {1, 2, 2, 3}, <|"MaxVertices" -> #|>, "FinalState", Method -> method],
          {WolframModel::nonListExpressions}
        ] & /@ {3, Infinity, 0}
      }], {method, DeleteCases[$SetReplaceMethods, Automatic]}],

      With[{$incrementingRule = <|"PatternRules" -> {{a_}} :> {a + 1, a + 2}|>}, {
        testUnevaluated[
          WolframModel[$incrementingRule, {1}, <|"MaxVertices" -> 4|>, "FinalState"],
          {WolframModel::nonListExpressions}
        ],
      
        VerificationTest[
          WolframModel[$incrementingRule, {{{{{{{{{1}}}}}}}}}, <|"MaxVertices" -> 12|>, "AtomsCountFinal"],
          6
        ],

        testUnevaluated[
          WolframModel[$incrementingRule, {{{{{{{{{1}}}}}}}}}, <|"MaxVertices" -> 13|>, "FinalState"],
          {WolframModel::nonListExpressions}
        ],

        VerificationTest[
          WolframModel[$incrementingRule, {{{{{{{{{1}}}}}}}}}, <||>, "AtomsCountFinal"],
          9
        ],

        testUnevaluated[
          WolframModel[$incrementingRule, {{{{{{{{{1}}}}}}}}}, <|"MaxVertices" -> DirectedInfinity[1]|>, "FinalState"],
          {WolframModel::nonListExpressions}
        ]
      }],

      VerificationTest[
        WolframModel[
          <|"PatternRules" -> {{f[a_, x], f[b_, x]}} :> Module[{c}, {{f[a, x], f[c, x]}, {f[c, x], f[b, x]}}]|>,
          {{f[1, x], f[1, x]}},
          <|"MaxVertices" -> 4|>,
          "ExpressionsCountFinal"],
        4
      ],

      VerificationTest[
        WolframModel[
          <|"PatternRules" -> {{{a_, x}, {b_, x}}} :> Module[{c}, {{{a, x}, {c, x}}, {{c, x}, {b, x}}}]|>,
          {{{1, x}, {1, x}}},
          <|"MaxVertices" -> 4|>,
          "ExpressionsCountFinal"],
        4
      ],

      VerificationTest[
        WolframModel[
          <|"PatternRules" -> {{$1_, $2_}} :> Module[{$3}, {{$1, $3}, {$3, $2}}]|>,
          {{1, 1}},
          <|"MaxVertices" -> 30|>,
          "AtomsCountFinal"],
        30
      ],

      VerificationTest[
        WolframModel[
          <|"PatternRules" ->
            {{{$1_, $11_}, {$2_, $22_}}} :> Module[{$3, $33}, {{{$1, $11}, {$3, $33}}, {{$3, $33}, {$2, $22}}}]|>,
          {{{1, 2}, {1, 2}}},
          <|"MaxVertices" -> 30|>,
          "AtomsCountFinal"],
        60
      ],

      (** Properties **)

      VerificationTest[
        WolframModel[1 -> 2, {1}, 2, "CausalGraph"],
        Graph[{1, 2}, {1 -> 2}]
      ],

      testUnevaluated[
        WolframModel[1 -> 2, {1}, 2, "123"],
        {WolframModel::invalidProperty}
      ],

      testUnevaluated[
        WolframModel[1 -> 2, {1}, 2, "Generation"],
        {WolframModel::invalidProperty}
      ],

      VerificationTest[
        WolframModel[1 -> 2, {1}, 2, #] & /@ $WolframModelProperties // Length,
        Length[$WolframModelProperties]
      ],

      VerificationTest[
        WolframModel[1 -> 2, {1}, 2, $WolframModelProperties] // Length,
        WolframModel[1 -> 2, {1}, 2, #] & /@ $WolframModelProperties // Length
      ],

      testUnevaluated[
        WolframModel[1 -> 2, {1}, 2, 2],
        {WolframModel::invalidProperty}
      ],

      testUnevaluated[
        WolframModel[1 -> 2, {1}, 2, {2, 3}],
        {WolframModel::invalidProperty}
      ],

      testUnevaluated[
        WolframModel[1 -> 2, {1}, 2, {"CausalGraph", 3}],
        {WolframModel::invalidProperty}
      ],

      testUnevaluated[
        WolframModel[1 -> 2, {1}, 2, {3, "CausalGraph"}],
        {WolframModel::invalidProperty}
      ],

      VerificationTest[
        WolframModel[1 -> 2, {1}, 2, {"CausalGraph", "CausalGraph"}],
        ConstantArray[Graph[{1, 2}, {1 -> 2}], 2]
      ],

      testUnevaluated[
        WolframModel[1 -> 2, {1}, 2, "Rules"],
        {WolframModel::invalidProperty}
      ],

      testUnevaluated[
        WolframModel[1 -> 2, {1}, 2, "Properties"],
        {WolframModel::invalidProperty}
      ],

      (** Missing arguments **)

      testUnevaluated[
        WolframModel[1 -> 2, {1}, 1 -> 2, 2 -> 3],
        {WolframModel::invalidSteps}
      ],

      testUnevaluated[
        WolframModel[1 -> 2, {1}, "sdfds" -> 2, "xcvxcv" -> 3],
        {WolframModel::optx}
      ],

      testUnevaluated[
        WolframModel[{1}, 1 -> 2],
        {WolframModel::invalidRules}
      ],

      testUnevaluated[
        WolframModel[1, 1 -> 2],
        {WolframModel::invalidRules}
      ],

      testUnevaluated[
        WolframModel[1 -> 2, "CausalGraph"],
        {WolframModel::invalidState}
      ],

      VerificationTest[
        WolframModel[1 -> 2, {1}, "CausalGraph"],
        Graph[{1}, {}]
      ],

      testUnevaluated[
        WolframModel[1 -> 2, {1}, "CausalGraph", 1],
        {WolframModel::invalidSteps}
      ],

      testUnevaluated[
        WolframModel[1 -> 2, 1, "CausalGraph"],
        {WolframModel::invalidState}
      ],

      (* Implementation *)

      (** Simple examples **)

      VerificationTest[
        WolframModel[{1} -> {1}, {1}]["EventsCount"],
        1
      ],

      VerificationTest[
        WolframModel[<|"PatternRules" -> (1 -> 2)|>, {1, 2, 3}][-1],
        {2, 3, 2}
      ],

      VerificationTest[
        WolframModel[<|"PatternRules" -> (2 -> 5)|>, {1, 2, 3}][-1],
        {1, 3, 5}
      ],

      VerificationTest[
        WolframModel[<|"PatternRules" -> (2 :> 5)|>, {1, 2, 3}][-1],
        {1, 3, 5}
      ],

      VerificationTest[
        WolframModel[<|"PatternRules" -> {2 :> 5, 3 :> 6}|>, {1, 2, 3}][-1],
        {1, 5, 6}
      ],

      VerificationTest[
        WolframModel[<|"PatternRules" -> {2 -> 5, 3 :> 6}|>, {1, 2, 3}][-1],
        {1, 5, 6}
      ],

      VerificationTest[
        WolframModel[<|"PatternRules" -> {2 -> 5, 3 :> 6}|>, {1, 2, 3}, 2]["GenerationsCount"],
        1
      ],

      VerificationTest[
        WolframModel[<|"PatternRules" -> {2 -> 5, 3 :> 6}|>, {1, 2, 3}, 2][-1],
        {1, 5, 6}
      ],

      VerificationTest[
        WolframModel[<|"PatternRules" -> ({3, 2} -> 5)|>, {1, 2, 3}][-1],
        {1, 5}
      ],

      VerificationTest[
        WolframModel[<|"PatternRules" -> (4 -> 5)|>, {1, 2, 3}]["EventsCount"],
        0
      ],

      VerificationTest[
        WolframModel[<|"PatternRules" -> ({{1}} :> {})|>, {{1}}][-1],
        {}
      ],

      VerificationTest[
        WolframModel[<|"PatternRules" -> ({{1}} :> {})|>, {{1}}, Method -> "LowLevel"][-1],
        {}
      ],

      VerificationTest[
        WolframModel[<|"PatternRules" -> ({{1}} :> {})|>, {{1}}, Method -> "Symbolic"][-1],
        {}
      ],

      VerificationTest[
        WolframModel[<|"PatternRules" -> ({{1}} :> {})|>, {{1}}, Method -> Automatic][-1],
        {}
      ],

      VerificationTest[
        WolframModel[<|"PatternRules" -> ({{1}, {2}} :> {{3}})|>, {{1}, {2}}][-1],
        {{3}}
      ],

      VerificationTest[
        WolframModel[<|"PatternRules" -> ({{1}, {2}} :> {{3}})|>, {{2}, {1}}][-1],
        {{3}}
      ],

      VerificationTest[
        WolframModel[
          <|"PatternRules" -> ({x_List ? (Length[#] == 3 &), y_List ? (Length[#] == 6 &)} :> {x, y, Join[x, y]})|>,
          {"This" -> "that", {2, 3, 4}, {2, 5}, {1, 2, 3, 4, 5, 6}},
          2][0],
        {"This" -> "that", {2, 3, 4}, {2, 5}, {1, 2, 3, 4, 5, 6}}
      ],

      VerificationTest[
        WolframModel[
          <|"PatternRules" -> ({x_List ? (Length[#] == 3 &), y_List ? (Length[#] == 6 &)} :> {x, y, Join[x, y]})|>,
          {"This" -> "that", {2, 3, 4}, {2, 5}, {1, 2, 3, 4, 5, 6}},
          2][-1],
        {"This" -> "that",
          {2, 5},
          {2, 3, 4, 1, 2, 3, 4, 5, 6},
          {2, 3, 4},
          {1, 2, 3, 4, 5, 6},
          {2, 3, 4, 1, 2, 3, 4, 5, 6}}
      ],

      VerificationTest[
        WolframModel[
          <|"PatternRules" -> ({x_List /; (Length[x] == 3), y_List /; (Length[y] == 6)} :> {x, y, Join[x, y]})|>,
          {"This" -> "that", {2, 3, 4}, {2, 5}, {1, 2, 3, 4, 5, 6}},
          2][0],
        {"This" -> "that", {2, 3, 4}, {2, 5}, {1, 2, 3, 4, 5, 6}}
      ],

      VerificationTest[
        WolframModel[
          <|"PatternRules" -> ({x_List /; (Length[x] == 3), y_List /; (Length[y] == 6)} :> {x, y, Join[x, y]})|>,
          {"This" -> "that", {2, 3, 4}, {2, 5}, {1, 2, 3, 4, 5, 6}},
          2][-1],
        {"This" -> "that",
          {2, 5},
          {2, 3, 4, 1, 2, 3, 4, 5, 6},
          {2, 3, 4},
          {1, 2, 3, 4, 5, 6},
          {2, 3, 4, 1, 2, 3, 4, 5, 6}}
      ],

      VerificationTest[
        WolframModel[<|"PatternRules" -> ({{a_, b_}, {b_, c_}} :> {{a, c}})|>, {{1, 2}, {2, 3}, {3, 4}, {4, 5}}, 2][1],
        {{1, 3}, {3, 5}}
      ],

      VerificationTest[
        WolframModel[<|"PatternRules" -> ({{a_, b_}, {b_, c_}} :> {{a, c}})|>, {{1, 2}, {2, 3}, {3, 4}, {4, 5}}, 2][1],
        WolframModel[<|"PatternRules" -> ({{a_, b_}, {b_, c_}} :> {{a, c}})|>, {{1, 2}, {2, 3}, {3, 4}, {4, 5}}, 1][-1]
      ],

      VerificationTest[
        WolframModel[<|"PatternRules" -> ({{a_, b_}, {b_, c_}} :> {{a, c}})|>, {{1, 2}, {2, 3}, {3, 4}, {4, 5}}, 2][-1],
        {{1, 5}}
      ],

      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 2}}, 10]["GenerationsCount"],
        10
      ],

      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 2}}, 10]["EventsCount"],
        1023
      ],

      VerificationTest[
        WolframModel[{{1}} -> {}, {{1}, {2}, {3}, {4}, {5}}, Infinity]["GenerationsCount"],
        1
      ],

      VerificationTest[
        WolframModel[{{1}} -> {}, {{1}, {2}, {3}, {4}, {5}}, Infinity]["EventsCount"],
        5
      ],

      VerificationTest[
        WolframModel[{{1}} -> {}, {{1}, {2}, {3}, {4}, {5}}, Infinity][-1],
        {}
      ],

      VerificationTest[
        WolframModel[{{1}} -> {{1}}, {{1}, {2}, {3}, {4}, {5}}, 0]["GenerationsCount"],
        0
      ],

      VerificationTest[
        WolframModel[{{1}} -> {{1}}, {{1}, {2}, {3}, {4}, {5}}, 0]["EventsCount"],
        0
      ],

      VerificationTest[
        WolframModel[
          {{{1}} -> {}, {{1, 2}} -> {{1}}},
          {{1, 2}, {2}, {3}, {4}, {5}},
          2]["GenerationsCount"],
        2
      ],

      VerificationTest[
        WolframModel[
          {{{1}} -> {}, {{1, 2}} -> {{1}}},
          {{1, 2}, {2}, {3}, {4}, {5}},
          2]["EventsCount"],
        6
      ],

      VerificationTest[
        WolframModel[
          <|"PatternRules" -> {{{1}} -> {{2}}}|>,
          {{1}, {1}, {1}},
          1,
          Method -> "LowLevel"],
        WolframModel[
          <|"PatternRules" -> {{{1}} -> {{2}}}|>,
          {{1}, {1}, {1}},
          1,
          Method -> "Symbolic"]
      ],

      VerificationTest[
        WolframModel[
          {{v[1], v[2]}, {v[2], v[3]}} -> {{v[1], v[3]}},
          {{v[1], v[2]}, {v[2], v[3]}},
          "FinalState",
          Method -> "Symbolic"],
        {{v[1], v[3]}}
      ],

      VerificationTest[
        WolframModel[
          {{v[1], v[2]}, {v[2], v[3]}} -> {{v[1], v[3]}},
          {{v[1], v[2]}, {v[2], v[3]}},
          "FinalState",
          Method -> "LowLevel"],
        {{v[1], v[3]}}
      ],

      (** Nested lists as vertices **)

      VerificationTest[
        Head[
          WolframModel[
            {{{2, 2, 1}, {2, 2, 2}} -> {{1, 1, 3}, {1, 1, 1}, {2, 1, 2}, {3, 3, 2}}}, {Table[{0, 0, 0}, 3]}, 2]],
        WolframModelEvolutionObject
      ],

      VerificationTest[
        WolframModel[
          {{{2, 2, 1}, {2, 2, 2}} -> {{1, 1, 3}, {1, 1, 1}, {2, 1, 2}, {3, 3, 2}}},
          {{{2}, {2}, 1}, {{2}, {2}, {2}}},
          1,
          "FinalState",
          Method -> #],
        {{1, 1, 2}, {1, 1, 1}, {{2}, 1, {2}}, {2, 2, {2}}}
      ] & /@ $SetReplaceMethods,

      VerificationTest[
        WolframModel[{{{1, 1, 1}} -> {{1, 1, 1, 1}}}, {Table[{0, 0, 0}, 3]}, 2, "FinalState", Method -> #],
        {ConstantArray[{0, 0, 0}, 4]}
      ] & /@ $SetReplaceMethods,

      (** NodeNamingFunction **)

      VerificationTest[
        WolframModel[
          {{1, 3}} -> {{1, 2}, {2, 3}},
          {{0, 0}},
          2,
          "FinalState"],
        WolframModel[
          {{1, 3}} -> {{1, 2}, {2, 3}},
          {{0, 0}},
          2,
          "FinalState",
          "NodeNamingFunction" -> Automatic]
      ],

      VerificationTest[
        WolframModel[
          {{1, 3}} -> {{1, 2}, {2, 3}},
          {{0, 0}},
          2,
          "FinalState",
          "NodeNamingFunction" -> Automatic],
        {{0, 2}, {2, 1}, {1, 3}, {3, 0}}
      ],

      VerificationTest[
        WolframModel[
          {{1, 3}} -> {{1, 2}, {2, 3}},
          {{2, 2}},
          2,
          "FinalState",
          "NodeNamingFunction" -> Automatic],
        {{2, 3}, {3, 1}, {1, 4}, {4, 2}}
      ],

      VerificationTest[
        WolframModel[
          {{1, 3}} -> {{1, 2}, {2, 3}},
          {{0, 0}},
          2,
          "FinalState",
          "NodeNamingFunction" -> All],
        {{1, 3}, {3, 2}, {2, 4}, {4, 1}}
      ],

      VerificationTest[
        WolframModel[
          {{1, 3}} -> {{1, 2}, {2, 3}},
          {{0, 0}},
          2,
          "FinalState",
          "NodeNamingFunction" -> None],
        {{0, x_Symbol}, {x_Symbol, y_Symbol}, {y_Symbol, z_Symbol}, {z_Symbol, 0}},
        SameTest -> MatchQ
      ],

      VerificationTest[
        WolframModel[
          <|"PatternRules" -> {{a_, b_}} :> Module[{c}, {{a, c}, {c, b}}]|>,
          {{0, 0}},
          2,
          "FinalState",
          "NodeNamingFunction" -> All],
        {{1, 3}, {3, 2}, {2, 4}, {4, 1}}
      ],

      VerificationTest[
        WolframModel[
          <|"PatternRules" -> {{a_, b_}} :> Module[{c}, {{a, c}, {c, b}}]|>,
          {{0, 0}},
          2,
          "FinalState",
          "NodeNamingFunction" -> #],
        {{0, x_Symbol}, {x_Symbol, y_Symbol}, {y_Symbol, z_Symbol}, {z_Symbol, 0}},
        SameTest -> MatchQ
      ] & /@ {Automatic, None},

      VerificationTest[
        WolframModel[
          <|"PatternRules" -> {{a_, b_}} :> Module[{c}, {{a, c}, {c, b}}]|>,
          {{0, 0}},
          2,
          "FinalState"],
        {{0, x_Symbol}, {x_Symbol, y_Symbol}, {y_Symbol, z_Symbol}, {z_Symbol, 0}},
        SameTest -> MatchQ
      ],

      With[{namingTestModel = $namingTestModel}, {
        VerificationTest[
          # == Range[Length[#]] & @ Union @ Flatten[
            WolframModel[##, "NodeNamingFunction" -> All] & @@
              namingTestModel]
        ],

        VerificationTest[
          # == Range[0, Length[#] - 1] & @ Union @ Flatten[
            WolframModel[##, "NodeNamingFunction" -> Automatic] & @@
              namingTestModel]
        ],

        VerificationTest[
          (#[[1]] /. Thread[Rule @@ Flatten /@ #]) == #[[2]] & @ (Table[
            WolframModel[##, "NodeNamingFunction" -> namingFunction] & @@ namingTestModel,
            {namingFunction, {All, None}}])
        ]
      }],

      (*** For anonymous rules, all level-2 expressions must be atomized, similar to ToPatternRules behavior ***)
      VerificationTest[
        WolframModel[
          {{s[1], s[2]}} -> {{s[1], s[3]}, {s[3], s[2]}},
          {{s[1], s[2]}},
          1,
          "FinalState",
          "NodeNamingFunction" -> All],
        {{1, 3}, {3, 2}}
      ],

      (** TimeConstraint **)

      With[{timeConstraintRule = $timeConstraintRule, timeConstraintInit = $timeConstraintInit}, {
        (*** Check that aborted evaluation still produces correct evolutions. ***)
        Table[With[{method = method, time = time}, VerificationTest[
          And @@ Table[
            With[{
                output =
                  WolframModel[timeConstraintRule, timeConstraintInit, 100, Method -> method, TimeConstraint -> time]},
              WolframModel[timeConstraintRule, timeConstraintInit, <|"MaxEvents" -> output["EventsCount"]|>] ===
                output],
            100]
        ]], {method, $SetReplaceMethods}, {time, {1.*^-100, 0.1}}],

        (*** This does not work with TimeConstrained though, $Aborted is returned in that case. ***)
        VerificationTest[
          TimeConstrained[WolframModel[timeConstraintRule, timeConstraintInit, 100, Method -> #], 0.1],
          $Aborted
        ] & /@ $SetReplaceMethods,

        (*** $Aborted should be returned if not an evolution object is asked for. ***)
        VerificationTest[
          WolframModel[timeConstraintRule, timeConstraintInit, 100, "FinalState", Method -> #, TimeConstraint -> 0.1],
          $Aborted
        ] & /@ $SetReplaceMethods
      }]
    }
  |>,

  "$SetReplaceMethods" -> <|
    "tests" -> {
      VerificationTest[
        ListQ[$SetReplaceMethods]
      ],

      VerificationTest[
        AllTrue[
          $SetReplaceMethods,
          SetReplace[{{0}}, {{0}} -> {{1}}, Method -> #] === {{1}} &]
      ]
    }
  |>,

  "$WolframModelProperties" -> <|
    "tests" -> {
      VerificationTest[
        ListQ[$WolframModelProperties]
      ],

      VerificationTest[
        AllTrue[
          $WolframModelProperties,
          Head[WolframModel[{{0}} -> {{1}}, {{0}}, 1, #]] =!= WolframModel &]
      ]
    }
  |>
|>
