<|
  "SetReplaceFixedPointList" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];
    ),
    "tests" -> {
      (* Symbol Leak *)

      testSymbolLeak[
        SetReplaceFixedPointList[Range[100], {a_, b_} :> {a + b}]
      ],
      
      (* Argument Checks *)

      (** Argument count **)

      testUnevaluated[
        SetReplaceFixedPointList[{1}],
        {SetReplaceFixedPointList::argr}
      ],

      testUnevaluated[
        SetReplaceFixedPointList[{1}, {1 -> 2}, 3],
        {SetReplaceFixedPointList::argrx}
      ],

      (** Set is a list **)

      testUnevaluated[
        SetReplaceFixedPointList[1, 1 -> 2],
        {SetReplaceFixedPointList::setNotList}
      ],

      (** Rules are valid **)

      testUnevaluated[
        SetReplaceFixedPointList[{1}, {1}],
        {SetReplaceFixedPointList::invalidRules}
      ],

      (** Options are valid **)

      testUnevaluated[
        SetReplaceFixedPointList[{1, 1, 1}, {1 -> 2}, # -> 123],
        {SetReplaceFixedPointList::optx}
      ] & /@ {"$$$InvalidOption###", "EventSelectionFunction"},

      (* Implementation *)

      VerificationTest[
        SetReplaceFixedPointList[{1, 1, 1}, {1 -> 2}],
        {{1, 1, 1}, {1, 1, 2}, {1, 2, 2}, {2, 2, 2}}
      ],

      VerificationTest[
        SetReplaceFixedPointList[{{1, 2}, {2, 3}, {3, 4}}, {{a_, b_}, {b_, c_}} :> {{a, c}}],
        {{{1, 2}, {2, 3}, {3, 4}}, {{3, 4}, {1, 3}}, {{1, 4}}}
      ],

      VerificationTest[
        SetReplaceFixedPointList[{{1, 2}, {2, 3}, {3, 1}}, {{a_, b_}, {b_, c_}} :> {{a, c}}, Method -> "LowLevel"],
        {{{1, 2}, {2, 3}, {3, 1}}, {{3, 1}, {1, 3}}, {{3, 3}}}
      ],

      VerificationTest[
        SetReplaceFixedPointList[{{1, 2}, {2, 3}, {3, 1}}, {{a_, b_}, {b_, c_}} :> {{a, c}}, Method -> "Symbolic"],
        {{{1, 2}, {2, 3}, {3, 1}}, {{3, 1}, {1, 3}}, {{3, 3}}}
      ],

      VerificationTest[
        SetReplaceFixedPointList[{{1, 2}, {2, 3}, {3, 4}}, {{a_, b_}} :> {}],
        {{{1, 2}, {2, 3}, {3, 4}}, {{2, 3}, {3, 4}}, {{3, 4}}, {}}
      ],

      VerificationTest[
        TimeConstrained[SetReplaceFixedPointList[{}, {} :> {{1, 2}}], 1],
        $Aborted
      ],

      VerificationTest[
        TimeConstrained[SetReplaceFixedPointList[{{1, 2}}, {{1, 2}} :> {{1, 2}}], 1],
        $Aborted
      ],

      (* TimeConstraint *)

      VerificationTest[
        SetReplaceFixedPointList[{{0, 0}}, ToPatternRules[{{1, 2}} -> {{1, 3}, {3, 2}}], Method -> #, TimeConstraint -> 0.1],
        $Aborted
      ] & /@ $SetReplaceMethods,

      VerificationTest[
        TimeConstrained[SetReplaceFixedPointList[{{0, 0}}, ToPatternRules[{{1, 2}} -> {{1, 3}, {3, 2}}], Method -> #], 0.1],
        $Aborted
      ] & /@ $SetReplaceMethods
    }
  |>
|>
