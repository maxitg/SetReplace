BeginTestSection["SetReplaceList"]

(* Argument Checks *)

(** Argument count **)

VerificationTest[
  SetReplaceList[{1}],
  SetReplaceList[{1}],
  {SetReplaceList::argr}
]

VerificationTest[
  SetReplaceList[{1}, {2 -> 5, 3 :> 6}, 10, 10],
  SetReplaceList[{1}, {2 -> 5, 3 :> 6}, 10, 10],
  {SetReplaceList::argrx}
]

(** Set is a list **)

VerificationTest[
  SetReplaceList[1, 1 -> 2, 2],
  SetReplaceList[1, 1 -> 2, 2],
  {SetReplace::setNotList}
]

(** Rules are valid **)

VerificationTest[
  SetReplaceList[{1}, {1}, 1],
  SetReplaceList[{1}, {1}, 1],
  {SetReplace::invalidRules}
]

(** Step count is valid **)

VerificationTest[
  SetReplaceList[{1}, {1 -> 2}, -1],
  SetReplaceList[{1}, {1 -> 2}, -1],
  {SetReplace::nonIntegerIterations}
]

(* Implementation *)

VerificationTest[
  SetReplaceList[{1, 2, 3}, {2 -> 5, 3 :> 6}, 10],
  {{1, 2, 3}, {1, 3, 5}, {1, 5, 6}}
]

VerificationTest[
  SetReplaceList[{1, 2, 3}, {2 -> 5, 3 :> 6}, 1],
  {{1, 2, 3}, {1, 3, 5}}
]

VerificationTest[
  SetReplaceList[{{1, 2}, {2, 3}, {3, 1}}, {{a_, b_}, {b_, c_}} :> {{a, c}}, 2],
  {{{1, 2}, {2, 3}, {3, 1}}, {{3, 1}, {1, 3}}, {{3, 3}}}
]

EndTestSection[]
