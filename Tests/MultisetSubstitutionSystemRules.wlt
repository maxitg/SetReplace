<|
  "MultisetSubstitutionSystemRules" -> <|
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
           {{x___} /; Plus[x] == 5 :> {Length[{x}]}, <|"MaxGeneration" -> 2|>, <||>, {1, 2, 3, 5}, {1, 2, 3, 3}},
           {{x_, y_} /; x < y :> Module[{z = Hash[{x, y}]}, {z}],
            <|"MaxEventInputs" -> 2, "MaxDestroyerEvents" -> 1|>,
            <||>,
            {1, 2, 3, 4},
            {Hash[{1, 2}], Hash[{3, 4}], Hash[{Hash[{1, 2}], Hash[{3, 4}]}]}},
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
  |>
|>
