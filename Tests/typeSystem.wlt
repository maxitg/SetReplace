<|
  "typeSystem" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];
      Global`objectType = SetReplace`PackageScope`objectType;
      Global`declareTypeTranslation = SetReplace`PackageScope`declareTypeTranslation;
      Global`declareMessage = SetReplace`PackageScope`declareMessage;
      Global`declareRawProperty = SetReplace`PackageScope`declareRawProperty;
      Global`initializeTypeSystem = SetReplace`PackageScope`initializeTypeSystem;
      Global`throw = SetReplace`PackageScope`throw;
      Global`throwInvalidPropertyArgumentCount = SetReplace`PackageScope`throwInvalidPropertyArgumentCount;

      (* UnknownObject *)

      objectType[obj_unknownObject] := "Unknown";

      (* String <-> Expression *)

      objectType[string_String] := "String";
      objectType[expr_expression] := "Expression";

      declareTypeTranslation[stringToExpression, "String", "Expression"];
      stringToExpression[str_] := expression[ToExpression[str]];

      declareTypeTranslation[expressionToString, "Expression", "String"];
      expressionToString[expression[expr_]] := ToString[expr];

      (* EvenInteger <-> HalfInteger *)

      objectType[halfInteger_halfInteger] := "HalfInteger";
      objectType[integer_evenInteger] := "EvenInteger";

      (** Translations **)

      declareMessage[General::notAnInteger, "The number `number` in `expr` is expected to be an integer."];
      declareTypeTranslation[halfToEvenInteger, "HalfInteger", "EvenInteger"];
      halfToEvenInteger[halfInteger[n_Integer]] := evenInteger[2 * n];
      halfToEvenInteger[halfInteger[n_]] := throw[Failure["notAnInteger", <|"number" -> n|>]];

      declareMessage[General::notEven, "The number `number` in `expr` should be even."];
      declareTypeTranslation[evenToHalfInteger, "EvenInteger", "HalfInteger"];
      evenToHalfInteger[evenInteger[n_ ? EvenQ]] := halfInteger[n / 2];
      evenToHalfInteger[evenInteger[n_]] := throw[Failure["notEven", <|"number" -> n|>]];

      (** Properties **)

      (*** Description ***)

      declareRawProperty[evenIntegerDescription, "EvenInteger", description];

      evenIntegerDescription[][evenInteger[n_]] := "I am an integer " <> ToString[n] <> ".";

      evenIntegerDescription[args__][_] := throwInvalidPropertyArgumentCount[0, Length[{args}]];

      (*** MultipliedHalf ***)

      declareRawProperty[multipliedNumber, "HalfInteger", multipliedHalf];

      multipliedNumber[factor_Integer][halfInteger[n_]] := factor * n;

      declareMessage[General::nonIntegerFactor, "The factor `factor` in `expr` must be an integer."];
      multipliedNumber[factor : Except[_Integer]][_] := throw[Failure["nonIntegerFactor", <|"factor" -> factor|>]];

      multipliedNumber[args___][_] /; Length[{args}] != 1 := throwInvalidPropertyArgumentCount[1, Length[{args}]];

      initializeTypeSystem[];
    ),
    "tests" -> {
      (* Translations *)
      VerificationTest[TypeConvert["Expression"] @ TypeConvert["String"] @ expression[4], expression[4]],
      VerificationTest[TypeConvert["HalfInteger"] @ evenInteger[4], halfInteger[2]],
      VerificationTest[TypeConvert["HalfInteger"] @ halfInteger[3], halfInteger[3]],
      VerificationTest[TypeConvert["EvenInteger"] @ halfInteger[3], evenInteger[6]],

      testUnevaluated[TypeConvert["Expression"] @ unknownObject[5], TypeConvert::unconvertibleType],
      testUnevaluated[TypeConvert["Unknown"] @ expression[4], TypeConvert::unconvertibleType],
      testUnevaluated[TypeConvert["Expression"] @ halfInteger[3], TypeConvert::noConversionPath],
      testUnevaluated[TypeConvert["HalfInteger"] @ evenInteger[3], TypeConvert::notEven],
      testUnevaluated[TypeConvert["EvenInteger"] @ halfInteger[a], TypeConvert::notAnInteger],

      (* Raw Properties *)
      VerificationTest[multipliedHalf[5] @ halfInteger[3], 15],
      VerificationTest[multipliedHalf[5] @ evenInteger[4], 10],
      VerificationTest[multipliedHalf[halfInteger[3], 4], 12],
      VerificationTest[multipliedHalf[evenInteger[4], 4], 8],
      VerificationTest[description @ evenInteger[4], "I am an integer 4."],
      VerificationTest[description @ halfInteger[4], "I am an integer 8."],
      VerificationTest[description[] @ halfInteger[4], "I am an integer 8."], (* Operator form with no arguments *)

      testUnevaluated[multipliedHalf[] @ halfInteger[3], multipliedHalf::invalidPropertyArgumentCount],
      testUnevaluated[multipliedHalf[1, 2, 3] @ halfInteger[3], multipliedHalf::invalidPropertyArgumentCount],
      testUnevaluated[multipliedHalf @ halfInteger[3], multipliedHalf::invalidPropertyArgumentCount],
      testUnevaluated[multipliedHalf[halfInteger[3], 4, 5], multipliedHalf::invalidPropertyArgumentCount],
      testUnevaluated[description[1] @ halfInteger[4], description::invalidPropertyArgumentCount],
      testUnevaluated[description[halfInteger[3], 3], description::invalidPropertyArgumentCount],

      testUnevaluated[multipliedHalf[4, 4, 5][], multipliedHalf::invalidPropertyOperatorArgument],
      testUnevaluated[multipliedHalf[4, 4, 5][halfInteger[4], 2, 3], multipliedHalf::invalidPropertyOperatorArgument],
      testUnevaluated[description[][], description::invalidPropertyOperatorArgument],

      testUnevaluated[multipliedHalf[4] @ cookie, multipliedHalf::unknownObject],
      testUnevaluated[multipliedHalf[4, 4, 5] @ cookie, multipliedHalf::unknownObject],
      testUnevaluated[description[] @ cookie, description::unknownObject],
      testUnevaluated[multipliedHalf[5] @ expression[3], multipliedHalf::noPropertyPath],
      testUnevaluated[multipliedHalf[5] @ evenInteger[3], multipliedHalf::notEven],
      testUnevaluated[multipliedHalf[evenInteger[3], 4], multipliedHalf::notEven],
      testUnevaluated[multipliedHalf[x] @ halfInteger[3], multipliedHalf::nonIntegerFactor],
      testUnevaluated[multipliedHalf @ cookie, {}], (* should not throw a message because it might be an operator *)
      testUnevaluated[description @ cookie, {}]
    }
  |>
|>
