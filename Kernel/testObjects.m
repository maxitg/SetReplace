Package["SetReplace`"]

PackageExport["Description"]
PackageExport["MultipliedHalf"]

(* String <-> Expression *)

declareMultihistoryTranslation[stringToExpression, "String", "Expression"];
stringToExpression[Multihistory["String", str_]] := Multihistory["Expression", ToExpression[str]];

declareMultihistoryTranslation[expressionToString, "Expression", "String"];
expressionToString[Multihistory["Expression", expr_]] := Multihistory["String", ToString[expr]];

(* EvenInteger <-> HalfInteger *)

(** Translations **)

declareMessage[General::notAnInteger, "The number `number` in `expr` is expected to be an integer."];
declareMultihistoryTranslation[halfToEvenInteger, "HalfInteger", "EvenInteger"];
halfToEvenInteger[Multihistory["HalfInteger", n_Integer]] := Multihistory["EvenInteger", 2 * n];
halfToEvenInteger[Multihistory["HalfInteger", n_]] := throw[Failure["notAnInteger", <|"number" -> n|>]];

declareMessage[General::notEven, "The number `number` in `expr` should be even."];
declareMultihistoryTranslation[evenToHalfInteger, "EvenInteger", "HalfInteger"];
evenToHalfInteger[Multihistory["EvenInteger", n_ ? EvenQ]] := Multihistory["HalfInteger", n / 2];
evenToHalfInteger[Multihistory["EvenInteger", n_]] := throw[Failure["notEven", <|"number" -> n|>]];

(** Properties **)

(*** Description ***)

declareRawMultihistoryProperty[evenIntegerDescription, "EvenInteger", Description];

evenIntegerDescription[][Multihistory[_, n_]] := "I am an integer " <> ToString[n] <> ".";

evenIntegerDescription[args__][_] := throwInvalidPropertyArgumentCount[0, Length[{args}]];

(*** MultipliedHalf ***)

declareRawMultihistoryProperty[multipliedNumber, "HalfInteger", MultipliedHalf];

multipliedNumber[factor_Integer][Multihistory[_, n_]] := factor * n;

declareMessage[General::nonIntegerFactor, "The factor `factor` in `expr` must be an integer."];
multipliedNumber[factor : Except[_Integer]][_] := throw[Failure["nonIntegerFactor", <|"factor" -> factor|>]];

multipliedNumber[args___][_] /; Length[{args}] != 1 := throwInvalidPropertyArgumentCount[1, Length[{args}]];
