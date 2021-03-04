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

      objectType[_unknownObject] := "Unknown";

      (* String <-> Expression *)

      objectType[_String] := "String";
      objectType[_expression] := "Expression";

      declareTypeTranslation[stringToExpression, "String", "Expression"];
      stringToExpression[str_] := expression[ToExpression[str]];

      declareTypeTranslation[expressionToString, "Expression", "String"];
      expressionToString[expression[expr_]] := ToString[expr];

      (* EvenInteger <-> HalfInteger *)

      objectType[_halfInteger] := "HalfInteger";
      objectType[_evenInteger] := "EvenInteger";

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

      (** Non-translatable type **)

      objectType[_Real] := "Real";
      declareRawProperty[realDescription, "Real", description];
      realDescription[][real_Real] := "I am a real " <> ToString[real] <> ".";
      realDescription[args__][_] := throwInvalidPropertyArgumentCount[0, Length[{args}]];

      Unprotect[$SetReplaceTypeGraph];
      Unprotect[$SetReplaceProperties];
      Unprotect[$SetReplaceTypes];
      initializeTypeSystem[];
      Protect[$SetReplaceTypes];
      Protect[$SetReplaceProperties];
      Protect[$SetReplaceTypeGraph];
    ),
    "tests" -> {
      (* Type and property lists *)
      (* unknownObject is not here because there are no translations or properties defined for it, so it's invisible to
         the type system. *)
      VerificationTest[$SetReplaceTypes, Sort @ {"String", "Expression", "HalfInteger", "EvenInteger", "Real"}],
      VerificationTest[$SetReplaceProperties, Sort @ {description, multipliedHalf}],

      VerificationTest[GraphQ @ $SetReplaceTypeGraph],
      VerificationTest[ContainsOnly[Head /@ VertexList[$SetReplaceTypeGraph],
                       {SetReplaceType, SetReplaceProperty, SetReplaceMethodImplementation}]],
      VerificationTest[
        Cases[
          EdgeList[$SetReplaceTypeGraph],
          Except[
            DirectedEdge[_SetReplaceType | _SetReplaceProperty, _SetReplaceMethodImplementation] |
              DirectedEdge[_SetReplaceMethodImplementation, _SetReplaceType | _SetReplaceProperty]]],
        {}],

      (* Type querying *)
      VerificationTest[SetReplaceObjectType[evenInteger[4]], "EvenInteger"],
      VerificationTest[SetReplaceObjectType[2.4], "Real"],
      VerificationTest[SetReplaceObjectType[unknownObject[4]], "Unknown"],
      testUnevaluated[SetReplaceObjectType[unseenObject[4]], SetReplaceObjectType::unknownObject],

      VerificationTest[SetReplaceObjectQ[evenInteger[4]]],
      VerificationTest[SetReplaceObjectQ[2.4]],
      (* unknownObject an object because it returns a type even though it's not in $SetReplaceTypes. *)
      VerificationTest[SetReplaceObjectQ[unknownObject[4]]],
      VerificationTest[!SetReplaceObjectQ[unseenObject[4]]],

      (* Translations *)
      VerificationTest[
        SetReplaceTypeConvert["Expression"] @ SetReplaceTypeConvert["String"] @ expression[4], expression[4]],
      VerificationTest[SetReplaceTypeConvert["HalfInteger"] @ evenInteger[4], halfInteger[2]],
      VerificationTest[SetReplaceTypeConvert["HalfInteger"] @ halfInteger[3], halfInteger[3]],
      VerificationTest[SetReplaceTypeConvert["EvenInteger"] @ halfInteger[3], evenInteger[6]],

      testUnevaluated[SetReplaceTypeConvert["Expression"] @ unknownObject[5], SetReplaceTypeConvert::unconvertibleType],
      testUnevaluated[SetReplaceTypeConvert["Unknown"] @ expression[4], SetReplaceTypeConvert::unconvertibleType],
      testUnevaluated[SetReplaceTypeConvert["Expression"] @ halfInteger[3], SetReplaceTypeConvert::noConversionPath],
      testUnevaluated[SetReplaceTypeConvert["HalfInteger"] @ evenInteger[3], SetReplaceTypeConvert::notEven],
      testUnevaluated[SetReplaceTypeConvert["EvenInteger"] @ halfInteger[a], SetReplaceTypeConvert::notAnInteger],

      (* Raw Properties *)
      VerificationTest[multipliedHalf[5] @ halfInteger[3], 15],
      VerificationTest[multipliedHalf[5] @ evenInteger[4], 10],
      VerificationTest[multipliedHalf[halfInteger[3], 4], 12],
      VerificationTest[multipliedHalf[evenInteger[4], 4], 8],
      VerificationTest[description @ evenInteger[4], "I am an integer 4."],
      VerificationTest[description @ halfInteger[4], "I am an integer 8."],
      VerificationTest[description[] @ halfInteger[4], "I am an integer 8."], (* Operator form with no arguments *)
      VerificationTest[description @ 2.4, "I am a real 2.4."],

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
