<|
  (* These are tests specific to Method -> "LowLevel" option of WolframModel (libSetReplace).
     Other test groups (like globalSpacelikeEvolution and matching) should be used to test libSetReplace as well. *)
  "lowLevelEvolution" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
    ),
    "tests" -> {
      (** Relatively large prime number of rules to verify all rules are allocated to threads when matching. **)
      VerificationTest[
        WolframModel[
          Array[{Range[1, #1]} -> {} &, 59],
          Array[Range[1, #1] &, 59],
          "FinalState"],
        {},
        SameTest -> SameQ
      ]
    }
  |>
|>
