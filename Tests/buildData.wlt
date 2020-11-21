<|
  "$SetReplaceGitSHA" -> <|
    "tests" -> {
      (* This tests will fail if the paclet was built from a dirty repo, i.e. there were uncommitted changes.
         The output will have an "*" at the end in this case. *)
      VerificationTest[
        StringMatchQ[$SetReplaceGitSHA, Repeated[HexadecimalCharacter, 40] ~~ Repeated["*", {0, 1}]]
      ]
    }
  |>,

  "$SetReplaceBuildTime" -> <|
    "tests" -> {
      VerificationTest[
        DateObjectQ @ $SetReplaceBuildTime
      ],

      VerificationTest[
        $SetReplaceBuildTime["TimeZone"],
        "UTC"
      ],

      (* could not be built in the future *)
      VerificationTest[
        $SetReplaceBuildTime < Now
      ],

      (* could not be built before $SetReplaceBuildTime was implemented *)
      VerificationTest[
        DateObject[{2020, 3, 17, 0, 0, 0}, TimeZone -> "UTC"] < $SetReplaceBuildTime
      ]
    }
  |>,

  "$SetReplaceLibraryPath" -> <|
    "tests" -> {
      VerificationTest[
        StringQ @ $SetReplaceLibraryPath
      ],

      VerificationTest[
        FileExistsQ @ $SetReplaceLibraryPath
      ]
    }
  |>,

  "$SetReplaceLibraryBuildTime" -> <|
    "tests" -> {
      VerificationTest[
        DateObjectQ @ $SetReplaceLibraryBuildTime
      ],

      VerificationTest[
        $SetReplaceLibraryBuildTime["TimeZone"],
        "UTC"
      ],

      (* could not be built in the future *)
      VerificationTest[
        $SetReplaceLibraryBuildTime < Now
      ],

      (* could not be built before $SetReplaceLibraryBuildTime was implemented *)
      VerificationTest[
        DateObject[{2020, 11, 22, 0, 0, 0}, TimeZone -> "UTC"] < $SetReplaceLibraryBuildTime
      ]
    }
  |>
|>
