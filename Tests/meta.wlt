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
        Select[exports, hasNoSymbolUsageQ], HoldComplete[]
      ],

      (* All public symbols have syntax information *)

      hasNoSyntaxInformationQ = Function[symbol, Not[
          StringStartsQ[SymbolName @ Unevaluated @ symbol, "$"] || 
          SyntaxInformation[Unevaluated @ symbol] =!= {}], HoldFirst];
      VerificationTest[
        Select[exports, hasNoSyntaxInformationQ], HoldComplete[]
      ],

      (* Test coverage: all public symbols appear in unit tests *)
      allSource = StringJoin[FileString /@ FileNames["*.wlt", $testsDirectory]];
      doesNotAppearInSourceQ = Function[symbol, 
        !StringContainsQ[allSource, SymbolName @ Unevaluated @ symbol],
        HoldFirst];
      VerificationTest[
        Select[exports, doesNotAppearInSourceQ], HoldComplete[]
      ]
    },
    "options" -> {
      "Parallel" -> False
    }
  |>
|>
