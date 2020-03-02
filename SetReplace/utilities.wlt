<|
  "utilities" -> <|
    "init" -> (
      Global`multisetComplement = SetReplace`PackageScope`multisetComplement;
      Global`multisetUnion = SetReplace`PackageScope`multisetUnion;
    ),
    "tests" -> {
      (* multisetComplement *)

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
      ],

      (* multisetUnion *)

      VerificationTest[
        multisetUnion[],
        {}
      ],

      VerificationTest[
        multisetUnion[{1, 2, 3}],
        {1, 2, 3}
      ],

      VerificationTest[
        multisetUnion[{1, 2, 3, 3}],
        {1, 2, 3, 3}
      ],

      VerificationTest[
        multisetUnion[{1, 2, 3, 3}, {1, 3, 5}],
        {1, 2, 3, 3, 5}
      ],

      VerificationTest[
        multisetUnion[{1, 1, 2}, {1, 2, 2}],
        {1, 1, 2, 2}
      ],

      VerificationTest[
        multisetUnion[{1, 1, 2}, {1, 2, 2}, {1, 2, 3, 3}],
        {1, 1, 2, 2, 3, 3}
      ],

      VerificationTest[
        multisetUnion[{1, 1}, {}],
        {1, 1}
      ],

      VerificationTest[
        multisetUnion[{{1, 5}, {1, 4}, {1, 5}, 3, 5}, {{1, 5}, 2, 2, 3, 4}],
        {{1, 5}, {1, 5}, {1, 4}, 3, 5, 2, 2, 4}
      ]
    }
  |>
|>
