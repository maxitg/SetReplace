BeginTestSection["SetReplaceFixedPoint"]

(* Argument Checks *)

(** Argument count **)

VerificationTest[
  SetReplaceFixedPoint[{1}],
  SetReplaceFixedPoint[{1}],
  {SetReplaceFixedPoint::argr}
]

VerificationTest[
  SetReplaceFixedPoint[{1}, {1 -> 2}, 3],
  SetReplaceFixedPoint[{1}, {1 -> 2}, 3],
  {SetReplaceFixedPoint::argrx}
]

(** Set is a list **)

VerificationTest[
  SetReplaceFixedPoint[1, 1 -> 2],
  SetReplaceFixedPoint[1, 1 -> 2],
  {SetReplaceFixedPoint::setNotList}
]

(** Rules are valid **)

VerificationTest[
  SetReplaceFixedPoint[{1}, {1}],
  SetReplaceFixedPoint[{1}, {1}],
  {SetReplaceFixedPoint::invalidRules}
]

(* Implementation *)

VerificationTest[
  SetReplaceFixedPoint[{1, 1, 1}, {1 -> 2}],
  {2, 2, 2}
]

VerificationTest[
  SetReplaceFixedPoint[{{1, 2}, {2, 3}, {3, 4}}, {{a_, b_}, {b_, c_}} :> {{a, c}}],
  {{1, 4}}
]

VerificationTest[
  SetReplaceFixedPoint[{{1, 2}, {2, 3}, {3, 1}}, {{a_, b_}, {b_, c_}} :> {{a, c}}],
  {{x_, x_}},
  SameTest -> MatchQ
]

EndTestSection[]
