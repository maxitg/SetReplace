<|
  "SetReplaceFixedPoint" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];
    ),
    "tests" -> {
      (* Symbol Leak *)

      testSymbolLeak[
        SetReplaceFixedPoint[Range[1000], {a_, b_} :> {a + b}]
      ],
      
      (* Argument Checks *)

      (** Argument count **)

      testUnevaluated[
        SetReplaceFixedPoint[{1}],
        {SetReplaceFixedPoint::argr}
      ],

      testUnevaluated[
        SetReplaceFixedPoint[{1}, {1 -> 2}, 3],
        {SetReplaceFixedPoint::argrx}
      ],

      (** Set is a list **)

      testUnevaluated[
        SetReplaceFixedPoint[1, 1 -> 2],
        {SetReplaceFixedPoint::setNotList}
      ],

      (** Rules are valid **)

      testUnevaluated[
        SetReplaceFixedPoint[{1}, {1}],
        {SetReplaceFixedPoint::invalidRules}
      ],

      (** Options are valid **)

      testUnevaluated[
        SetReplaceFixedPoint[{1, 1, 1}, {1 -> 2}, # -> 123],
        {SetReplaceFixedPoint::optx}
      ] & /@ {"$$$InvalidOption###", "EventSelectionFunction"},

      (* Implementation *)

      VerificationTest[
        SetReplaceFixedPoint[{1, 1, 1}, {1 -> 2}],
        {2, 2, 2}
      ],

      VerificationTest[
        SetReplaceFixedPoint[{{1, 2}, {2, 3}, {3, 4}}, {{a_, b_}, {b_, c_}} :> {{a, c}}],
        {{1, 4}}
      ],

      VerificationTest[
        SetReplaceFixedPoint[{{1, 2}, {2, 3}, {3, 1}}, {{a_, b_}, {b_, c_}} :> {{a, c}}, Method -> "Symbolic"],
        {{3, 3}}
      ],

      VerificationTest[
        SetReplaceFixedPoint[{{1, 2}, {2, 3}, {3, 1}}, {{a_, b_}, {b_, c_}} :> {{a, c}}, Method -> "LowLevel"],
        {{3, 3}}
      ],

      VerificationTest[
        SetReplaceFixedPoint[{{1, 2}, {2, 3}, {3, 4}}, {{a_, b_}} :> {}],
        {}
      ],

      VerificationTest[
        TimeConstrained[SetReplaceFixedPoint[{}, {} :> {{1, 2}}], 1],
        $Aborted
      ],

      VerificationTest[
        TimeConstrained[SetReplaceFixedPoint[{{1, 2}}, {{1, 2}} :> {{1, 2}}], 1],
        $Aborted
      ],

      (* TimeConstraint *)

      VerificationTest[
        SetReplaceFixedPoint[{{0, 0}}, ToPatternRules[{{1, 2}} -> {{1, 3}, {3, 2}}], Method -> #, TimeConstraint -> 0.1],
        $Aborted
      ] & /@ $SetReplaceMethods,

      VerificationTest[
        TimeConstrained[SetReplaceFixedPoint[{{0, 0}}, ToPatternRules[{{1, 2}} -> {{1, 3}, {3, 2}}], Method -> #], 0.1],
        $Aborted
      ] & /@ $SetReplaceMethods
    }
  |>
|>
