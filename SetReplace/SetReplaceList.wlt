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
  {SetReplaceList::setNotList}
]

(** Rules are valid **)

VerificationTest[
  SetReplaceList[{1}, {1}, 1],
  SetReplaceList[{1}, {1}, 1],
  {SetReplaceList::invalidRules}
]

(** Step count is valid **)

VerificationTest[
  SetReplaceList[{1}, {1 -> 2}, -1],
  SetReplaceList[{1}, {1 -> 2}, -1],
  {SetReplaceList::nonIntegerIterations}
]

(* Implementation *)

VerificationTest[
  SetReplaceList[{1, 2, 3}, {2 -> 5, 3 :> 6, 5 :> 9}, 10],
  {{1, 2, 3}, {1, 3, 5}, {1, 5, 6}, {1, 6, 9}}
]

VerificationTest[
  SetReplaceList[{1, 2, 3}, {2 -> 5, 3 :> 6, 5 :> 9}, Infinity],
  {{1, 2, 3}, {1, 3, 5}, {1, 5, 6}, {1, 6, 9}}
]

VerificationTest[
  SetReplaceList[{1, 2, 3}, {2 -> 5, 3 :> 6, 5 :> 9}, 1],
  {{1, 2, 3}, {1, 3, 5}}
]

VerificationTest[
  SetReplaceList[{{1}, {2}, {3}}, {{{2}} -> {{5}}, {{3}} :> {{6}}, {{5}} :> {{9}}}, 2, Method -> "LowLevel"],
  {{{1}, {2}, {3}}, {{1}, {3}, {5}}, {{1}, {5}, {6}}}
]

VerificationTest[
  SetReplaceList[{{1}, {2}, {3}}, {{{2}} -> {{5}}, {{3}} :> {{6}}, {{5}} :> {{9}}}, 2, Method -> "Symbolic"],
  {{{1}, {2}, {3}}, {{1}, {3}, {5}}, {{1}, {5}, {6}}}
]

VerificationTest[
  SetReplaceList[{{1, 2}, {2, 3}, {3, 1}}, {{a_, b_}, {b_, c_}} :> {{a, c}}, 2],
  {{{1, 2}, {2, 3}, {3, 1}}, {{3, 1}, {1, 3}}, {{3, 3}}}
]

VerificationTest[
  SetReplaceList[{}, {} :> {{1, 2}}, 2],
  {{}, {{1, 2}}, {{1, 2}, {1, 2}}}
]

VerificationTest[
  SetReplaceList[{{1, 2}}, {{1, 2}} :> {{1, 2}}, 2],
  {{{1, 2}}, {{1, 2}}, {{1, 2}}}
]

(* TimeConstraint *)

VerificationTest[
  SetReplaceList[{{0, 0}}, ToPatternRules[{{1, 2}} -> {{1, 3}, {3, 2}}], 100000, Method -> #, TimeConstraint -> 0.1],
  $Aborted
] & /@ $SetReplaceMethods

VerificationTest[
  TimeConstrained[SetReplaceList[{{0, 0}}, ToPatternRules[{{1, 2}} -> {{1, 3}, {3, 2}}], 100000, Method -> #], 0.1],
  $Aborted
] & /@ $SetReplaceMethods

EndTestSection[]
