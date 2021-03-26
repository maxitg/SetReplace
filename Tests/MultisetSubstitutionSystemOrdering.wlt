<|
  "MultisetSubstitutionSystemOrdering" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];

      (* These will not be necessary once we have properties. *)
      lastEventInputs[Multihistory[_, data_]] := data["EventInputs"]["Part", -1];
      lastExpression[Multihistory[_, data_]] := data["Expressions"]["Part", -1];
    ),
    "tests" -> {
      Function[{rule, init, lastEventInputsOutput},
        VerificationTest[
          lastEventInputs @
            GenerateMultihistory[MultisetSubstitutionSystem[rule],
                                 <||>,
                                 None,
                                 {"InputCount", "SortedInputExpressions", "UnsortedInputExpressions", "RuleIndex"},
                                 <|"MaxEvents" -> 1|>] @ init,
          lastEventInputsOutput]
      ] @@@ {
        {{{2, 3, 4} -> {X}, {3} -> {X}}, {1, 2, 3, 4, 5}, {3}},
        {{{b_, _}, {_, b_}} :> {}, {{1, 2}, {3, 4}, {4, 5}, {2, 3}, {a, b}, {b, c}, {5, 6}}, {4, 1}},
        {ToPatternRules[{{{1, 2}, {2, 3}} -> {{1, 3}, {2, 4}, {4, 3}}, {{1, 1}, {2, 1}} -> {{1, 1}}}],
         {{2, 2}, {1, 4}, {4, 2}, {1, 2}, {3, 5}, {5, 2}},
         {1, 3}}
      },

      Function[{rule, inits, lastExpressions},
        VerificationTest[
          lastExpression @*
            GenerateMultihistory[MultisetSubstitutionSystem[rule],
                                 <||>,
                                 None,
                                 {"InputCount", "SortedInputExpressions", "UnsortedInputExpressions", "RuleIndex"},
                                 <|"MaxEvents" -> 1|>] /@ inits,
          lastExpressions]
      ] @@@ {
        {{{{1, 2}, {2, 3}} -> {1}, {{4, 5}, {5, 6}} -> {2}},
         Permutations[{{1, 2}, {2, 3}, {4, 5}, {5, 6}}],
         Join[ConstantArray[1, 12], ConstantArray[2, 12]]},
        {{{1, 2, x_}, {1, 2, z_}} :> {{x, z}},
         Permutations[{{1, 2, x}, {1, 2, y}, {1, 2, z}}],
         {{x, y}, {x, z}, {y, x}, {y, z}, {z, x}, {z, y}}},
        {{{{1, 2, x_}, {1, 3, z_}} :> {{1, x, z}}, {{1, 2, x_}, {1, 2, z_}} :> {{2, x, z}}},
         Permutations[{{1, 2, x}, {1, 2, y}, {1, 3, z}}],
         {{2, x, y}, {1, x, z}, {2, y, x}, {1, y, z}, {1, x, z}, {1, y, z}}}
      }
    }
  |>
|>
