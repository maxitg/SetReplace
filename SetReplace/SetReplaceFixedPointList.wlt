BeginTestSection["SetReplaceFixedPointList"]

(* Argument Checks *)

(** Argument count **)

VerificationTest[
  SetReplaceFixedPointList[{1}],
  SetReplaceFixedPointList[{1}],
  {SetReplaceFixedPointList::argr}
]

VerificationTest[
  SetReplaceFixedPointList[{1}, {1 -> 2}, 3],
  SetReplaceFixedPointList[{1}, {1 -> 2}, 3],
  {SetReplaceFixedPointList::argrx}
]

(** Set is a list **)

VerificationTest[
  SetReplaceFixedPointList[1, 1 -> 2],
  SetReplaceFixedPointList[1, 1 -> 2],
  {SetReplaceFixedPointList::setNotList}
]

(** Rules are valid **)

VerificationTest[
  SetReplaceFixedPointList[{1}, {1}],
  SetReplaceFixedPointList[{1}, {1}],
  {SetReplaceFixedPointList::invalidRules}
]

(* Implementation *)

VerificationTest[
  SetReplaceFixedPointList[{1, 1, 1}, {1 -> 2}],
  {{1, 1, 1}, {1, 1, 2}, {1, 2, 2}, {2, 2, 2}}
]

VerificationTest[
  SetReplaceFixedPointList[{{1, 2}, {2, 3}, {3, 4}}, {{a_, b_}, {b_, c_}} :> {{a, c}}],
  {{{1, 2}, {2, 3}, {3, 4}}, {{3, 4}, {1, 3}}, {{1, 4}}}
]

VerificationTest[
  SetReplaceFixedPointList[{{1, 2}, {2, 3}, {3, 1}}, {{a_, b_}, {b_, c_}} :> {{a, c}}, Method -> "C++"],
  {{{1, 2}, {2, 3}, {3, 1}}, {{3, 1}, {1, 3}}, {{3, 3}}}
]

VerificationTest[
  SetReplaceFixedPointList[{{1, 2}, {2, 3}, {3, 1}}, {{a_, b_}, {b_, c_}} :> {{a, c}}, Method -> "WolframLanguage"],
  {{{1, 2}, {2, 3}, {3, 1}}, {{3, 1}, {1, 3}}, {{3, 3}}}
]

VerificationTest[
  SetReplaceFixedPointList[{{1, 2}, {2, 3}, {3, 4}}, {{a_, b_}} :> {}],
  {{{1, 2}, {2, 3}, {3, 4}}, {{2, 3}, {3, 4}}, {{3, 4}}, {}}
]

VerificationTest[
  TimeConstrained[SetReplaceFixedPointList[{}, {} :> {{1, 2}}], 1],
  $Aborted
]

VerificationTest[
  TimeConstrained[SetReplaceFixedPointList[{{1, 2}}, {{1, 2}} :> {{1, 2}}], 1],
  $Aborted
]

EndTestSection[]
