<|
  "$SetReplaceRootDirectory" -> <|
    "tests" -> {
      VerificationTest[
        FileExistsQ @ $SetReplaceRootDirectory
      ]
    }
  |>,

  "$SetReplaceGitSHA" -> <|
    "tests" -> {
      (* This tests will fail if the paclet was built from a dirty repo, i.e. there were uncommitted changes.
         The output will have an "*" at the end in this case. *)
      VerificationTest[
        StringMatchQ[$SetReplaceGitSHA, Repeated[HexadecimalCharacter, 40] ~~ Repeated["*", {0, 1}]
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

      (* could not be built before $SetReplaceBuildTime was implemented *)
      VerificationTest[
        DateObject[{2020, 3, 17, 0, 0, 0}, TimeZone -> "UTC"] < $SetReplaceLibraryBuildTime
      ]
    }
  |>
|>
