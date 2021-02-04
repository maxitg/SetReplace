<|
  "message" -> <|
    "init" -> {
      Global`message = SetReplace`PackageScope`message;
      Global`declareMessage = SetReplace`PackageScope`declareMessage;

      Attributes[testNull] = {HoldAll};
      testNull[input_, msgs_] := VerificationTest[input, Null, msgs];
    },
    "tests" -> {
      testNull[
        declareMessage[symb::msg, "Msg `a` of `b`."];
        message[symb::msg, <|"a" -> 0, "b" -> 1|>]
      ,
        {symb::msg}
      ],

      testNull[
        declareMessage[General::msg, "Msg `a` of `b`."];
        message[symb::msg, <|"a" -> 0, "b" -> 1|>]
      ,
        {symb::msg}
      ],

      testNull[
        declareMessage[symb::msg, "Msg `a` of `b`."];
        message[symb::wrongName, <|"a" -> 0, "b" -> 1|>]
      ,
        {SetReplace`PackageScope`message::messageNotFound}
      ],

      testNull[
        declareMessage[symb::msg, "Msg `a` of `b`."];
        message[symb::msg, <|"a" -> 0|>]
      ,
        {SetReplace`PackageScope`message::missingArgs}
      ],

      testNull[
        declareMessage[symb::msg, "Msg `a` of `b`."];
        message[symb::msg, <|"a" -> 0, "b" -> 1, "c" -> 2|>]
      ,
        {SetReplace`PackageScope`message::extraArgs}
      ]
    }
  |>
|>
