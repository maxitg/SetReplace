<|
  "ToPatternRules" -> <|
    "init" -> (
      Global`multisetComplement = SetReplace`PackageScope`multisetComplement;
    ),
    "tests" -> {
      VerificationTest[
        multisetComplement[{}, {}],
        {}
      ],

      VerificationTest[
        multisetComplement[{1}, {}],
        {1}
      ],

      VerificationTest[
        multisetComplement[{}, {1}],
        {}
      ],

      VerificationTest[
        multisetComplement[{1}, {1}],
        {}
      ],

      VerificationTest[
        multisetComplement[{1, 1}, {1}],
        {1}
      ],

      VerificationTest[
        multisetComplement[{1, 2, 2, 3, 4}, {1, 1, 2, 3, 5}],
        {2, 4}
      ],

      VerificationTest[
        multisetComplement[{{1, 5}, {1, 4}, {1, 5}, 3, 5}, {{1, 5}, 2, 2, 3, 4}],
        {{1, 5}, {1, 4}, 5}
      ],

      VerificationTest[
        multisetComplement[{1, 1, 1, 1, 2, 3, 4, 5}, {1, 1, 2, 4, 6}],
        {1, 1, 3, 5}
      ]
    }
  |>
|>
