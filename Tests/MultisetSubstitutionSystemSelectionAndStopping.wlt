<|
  "MultisetSubstitutionSystemSelectionAndStopping" -> <|
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
              GenerateMultihistory[MultisetSubstitutionSystem[rule], selection, None, anEventOrdering, stopping] @ init],
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
           2, 10, "Terminated"},
          {ToPatternRules[{{0, 1}, {1, 2}} -> {{0, 2}}],
           <|"MaxEventInputs" -> 2|>,
           <||>,
           {{0, 1}, {1, 2}, {2, 3}, {3, 4}},
           2, 12, "Terminated"},
          {ToPatternRules[{{0, 1}, {1, 2}} -> {{0, 2}}],
           <|"MaxEventInputs" -> 2, "MaxDestroyerEvents" -> 0|>,
           <||>,
           {{0, 1}, {1, 2}, {2, 3}, {3, 4}},
           0, 0, "Terminated"}
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
