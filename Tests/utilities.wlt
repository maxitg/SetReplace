<|
  "utilities" -> <|
    "init" -> (
      Global`multisetComplement = SetReplace`PackageScope`multisetComplement;
      Global`multisetFilterRules = SetReplace`PackageScope`multisetFilterRules;
      Global`multisetUnion = SetReplace`PackageScope`multisetUnion;
      Global`connectedHypergraphQ = SetReplace`PackageScope`connectedHypergraphQ;
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

      (* multisetFilterRules *)

      VerificationTest[
        multisetFilterRules[{}, {}],
        {}
      ],

      VerificationTest[
        multisetFilterRules[{1 -> a}, {}],
        {}
      ],

      VerificationTest[
        multisetFilterRules[{}, {1}],
        {}
      ],

      VerificationTest[
        multisetFilterRules[{1 -> a}, {1}],
        {1 -> a}
      ],

      VerificationTest[
        multisetFilterRules[{1 -> a}, {1, 1}],
        {1 -> a}
      ],

      VerificationTest[
        multisetFilterRules[{1 -> a, 1 -> b}, {1}],
        {1 -> a}
      ],

      VerificationTest[
        multisetFilterRules[{1 -> a, 1 -> b}, {1, 1}],
        {1 -> a, 1 -> b}
      ],

      VerificationTest[
        multisetFilterRules[{1 -> a, 2 -> b, 2 -> c}, {1, 1, 2}],
        {1 -> a, 2 -> b}
      ],

      VerificationTest[
        multisetFilterRules[{1 -> a, 2 -> b, 2 -> c, 2 -> d, 3 -> e, 3 -> f}, {2, 2, 3, 3, 3}],
        {2 -> b, 2 -> c, 3 -> e, 3 -> f}
      ],

      VerificationTest[
        multisetFilterRules[{2 -> {b, c}, 2 -> {c, d}, 2 -> {d, e}, 3 -> e, 3 -> f}, {2, 2, 3, 3, 3}],
        {2 -> {b, c}, 2 -> {c, d}, 3 -> e, 3 -> f}
      ],

      VerificationTest[
        multisetFilterRules[{1 -> a, {2, x} -> b, {2, x} -> c, {2, x} -> d, 3 -> e, 3 -> f}, {{2, x}, {2, x}, 3, 3, 3}],
        {3 -> e, 3 -> f, {2, x} -> b, {2, x} -> c}
      ],

      VerificationTest[
        multisetFilterRules[{1 -> a, 2 -> b, 2 -> c, 2 -> d, {3, x} -> e, {3, x} -> f}, {2, 2, {3, x}, {3, x}, 3}],
        {2 -> b, 2 -> c, {3, x} -> e, {3, x} -> f}
      ],

      VerificationTest[
        multisetFilterRules[{1 -> a, 2 -> b, 2 -> c, 2 -> d, {3, x} -> e, {3, x} -> f}, {2, 2, {3, x}, {3, x}}],
        {2 -> b, 2 -> c, {3, x} -> e, {3, x} -> f}
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
      ],

      (* connectedHypergraphQ *)

      VerificationTest[
        connectedHypergraphQ[1],
        True
      ],

      VerificationTest[
        connectedHypergraphQ[{1}],
        True
      ],

      VerificationTest[
        connectedHypergraphQ[{1, 2}],
        False
      ],

      VerificationTest[
        connectedHypergraphQ[{1, {1, 2}}],
        True
      ],

      VerificationTest[
        connectedHypergraphQ[{{1, 3}, {1, 2}}],
        True
      ],

      VerificationTest[
        connectedHypergraphQ[{{1, 2}, {2, 3}}],
        True
      ],

      VerificationTest[
        connectedHypergraphQ[{{{1, 0}, {2, 0}}, {{2, 0}, {3, 0}}}],
        True
      ],

      VerificationTest[
        connectedHypergraphQ[{{{1, 0}, {2, 0}}, {{3, 0}, {4, 0}}}],
        False
      ],

      VerificationTest[
        connectedHypergraphQ[{{1}, {2, 3}}],
        False
      ],

      VerificationTest[
        connectedHypergraphQ[{{1}, {1, 2}}],
        True
      ],

      VerificationTest[
        connectedHypergraphQ[{{1, 2, 3}, {2, 4, 5}}],
        True
      ],

      VerificationTest[
        connectedHypergraphQ[{{10, 17, 14}, {15, 8, 9}, {18, 15, 14}, {3, 12, 18}, {0, 16, 5}, {8, 13, 14}}],
        False
      ],

      VerificationTest[
        connectedHypergraphQ[{{13, 1, 14}, {13, 2, 16}, {16, 14, 18}, {6, 10, 15}, {1, 13, 15}, {13, 13, 15}}],
        True
      ]
    }
  |>
|>
