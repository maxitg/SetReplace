<|
  "WolframModel" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];

      $interestingRule = {{0, 1}, {0, 2}, {0, 3}} ->
        {{4, 5}, {5, 4}, {4, 6}, {6, 4}, {5, 6},
          {6, 5}, {4, 1}, {5, 2}, {6, 3}, {1, 6}, {3, 4}};
      $interestingInit = {{0, 0}, {0, 0}, {0, 0}};

      $namingTestModel = {$interestingRule, $interestingInit, 5, "FinalState"};

      $timeConstraintRule = {{1, 2}} -> {{1, 3}, {3, 2}};
      $timeConstraintInit = {{0, 0}};

      maxVertexDegree[set_] := Max[Counts[Catenate[Union /@ set]]];
    ),
    "tests" -> {
      (* Symbol Leak *)

      testSymbolLeak[
        WolframModel[
          {{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 5, "FinalState", Method -> #1, "VertexNamingFunction" -> #2]
      ] & @@@ Tuples[{$SetReplaceMethods, {Automatic, All}}],

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
        WolframModel[1 -> 2, {1}, 2]["TotalGenerationsCount"],
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
        WolframModel[{{0, 1}} -> {{0, 2}, {2, 1}}, {{0, 1}}, 3] /@ {"TotalGenerationsCount", "EventsCount"},
        {3, 7}
      ],

      VerificationTest[
        WolframModel[{{0, 1}} -> {{0, 2}, {2, 1}}, {{0, 1}}, <|"MaxGenerations" -> 3|>] /@
          {"TotalGenerationsCount", "EventsCount", "TerminationReason"},
        {3, 7, "MaxGenerations"}
      ],

      VerificationTest[
        WolframModel[{{0, 1}} -> {{0, 2}, {2, 1}}, {{0, 1}}, <|"MaxEvents" -> 6|>] /@
          {"TotalGenerationsCount", "EventsCount", "TerminationReason"},
        {3, 6, "MaxEvents"}
      ],

      VerificationTest[
        WolframModel[{{0, 1}} -> {{0, 2}, {2, 1}}, {{0, 1}}, <|"MaxGenerations" -> 3, "MaxEvents" -> 6|>] /@
          {"TotalGenerationsCount", "EventsCount", "TerminationReason"},
        {3, 6, "MaxGenerations" | "MaxEvents"},
        SameTest -> MatchQ
      ],

      VerificationTest[
        WolframModel[{{0, 1}} -> {{0, 2}, {2, 1}}, {{0, 1}}, <|"MaxGenerations" -> 2, "MaxEvents" -> 6|>] /@
          {"TotalGenerationsCount", "EventsCount", "TerminationReason"},
        {2, 3, "MaxGenerations"}
      ],

      VerificationTest[
        WolframModel[{{0, 1}, {1, 2}} -> {{0, 2}}, {{0, 1}, {1, 2}, {2, 3}, {3, 4}}, <||>] /@
          {"TotalGenerationsCount", "EventsCount", "TerminationReason"},
        {2, 3, "FixedPoint"}
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
          {"TotalGenerationsCount", "EventsCount", "TerminationReason"},
        {4, 12, "MaxEvents"}
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
          WolframModel[
            $simpleGrowingRule,
            $simpleGrowingInit,
            <|"MaxVertices" -> #1|>,
            {"FinalState", "TerminationReason"},
            Method -> method],
          {#2, "MaxVertices"}
        ] & @@@ {{1, {{1, 1}}}, {2, {{1, 2}, {2, 1}}}, {3, {{2, 1}, {1, 3}, {3, 2}}}},

        VerificationTest[
          WolframModel[
            $simpleGrowingRule,
            $simpleGrowingInit,
            <|"MaxVertices" -> Infinity, "MaxEvents" -> 100|>,
            {"EventsCount", "TerminationReason"},
            Method -> method],
          {100, "MaxEvents"}
        ],

        testUnevaluated[
          WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, #1, <|"MaxVertices" -> #2|>, "FinalState", Method -> method],
          {WolframModel::tooSmallStepLimit}
        ] & @@@ {{{{1, 2}}, 1}, {{{1, 2}, {2, 3}}, 2}},

        VerificationTest[
          WolframModel[
            {{1, 2}} -> {{1, 3}, {3, 2}},
            {{1, 2}, {2, 3}},
            <|"MaxVertices" -> 3|>,
            {"FinalState", "TerminationReason"},
            Method -> method],
          {{{1, 2}, {2, 3}}, "MaxVertices"}
        ],

        VerificationTest[
          WolframModel[
            {{1, 2}} -> {{1, 2}, {2, 2}},
            {{1, 2}, {2, 3}},
            <|"MaxVertices" -> 3, "MaxEvents" -> 100|>,
            {"EventsCount", "TerminationReason"},
            Method -> method],
          {100, "MaxEvents"}
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
            {"EventsCount", "TerminationReason"},
            Method -> method],
          {100, "MaxEvents"}
        ],

        VerificationTest[
          WolframModel[
            {{{1, 2}} -> {{1, 2, 3, 4, 5, 6}}, {{1, 2, 3, 4, 5, 6}} -> {{1, 2}, {2, 6}}},
            {{1, 2}},
            <|"MaxVertices" -> #|>,
            "EventsCount",
            Method -> method] & /@ Range[2, 11],
          {0, 0, 0, 0, 2, 3, 3, 3, 3, 7}
        ]
      }], {method, DeleteCases[$SetReplaceMethods, Automatic]}],

      testUnevaluated[
        WolframModel[{1, 2} -> {1, 3, 3, 2}, {1, 2, 2, 3}, <|"MaxVertices" -> #|>, "FinalState"],
        {WolframModel::nonListExpressions}
      ] & /@ {3, Infinity, 0},

      With[{$incrementingRule = <|"PatternRules" -> {{a_}} :> {a + 1, a + 2}|>}, {
        testUnevaluated[
          WolframModel[$incrementingRule, {1}, <|"MaxVertices" -> 4|>, "FinalState"],
          {WolframModel::nonListExpressions}
        ],
      
        VerificationTest[
          WolframModel[
            $incrementingRule, {{{{{{{{{1}}}}}}}}}, <|"MaxVertices" -> 12|>, {"AtomsCountFinal", "TerminationReason"}],
          {6, "MaxVertices"}
        ],

        testUnevaluated[
          WolframModel[$incrementingRule, {{{{{{{{{1}}}}}}}}}, <|"MaxVertices" -> 13|>, "FinalState"],
          {WolframModel::nonListExpressions}
        ],

        VerificationTest[
          WolframModel[$incrementingRule, {{{{{{{{{1}}}}}}}}}, <||>, {"AtomsCountFinal", "TerminationReason"}],
          {9, "FixedPoint"}
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
          {"ExpressionsCountFinal", "TerminationReason"}],
        {4, "MaxVertices"}
      ],

      VerificationTest[
        WolframModel[
          <|"PatternRules" -> {{{a_, x}, {b_, x}}} :> Module[{c}, {{{a, x}, {c, x}}, {{c, x}, {b, x}}}]|>,
          {{{1, x}, {1, x}}},
          <|"MaxVertices" -> 4|>,
          {"ExpressionsCountFinal", "TerminationReason"}],
        {4, "MaxVertices"}
      ],

      VerificationTest[
        WolframModel[
          <|"PatternRules" -> {{$1_, $2_}} :> Module[{$3}, {{$1, $3}, {$3, $2}}]|>,
          {{1, 1}},
          <|"MaxVertices" -> 30|>,
          {"AtomsCountFinal", "TerminationReason"}],
        {30, "MaxVertices"}
      ],

      VerificationTest[
        WolframModel[
          <|"PatternRules" ->
            {{{$1_, $11_}, {$2_, $22_}}} :> Module[{$3, $33}, {{{$1, $11}, {$3, $33}}, {{$3, $33}, {$2, $22}}}]|>,
          {{{1, 2}, {1, 2}}},
          <|"MaxVertices" -> 30|>,
          {"AtomsCountFinal", "TerminationReason"}],
        {60, "MaxVertices"}
      ],

      (*** MaxEdges ***)

      Table[With[{method = method, $simpleGrowingRule = {{1, 2}} -> {{1, 3}, {3, 2}}, $simpleGrowingInit = {{1, 1}}}, {
        testUnevaluated[
          WolframModel[$simpleGrowingRule, $simpleGrowingInit, <|"MaxEdges" -> x|>, Method -> method],
          {WolframModel::invalidSteps}
        ],

        testUnevaluated[
          WolframModel[$simpleGrowingRule, $simpleGrowingInit, <|"MaxEdges" -> 0|>, Method -> method],
          {WolframModel::tooSmallStepLimit}
        ],

        VerificationTest[
          WolframModel[
            $simpleGrowingRule,
            $simpleGrowingInit,
            <|"MaxEdges" -> #1|>,
            {"FinalState", "TerminationReason"},
            Method -> method],
          {#2, "MaxEdges"}
        ] & @@@ {{1, {{1, 1}}}, {2, {{1, 2}, {2, 1}}}, {3, {{2, 1}, {1, 3}, {3, 2}}}},

        VerificationTest[
          WolframModel[
            $simpleGrowingRule,
            $simpleGrowingInit,
            <|"MaxEdges" -> Infinity, "MaxEvents" -> 100|>,
            {"EventsCount", "TerminationReason"},
            Method -> method],
          {100, "MaxEvents"}
        ],

        testUnevaluated[
          WolframModel[$simpleGrowingRule, #1, <|"MaxEdges" -> #2|>, "FinalState", Method -> method],
          {WolframModel::tooSmallStepLimit}
        ] & @@@ {{{{1, 2}, {2, 3}}, 1}, {{{1, 2}, {2, 3}, {3, 4}}, 2}},

        VerificationTest[
          WolframModel[
            {{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 2}, {2, 3}, {3, 4}},
            <|"MaxEdges" -> 3|>,
            {"FinalState", "TerminationReason"},
            Method -> method],
          {{{1, 2}, {2, 3}, {3, 4}}, "MaxEdges"}
        ],

        VerificationTest[
          WolframModel[
            {{1, 2}} -> {{3, 4}},
            {{1, 2}, {2, 3}},
            <|"MaxEdges" -> 3, "MaxEvents" -> 100|>,
            {"EventsCount", "TerminationReason"},
            Method -> method],
          {100, "MaxEvents"}
        ],

        VerificationTest[
          WolframModel[
            {{1, 2}} -> {{1, 2}, {1, 2}, {2, 3}},
            {{1, 1}},
            <|"MaxEdges" -> #|>,
            "ExpressionsCountFinal",
            Method -> method] & /@ Range[20],
          {1, 1, 3, 3, 5, 5, 7, 7, 9, 9, 11, 11, 13, 13, 15, 15, 17, 17, 19, 19}
        ],

        VerificationTest[
          WolframModel[
            {{{1, 2}, {2, 3}} -> {{1, 2, 3, 4, 5, 6}, {1, 4}, {1, 4}, {4, 6}},
              {{1, 2, 3, 4, 5, 6}, {1, 4}} -> {{1, 6}}},
            {{1, 2}, {2, 3}},
            <|"MaxEdges" -> #|>,
            "EventsCount",
            Method -> method] & /@ Range[2, 11],
          {0, 0, 2, 4, 6, 8, 10, 12, 14, 16}
        ]
      }], {method, DeleteCases[$SetReplaceMethods, Automatic]}],

      VerificationTest[
        WolframModel[{1, 2} -> {1, 3, 3, 2}, {1, 2, 2, 3}, <|"MaxEdges" -> 6|>, {"FinalState", "TerminationReason"}],
        {{2, 3, 1, 4, 4, 2}, "MaxEdges"}
      ],

      With[{$incrementingRule = <|"PatternRules" -> {{a_}} :> {a + 1, a + 2}|>}, {
        VerificationTest[
          WolframModel[$incrementingRule, {{1}}, <|"MaxEdges" -> 2|>, {"FinalState", "TerminationReason"}],
          {{2, 3}, "FixedPoint"}
        ],

        VerificationTest[
          WolframModel[
            $incrementingRule,
            {{{{{{{{{1}}}}}}}}},
            <|"MaxEdges" -> 12|>,
            {"ExpressionsCountFinal", "TerminationReason"}],
          {12, "MaxEdges"}
        ]
      }],

      (** MaxVertexDegree **)

      Table[With[{
          method = method,
          $simpleGrowingRule = {{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}},
          $simpleGrowingInit = {{1, 1}},
          maxVertexDegree = maxVertexDegree}, {
        testUnevaluated[
          WolframModel[$simpleGrowingRule, $simpleGrowingInit, <|"MaxVertexDegree" -> x|>, Method -> method],
          {WolframModel::invalidSteps}
        ],

        testUnevaluated[
          WolframModel[$simpleGrowingRule, $simpleGrowingInit, <|"MaxVertexDegree" -> 0|>, Method -> method],
          {WolframModel::tooSmallStepLimit}
        ],

        VerificationTest[
          WolframModel[
            $simpleGrowingRule,
            $simpleGrowingInit,
            <|"MaxVertexDegree" -> #1|>,
            {"FinalState", "TerminationReason"},
            Method -> method],
          {#2, "MaxVertexDegree"}
        ] & @@@ {
          {1, {{1, 1}}},
          {2, {{1, 1}}},
          {3, {{1, 2}, {1, 2}, {2, 1}}},
          {4, {{1, 2}, {2, 1}, {1, 3}, {1, 3}, {3, 2}}}},

        VerificationTest[
          WolframModel[
            $simpleGrowingRule,
            $simpleGrowingInit,
            <|"MaxVertexDegree" -> Infinity, "MaxEvents" -> 100|>,
            {"EventsCount", "TerminationReason"},
            Method -> method],
          {100, "MaxEvents"}
        ],

        testUnevaluated[
          WolframModel[
            {{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, #, <|"MaxVertexDegree" -> #2|>, "FinalState", Method -> method],
          {WolframModel::tooSmallStepLimit}
        ] & @@@ {{{{1, 2}, {1, 3}}, 1}, {{{1, 2}, {1, 3}, {1, 4}}, 2}},

        VerificationTest[
          WolframModel[
            {{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 2}, {1, 3}, {1, 4}},
            <|"MaxVertexDegree" -> 3|>,
            {"FinalState", "TerminationReason"},
            Method -> method],
          {{{1, 2}, {1, 3}, {1, 4}}, "MaxVertexDegree"}
        ],

        VerificationTest[
          WolframModel[
            {{1, 2}} -> {{1, 3}, {3, 2}},
            {{1, 1}},
            <|"MaxVertexDegree" -> #, "MaxEvents" -> 100|>,
            {"EventsCount", "TerminationReason"},
            Method -> method] & /@ {1, 2},
          {{0, "MaxVertexDegree"}, {100, "MaxEvents"}}
        ],

        VerificationTest[
          maxVertexDegree @ WolframModel[
            {{1, 2}} -> {{1, 3}, {1, 4}, {1, 5}},
            {{1, 1}},
            <|"MaxVertexDegree" -> #|>,
            "FinalState",
            Method -> method] & /@ Range[20],
          {1, 1, 3, 3, 5, 5, 7, 7, 9, 9, 11, 11, 13, 13, 15, 15, 17, 17, 19, 19}
        ],

        VerificationTest[
          WolframModel[
            {{1, 2}} -> {{1, 3}},
            {{1, 2}, {1, 3}},
            <|"MaxVertexDegree" -> 2, "MaxEvents" -> 100|>,
            {"EventsCount", "TerminationReason"},
            Method -> method],
          {100, "MaxEvents"}
        ],

        VerificationTest[
          WolframModel[
            {{{1, 2}} -> {{1, 2, 3}, {1, 3, 4}, {1, 4, 5}}, {{1, 2, 3}, {1, 3, 4}} -> {{1, 2}, {3, 4}}},
            {{1, 2}},
            <|"MaxVertexDegree" -> #|>,
            "EventsCount",
            Method -> method] & /@ Range[1, 5],
          {0, 0, 2, 6, 14}
        ]
      }], {method, DeleteCases[$SetReplaceMethods, Automatic]}],

      testUnevaluated[
        WolframModel[{1, 2} -> {1, 3, 3, 2}, {1, 2, 2, 3}, <|"MaxVertexDegree" -> #|>, "FinalState"],
        {WolframModel::nonListExpressions}
      ] & /@ {3, Infinity, 0},

      With[{$incrementingRule = <|"PatternRules" -> {{a_}} :> {a + 1, a + 2}|>, maxVertexDegree = maxVertexDegree}, {
        testUnevaluated[
          WolframModel[$incrementingRule, {1}, <|"MaxVertexDegree" -> 4|>, "FinalState"],
          {WolframModel::nonListExpressions}
        ],
      
        VerificationTest[
          maxVertexDegree[
            WolframModel[$incrementingRule, {{{{{{{{{1}}}}}}}}}, <|"MaxVertexDegree" -> 34|>, "FinalState"]],
          34
        ],

        testUnevaluated[
          WolframModel[$incrementingRule, {{{{{{{{{1}}}}}}}}}, <|"MaxVertexDegree" -> 35|>, "FinalState"],
          {WolframModel::nonListExpressions}
        ],

        testUnevaluated[
          WolframModel[$incrementingRule, {{{{{{{{{1}}}}}}}}}, <|"MaxVertexDegree" -> DirectedInfinity[1]|>],
          {WolframModel::nonListExpressions}
        ]
      }],

      VerificationTest[
        WolframModel[
          <|"PatternRules" -> {{f[a_, x], f[b_, x]}} :> Module[{c}, {{f[a, x], f[b, x]}, {f[b, x], f[c, x]}}]|>,
          {{f[1, x], f[1, x]}},
          <|"MaxVertexDegree" -> 4|>,
          {"ExpressionsCountFinal", "TerminationReason"}],
        {8, "MaxVertexDegree"}
      ],

      VerificationTest[
        WolframModel[
          <|"PatternRules" -> {{{a_, x}, {b_, x}}} :> Module[{c}, {{{a, x}, {b, x}}, {{b, x}, {c, x}}}]|>,
          {{{1, x}, {1, x}}},
          <|"MaxVertexDegree" -> 4|>,
          {"ExpressionsCountFinal", "TerminationReason"}],
        {8, "MaxVertexDegree"}
      ],

      (*** Multiple stop conditions ***)

      Function[method, With[{
          model = Sequence[{{1, 2}, {1, 3}} -> {{1, 3}, {1, 4}, {2, 4}, {3, 4}}, {{1, 1}, {1, 1}}],
          maxVertexDegree = maxVertexDegree}, {
        VerificationTest[
          WolframModel[
            model,
            <|"MaxGenerations" -> 5, "MaxEvents" -> 41, "MaxVertices" -> 42, "MaxEdges" -> 84, "MaxVertexDegree" -> 9|>,
            {"TotalGenerationsCount", "TerminationReason"},
            Method -> method],
          {5, "MaxGenerations"}
        ],

        VerificationTest[
          WolframModel[
            model,
            <|"MaxGenerations" -> 6, "MaxEvents" -> 40, "MaxVertices" -> 42, "MaxEdges" -> 84, "MaxVertexDegree" -> 9|>,
            {"EventsCount", "TerminationReason"},
            Method -> method],
          {40, "MaxEvents"}
        ],

        VerificationTest[
          WolframModel[
            model,
            <|"MaxGenerations" -> 6, "MaxEvents" -> 41, "MaxVertices" -> 41, "MaxEdges" -> 84, "MaxVertexDegree" -> 9|>,
            {"AtomsCountFinal", "TerminationReason"},
            Method -> method],
          {41, "MaxVertices"}
        ],

        VerificationTest[
          WolframModel[
            model,
            <|"MaxGenerations" -> 6, "MaxEvents" -> 41, "MaxVertices" -> 42, "MaxEdges" -> 83, "MaxVertexDegree" -> 9|>,
            {"ExpressionsCountFinal", "TerminationReason"},
            Method -> method],
          {82, "MaxEdges"}
        ],

        VerificationTest[
          {maxVertexDegree[#[[1]]], #[[2]]} & @ WolframModel[
            model,
            <|"MaxGenerations" -> 6, "MaxEvents" -> 41, "MaxVertices" -> 42, "MaxEdges" -> 84, "MaxVertexDegree" -> 8|>,
            {"FinalState", "TerminationReason"},
            Method -> method],
          {8, "MaxVertexDegree"}
        ]
      }]] /@ DeleteCases[$SetReplaceMethods, Automatic],

      (*** Automatic steps ***)

      VerificationTest[
        2 WolframModel[{{1, 2}} -> {{2, 3}}, {{1, 1}}, Automatic, "AllEventsCount"],
        WolframModel[{{1, 2}} -> {{2, 3}}, {{1, 1}}, {Automatic, 2}, "AllEventsCount"]
      ],

      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, Automatic, "AllEventsCount"] > 0
      ],

      (* fractional factors should work *)
      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, {Automatic, 1 / Pi}, "AllEventsCount"] <
          WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, Automatic, "AllEventsCount"]
      ],

      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, {Automatic, 1. - 1.*^-20}, "AllEventsCount"],
        WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, Automatic, "AllEventsCount"]
      ],

      (* there should be no message if input has more edges than the step constraint *)
      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, {Automatic, 0}, "AllEventsCount"],
        0
      ],

      (* TerminationReason should not leak internal information *)
      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, Automatic, "TerminationReason"],
        Automatic
      ],

      (* Evaluation should never take too long *)
      VerificationTest[
        Head[TimeConstrained[WolframModel[
          {{0, 0}, {0, 0}, {0, 0}} -> {{0, 0}, {0, 0}, {0, 0}, {0, 0}}, {{1, 1}, {1, 1}, {1, 1}}, Automatic], 60]],
        WolframModelEvolutionObject
      ],

      (* We don't want partial generations *)
      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, Automatic, "PartialGenerationsCount"],
        0
      ],

      (* even if specifically asked for *)
      VerificationTest[
        WolframModel[
          {{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}},
          {{1, 1}},
          Automatic,
          "PartialGenerationsCount",
          "IncludePartialGenerations" -> True],
        0
      ],

      (* time constraint should scale as well *)
      VerificationTest[
        #1 < #2 / 2 & @@ (
          First[AbsoluteTiming[
              WolframModel[{{1, 1}, {1, 1}, {1, 1}} -> {{1, 1}, {1, 1}, {1, 1}, {1, 1}}, Automatic, #]]] & /@
            {{Automatic, 0.2}, Automatic})
      ],

      (* even non-evolution properties should return if an automatic time constraint is triggered *)
      VerificationTest[
        ListQ @ WolframModel[{{1, 1}, {1, 1}, {1, 1}} -> {{1, 1}, {1, 1}, {1, 1}, {1, 1}}, Automatic, #, "FinalState"]
      ] & /@ {Automatic, {Automatic, 0.2}},

      (* even if the time constraint is manually specified *)
      VerificationTest[
        ListQ @ WolframModel[
          {{1, 1}, {1, 1}, {1, 1}} -> {{1, 1}, {1, 1}, {1, 1}, {1, 1}},
          Automatic,
          Automatic,
          "FinalState",
          TimeConstraint ->
            First[AbsoluteTiming[
              WolframModel[{{1, 1}, {1, 1}, {1, 1}} -> {{1, 1}, {1, 1}, {1, 1}, {1, 1}}, Automatic, Automatic]]] / 2]
      ],

      (** Properties **)

      VerificationTest[
        EdgeList[WolframModel[1 -> 2, {1}, 2, "CausalGraph"]],
        {DirectedEdge[1, 2]}
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
        WolframModel[{{1}} -> {{2}}, {{1}}, 2, #] & /@ $WolframModelProperties // Length,
        Length[$WolframModelProperties]
      ],

      VerificationTest[
        WolframModel[{{1}} -> {{2}}, {{1}}, 2, $WolframModelProperties] // Length,
        WolframModel[{{1}} -> {{2}}, {{1}}, 2, #] & /@ $WolframModelProperties // Length
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
        EdgeList /@ WolframModel[1 -> 2, {1}, 2, {"CausalGraph", "CausalGraph"}],
        ConstantArray[{DirectedEdge[1, 2]}, 2]
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
        Through[{VertexList, EdgeList}[WolframModel[1 -> 2, {1}, "CausalGraph"]]],
        {{1}, {}}
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
        WolframModel[<|"PatternRules" -> {2 -> 5, 3 :> 6}|>, {1, 2, 3}, 2]["TotalGenerationsCount"],
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
        WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 2}}, 10]["TotalGenerationsCount"],
        10
      ],

      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 2}}, 10]["EventsCount"],
        1023
      ],

      VerificationTest[
        WolframModel[{{1}} -> {}, {{1}, {2}, {3}, {4}, {5}}, Infinity]["TotalGenerationsCount"],
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
        WolframModel[{{1}} -> {{1}}, {{1}, {2}, {3}, {4}, {5}}, 0]["TotalGenerationsCount"],
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
          2]["TotalGenerationsCount"],
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

      (** VertexNamingFunction **)

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
          "VertexNamingFunction" -> Automatic]
      ],

      VerificationTest[
        WolframModel[
          {{1, 3}} -> {{1, 2}, {2, 3}},
          {{0, 0}},
          2,
          "FinalState",
          "VertexNamingFunction" -> Automatic],
        {{0, 2}, {2, 1}, {1, 3}, {3, 0}}
      ],

      VerificationTest[
        WolframModel[
          {{1, 3}} -> {{1, 2}, {2, 3}},
          {{2, 2}},
          2,
          "FinalState",
          "VertexNamingFunction" -> Automatic],
        {{2, 3}, {3, 1}, {1, 4}, {4, 2}}
      ],

      VerificationTest[
        WolframModel[
          {{1, 3}} -> {{1, 2}, {2, 3}},
          {{0, 0}},
          2,
          "FinalState",
          "VertexNamingFunction" -> All],
        {{1, 3}, {3, 2}, {2, 4}, {4, 1}}
      ],

      VerificationTest[
        WolframModel[
          {{1, 3}} -> {{1, 2}, {2, 3}},
          {{0, 0}},
          2,
          "FinalState",
          "VertexNamingFunction" -> None],
        {{0, x_Symbol}, {x_Symbol, y_Symbol}, {y_Symbol, z_Symbol}, {z_Symbol, 0}},
        SameTest -> MatchQ
      ],

      VerificationTest[
        WolframModel[
          <|"PatternRules" -> {{a_, b_}} :> Module[{c}, {{a, c}, {c, b}}]|>,
          {{0, 0}},
          2,
          "FinalState",
          "VertexNamingFunction" -> All],
        {{1, 3}, {3, 2}, {2, 4}, {4, 1}}
      ],

      VerificationTest[
        WolframModel[
          <|"PatternRules" -> {{a_, b_}} :> Module[{c}, {{a, c}, {c, b}}]|>,
          {{0, 0}},
          2,
          "FinalState",
          "VertexNamingFunction" -> #],
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
            WolframModel[##, "VertexNamingFunction" -> All] & @@
              namingTestModel]
        ],

        VerificationTest[
          # == Range[0, Length[#] - 1] & @ Union @ Flatten[
            WolframModel[##, "VertexNamingFunction" -> Automatic] & @@
              namingTestModel]
        ],

        VerificationTest[
          (#[[1]] /. Thread[Rule @@ Flatten /@ #]) == #[[2]] & @ (Table[
            WolframModel[##, "VertexNamingFunction" -> namingFunction] & @@ namingTestModel,
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
          "VertexNamingFunction" -> All],
        {{1, 3}, {3, 2}}
      ],

      (*** weed #300 ***)
      (*** should not fail for non-atom non-list edges ***)
      VerificationTest[
        WolframModel[
          <|"PatternRules" -> {f[x_], f[y_]} :> {f[x + y], f[x - y]}|>,
          {f[1], f[1]},
          4,
          "StatesList",
          "VertexNamingFunction" -> All],
        {{1, 1}, {2, 3}, {2, 2}, {4, 3}, {4, 4}}
      ],

      (** TimeConstraint **)

      With[{timeConstraintRule = $timeConstraintRule, timeConstraintInit = $timeConstraintInit}, {
        (*** Check that aborted evaluation still produces correct evolutions. ***)
        Table[With[{method = method, time = time}, VerificationTest[
          And @@ Table[
            Module[{timeConstrained, eventConstrained},
              timeConstrained =
                WolframModel[timeConstraintRule, timeConstraintInit, 100, Method -> method, TimeConstraint -> time];
              eventConstrained =
                WolframModel[timeConstraintRule, timeConstraintInit, <|"MaxEvents" -> timeConstrained["EventsCount"]|>];
              timeConstrained["TerminationReason"] === "TimeConstraint" &&
              eventConstrained["TerminationReason"] === "MaxEvents" &&
              SameQ @@ (# /@ {
                "CreatorEvents", "DestroyerEvents", "ExpressionGenerations", "AllExpressions", "Rules",
                "MaxCompleteGeneration"} & /@ {timeConstrained, eventConstrained})
            ],
            100]
        (* small time constrained case temporarily removed due to Wolfram bug #387470 *)
        ]], {method, $SetReplaceMethods}, {time, {(*1.*^-100, *)0.1}}],

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
      }],

      (** MaxCompleteGeneration **)

      Table[With[{method = method}, {
        With[{rule = $interestingRule, init = $interestingInit},
          VerificationTest[
            WolframModel[rule, init, <|"MaxEvents" -> 10|>, "MaxCompleteGeneration", Method -> method],
            2
          ]
        ],

        VerificationTest[
          Table[WolframModel[#1, #2, <|"MaxEvents" -> e|>, "MaxCompleteGeneration", Method -> method], {e, 0, #3}],
          #4
        ] & @@@ {
          {{{1}} -> {}, {{1}, {2}, {3}}, 4, {0, 0, 0, 1, 1}},
          {{{{1}} -> {}, {{3, 4}} -> {{3, 4, 5}}, {{3, 4, 5}} -> {}}, {{1}, {2}, {3, 4}}, 5, {0, 0, 0, 1, 2, 2}},
          {{{1, 2}, {2, 3}} -> {{1, 2, 3}}, {{1, 2}, {2, 3}, {3, 4}}, 2, {0, 1, 1}},
          {{{1, 2}, {2, 3}} -> {{1, 2, 3}}, {{1, 2}, {2, 3}, {3, 4}, {4, 5}}, 3, {0, 0, 1, 1}}},

        VerificationTest[
          WolframModel[{} -> {{1}}, {}, <|"MaxEvents" -> 10|>, "MaxCompleteGeneration"],
          0
        ]
      }], {method, DeleteCases[$SetReplaceMethods, Automatic]}],

      (** IncludePartialGenerations **)

      Table[With[{
          models = {
            {{{1, 2, 3}, {4, 5, 6}, {1, 4}} ->
                {{2, 8, 7}, {9, 3, 10}, {5, 11, 12}, {6, 13, 14}, {10, 13}, {7, 9}, {11, 8}, {12, 14}},
              {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1, 1}},
              7},
            {{{1, 1}} -> {{1, 2}, {2, 2}, {2, 2}}, {{1, 1}}, 7},
            {{{1, 2}, {1, 3}, {1, 4}} -> {{2, 3}, {2, 4}, {3, 3}, {3, 5}, {4, 5}}, {{1, 1}, {1, 1}, {1, 1}}, 8},
            {{{{1, 2}, {2, 3}} -> {{1, 3}, {2, 4}, {4, 3}}, {{1, 1}, {2, 1}} -> {{1, 1}}},
              {{1, 1}, {1, 1}},
              6}},
          method = method},
        With[{
            eventCounts = {#[[1]], Round[Mean[#]], #[[2]] - 1, #[[2]]} & @
              {WolframModel[#1, #2, #3, "EventsCount"], WolframModel[#1, #2, #3 + 1, "EventsCount"]}}, {
          Table[With[{property = property}, {
            VerificationTest[
              SameQ @@ Table[
                WolframModel[
                  #1,
                  #2,
                  <|"MaxEvents" -> eventCounts[[k]]|>,
                  property,
                  "IncludePartialGenerations" -> False,
                  Method -> method],
                {k, 3}]
            ],

            If[!ListQ[property], VerificationTest[
              SameQ @@ Table[
                WolframModel[
                  #1,
                  #2,
                  <|"MaxEvents" -> eventCounts[[k]]|>,
                  Method -> method][property, "IncludePartialGenerations" -> False],
                {k, 3}]
            ], Nothing],

            VerificationTest[
              Not @* SameQ @@ Table[
                WolframModel[
                  #1,
                  #2,
                  <|"MaxEvents" -> eventCounts[[k]]|>,
                  property,
                  "IncludePartialGenerations" -> False,
                  Method -> method],
                {k, {1, 4}}]
            ],

            If[!ListQ[property], VerificationTest[
              Not @* SameQ @@ Table[
                WolframModel[
                  #1,
                  #2,
                  <|"MaxEvents" -> eventCounts[[k]]|>,
                  Method -> method][property, "IncludePartialGenerations" -> False],
                {k, {1, 4}}]
            ], Nothing]
          }], {property, {"EvolutionObject", "FinalState", {"FinalState", "AtomsCountFinal"}}}]
        }] & @@@ models
      ], {method, DeleteCases[$SetReplaceMethods, Automatic]}],

      VerificationTest[
        SameQ @@ ((SeedRandom[2];
          WolframModel[
            {{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}},
            {{1, 1}},
            <|"MaxEvents" -> #|>,
            "EventOrderingFunction" -> "Random",
            "IncludePartialGenerations" -> False]) & /@ {200, 300})
      ],

      VerificationTest[
        SeedRandom[2];
          Sort[VertexList[WolframModel[
            {{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}},
            {{1, 1}},
            <|"MaxEvents" -> 200|>,
            "EventOrderingFunction" -> "Random",
            "IncludePartialGenerations" -> False][
            "CausalGraph"]]],
        Range[13]
      ],

      testUnevaluated[
        WolframModel[{{1, 2, 3}} -> {{1, 2, 3}}, {{1, 2, 3}}, 1, "IncludePartialGenerations" -> $$$invalid$$$],
        {WolframModel::invalidFiniteOption}
      ],

      testUnevaluated[
        WolframModel[
          {{1, 2, 3}} -> {{1, 2, 3}},
          {{1, 2, 3}},
          1,
          {"FinalState", "AtomsCountFinal"},
          "IncludePartialGenerations" -> $$$invalid$$$],
        {WolframModel::invalidFiniteOption}
      ],

      With[{evolution = WolframModel[{{1, 2, 3}} -> {{1, 2, 3}}, {{1, 2, 3}}, 1]},
        testUnevaluated[
          evolution["AtomsCountFinal", "IncludePartialGenerations" -> $$$invalid$$$],
          {WolframModelEvolutionObject::invalidFiniteOption}
        ]
      ],

      VerificationTest[
        WolframModel[
          {{1, 2}} -> {}, {{1, 2}, {2, 3}, {3, 4}, {4, 5}}, <|"MaxEvents" -> 3|>, "IncludePartialGenerations" -> False],
        WolframModel[{{1, 2}} -> {}, {{1, 2}, {2, 3}, {3, 4}, {4, 5}}, <|"MaxEvents" -> 0|>]
      ],

      VerificationTest[
        WolframModel[{} -> {{1, 2}}, {}, <|"MaxEvents" -> 3|>, "IncludePartialGenerations" -> False],
        WolframModel[{} -> {{1, 2}}, {}, <|"MaxEvents" -> 0|>]
      ],

      (** IncludeBoundaryEvents **)

      testUnevaluated[
        WolframModel[{{1, 2}} -> {{1, 2}}, {{1, 1}}, 1, "EventsCount", "IncludeBoundaryEvents" -> $$$invalid$$$],
        {WolframModel::invalidFiniteOption}
      ],

      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 2}}, {{1, 1}}, 1, "EventsCount", "IncludeBoundaryEvents" -> All],
        3
      ],

      (** EventOrderingFunction & EventSelectionFunction **)

      Function[{optionAndValue},
        VerificationTest[
          Head[WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 3, optionAndValue]],
          WolframModelEvolutionObject
        ]
      ] /@ {"EventOrderingFunction" -> Automatic,
            "EventOrderingFunction" -> "Random",
            "EventSelectionFunction" -> "GlobalSpacelike",
            "EventSelectionFunction" -> None},

      Function[{optionAndValue},
        VerificationTest[
          Head[WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 3, optionAndValue, Method -> "Symbolic"]],
          WolframModelEvolutionObject
        ]
      ] /@ {"EventOrderingFunction" -> Automatic, "EventSelectionFunction" -> "GlobalSpacelike"},

      Function[{option, message, value, method},
        testUnevaluated[
          WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, 3, option -> value, Method -> method],
          {message}
        ]
      ] @@@ Flatten /@ Tuples[{{{"EventOrderingFunction", WolframModel::invalidEventOrdering},
                               {"EventSelectionFunction", WolframModel::invalidEventSelection}},
                              {"$$$invalid$$$", $$$invalid$$$, 1},
                              {Automatic, "Symbolic"}}],

      (** AllEventsRuleIndices **)

      Table[With[{method = method}, {
        VerificationTest[
          WolframModel[{{{1}} -> {{1}}}, {{1}}, 4, "AllEventsRuleIndices", Method -> method],
          {1, 1, 1, 1}
        ],

        VerificationTest[
          WolframModel[{{{1}} -> {{1, 2}}, {{1, 2}} -> {{1}}}, {{1}}, 4, "AllEventsRuleIndices", Method -> method],
          {1, 2, 1, 2}
        ],

        VerificationTest[
          WolframModel[{{{1, 2}} -> {{1}}, {{1}} -> {{1, 2}}}, {{1}}, 4, "AllEventsRuleIndices", Method -> method],
          {2, 1, 2, 1}
        ],

        VerificationTest[
          WolframModel[{{{1, 2}} -> {{1}}, {{1}} -> {{1, 2}}}, {{1}}, 0, "AllEventsRuleIndices", Method -> method],
          {}
        ],

        VerificationTest[
          WolframModel[
            {{{1, 2}} -> {{1}}, {{1}} -> {{1, 2}}},
            {{1}},
            4,
            "AllEventsRuleIndices",
            "IncludeBoundaryEvents" -> "Initial",
            Method -> method],
          {0, 2, 1, 2, 1}
        ],

        VerificationTest[
          WolframModel[
            {{{1, 2}} -> {{1}}, {{1}} -> {{1, 2}}},
            {{1}},
            4,
            "AllEventsRuleIndices",
            "IncludeBoundaryEvents" -> "Final",
            Method -> method],
          {2, 1, 2, 1, Infinity}
        ],

        VerificationTest[
          WolframModel[
            {{{1, 2}} -> {{1}}, {{1}} -> {{1, 2}}},
            {{1}},
            4,
            "AllEventsRuleIndices",
            "IncludeBoundaryEvents" -> All,
            Method -> method],
          {0, 2, 1, 2, 1, Infinity}
        ]
      }], {method, DeleteCases[$SetReplaceMethods, Automatic]}],

      (** Automatic initial state **)

      VerificationTest[
        WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, Automatic][0],
        {{1, 1}}
      ],

      VerificationTest[
        WolframModel[
          {{{1}, {1, 2}} -> {{1, 2}, {2}}, {{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 2, 3}} -> {{1, 2}, {2, 3, 4}}},
          Automatic][0],
        {{1}, {1, 1}, {1, 1, 1}}
      ],

      VerificationTest[
        WolframModel[{{1}, {1, 2}} -> {{1}, {1, 3}, {3, 2}}, Automatic][0],
        {{1}, {1, 1}}
      ],

      testUnevaluated[
        WolframModel[<|"PatternRules" -> {{a_, b_}} :> {{a, b}, {b, a}}|>, Automatic],
        {WolframModel::noPatternAutomatic}
      ],

      VerificationTest[
        WolframModel[1 -> 2, Automatic][0],
        {1}
      ],

      VerificationTest[
        WolframModel[{1, {2}} -> {2, {3}}, Automatic][0],
        {1, {1}}
      ]
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
