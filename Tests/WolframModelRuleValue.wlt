<|
  "WolframPhysicsProjectStyleData" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];
    ),
    "tests" -> {
      testSymbolLeak[
        WolframModelRuleValue[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}]
      ],

      testUnevaluated[
        WolframModelRuleValue[],
        {WolframModelRuleValue::argt}
      ],

      testUnevaluated[
        WolframModelRuleValue[1, 2, 3],
        {WolframModelRuleValue::argt}
      ],

      testUnevaluated[
        WolframModelRuleValue[#],
        {WolframModelRuleValue::invalidRule}
      ] & /@ {1, {1, 2}, {{1, 2}}, $$$invalidrule$$$, "invalidRule", {{{1, 2}} -> {{2, 3}}, {{1, 2}}}},

      testUnevaluated[
        WolframModelRuleValue[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, #],
        {WolframModelRuleValue::invalidProperty}
      ] & /@ {sdf, {sdd, "sdf"}},

      testUnevaluated[
        WolframModelRuleValue[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, #],
        {WolframModelRuleValue::unknownProperty}
      ] & /@ {"sdf", {"sdd", "sdf"}},

      testUnevaluated[
        WolframModelRuleValue[Rule[1], "NodesDroppedAdded"],
        {Rule::argr, WolframModelRuleValue::invalidRule}
      ],

      testUnevaluated[
        WolframModelRuleValue[Rule[1, 2, 3]],
        {Rule::argr, WolframModelRuleValue::invalidRule}
      ],

      testUnevaluated[
        WolframModelRuleValue[{Rule[1, 2], Rule[1, 2, 3]}, "NodesDroppedAdded"],
        {Rule::argr, WolframModelRuleValue::invalidRule}
      ],

      VerificationTest[
        Keys[WolframModelRuleValue[{}]],
        $WolframModelRuleProperties
      ],

      VerificationTest[
        Keys[WolframModelRuleValue[{{1, 2}} -> {{1, 3}, {3, 2}}]],
        $WolframModelRuleProperties
      ],

      VerificationTest[
        WolframModelRuleValue[{{1, 2}} -> {{1, 3}, {3, 2}}, {"Signature", "TransformationCount"}],
        WolframModelRuleValue[{{1, 2}} -> {{1, 3}, {3, 2}}, #] & /@ {"Signature", "TransformationCount"}
      ],

      {
        VerificationTest[
          WolframModelRuleValue[#1, "ConnectedInput"],
          #2
        ],
        VerificationTest[
          WolframModelRuleValue[#1 /. Rule[a_, b_] :> Rule[b, a], "ConnectedOutput"],
          #2
        ]
      } & @@@ {
        {1 -> 2, True},
        {{1, 2} -> 3, False},
        {{{1}, {2}} -> 3, False},
        {{{1, 2}, {2}} -> 3, True},
        {{{0, 1}, {0, 2}, {0, 3}} -> {{4, 5}, {5, 4}, {4, 6}, {6, 4}, {5, 6}, {6, 5}, {4, 1}, {5, 2}, {6, 3}}, True},
        {{{1}, {1, 2}} -> {{1, 2}, 2, {2, 3}}, True},
        {{{1, 2}} -> {{2, 3}}, True},
        {{{1, 2, 3}, {3, 4, 5}} -> {{1, 3, 5}}, True},
        {{{1, 2}, {1, 3}} -> {{2, 2}, {3, 2}, {4, 3}, {5, 4}, {5, 6}}, True},
        {{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2, 3}, {3, 4, 5}} -> {{1, 3, 5}}}, True},
        {{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2, 3}, {4, 4, 5}} -> {{1, 3, 5}}}, False},
        {{{{1, 2}, {3, 3}} -> {{1, 3}}, {{1, 2, 3}, {4, 4, 5}} -> {{1, 3, 5}}}, False},
        {{{1, 2, 3}, {4, 4, 5}} -> {{1, 3, 5}}, False},
        {{{1, 2}} -> {}, True},
        {{} -> {{1, 2}}, True},
        {{} -> {}, True},
        {{}, True}
      },

      VerificationTest[
        WolframModelRuleValue[#1, "ConnectedInputOutputUnion"],
        #2
      ] & @@@ {
        {1 -> 2, False},
        {{1, 2} -> 3, False},
        {{1, 2} -> {2, 3}, False},
        {{{1, 2}, {2, 3}} -> {{3, 4}}, True},
        {{{1, 2}, {3, 4}} -> {{2, 3}}, True},
        {{{1, 2}, {3, 4}} -> {{4, 5}}, False},
        {{{1, 2}} -> {{2, 3}, {4, 5}}, False},
        {{{1, 2}, {2, 3}} -> {{4, 5}, {5, 6}}, False},
        {{{0, 1}, {0, 2}, {0, 3}} -> {{4, 5}, {5, 4}, {4, 6}, {6, 4}, {5, 6}, {6, 5}, {4, 1}, {5, 2}, {6, 3}}, True},
        {{{1}, {1, 2}} -> {{1, 2}, 2, {2, 3}}, True},
        {{{1, 2, 3}, {4, 4, 5}} -> {{1, 3, 5}}, True},
        {{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2, 3}, {4, 4, 5}} -> {{1, 3, 2}}}, False},
        {{{1, 2}} -> {}, True},
        {{} -> {{1, 2}}, True},
        {{} -> {}, True},
        {{}, True}
      },

      VerificationTest[
        WolframModelRuleValue[#1, {"MaximumArity", "NodeCounts", "NodesDroppedAdded", "Signature"}],
        {##2}
      ] & @@@ {
        {1 -> 2, 1, 1 -> 1, {1, 1}, {{1, 1}} -> {{1, 1}}},
        {{1, 2} -> 3, 1, 2 -> 1, {2, 1}, {{2, 1}} -> {{1, 1}}},
        {{{1}, {2}} -> {{3}}, 1, 2 -> 1, {2, 1}, {{2, 1}} -> {{1, 1}}},
        {{{1, 2}, {2}} -> {{1}, {1, 2}}, 2, 2 -> 2, {0, 0}, {{1, 1}, {1, 2}} -> {{1, 1}, {1, 2}}},
        {{{1, 2}, {2}} -> {{1}}, 2, 2 -> 1, {1, 0}, {{1, 1}, {1, 2}} -> {{1, 1}}},
        {{{2}} -> {{1}, {1, 2}}, 2, 1 -> 2, {0, 1}, {{1, 1}} -> {{1, 1}, {1, 2}}},
        {{{0, 1}, {0, 2}, {0, 3}} -> {{4, 5}, {5, 4}, {4, 6}, {6, 4}, {5, 6}, {6, 5}, {4, 1}, {5, 2}, {6, 3}},
          2, 4 -> 6, {1, 3}, {{3, 2}} -> {{9, 2}}},
        {{{1}, {1, 2}} -> {{1, 2}, 2, {2, 3}}, 2, 2 -> 3, {0, 1}, {{1, 1}, {1, 2}} -> {{1, 1}, {2, 2}}},
        {{{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2, 3}, {3, 4, 5}} -> {{1, 3, 5}}},
          3, {3 -> 2, 5 -> 3}, {{1, 0}, {2, 0}}, {{{2, 2}} -> {{1, 2}}, {{2, 3}} -> {{1, 3}}}},
        {{{1, 2}} -> {}, 2, 2 -> 0, {2, 0}, {{1, 2}} -> {}},
        {{} -> {{1, 2}}, 2, 0 -> 2, {0, 2}, {} -> {{1, 2}}},
        {{} -> {}, 0, 0 -> 0, {0, 0}, {} -> {}},
        {{}, 0, {}, {}, {}}
      },

      VerificationTest[
        WolframModelRuleValue[#1, "SignatureTraditionalForm"],
        #2
      ] & @@@ {
        {1 -> 2, Subscript[1, 1] -> Subscript[1, 1]},
        {{{1, 2}, {2}} -> {{1}, {1, 2}},
          Row[{Subscript[1, 1], Subscript[1, 2]}] -> Row[{Subscript[1, 1], Subscript[1, 2]}]},
        {{{1, 2}} -> {}, Subscript[1, 2] -> "\[EmptySet]"},
        {{} -> {{1, 2}}, "\[EmptySet]" -> Subscript[1, 2]},
        {{} -> {}, "\[EmptySet]" -> "\[EmptySet]"},
        {{}, {}}
      },

      VerificationTest[
        WolframModelRuleValue[#1, "TransformationCount"],
        #2
      ] & @@@ {
        {1 -> 2, 1},
        {{{1}} -> {{1}}, 1},
        {{1 -> 2, 3 -> 4}, 2},
        {{}, 0}
      }
    }]
  |>,

  "$WolframModelRuleProperties" -> <|
    "tests" -> {
      VerificationTest[
        ListQ @ $WolframModelRuleProperties
      ],

      VerificationTest[
        Length[$WolframModelRuleProperties] > 0
      ],

      VerificationTest[
        AllTrue[StringQ, $WolframModelRuleProperties]
      ],

      VerificationTest[
        OrderedQ[$WolframModelRuleProperties]
      ]
    }
  |>
|>
