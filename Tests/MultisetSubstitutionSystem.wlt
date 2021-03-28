<|
  "Multiset System API" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];
    ),
    "tests" -> {
      With[{anEventOrdering = {"InputCount", "SortedInputExpressions", "UnsortedInputExpressions", "RuleIndex"}}, {
        (* Symbol Leak *)

        testSymbolLeak[
          GenerateMultihistory[
              MultisetSubstitutionSystem[{a_, b_} :> {a + b}], <|"MaxEventInputs" -> 2|>, None, anEventOrdering, <||>] @
            {1, 2, 3}],

        (* Rules *)

        testUnevaluated[
            GenerateMultihistory[MultisetSubstitutionSystem[##2], <||>, None, anEventOrdering, <||>] @ {1}, {#}] & @@@
          {{MultisetSubstitutionSystem::argx},
           {MultisetSubstitutionSystem::argx, 1, 2},
           {GenerateMultihistory::invalidMultisetRules, 1},
           {GenerateMultihistory::ruleOutputNotList, {1} -> 2}},

        (* Init *)

        testUnevaluated[
          GenerateMultihistory[MultisetSubstitutionSystem[{1} -> {2}], <||>, None, anEventOrdering, <||>] @ 1,
          {GenerateMultihistory::multisetInitNotList}],

        (* Parameters *)

        testUnevaluated[
            GenerateMultihistory[MultisetSubstitutionSystem[{1} -> {2}], <|# -> -1|>, None, anEventOrdering, <||>] @
              {1},
            {GenerateMultihistory::notNonNegativeIntegerOrInfinityParameter}] & /@
          {"MaxGeneration", "MaxDestroyerEvents", "MinEventInputs", "MaxEventInputs"},

        testUnevaluated[
          GenerateMultihistory[
              MultisetSubstitutionSystem[{1} -> {2}], <||>, None, anEventOrdering, <|"MaxEvents" -> -1|>] @ {1},
          {GenerateMultihistory::notNonNegativeIntegerOrInfinityParameter}]
      }]
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
      With[{anEventOrdering = {"InputCount", "SortedInputExpressions", "UnsortedInputExpressions", "RuleIndex"}}, {
        Function[{rules, selection, stopping, init, expectedCreatedExpressions},
            VerificationTest[
              allExpressions @ GenerateMultihistory[
                MultisetSubstitutionSystem[rules], selection, None, anEventOrdering, stopping] @ init,
              Join[init, expectedCreatedExpressions],
              SameTest -> MatchQ]] @@@
          {{{1} -> {1}, <||>, <|"MaxEvents" -> 1|>, {1}, {1}},
           (* 1 does not match any lists, {1} should be used for matching a single 1 *)
           {1 -> 2, <||>, <|"MaxEvents" -> 1|>, {1, 2, 3}, {}},
           {{1} -> {2}, <|"MaxGeneration" -> 1|>, <||>, {1, 2, 3}, {2}},
           {{2} -> {5}, <|"MaxGeneration" -> 1|>, <||>, {1, 2, 3}, {5}},
           {{2} :> {5}, <|"MaxGeneration" -> 1|>, <||>, {1, 2, 3}, {5}},
           {{{2} :> {5}, {3} :> {6}}, <|"MaxGeneration" -> 1|>, <||>, {1, 2, 3}, {5, 6}},
           {{{2} -> {5}, {3} :> {6}}, <|"MaxGeneration" -> 1|>, <||>, {1, 2, 3}, {5, 6}},
           {{{2} -> {5}, {3} :> {6}}, <|"MaxGeneration" -> 2|>, <||>, {1, 2, 3}, {5, 6}},
           {{3, 2} -> {5}, <|"MaxGeneration" -> 1|>, <||>, {1, 2, 3}, {5}},
           {{4} -> {5}, <|"MaxGeneration" -> 1|>, <||>, {1, 2, 3}, {}},
           {{{1}} :> {}, <|"MaxGeneration" -> 1|>, <||>, {{1}}, {}},
           {{{1}, {2}} :> {{3}}, <|"MaxGeneration" -> 1|>, <||>, {{1}, {2}}, {{3}}},
           {{{1}, {2}} :> {{3}}, <|"MaxGeneration" -> 1|>, <||>, {{2}, {1}}, {{3}}},
           {{x_List ? (Length[#] == 3 &), y_List ? (Length[#] == 6 &)} :> {x, y, Join[x, y]},
            <|"MaxGeneration" -> 2, "MaxEventInputs" -> 6|>,
            <||>,
            {"This" -> "that", {2, 3, 4}, {2, 5}, {1, 2, 3, 4, 5, 6}},
            {{2, 3, 4}, {1, 2, 3, 4, 5, 6}, {2, 3, 4, 1, 2, 3, 4, 5, 6}, {2, 3, 4}, {1, 2, 3, 4, 5, 6},
             {2, 3, 4, 1, 2, 3, 4, 5, 6}}},
           {{x_List /; (Length[x] == 3), y_List /; (Length[y] == 6)} :> {x, y, Join[x, y]},
            <|"MaxGeneration" -> 2, "MaxEventInputs" -> 6|>,
            <||>,
            {"This" -> "that", {2, 3, 4}, {2, 5}, {1, 2, 3, 4, 5, 6}},
            {{2, 3, 4}, {1, 2, 3, 4, 5, 6}, {2, 3, 4, 1, 2, 3, 4, 5, 6}, {2, 3, 4}, {1, 2, 3, 4, 5, 6},
             {2, 3, 4, 1, 2, 3, 4, 5, 6}}},
           {{{a_, b_}, {b_, c_}} :> {{a, c}},
            <|"MaxGeneration" -> 3, "MaxDestroyerEvents" -> 1|>,
            <||>,
            {{1, 2}, {2, 3}, {3, 4}, {4, 5}},
            {{1, 3}, {3, 5}, {1, 5}}},
           {{{a_, b_}, {b_, c_}} :> {{a, c}},
            <|"MaxGeneration" -> 2, "MaxEventInputs" -> 2|>,
            <||>,
            {{1, 2}, {2, 3}, {3, 4}, {4, 5}},
            {{1, 3}, {2, 4}, {1, 4}, {3, 5}, {2, 5}, {1, 4}, {2, 5}, {1, 5}}},
           {{{a_, b_}, {b_, c_}} :> {{a, c}},
            <|"MaxGeneration" -> 1, "MaxEventInputs" -> 2|>,
            <||>,
            {{1, 2}, {2, 3}, {3, 4}, {4, 5}},
            {{1, 3}, {2, 4}, {3, 5}}},
           {{{_}} -> {}, <||>, <||>, {{1}, {2}, {3}, {4}, {5}}, {}},
           {{{1}} -> {{2}}, <|"MaxGeneration" -> 1|>, <||>, {{1}, {1}, {1}}, {{2}, {2}, {2}}},
           {{{v[a1_], v[a2_]}, {v[a2_], v[a3_]}} :> {{v[a1], v[a3]}},
            <|"MaxGeneration" -> 1|>,
            <||>,
            {{v[1], v[2]}, {v[2], v[3]}},
            {{v[1], v[3]}}},
           (* Nested lists of vertices *)
           {ToPatternRules[{{2, 2, 1}, {2, 2, 2}} -> {{1, 1, 3}, {1, 1, 1}, {2, 1, 2}, {3, 3, 2}}],
            <|"MaxGeneration" -> 2|>,
            <||>,
            {Table[{0, 0, 0}, 3]},
            {}},
           {ToPatternRules[{{2, 2, 1}, {2, 2, 2}} -> {{1, 1, 3}, {1, 1, 1}, {2, 1, 2}, {3, 3, 2}}],
            <|"MaxGeneration" -> 1|>,
            <||>,
            {{{2}, {2}, 1}, {{2}, {2}, {2}}},
            {{1, 1, v2_ ? AtomQ}, {1, 1, 1}, {{2}, 1, {2}}, {v2_ ? AtomQ, v2_ ? AtomQ, {2}}}},
           {ToPatternRules[{{1, 1, 1}} -> {{1, 1, 1, 1}}],
            <|"MaxGeneration" -> 2|>,
            <||>,
            {Table[{0, 0, 0}, 3]},
            {ConstantArray[{0, 0, 0}, 4]}},
           (* Potential variable collision between different rule inputs and outputs *)
           {ToPatternRules[{{{1, 1}, {2, 3}} -> {{2, 1}, {2, 2}, {2, 3}, {4, 2}}, {{1, 2}, {1, 2}} -> {{3, 2}}}],
            <||>,
            <|"MaxEvents" -> 1|>,
            {{1, 0}, {6, 1}, {1, 0}, {1, 1}, {1, 0}, {7, 1}, {3, 0}, {3, 3}, {3, 1}, {8, 3}, {4, 0}, {4, 4}, {4, 0},
             {9, 4}, {2, 2}, {2, 2}, {2, 0}, {10, 2}, {2, 1}, {2, 2}, {2, 0}, {11, 2}, {5, 1}, {5, 5}, {5, 2}, {12, 5}},
            {{_Symbol, 0}}},
           {ToPatternRules[{{1, 2} -> {}, {1} -> {2}}], <||>, <|"MaxEvents" -> 1|>, {{1}}, {_ ? AtomQ}},
           {{0} :> {1, 2}, <||>, <|"MaxEvents" -> 2|>, {0}, {1, 2}},
           (* there is only one created expression because the empty set {} can only be matched once *)
           {{} :> {0}, <||>, <|"MaxEvents" -> 2|>, {}, {0}},
           {{x_, y_} /; OddQ[x + y] :> {x + y},
            <|"MaxEventInputs" -> 2, "MaxDestroyerEvents" -> 1|>,
            <||>,
            Range[10],
            {3, 7, 11, 15, 19}},
           {{x_, y_} /; Mod[x + y, 2] == 0 :> {x + y},
            <|"MaxEventInputs" -> 2, "MaxDestroyerEvents" -> 1|>,
            <||>,
            Range[10],
            {4, 6, 12, 14, 14, 18, 28, 46}},
           {{x_, y_} /; x >= 8 :> {x - 8, y + 8},
            <|"MaxGeneration" -> 20, "MaxEventInputs" -> 2, "MaxDestroyerEvents" -> 1|>,
            <||>,
            Range[10],
            {__ ? (Not @* Negative)}},
           {{x___} /; Plus[x] == 5 && OrderedQ[{x}] :> {Length[{x}]},
            <|"MaxGeneration" -> 2|>,
            <||>,
            {1, 2, 3, 5},
            {1, 2, 3, 3}},
           {{x_, y_} /; x < y :> Module[{z = Hash[{x, y}]}, {z}],
            <|"MaxEventInputs" -> 2, "MaxDestroyerEvents" -> 1|>,
            <||>,
            {1, 2, 3, 4},
            {Hash[{1, 2}], Hash[{3, 4}], Hash[Sort @ {Hash[{1, 2}], Hash[{3, 4}]}]}},
           {{x__, y__} /; OrderedQ[Catenate[{x, y}]] :> {Catenate[{x, y}]},
            <|"MaxEventInputs" -> 3|>,
            <||>,
            {{1}, {2}, {3}},
            {{1, 2}, {1, 3}, {2, 3}, {1, 2, 3}, {1, 2, 3}, {1, 2, 3}}}},

        VerificationTest[
          eventCount @ GenerateMultihistory[
            MultisetSubstitutionSystem[{{1}} :> {}], <|"MaxGeneration" -> 1|>, None, anEventOrdering, <||>] @ {{1}},
          1],

        Function[{rules, selection, init, expectedMaxGeneration, expectedEventCount},
            VerificationTest[
              Through[{lastEventGeneration, eventCount} @ GenerateMultihistory[
                MultisetSubstitutionSystem[rules], selection, None, anEventOrdering, <||>] @ init],
              {expectedMaxGeneration, expectedEventCount}]] @@@
          {{{{a_, b_}} :> Module[{c}, {{a, c}, {c, b}}],
            <|"MaxGeneration" -> 7, "MaxEventInputs" -> 1|>,
            {{1, 2}},
            7,
            2^7 - 1},
           {{{_}} :> {}, <||>, {{1}, {2}, {3}, {4}, {5}}, 1, 5},
           {{{x_}} :> {{x}}, <|"MaxGeneration" -> 0|>, {{1}, {2}, {3}, {4}, {5}}, 0, 0},
           {{{{_}} :> {}, {{x_, _}} :> {{x}}}, <|"MaxGeneration" -> 2|>, {{1, 2}, {2}, {3}, {4}, {5}}, 2, 6}},

        (* Test invalid patterns *)
        VerificationTest[
            eventCount @ GenerateMultihistory[
              MultisetSubstitutionSystem[#],
              <|"MaxGeneration" -> 1|>,
              None,
              anEventOrdering,
              <||>] @ {{1}},
            0,
            {Pattern::patvar, Pattern::patvar}] & /@
          {{{{Pattern[1, _], v2_}} :> {}, {{Pattern[2, _], v1_}} :> Module[{v2}, {v2}]},
           {{{Pattern[Pattern[a, _], _], v2_}} :> {}, {{Pattern[2, _], v1_}} :> Module[{v2}, {v2}]}}
      }]
    }
  |>,
  "Multiset System Matching" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];

      (* These will not be necessary once we have properties. *)
      allExpressions[Multihistory[_, data_]] := Normal @ data["Expressions"];
    ),
    "tests" -> {
      With[{anEventOrdering = {"InputCount", "SortedInputExpressions", "UnsortedInputExpressions", "RuleIndex"}}, {
        Function[{rule, selection, init, expectedCreatedExpressions},
          VerificationTest[
            allExpressions @ GenerateMultihistory[
              MultisetSubstitutionSystem[rule],
              selection,
              None,
              anEventOrdering,
              <||>] @ init,
            Join[init, expectedCreatedExpressions]]
        ] @@@ {
          (* multihistory branching *)
          {{{1} -> {2}, {1} -> {3}}, <||>, {1}, {2, 3}},
          {{{1} -> {2}, {1} -> {3}}, <|"MaxDestroyerEvents" -> 1|>, {1}, {2}},
          (* matching inconsistent expressions *)
          {{{1} -> {2}, {1} -> {3}, {2, 3} -> {4}}, <||>, {1}, {2, 3}},
          (* matching past/future expressions *)
          {{{1} -> {2}, {2} -> {3}, {2, 3} -> {4}}, <||>, {1}, {2, 3}},
          (* matching compatible expressions *)
          {{{1} -> {2, 3}, {2, 3} -> {4}}, <||>, {1}, {2, 3, 4}},
          (* instantiating the same match multiple times *)
          {{1} -> {2}, <||>, {1}, {2}},
          (* no matching rules that don't match *)
          {{a_, a_} :> {0}, <||>, {1, 2}, {}},
          (* mixed compatible/inconsistent matching *)
          {{{{v, i}} -> {{v, 1}, {v, 2}},
            {{v, 1}} -> {{v, 1, 1}, {v, 1, 2}},
            {{v, 1, 1}, {v, 2}} -> {{v, f, 1}},
            {{v, 1, 2}, {v, 2}} -> {{v, f, 2}},
            {{v, f, 1}, {v, f, 2}} -> {{f}}},
           <||>,
           {{v, i}},
           {{v, 1}, {v, 2}, {v, 1, 1}, {v, 1, 2}, {v, f, 1}, {v, f, 2}}},
          (* single-history spacelike merging *)
          {{{{a_}, {a_, b_}} :> {{a, b}, {b}}, {{a_}, {a_}} :> {{a, a, a}}},
           <|"MaxDestroyerEvents" -> 1, "MaxEventInputs" -> 2|>,
           {{a1}, {a1, a2}, {a2, a3}, {a3, m1}, {b1}, {b1, b2}, {b2, m1}, {m1, m2}},
           {{a1, a2}, {a2}, {a2, a3}, {a3}, {a3, m1}, {m1}, {b1, b2}, {b2}, {b2, m1}, {m1}, {m1, m2}, {m2}, {m1, m2},
            {m2}, {m2, m2, m2}}},
          (* multihistory spacelike merging *)
          {{{{a_}, {a_, b_}} :> {{b}}, {{a_}, {a_}} :> {{a, a, a}}},
           <|"MaxEventInputs" -> 2|>,
           {{a1}, {a1, a2}, {a2, a3}, {a3, m1}, {b1}, {b1, b2}, {b2, m1}, {m1, m2}},
           {{a2}, {a3}, {m1}, {b2}, {m1}, {m2}, {m2}, {m1, m1, m1}, {m1, m1, m1}}},
          (* no single-history branchlike merging *)
          {{{{a_}, {a_, b_}} :> {{a, b}, {b}}, {{a_}, {a_}} :> {{a, a, a}}},
           <|"MaxDestroyerEvents" -> 1, "MaxEventInputs" -> 2|>,
           {{o1}, {o1, a1}, {o1, b1}, {a1, a2}, {a2, a3}, {a3, m1}, {b1, b2}, {b2, m1}, {m1, m2}},
           {{o1, a1}, {a1}, {a1, a2}, {a2}, {a2, a3}, {a3}, {a3, m1}, {m1}, {m1, m2}, {m2}}},
          (* no multihistory branchlike merging *)
          {{{{a_}, {a_, b_}} :> {{b}}, {{a_}, {a_}} :> {{a, a, a}}},
           <|"MaxEventInputs" -> 2|>,
           {{o1}, {o1, a1}, {o1, b1}, {a1, a2}, {a2, a3}, {a3, m1}, {b1, b2}, {b2, m1}, {m1, m2}},
           {{a1}, {b1}, {a2}, {a3}, {m1}, {b2}, {m1}, {m2}, {m2}}}},

        (* non-overlapping systems produce the same behavior *)
        VerificationTest[
          With[{
              serializeMultihistory = (Normal /@ # &) /@ Normal /@ Last @ # &,
              multihistories = GenerateMultihistory[
                MultisetSubstitutionSystem[
                  {{v1_, v2_}, {v2_, v3_, v4_}} :>
                      Module[{v5 = Hash[{{v1, v2}, {v2, v3, v4}}]}, {{v2, v3}, {v3, v4, v5}, {v1, v2, v3, v4}}]],
                  <|"MaxEventInputs" -> 2, "MaxDestroyerEvents" -> #|>,
                  None,
                  anEventOrdering,
                  <|"MaxEvents" -> 30|>] @
                {{1, 2}, {2, 3, 4}} & /@ {1, Infinity}},
            SameQ @@ serializeMultihistory /@ multihistories]
        ]
      }]
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
  |>,
  "Multiset System Selection and Stopping" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];

      (* These will not be necessary once we have properties. *)
      eventCount[Multihistory[_, data_]] := data["EventRuleIndices"]["Length"] - 1;
      maxEventGeneration[Multihistory[_, data_]] := Max @ Normal @ data["EventGenerations"];
      conclusionReason[Multihistory[_, data_]] := data["ConclusionReason"];
      destroyerEventCounts[Multihistory[_, data_]] := Normal @ data["ExpressionDestroyerEventCounts"];
    ),
    "tests" -> {
      With[{anEventOrdering = {"InputCount", "SortedInputExpressions", "UnsortedInputExpressions", "RuleIndex"}}, {
        Function[{
            rule, selection, stopping, init, expectedMaxEventGeneration, expectedEventCount, expectedConclusionReason},
          VerificationTest[
            Through[{maxEventGeneration, eventCount, conclusionReason} @
              GenerateMultihistory[
                MultisetSubstitutionSystem[rule], selection, None, anEventOrdering, stopping] @ init],
            {expectedMaxEventGeneration, expectedEventCount, expectedConclusionReason}]
        ] @@@ {
          (* Terminated is returned if MaxGeneration is reached because MaxGeneration is not a stopping condition *)
          {{_} :> {Unique[]}, <|"MaxGeneration" -> 2|>, <||>, {1}, 2, 2, "Terminated"},
          {{_} :> {Unique[]}, <|"MaxGeneration" -> 0|>, <||>, {1}, 0, 0, "Terminated"},
          {{_} :> {Unique[]}, <|"MaxGeneration" -> 3|>, <|"MaxEvents" -> 2|>, {1}, 2, 2, "MaxEvents"},
          {{_} :> {Unique[]}, <||>, <|"MaxEvents" -> 0|>, {1}, 0, 0, "MaxEvents"},
          {ToPatternRules[{{0, 1}} -> {{0, 2}, {2, 1}}],
           <|"MaxGeneration" -> 3, "MaxEventInputs" -> 1|>,
           <||>,
           {{0, 1}},
           3, 7, "Terminated"},
          {ToPatternRules[{{0, 1}} -> {{0, 2}, {2, 1}}], <|"MaxEventInputs" -> 1|>, <|"MaxEvents" -> 6|>, {{0, 1}},
           3, 6, "MaxEvents"},
          {ToPatternRules[{{0, 1}} -> {{0, 2}, {2, 1}}],
           <|"MaxGeneration" -> 3, "MaxEventInputs" -> 1|>,
           <|"MaxEvents" -> 6|>,
           {{0, 1}},
           3, 6, "MaxEvents"},
          {ToPatternRules[{{0, 1}} -> {{0, 2}, {2, 1}}],
           <|"MaxGeneration" -> 2, "MaxEventInputs" -> 1|>,
           <|"MaxEvents" -> 6|>,
           {{0, 1}},
           2, 3, "Terminated"},
          {ToPatternRules[{{0, 1}, {1, 2}} -> {{0, 2}}],
           <|"MaxEventInputs" -> 2, "MaxDestroyerEvents" -> 1|>,
           <||>,
           {{0, 1}, {1, 2}, {2, 3}, {3, 4}},
           2, 3, "Terminated"},
          {ToPatternRules[{{0, 1}, {1, 2}} -> {{0, 2}}],
           <|"MaxEventInputs" -> 2, "MaxDestroyerEvents" -> 2|>,
           <||>,
           {{0, 1}, {1, 2}, {2, 3}, {3, 4}},
           2, 6, "Terminated"},
          {ToPatternRules[{{0, 1}, {1, 2}} -> {{0, 2}}],
           <|"MaxEventInputs" -> 2, "MaxDestroyerEvents" -> 3|>,
           <||>,
           {{0, 1}, {1, 2}, {2, 3}, {3, 4}},
           3, 10, "Terminated"},
          {ToPatternRules[{{0, 1}, {1, 2}} -> {{0, 2}}],
           <|"MaxEventInputs" -> 2|>,
           <||>,
           {{0, 1}, {1, 2}, {2, 3}, {3, 4}},
           3, 12, "Terminated"},
          {ToPatternRules[{{0, 1}, {1, 2}} -> {{0, 2}}],
           <|"MaxEventInputs" -> 2, "MaxDestroyerEvents" -> 0|>,
           <||>,
           {{0, 1}, {1, 2}, {2, 3}, {3, 4}},
           0, 0, "Terminated"}
          (* TODO: add tests for MinEventInputs and MaxEventInputs *)
        },

        VerificationTest[
            destroyerEventCounts @ GenerateMultihistory[
              MultisetSubstitutionSystem[ToPatternRules[{{1, 2}, {2, 3}} -> {{2, 3}, {2, 4}, {3, 4}, {2, 1}}]],
              <|"MaxDestroyerEvents" -> #|>,
              None,
              anEventOrdering,
              <|"MaxEvents" -> 5|>] @ {{1, 1}, {1, 1}},
            #2,
            SameTest -> MatchQ] & @@@
         {{2, {2, 2, 2, 2, 1, 1, 0..}}, {3, {2, 2, 3, 1, 1, 1, 0..}}}
      }]
    }
  |>
|>
