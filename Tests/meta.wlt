<|
  "meta" -> <|
    "init" -> (
      $testsDirectory = If[$TestFileName =!= "",
        FileNameJoin[Most @ FileNameSplit @ $TestFileName],
        FileNameJoin[Append[Most[FileNameSplit[$ScriptCommandLine[[1]]]], "Tests"]]
      ];
    ),
    "tests" -> {
      exports = Lookup[Package`PackageInformation["SetReplace`"], "PackageExports"];

      (* All public symbols have usage message *)

      hasNoSymbolUsageQ = Function[symbol,
        Not @ StringQ @ MessageName[symbol, "usage"], HoldFirst];
      VerificationTest[
        Select[exports, hasNoSymbolUsageQ],
        HoldComplete[]
      ],

      (* All public symbols have syntax information *)
      (* Additionally, SyntaxInformation should specify "OptionNames" if the symbol has Options. *)

      hasSyntaxInformationQ = Function[
        symbol,
        Or[
          StringStartsQ[SymbolName @ Unevaluated @ symbol, "$"],
          And[
            SyntaxInformation[Unevaluated @ symbol] =!= {},
            Implies[
              Options[Unevaluated @ symbol] =!= {},
              ListQ[Lookup[SyntaxInformation[Unevaluated @ symbol], "OptionNames"]]]]],
        HoldFirst];
      VerificationTest[
        Complement[exports, Select[exports, hasSyntaxInformationQ]],
        HoldComplete[]
      ],

      (* Test coverage: all public symbols appear in unit tests *)
      allTestsCode = StringJoin[FileString /@ FileNames["*.wlt", $testsDirectory]];
      doesNotAppearInTestsQ = Function[symbol,
        !StringContainsQ[allTestsCode, SymbolName @ Unevaluated @ symbol],
        HoldFirst];
      VerificationTest[
        Select[exports, doesNotAppearInTestsQ],
        HoldComplete[]
      ]
    },
    "options" -> {
      "Parallel" -> False
    }
  |>
|>
