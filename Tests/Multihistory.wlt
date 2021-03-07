<|
  "Multihistory" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
    ),
    "tests" -> {
      (* Multihistory should never evaluate *)
      testUnevaluated[Multihistory["type", <||>], {}],
      testUnevaluated[Multihistory["type"], Multihistory::invalid],
      testUnevaluated[Multihistory["type", <||>, 4], Multihistory::invalid],

      VerificationTest[SetReplace`PackageScope`objectType[Multihistory["someType", <||>]], "someType"]
    }
  |>
|>
