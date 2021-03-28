<|
  "MultisetSubstitutionSystemSeparationMatching" -> <|
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
  |>
|>
