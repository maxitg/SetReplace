Package["SetReplace`"]

PackageScope["testUnevaluated"]

(* VerificationTest should not directly appear here, as it is replaced by test.wls into other heads during evaluation.
    Use testHead argument instead. *)

(* It is necessary to compare strings because, i.e.,
    MatchQ[<|x -> 1|>, HoldPattern[<|x -> 1|>]] returns False. *)
Attributes[testUnevaluated] = {HoldAll};
testUnevaluated[testHead_, input_, messages_, opts___] :=
  testHead[
    ToString[FullForm[input]],
    StringReplace[ToString[FullForm[Hold[input]]], StartOfString ~~ "Hold[" ~~ expr___ ~~ "]" ~~ EndOfString :> expr],
    messages,
    opts];
