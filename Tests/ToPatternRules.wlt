<|
  "ToPatternRules" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];
    ),
    "tests" -> {
      (* Symbol Leak *)

      testSymbolLeak[
        SeedRandom[123];
        ToPatternRules[Rule @@ RandomInteger[100, {2, 50, 3}]]
      ],

      (* Argument Checks *)

      (** Argument count **)

      testUnevaluated[
        ToPatternRules[],
        {ToPatternRules::argx}
      ],

      testUnevaluated[
        ToPatternRules[1, 2],
        {ToPatternRules::argx}
      ],

      (** Argument is a list of rules or a single rule **)

      testUnevaluated[
        ToPatternRules[1],
        {ToPatternRules::notRules}
      ],

      (* Implementation *)

      (** Simple examples **)

      VerificationTest[
        SetReplace[{1}, ToPatternRules[4 -> 5]] =!= {1}
      ],

      VerificationTest[
        SetReplace[{1}, ToPatternRules[4 -> {5, 5}]] =!= {1}
      ],

      VerificationTest[
        SetReplace[{1}, ToPatternRules[{4} -> 9]] =!= {9}
      ],

      VerificationTest[
        ToPatternRules[{{} -> {}}],
        {{} :> {}}
      ],

      VerificationTest[
        SetReplace[{{1, 2}, {2, 3}}, ToPatternRules[{{} -> {}}], 3],
        {{1, 2}, {2, 3}}
      ],

      VerificationTest[
        SetReplace[{{"v1", "v2"}}, ToPatternRules[{{1, 2}} -> {{1}}]],
        {{"v1"}}
      ],

      VerificationTest[
        SetReplace[
          {{"v1", "v2"}, {"v2", "v3"}},
          ToPatternRules[{{1, 2}, {2, 3}} -> {{1, 3}}]],
        {{"v1", "v3"}}
      ],

      (** Multiple rules **)

      VerificationTest[
        SetReplace[
          {{"v1", "v2"}, {"v2", "v3"}},
          ToPatternRules[{
            {{1, 2}, {2, 3}} -> {{1, 3}},
            {{1, 2}} -> {{1, 1, 2, 2}}}], 2],
        {{"v1", "v1", "v2", "v2"}, {"v2", "v2", "v3", "v3"}}
      ],

      (** Creating vertices **)

      VerificationTest[
        SetReplace[
          SetReplace[{{"v1", "v2"}}, ToPatternRules[{{1, 2}} -> {{1, 2, 3}}]],
          {{"v1", "v2", z_}} :> {{"v1", "v2"}}],
        {{"v1", "v2"}}
      ],

      (** Check new vertices are being held **)

      VerificationTest[
        Module[{v1 = 1, v2 = 1, v3 = 1, v4 = 1, v5 = 1},
          SetReplace[{z + z^z, y + y^y}, ToPatternRules[x + x^x -> x]]
        ],
        {y + y^y, z}
      ],

      (** Non-list rule structures **)

      VerificationTest[
        SetReplace[
          {10 -> 20, {30, 40}},
          ToPatternRules[{1 -> 2, {3, 4}} -> {{1, 2, 3}, {3, 4, 5}}]][[1]],
        {10, 20, 30}
      ],

      VerificationTest[
        SetReplace[{{2, 2}, 1},
          ToPatternRules[{
            {{Graph[{3 -> 4}], Graph[{3 -> 4}]}, Graph[{1 -> 2}]} ->
            {Graph[{3 -> 4}], Graph[{1 -> 2}], Graph[{3 -> 4}]}}]],
        {2, 1, 2}
      ],

      VerificationTest[
        SetReplace[
          {{v[1], v[2]}, {v[2], v[3]}},
          ToPatternRules[{{v[1], v[2]}, {v[2], v[3]}} -> {{v[1], v[3]}}]],
        {{v[1], v[3]}}
      ],

      (** Renaming anonymous atoms does not affect names in the output #219 **)
      VerificationTest[
        ToPatternRules[{{1, 2}, {1, 3}} -> {{1, 2}, {1, 4}, {2, 4}, {3, 4}}],
        ToPatternRules[{{x, y}, {x, z}} -> {{x, y}, {x, w}, {y, w}, {z, w}}]
      ]
    }
  |>
|>
