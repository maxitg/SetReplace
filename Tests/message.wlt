<|
  "message" -> <|
    "init" -> {
      Global`message = SetReplace`PackageScope`message;
      Global`declareMessage = SetReplace`PackageScope`declareMessage;
      Global`throw = SetReplace`PackageScope`throw;

      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];

      HalfInteger[x_] := ModuleScope[
        result = Catch[halfInteger[x], _ ? FailureQ, message[HalfInteger]];
        result /; !FailureQ[result]
      ];

      halfInteger[x_ ? EvenQ] := x / 2;

      declareMessage[HalfInteger::odd, "The number `number` is odd."];
      halfInteger[x_ ? OddQ] := throw[Failure["odd", <|"number" -> x|>]];
    },
    "tests" -> {
      VerificationTest[
        declareMessage[symb::msg, "Msg `a` of `b`."];
        message[symb::msg, <|"a" -> 0, "b" -> 1|>]
      ,
        Null
      ,
        {symb::msg}
      ],

      VerificationTest[
        declareMessage[General::msg, "Msg `a` of `b`."];
        message[symb::msg, <|"a" -> 0, "b" -> 1|>]
      ,
        Null
      ,
        {symb::msg}
      ],

      VerificationTest[
        declareMessage[symb::msg, "Msg `a` of `b`."];
        message[symb::wrongName, <|"a" -> 0, "b" -> 1|>]
      ,
        Null
      ,
        {SetReplace`PackageScope`message::messageNotFound}
      ],

      VerificationTest[
        declareMessage[symb::msg, "Msg `a` of `b`."];
        message[symb::msg, <|"a" -> 0|>]
      ,
        Null
      ,
        {SetReplace`PackageScope`message::missingArgs}
      ],

      VerificationTest[
        declareMessage[symb::msg, "Msg `a` of `b`."];
        message[symb, Failure["msg", <|"a" -> 0, "b" -> 1|>]]
      ,
        Failure["msg", <|"a" -> 0, "b" -> 1|>]
      ,
        {symb::msg}
      ],

      VerificationTest[
        declareMessage[symb::msg, "Msg `a` of `b`."];
        message[symb][Failure["msg", <|"a" -> 0, "b" -> 1|>]]
      ,
        Failure["msg", <|"a" -> 0, "b" -> 1|>]
      ,
        {symb::msg}
      ],

      VerificationTest[
        declareMessage[symb::msg, "Msg `a` of `b`."];
        message[symb][Failure["msg", <|"a" -> 0, "b" -> 1|>], Failure["msg", <|"a" -> 0, "b" -> 1|>]]
      ,
        Failure["msg", <|"a" -> 0, "b" -> 1|>]
      ,
        {symb::msg}
      ],

      VerificationTest[
        declareMessage[symb::msg, "Msg `a`, `b` and `c`."];
        message[symb, Failure["msg", <|"a" -> 0, "b" -> 1|>], <|"c" -> 2|>]
      ,
        Failure["msg", <|"a" -> 0, "b" -> 1, "c" -> 2|>]
      ,
        {symb::msg}
      ],

      VerificationTest[
        declareMessage[symb::msg, "Msg `a` of `b`."];
        Catch[throw[Failure["msg", <|"a" -> 0, "b" -> 1|>]], _ ? FailureQ, message[symb]]
      ,
        Failure["msg", <|"a" -> 0, "b" -> 1|>]
      ,
        {symb::msg}
      ],

      VerificationTest[
        HalfInteger[2],
        1
      ],

      testUnevaluated[
        HalfInteger[1],
        HalfInteger::odd
      ]
    }
  |>
|>
