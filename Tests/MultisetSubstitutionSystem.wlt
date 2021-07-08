<|
  "Multiset System API" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];
    ),
    "tests" -> {
      (* Symbol Leak *)
      testSymbolLeak[GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} :> {a + b}], {1, 2, 3}]],

      (* Rules *)
      testUnevaluated[GenerateMultihistory[MultisetSubstitutionSystem[##2], {1}], {#}] & @@@ {
        {MultisetSubstitutionSystem::argx},
        {MultisetSubstitutionSystem::argx, 1, 2},
        {GenerateMultihistory::invalidMultisetRules, 1},
        {GenerateMultihistory::ruleOutputNotList, {1} -> 2}},

      (* Init *)
      testUnevaluated[GenerateMultihistory[MultisetSubstitutionSystem[{1} -> {2}], 1], {}],

      (* Parameters *)
      testUnevaluated[GenerateMultihistory[MultisetSubstitutionSystem[{1} -> {2}], {1}, # -> -1],
                      {GenerateMultihistory::invalidParameter}] & /@
        {MaxGeneration, MaxDestroyerEvents, MinEventInputs, MaxEventInputs, MaxEvents}
    }
  |>,
  "Multiset System Rules" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];

      (* These will not be necessary once we have properties. *)
      allExpressions[Multihistory[_, data_]] := Normal @ data["Expressions"];
      eventCount[Multihistory[_, data_]] := data["EventRuleIndices"]["Length"] - 1;
      lastEventGeneration[Multihistory[_, data_]] := data["EventGenerations"]["Part", -1];
    ),
    "tests" -> {
      Function[{rules, parameters, init, expectedCreatedExpressions},
          VerificationTest[allExpressions @ GenerateMultihistory[MultisetSubstitutionSystem[rules], init, parameters],
                           Join[init, expectedCreatedExpressions],
                           SameTest -> MatchQ]] @@@
        {{{1} -> {1}, MaxEvents -> 1, {1}, {1}},
         (* 1 does not match any lists, {1} should be used for matching a single 1 as an expression *)
         {1 -> 2, MaxEvents -> 1, {1, 2, 3}, {}},
         {{1} -> {2}, MaxGeneration -> 1, {1, 2, 3}, {2}},
         {{2} -> {5}, MaxGeneration -> 1, {1, 2, 3}, {5}},
         {{2} :> {5}, MaxGeneration -> 1, {1, 2, 3}, {5}},
         {{{2} :> {5}, {3} :> {6}}, MaxGeneration -> 1, {1, 2, 3}, {5, 6}},
         {{{2} -> {5}, {3} :> {6}}, MaxGeneration -> 1, {1, 2, 3}, {5, 6}},
         {{{2} -> {5}, {3} :> {6}}, MaxGeneration -> 2, {1, 2, 3}, {5, 6}},
         {{3, 2} -> {5}, MaxGeneration -> 1, {1, 2, 3}, {5}},
         {{4} -> {5}, MaxGeneration -> 1, {1, 2, 3}, {}},
         {{{1}} :> {}, MaxGeneration -> 1, {{1}}, {}},
         {{{1}, {2}} :> {{3}}, MaxGeneration -> 1, {{1}, {2}}, {{3}}},
         {{{1}, {2}} :> {{3}}, MaxGeneration -> 1, {{2}, {1}}, {{3}}},
         {{x_List ? (Length[#] == 3 &), y_List ? (Length[#] == 6 &)} :> {x, y, Join[x, y]},
          {MaxGeneration -> 2, MaxEventInputs -> 6},
          {"This" -> "that", {2, 3, 4}, {2, 5}, {1, 2, 3, 4, 5, 6}},
          {{2, 3, 4}, {1, 2, 3, 4, 5, 6}, {2, 3, 4, 1, 2, 3, 4, 5, 6}, {2, 3, 4}, {1, 2, 3, 4, 5, 6},
           {2, 3, 4, 1, 2, 3, 4, 5, 6}}},
         {{x_List /; (Length[x] == 3), y_List /; (Length[y] == 6)} :> {x, y, Join[x, y]},
          {MaxGeneration -> 2, MaxEventInputs -> 6},
          {"This" -> "that", {2, 3, 4}, {2, 5}, {1, 2, 3, 4, 5, 6}},
          {{2, 3, 4}, {1, 2, 3, 4, 5, 6}, {2, 3, 4, 1, 2, 3, 4, 5, 6}, {2, 3, 4}, {1, 2, 3, 4, 5, 6},
           {2, 3, 4, 1, 2, 3, 4, 5, 6}}},
         {{{a_, b_}, {b_, c_}} :> {{a, c}},
          {MaxGeneration -> 3, MaxDestroyerEvents -> 1},
          {{1, 2}, {2, 3}, {3, 4}, {4, 5}},
          {{1, 3}, {3, 5}, {1, 5}}},
         {{{a_, b_}, {b_, c_}} :> {{a, c}},
          MaxGeneration -> 2,
          {{1, 2}, {2, 3}, {3, 4}, {4, 5}},
          {{1, 3}, {2, 4}, {1, 4}, {3, 5}, {2, 5}, {1, 4}, {2, 5}, {1, 5}}},
         {{{a_, b_}, {b_, c_}} :> {{a, c}},
          MaxGeneration -> 1,
          {{1, 2}, {2, 3}, {3, 4}, {4, 5}},
          {{1, 3}, {2, 4}, {3, 5}}},
         {{{_}} -> {}, {}, {{1}, {2}, {3}, {4}, {5}}, {}},
         {{{1}} -> {{2}}, MaxGeneration -> 1, {{1}, {1}, {1}}, {{2}, {2}, {2}}},
         {{{v[a1_], v[a2_]}, {v[a2_], v[a3_]}} :> {{v[a1], v[a3]}},
          MaxGeneration -> 1,
          {{v[1], v[2]}, {v[2], v[3]}},
          {{v[1], v[3]}}},
         (* Nested lists of vertices *)
         {ToPatternRules[{{2, 2, 1}, {2, 2, 2}} -> {{1, 1, 3}, {1, 1, 1}, {2, 1, 2}, {3, 3, 2}}],
          MaxGeneration -> 2,
          {Table[{0, 0, 0}, 3]},
          {}},
         {ToPatternRules[{{2, 2, 1}, {2, 2, 2}} -> {{1, 1, 3}, {1, 1, 1}, {2, 1, 2}, {3, 3, 2}}],
          MaxGeneration -> 1,
          {{{2}, {2}, 1}, {{2}, {2}, {2}}},
          {{1, 1, v2_ ? AtomQ}, {1, 1, 1}, {{2}, 1, {2}}, {v2_ ? AtomQ, v2_ ? AtomQ, {2}}}},
         {ToPatternRules[{{1, 1, 1}} -> {{1, 1, 1, 1}}],
          MaxGeneration -> 2,
          {Table[{0, 0, 0}, 3]},
          {ConstantArray[{0, 0, 0}, 4]}},
         (* Potential variable collision between different rule inputs and outputs *)
         {ToPatternRules[{{{1, 1}, {2, 3}} -> {{2, 1}, {2, 2}, {2, 3}, {4, 2}}, {{1, 2}, {1, 2}} -> {{3, 2}}}],
          MaxEvents -> 1,
          {{1, 0}, {6, 1}, {1, 0}, {1, 1}, {1, 0}, {7, 1}, {3, 0}, {3, 3}, {3, 1}, {8, 3}, {4, 0}, {4, 4}, {4, 0},
           {9, 4}, {2, 2}, {2, 2}, {2, 0}, {10, 2}, {2, 1}, {2, 2}, {2, 0}, {11, 2}, {5, 1}, {5, 5}, {5, 2}, {12, 5}},
          {{_Symbol, 0}}},
         {ToPatternRules[{{1, 2} -> {}, {1} -> {2}}], MaxEvents -> 1, {{1}}, {_ ? AtomQ}},
         {{0} :> {1, 2}, MaxEvents -> 2, {0}, {1, 2}},
         (* there is only one created expression because the empty set {} can only be matched once *)
         {{} :> {0}, MaxEvents -> 2, {}, {0}},
         {{x_, y_} /; OddQ[x + y] :> {x + y}, MaxDestroyerEvents -> 1, Range[10], {3, 7, 11, 15, 19}},
         {{x_, y_} /; Mod[x + y, 2] == 0 :> {x + y},
          MaxDestroyerEvents -> 1,
          Range[10],
          {4, 6, 12, 14, 14, 18, 28, 46}},
         {{x_, y_} /; x >= 8 :> {x - 8, y + 8},
          {MaxGeneration -> 20, MaxDestroyerEvents -> 1},
          Range[10],
          {__ ? (Not @* Negative)}},
         {{x___} /; Plus[x] == 5 && OrderedQ[{x}] :> {Length[{x}]}, MaxGeneration -> 2, {1, 2, 3, 5}, {1, 2, 3, 3}},
         {{x_, y_} /; x < y :> Module[{z = Hash[{x, y}]}, {z}],
          MaxDestroyerEvents -> 1,
          {1, 2, 3, 4},
          {Hash[{1, 2}], Hash[{3, 4}], Hash[Sort @ {Hash[{1, 2}], Hash[{3, 4}]}]}},
         {{x__, y__} /; OrderedQ[Catenate[{x, y}]] :> {Catenate[{x, y}]},
          MaxEventInputs -> 3,
          {{1}, {2}, {3}},
          {{1, 2}, {1, 3}, {2, 3}, {1, 2, 3}, {1, 2, 3}, {1, 2, 3}, {1, 2, 3}}},
         {{a__, b__} /; OrderedQ[{a, b}] :> {{a}, {b}},
          {MaxGeneration -> 1, MinEventInputs -> 3, MaxEventInputs -> 3},
          {1, 2, 3},
          {{1}, {2, 3}, {1, 2}, {3}}},
         {{Longest[a__], b__} /; OrderedQ[{a, b}] :> {{a}, {b}},
          {MaxGeneration -> 1, MinEventInputs -> 3, MaxEventInputs -> 3},
          {1, 2, 3},
          {{1, 2}, {3}, {1}, {2, 3}}},
         {{a_Integer, b_Integer} :> {a + b}, MaxGeneration -> 1, {1, 2, 3, "x"}, {3, 3, 4, 4, 5, 5}},
         {{PatternSequence[a_, b_], c_} :> {a + b + c}, MaxGeneration -> 1, {1, 2, 3}, ConstantArray[6, 6]},
         {{x_ | Repeated[x_, {2}]} :> {2 x}, MaxGeneration -> 1, {1, 1, 1}, ConstantArray[2, 9]},
         {{Alternatives[]} :> {}, {}, Range[1000], {}}, (* empty Alternatives does not match to anything *)
         {{x_ ..} :> {x + 1}, MaxGeneration -> 1, {1, 1}, ConstantArray[2, 4]},
         {{Repeated[x_, 2]} :> {x + 1}, MaxGeneration -> 1, {1, 1, 1}, ConstantArray[2, 9]},
         {{Repeated[x_, {2, 3}]} :> {x + 1}, MaxGeneration -> 1, {1, 1, 1}, ConstantArray[2, 12]},
         {{Repeated[x_, {2}]} :> {x + 1}, MaxGeneration -> 1, {1, 1, 1}, ConstantArray[2, 6]},
         {{x_ ...} :> {x + 1}, MaxGeneration -> 1, {1}, {1, 2, 2, 2, 2}},
         {{RepeatedNull[x_, 2]} :> {x + 1}, MaxGeneration -> 1, {1, 1}, Join[{1}, ConstantArray[2, 9]]},
         {{RepeatedNull[x_, {2, 3}]} :> {x + 1}, MaxGeneration -> 1, {1, 1, 1}, ConstantArray[2, 12]},
         {{RepeatedNull[x_, {2}]} :> {x + 1}, MaxGeneration -> 1, {1, 1, 1}, ConstantArray[2, 6]},
         {{x : Except[1]} :> {x + 1}, MaxGeneration -> 1, Range[10], Range[3, 11]},
         {{x : Except[1, _Integer]} :> {x + 1}, MaxGeneration -> 1, {0, 1, "x"}, {1}},
         {{Longest[Repeated[x_, {2}]]} :> {x + 1}, MaxGeneration -> 1, {1, 1, 1}, ConstantArray[2, 6]},
         {{Shortest[Repeated[x_, {2}]]} :> {x + 1}, MaxGeneration -> 1, {1, 1, 1}, ConstantArray[2, 6]},
         {{OptionsPattern[]} :> {3}, MaxGeneration -> 1, {1, {"test" -> 2}}, {3, 3}},
         {{OptionsPattern[], OptionsPattern[]} :> {3}, MaxGeneration -> 1, {1, {"test" -> 2}}, {3, 3, 3}},
         {{PatternSequence[x_, y_]} :> {x + y}, MaxGeneration -> 1, {1, 2, 3}, {3, 3, 4, 4, 5, 5}},
         {{Verbatim[_], Verbatim[_]} :> {4}, MaxGeneration -> 1, {_, _, 2, 3}, {4, 4}},
         {{HoldPattern[_[x_ + x_]]} :> {0}, MaxGeneration -> 1, {Hold[2 + 2], Hold[2 + 3], Hold[x + x]}, {0, 0, 0, 0}},
         {{OrderlessPatternSequence[x_, y_]} :> {x + y},
          MaxGeneration -> 1,
          {1, 2, 3},
          Catenate[ConstantArray[#, 4] & /@ {3, 4, 5}]},
         {{KeyValuePattern[{}]} :> {3}, MaxGeneration -> 1, {1, {}, {"test" -> 2}}, {3, 3}},
         {{a_ /; OddQ[a], (b_ ? EvenQ)} :> {a + b}, MaxGeneration -> 1, {1, 2, 3, 4}, {3, 5, 5, 7}},
         {{a_ : 0} :> {a}, MaxGeneration -> 1, {1, 2, 3, 4}, {0, 1, 2, 3, 4, 0}},
         {HoldPattern @ {_[x_ + x_]} :> {0}, MaxGeneration -> 1, {Hold[2 + 2], Hold[2 + 3], Hold[x + x]}, {0, 0, 0, 0}},
         {{x_} | HoldPattern[{x_, y_}] :> {x + y}, MaxGeneration -> 1, {1, 2, 3}, {1, 2, 3, 3, 3, 4, 4, 5, 5}},
         {{a_, b_} /; OddQ[a] && EvenQ[b] :> {a + b}, MaxGeneration -> 1, {1, 2, 3, 4}, {3, 5, 5, 7}},
         {x : {_, _} :> {Total[x]}, MaxGeneration -> 1, {1, 2, 3, 4}, {3, 3, 4, 4, 5, 5, 5, 5, 6, 6, 7, 7}},
         {Except[{1, 2}, {a_, b_}] /; a < b :> {a + b}, MaxGeneration -> 1, {1, 2, 3, 4}, {4, 5, 5, 6, 7}},
         {Verbatim[{_, __}] :> {0}, MaxGeneration -> 1, {_, __, 1}, {0}}},

      VerificationTest[
        eventCount @ GenerateMultihistory[MultisetSubstitutionSystem[{{1}} :> {}], {{1}}, MaxGeneration -> 1], 1],

      Function[{rules, parameters, init, expectedMaxGeneration, expectedEventCount},
          VerificationTest[
            Through[{lastEventGeneration, eventCount} @ GenerateMultihistory[
              MultisetSubstitutionSystem[rules], init, parameters]],
            {expectedMaxGeneration, expectedEventCount}]] @@@
        {{{{a_, b_}} :> Module[{c}, {{a, c}, {c, b}}], MaxGeneration -> 7, {{1, 2}}, 7, 2^7 - 1},
         {{{_}} :> {}, {}, {{1}, {2}, {3}, {4}, {5}}, 1, 5},
         {{{x_}} :> {{x}}, MaxGeneration -> 0, {{1}, {2}, {3}, {4}, {5}}, 0, 0},
         {{{{_}} :> {}, {{x_, _}} :> {{x}}}, MaxGeneration -> 2, {{1, 2}, {2}, {3}, {4}, {5}}, 2, 6}},

      (* Test invalid patterns *)
      testUnevaluated[
          eventCount @ GenerateMultihistory[MultisetSubstitutionSystem[#], {{1}}, MaxGeneration -> 1],
          {Pattern::patvar, GenerateMultihistory::ruleInstantiationMessage}] & /@
        {{{{Pattern[1, _], v2_}} :> {}, {{Pattern[2, _], v1_}} :> Module[{v2}, {v2}]},
         {{{Pattern[Pattern[a, _], _], v2_}} :> {}, {{Pattern[2, _], v1_}} :> Module[{v2}, {v2}]}}
    }
  |>,
  "Multiset System Matching" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];

      (* This will not be necessary once we have properties. *)
      allExpressions[Multihistory[_, data_]] := Normal @ data["Expressions"];
    ),
    "tests" -> {
      Function[{rule, parameters, init, expectedCreatedExpressions},
        VerificationTest[allExpressions @ GenerateMultihistory[MultisetSubstitutionSystem[rule], init, parameters],
                         Join[init, expectedCreatedExpressions]]
      ] @@@ {
        (* multihistory branching *)
        {{{1} -> {2}, {1} -> {3}}, {}, {1}, {2, 3}},
        {{{1} -> {2}, {1} -> {3}}, MaxDestroyerEvents -> 1, {1}, {2}},
        (* no branchlike-expressions matching *)
        {{{1} -> {2}, {1} -> {3}, {2, 3} -> {4}}, {}, {1}, {2, 3}},
        (* no timelike-expressions matching *)
        {{{1} -> {2}, {2} -> {3}, {2, 3} -> {4}}, {}, {1}, {2, 3}},
        (* spacelike-expressions matching *)
        {{{1} -> {2, 3}, {2, 3} -> {4}}, {}, {1}, {2, 3, 4}},
        (* no instantiating the same match multiple times *)
        {{1} -> {2}, {}, {1}, {2}},
        (* no matching rules that don't match *)
        {{a_, a_} :> {0}, {}, {1, 2}, {}},
        (* no mixed spacelike/branchlike matching *)
        {{{{v, i}} -> {{v, 1}, {v, 2}},
          {{v, 1}} -> {{v, 1, 1}, {v, 1, 2}},
          {{v, 1, 1}, {v, 2}} -> {{v, f, 1}},
          {{v, 1, 2}, {v, 2}} -> {{v, f, 2}},
          {{v, f, 1}, {v, f, 2}} -> {{f}}},
         {},
         {{v, i}},
         {{v, 1}, {v, 2}, {v, 1, 1}, {v, 1, 2}, {v, f, 1}, {v, f, 2}}},
        (* single-history spacelike merging *)
        {{{{a_}, {a_, b_}} :> {{a, b}, {b}}, {{a_}, {a_}} :> {{a, a, a}}},
         MaxDestroyerEvents -> 1,
         {{a1}, {a1, a2}, {a2, a3}, {a3, m1}, {b1}, {b1, b2}, {b2, m1}, {m1, m2}},
         {{a1, a2}, {a2}, {a2, a3}, {a3}, {a3, m1}, {m1}, {b1, b2}, {b2}, {b2, m1}, {m1}, {m1, m2}, {m2}, {m1, m2},
          {m2}, {m2, m2, m2}}},
        (* multihistory spacelike merging *)
        {{{{a_}, {a_, b_}} :> {{b}}, {{a_}, {a_}} :> {{a, a, a}}},
         {},
         {{a1}, {a1, a2}, {a2, a3}, {a3, m1}, {b1}, {b1, b2}, {b2, m1}, {m1, m2}},
         {{a2}, {a3}, {m1}, {b2}, {m1}, {m2}, {m2}, {m1, m1, m1}, {m1, m1, m1}}},
        (* no single-history branchlike merging *)
        {{{{a_}, {a_, b_}} :> {{a, b}, {b}}, {{a_}, {a_}} :> {{a, a, a}}},
         MaxDestroyerEvents -> 1,
         {{o1}, {o1, a1}, {o1, b1}, {a1, a2}, {a2, a3}, {a3, m1}, {b1, b2}, {b2, m1}, {m1, m2}},
         {{o1, a1}, {a1}, {a1, a2}, {a2}, {a2, a3}, {a3}, {a3, m1}, {m1}, {m1, m2}, {m2}}},
        (* no multihistory branchlike merging *)
        {{{{a_}, {a_, b_}} :> {{b}}, {{a_}, {a_}} :> {{a, a, a}}},
         {},
         {{o1}, {o1, a1}, {o1, b1}, {a1, a2}, {a2, a3}, {a3, m1}, {b1, b2}, {b2, m1}, {m1, m2}},
         {{a1}, {b1}, {a2}, {a3}, {m1}, {b2}, {m1}, {m2}, {m2}}}},

      (* non-overlapping systems produce the same behavior *)
      (* "InstantiationCounts" stores the sequences of expressions that were tried but do not match.
         "MaxDestroyerEvents" prevents some of these sequences to be tried in the first place, thus changing
         "InstantiationCounts" *)
      VerificationTest[
        With[{
            serializeMultihistory = (Normal /@ # &) /@ Normal /@ KeyDrop[Last @ #, "InstantiationCounts"] &,
            multihistories = GenerateMultihistory[
              MultisetSubstitutionSystem[
                {{v1_, v2_}, {v2_, v3_, v4_}} :>
                    Module[{v5 = Hash[{{v1, v2}, {v2, v3, v4}}]}, {{v2, v3}, {v3, v4, v5}, {v1, v2, v3, v4}}]],
                {{1, 2}, {2, 3, 4}},
                MaxEvents -> 30, MaxDestroyerEvents -> #] & /@ {1, Infinity}},
          SameQ @@ serializeMultihistory /@ multihistories]
      ]
    }
  |>,
  "Multiset System Ordering" -> <|
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
        VerificationTest[lastEventInputs @ GenerateMultihistory[MultisetSubstitutionSystem[rule], init, MaxEvents -> 1],
                         lastEventInputsOutput]
      ] @@@ {
        {{{2, 3, 4} -> {X}, {3} -> {X}}, {1, 2, 3, 4, 5}, {3}},
        {{{b_, _}, {_, b_}} :> {}, {{1, 2}, {3, 4}, {4, 5}, {2, 3}, {a, b}, {b, c}, {5, 6}}, {4, 1}},
        {ToPatternRules[{{{1, 2}, {2, 3}} -> {{1, 3}, {2, 4}, {4, 3}}, {{1, 1}, {2, 1}} -> {{1, 1}}}],
         {{2, 2}, {1, 4}, {4, 2}, {1, 2}, {3, 5}, {5, 2}},
         {1, 3}}},

      Function[{rule, inits, lastExpressions},
        VerificationTest[
          lastExpression @* GenerateMultihistory[MultisetSubstitutionSystem[rule], MaxEvents -> 1] /@ inits,
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
         {{2, x, y}, {1, x, z}, {2, y, x}, {1, y, z}, {1, x, z}, {1, y, z}}}}
    }
  |>,
  "Multiset System Selection and Stopping" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];

      (* These will not be necessary once we have properties. *)
      allExpressions[Multihistory[_, data_]] := Normal @ data["Expressions"];
      eventCount[Multihistory[_, data_]] := data["EventRuleIndices"]["Length"] - 1;
      maxEventGeneration[Multihistory[_, data_]] := Max @ Normal @ data["EventGenerations"];
      terminationReason[Multihistory[_, data_]] := data["TerminationReason"];
      destroyerEventCounts[Multihistory[_, data_]] := Normal @ data["ExpressionDestroyerEventCounts"];
    ),
    "tests" -> {
      Function[{
          rule, parameters, init, expectedMaxEventGeneration, expectedEventCount, expectedTerminationReason},
        VerificationTest[
          Through[{maxEventGeneration, eventCount, terminationReason} @
            GenerateMultihistory[MultisetSubstitutionSystem[rule], init, parameters]],
          {expectedMaxEventGeneration, expectedEventCount, expectedTerminationReason}]
      ] @@@ {
        (* Complete is returned if MaxGeneration is reached because MaxGeneration is not a stopping condition *)
        {{_} :> {Unique[]}, MaxGeneration -> 2, {1}, 2, 2, "Complete"},
        {{_} :> {Unique[]}, MaxGeneration -> 0, {1}, 0, 0, "Complete"},
        {{_} :> {Unique[]}, {MaxGeneration -> 3, MaxEvents -> 2}, {1}, 2, 2, "MaxEvents"},
        {{_} :> {Unique[]}, MaxEvents -> 0, {1}, 0, 0, "MaxEvents"},
        {ToPatternRules[{{0, 1}} -> {{0, 2}, {2, 1}}], MaxGeneration -> 3, {{0, 1}}, 3, 7, "Complete"},
        {ToPatternRules[{{0, 1}} -> {{0, 2}, {2, 1}}], MaxEvents -> 6, {{0, 1}}, 3, 6, "MaxEvents"},
        {ToPatternRules[{{0, 1}} -> {{0, 2}, {2, 1}}], {MaxGeneration -> 3, MaxEvents -> 6}, {{0, 1}},
         3, 6, "MaxEvents"},
        {ToPatternRules[{{0, 1}} -> {{0, 2}, {2, 1}}], {MaxGeneration -> 2, MaxEvents -> 6}, {{0, 1}},
         2, 3, "Complete"},
        {ToPatternRules[{{0, 1}, {1, 2}} -> {{0, 2}}], MaxDestroyerEvents -> 1, {{0, 1}, {1, 2}, {2, 3}, {3, 4}},
         2, 3, "Complete"},
        {ToPatternRules[{{0, 1}, {1, 2}} -> {{0, 2}}], MaxDestroyerEvents -> 2, {{0, 1}, {1, 2}, {2, 3}, {3, 4}},
         2, 6, "Complete"},
        {ToPatternRules[{{0, 1}, {1, 2}} -> {{0, 2}}], MaxDestroyerEvents -> 3, {{0, 1}, {1, 2}, {2, 3}, {3, 4}},
         3, 10, "Complete"},
        {ToPatternRules[{{0, 1}, {1, 2}} -> {{0, 2}}], {}, {{0, 1}, {1, 2}, {2, 3}, {3, 4}}, 3, 12, "Complete"},
        {ToPatternRules[{{0, 1}, {1, 2}} -> {{0, 2}}], MaxDestroyerEvents -> 0, {{0, 1}, {1, 2}, {2, 3}, {3, 4}},
         0, 0, "Complete"}},

      With[{init = {1, 2, 3, 4, 5, 2/3, 5/3, 7/3}},
        VerificationTest[
          allExpressions @ GenerateMultihistory[
            MultisetSubstitutionSystem[{n___} /; Plus[n] == 5 && OrderedQ[{n}] :> {{n}}],
            init,
            MinEventInputs -> #1, MaxEventInputs -> #2, MaxGeneration -> 1],
          Join[init, #3],
          SameTest -> MatchQ]
      ] & @@@
        {{1, 2, {{5}, {1, 4}, {2, 3}}}, {2, 3, {{1, 4}, {2, 3}, {1, 5/3, 7/3}, {2/3, 2, 7/3}}}, {2, 0, {}}},

      VerificationTest[
          destroyerEventCounts @ GenerateMultihistory[
            MultisetSubstitutionSystem[ToPatternRules[{{1, 2}, {2, 3}} -> {{2, 3}, {2, 4}, {3, 4}, {2, 1}}]],
            {{1, 1}, {1, 1}},
            MaxDestroyerEvents -> #, MaxEvents -> 5],
          #2,
          SameTest -> MatchQ] & @@@
       {{2, {2, 2, 2, 2, 1, 1, 0..}}, {3, {2, 2, 3, 1, 1, 1, 0..}}}
    }
  |>
|>
