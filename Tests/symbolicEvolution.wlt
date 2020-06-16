<|
  (* These are tests specific to Method -> "Symbolic" option of WolframModel.
     Other test groups (like globalSpacelikeEvolution and matching) should be used to test it as well. *)
  "symbolicEvolution" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];

      (* Assign variables that ToPatternRules would use to confuse setSubstitutionSystem as much as possible. *)
      v1 = v2 = v3 = v4 = v5 = 1;
    ),
    "tests" -> {
      (** Potential variable collision between different rule inputs and outputs **)
      VerificationTest[
        WolframModel[
          {{{1, 1}, {2, 3}} -> {{2, 1}, {2, 2}, {2, 3}, {4, 2}}, {{1, 2}, {1, 2}} -> {{3, 2}}},
          {{1, 0}, {6, 1}, {1, 0}, {1, 1}, {1, 0}, {7, 1}, {3, 0}, {3, 3}, {3, 1}, {8, 3}, {4, 0}, {4, 4}, {4, 0},
            {9, 4}, {2, 2}, {2, 2}, {2, 0}, {10, 2}, {2, 1}, {2, 2}, {2, 0}, {11, 2}, {5, 1}, {5, 5}, {5, 2}, {12, 5}},
          <|"MaxEvents" -> 1|>,
          "FinalState",
          Method -> "Symbolic"],
        {{6, 1}, {1, 1}, {1, 0}, {7, 1}, {3, 0}, {3, 3}, {3, 1}, {8, 3}, {4, 0}, {4, 4}, {4, 0}, {9, 4}, {2, 2}, {2, 2},
          {2, 0}, {10, 2}, {2, 1}, {2, 2}, {2, 0}, {11, 2}, {5, 1}, {5, 5}, {5, 2}, {12, 5}, {13, 0}}
      ],

      VerificationTest[
        SetReplace[{1}, ToPatternRules[{{1, 2} -> {}, {1} -> {2}}], Method -> "Symbolic"],
        {_ ? AtomQ},
        SameTest -> MatchQ
      ],

      (** Check invalid patterns produce a single message. **)
      testUnevaluated[
        SetReplace[
          {{1}},
          {{{Pattern[1, _], v2_}} :> {}, {{Pattern[2, _], v1_}} :> Module[{v2}, {v2}]},
          Method -> "Symbolic"],
        {Pattern::patvar}
      ],

      (** Nested Pattern in the inputs **)
      testUnevaluated[
        SetReplace[
          {{1}},
          {{{Pattern[Pattern[a, _], _], v2_}} :> {}, {{Pattern[2, _], v1_}} :> Module[{v2}, {v2}]},
          Method -> "Symbolic"],
        {Pattern::patvar}
      ]
    }
  |>
|>
