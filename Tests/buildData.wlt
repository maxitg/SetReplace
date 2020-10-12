<|
  "$SetReplaceGitSHA" -> <|
    "tests" -> {
      (* these two tests will fail if the build is not clean, i.e., there will be an "*" at the end of the output *)
      VerificationTest[
        StringLength @ $SetReplaceGitSHA,
        40
      ],

      VerificationTest[
        StringMatchQ[$SetReplaceGitSHA, HexadecimalCharacter...]
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
  |>
|>
