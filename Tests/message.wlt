<|
  "message" -> <|
    "init" -> {
      Global`declareMessage = SetReplace`PackageScope`declareMessage;
      Global`message = SetReplace`PackageScope`message;

      Attributes[testNull] = {HoldFirst};
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
        {message::messageNotFound}
      ]
    }
  |>
|>
