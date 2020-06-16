<|
  "eventOrderingFunction" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
    ),
    "tests" -> {
      testUnevaluated[
        WolframModel[{1 -> 2, 1 -> 3}, {1}, "EventOrderingFunction" -> "Random", Method -> #1],
        #2
      ] & @@@ {{Automatic, WolframModel::symbNotImplemented}, {"Symbolic", WolframModel::symbOrdering}},

      VerificationTest[
        SetReplace[{{1}, {2}, {3}, {4}, {5}}, {{{2}, {3}, {4}} -> {{X}}, {{3}} -> {{X}}}],
        {{1}, {2}, {4}, {5}, {X}}
      ],

      With[{methods = DeleteCases[$SetReplaceMethods, Automatic]}, {
        VerificationTest[
          Table[
            WolframModel[
                <|"PatternRules" -> {{{1, 2}, {2, 3}} -> {{R1}}, {{4, 5}, {5, 6}} -> {{R2}}}|>,
                #,
                <|"MaxEvents" -> 1|>,
                "FinalState",
                Method -> method][[-1, 1]] & /@
              Permutations[{{1, 2}, {2, 3}, {4, 5}, {5, 6}}],
            {method, methods}],
          ConstantArray[{
              R1, R1, R1, R2, R1, R2, R1, R1, R1, R2, R1, R2,
              R1, R2, R1, R2, R2, R2, R1, R2, R1, R2, R2, R2},
            2]
        ],

        VerificationTest[
          Table[
            WolframModel[
                <|"PatternRules" -> {{1, 2, x_}, {1, 2, z_}} :> {{x, z}}|>,
                #,
                <|"MaxEvents" -> 1|>,
                "FinalState",
                Method -> method][[-1]] & /@
              Permutations[{{1, 2, x}, {1, 2, y}, {1, 2, z}}],
            {method, methods}],
          ConstantArray[
            {{x, y}, {x, z}, {y, x}, {y, z}, {z, x}, {z, y}},
            2]
        ],

          VerificationTest[
            Table[
              WolframModel[
                  <|"PatternRules" -> {
                    {{1, 2, x_}, {1, 3, z_}} :> {{1, x, z}},
                    {{1, 2, x_}, {1, 2, z_}} :> {{2, x, z}}}|>,
                  #,
                  <|"MaxEvents" -> 1|>,
                  "FinalState",
                  Method -> method][[-1]] & /@
                Permutations[{{1, 2, x}, {1, 2, y}, {1, 3, z}}],
              {method, methods}],
            ConstantArray[
              {{2, x, y}, {1, x, z}, {2, y, x}, {1, y, z}, {1, x, z}, {1, y, z}},
              2]
        ]
      }],

      VerificationTest[
        WolframModel[
          {{b, c}, {a, b}} -> {},
          {{1, 2}, {3, 4}, {4, 5}, {2, 3}, {a, b}, {b, c}, {5, 6}},
          <|"MaxEvents" -> 1|>,
          "FinalState",
          "EventOrderingFunction" -> #1],
        #2
      ] & @@@ {
        {"OldestEdge", {{3, 4}, {4, 5}, {a, b}, {b, c}, {5, 6}}},
        {"LeastOldEdge", {{1, 2}, {3, 4}, {4, 5}, {2, 3}, {5, 6}}},
        {"LeastRecentEdge", {{1, 2}, {2, 3}, {a, b}, {b, c}, {5, 6}}},
        {"NewestEdge", {{1, 2}, {3, 4}, {2, 3}, {a, b}, {b, c}}},
        {"RuleOrdering", {{1, 2}, {4, 5}, {a, b}, {b, c}, {5, 6}}},
        {"ReverseRuleOrdering", {{1, 2}, {3, 4}, {2, 3}, {a, b}, {b, c}}}
      },

      Function[{ordering, result}, VerificationTest[
          WolframModel[
              <|"PatternRules" -> {{{1, 2}, {2, 3}} -> {{R1}}, {{4, 5}, {5, 6}} -> {{R2}}}|>,
              #,
              <|"MaxEvents" -> 1|>,
              "FinalState",
              "EventOrderingFunction" -> ordering][[-1, 1]] & /@
            Permutations[{{1, 2}, {2, 3}, {4, 5}, {5, 6}}],
          result
      ]] @@@ {
        {"OldestEdge",
          {R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2}},
        {"LeastOldEdge",
          {R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1}},
        {"LeastRecentEdge",
          {R1, R1, R1, R2, R1, R2, R1, R1, R1, R2, R1, R2, R1, R2, R1, R2, R2, R2, R1, R2, R1, R2, R2, R2}},
        {"NewestEdge",
          {R2, R2, R2, R1, R2, R1, R2, R2, R2, R1, R2, R1, R2, R1, R2, R1, R1, R1, R2, R1, R2, R1, R1, R1}},
        {"RuleOrdering",
          {R1, R1, R1, R1, R1, R1, R1, R1, R2, R2, R1, R2, R2, R2, R2, R2, R2, R2, R1, R1, R1, R2, R2, R2}},
        {"ReverseRuleOrdering",
          {R2, R2, R2, R2, R2, R2, R2, R2, R1, R1, R2, R1, R1, R1, R1, R1, R1, R1, R2, R2, R2, R1, R1, R1}},
        {"RuleIndex",
          {R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1, R1}},
        {"ReverseRuleIndex",
          {R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2, R2}}
      },

      Function[{ordering, result}, VerificationTest[
        WolframModel[
            <|"PatternRules" -> {{1, 2, x_}, {1, 2, z_}} :> {{x, z}}|>,
            #,
            <|"MaxEvents" -> 1|>,
            "FinalState",
            "EventOrderingFunction" -> ordering][[-1]] & /@
          Permutations[{{1, 2, x}, {1, 2, y}, {1, 2, z}}],
        result
      ]] @@@ {
        {{"OldestEdge", "RuleOrdering"}, {{x, y}, {x, z}, {y, x}, {y, z}, {z, x}, {z, y}}},
        {"RuleOrdering", {{x, y}, {x, z}, {y, x}, {y, z}, {z, x}, {z, y}}},
        {{"OldestEdge", "ReverseRuleOrdering"}, {{y, x}, {z, x}, {x, y}, {z, y}, {x, z}, {y, z}}}
      },

      Function[{ordering, result}, VerificationTest[
        WolframModel[
            <|"PatternRules" -> {{{1, 2, x_}, {1, 3, z_}} :> {{1, x, z}}, {{1, 2, x_}, {1, 2, z_}} :> {{2, x, z}}}|>,
            #,
            <|"MaxEvents" -> 1|>,
            "FinalState",
            "EventOrderingFunction" -> ordering][[-1]] & /@
          Permutations[{{1, 2, x}, {1, 2, y}, {1, 3, z}}],
        result
      ]] @@@ {
        {{"OldestEdge", "RuleOrdering"}, {{2, x, y}, {1, x, z}, {2, y, x}, {1, y, z}, {1, x, z}, {1, y, z}}},
        {{"RuleIndex", "RuleOrdering"}, {{1, x, z}, {1, x, z}, {1, y, z}, {1, y, z}, {1, x, z}, {1, y, z}}},
        {{"ReverseRuleIndex", "ReverseRuleOrdering"},
          {{2, y, x}, {2, y, x}, {2, x, y}, {2, x, y}, {2, y, x}, {2, x, y}}}
      },

      VerificationTest[
        WolframModel[
          {{{1, 2}, {2, 3}} -> {{1, 3}, {2, 4}, {4, 3}}, {{1, 1}, {2, 1}} -> {{1, 1}}},
          {{2, 2}, {1, 4}, {4, 2}, {1, 2}, {3, 5}, {5, 2}},
          <|"MaxEvents" -> 1|>,
          "FinalState",
          "EventOrderingFunction" -> #1],
        #2
      ] & @@@ {
        {{"OldestEdge", "RuleOrdering"}, {{1, 4}, {1, 2}, {3, 5}, {5, 2}, {2, 2}}},
        {{"OldestEdge", "ReverseRuleOrdering"}, {{1, 4}, {1, 2}, {3, 5}, {5, 2}, {4, 2}, {2, 6}, {6, 2}}},
        {"LeastOldEdge", {{2, 2}, {1, 4}, {4, 2}, {1, 2}, {3, 2}, {5, 6}, {6, 2}}},
        {{"LeastRecentEdge", "RuleOrdering"}, {{1, 4}, {1, 2}, {3, 5}, {5, 2}, {2, 2}}}
      },

      VerificationTest[
        Length[
          Counts[
            Table[
              SeedRandom[k];
              WolframModel[
                {{1, 2}, {1, 3}} -> {{2, 3}},
                {{1, 2}, {1, 3}, {1, 4}, {1, 5}, {1, 6}},
                <|"MaxEvents" -> 1|>,
                "FinalState",
                "EventOrderingFunction" -> "OldestEdge"][[-1]],
              {k, 100}]]],
        2
      ],

      With[{rule = {{0, 1}, {0, 2}, {0, 3}} -> {{4, 5}, {5, 4}, {4, 6}, {6, 4}, {5, 6}, {6, 5}, {4, 1}, {5, 2}, {6, 3}},
            init = {{0, 0}, {0, 0}, {0, 0}},
            maxEvents = 80,
            maxGenerations = 4}, {
        (* Fixed number of events same seed consistentcy *)
        VerificationTest[
          SeedRandom[1655]; WolframModel[rule, init, <|"MaxEvents" -> maxEvents|>, "EventOrderingFunction" -> "Random"],
          SeedRandom[1655]; WolframModel[rule, init, <|"MaxEvents" -> maxEvents|>, "EventOrderingFunction" -> "Random"]
        ],

        (* Fixed number of events different seeds difference *)
        VerificationTest[
          (SeedRandom[1655];
           WolframModel[rule, init, <|"MaxEvents" -> maxEvents|>, "EventOrderingFunction" -> "Random"]) =!=
          (SeedRandom[1656];
           WolframModel[rule, init, <|"MaxEvents" -> maxEvents|>, "EventOrderingFunction" -> "Random"])
        ],

        (* Fixed number of generations same seed consistentcy *)
        VerificationTest[
          SeedRandom[1655]; WolframModel[rule, init, maxGenerations, "EventOrderingFunction" -> "Random"],
          SeedRandom[1655]; WolframModel[rule, init, maxGenerations, "EventOrderingFunction" -> "Random"]
        ],

        (* Correct number of generations is obtained *)
        VerificationTest[
          SeedRandom[1655]; WolframModel[rule,
                                         init,
                                         maxGenerations,
                                         {"TotalGenerationsCount", "MaxCompleteGeneration"},
                                         "EventOrderingFunction" -> "Random"],
          {maxGenerations, maxGenerations}
        ],

        (* Fixed number of generations different seeds difference *)
        (* Even though final sets might be the same for some of these systems, different evaluation order will make *)
        (* evolution objects different *)
        VerificationTest[
          (SeedRandom[1655]; WolframModel[rule, init, maxGenerations, "EventOrderingFunction" -> "Random"]) =!=
          (SeedRandom[1656]; WolframModel[rule, init, maxGenerations, "EventOrderingFunction" -> "Random"])
        ]
      }]
    }
  |>
|>
