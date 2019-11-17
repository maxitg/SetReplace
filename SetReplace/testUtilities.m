Package["SetReplace`"]

PackageScope["testUnevaluated"]

Attributes[testUnevaluated] = {HoldAll};
testUnevaluated[input_, messages_, opts___] :=
  VerificationTest[
    input,
    HoldPattern[input],
    messages,
    SameTest -> MatchQ,
    opts];
