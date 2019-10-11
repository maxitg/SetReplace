BeginTestSection["SetReplaceAll"]

(* Argument Checks *)

(** Argument count **)

VerificationTest[
  SetReplaceAll[],
  SetReplaceAll[],
  {SetReplaceAll::argt}
]

VerificationTest[
  SetReplaceAll[1, 2, 3, 4],
  SetReplaceAll[1, 2, 3, 4],
  {SetReplaceAll::argt}
]

(** Set is a list **)

VerificationTest[
  SetReplaceAll[1, 1 -> 2],
  SetReplaceAll[1, 1 -> 2],
  {SetReplaceAll::setNotList}
]

(** Rules are valid **)

VerificationTest[
  SetReplaceAll[{1}, 1],
  SetReplaceAll[{1}, 1],
  {SetReplaceAll::invalidRules}
]

VerificationTest[
  SetReplaceAll[{1}, {1}],
  SetReplaceAll[{1}, {1}],
  {SetReplaceAll::invalidRules}
]

(** Step count is valid **)

VerificationTest[
  SetReplaceAll[{1}, {1 -> 2}, -1],
  SetReplaceAll[{1}, {1 -> 2}, -1],
  {SetReplaceAll::nonIntegerIterations}
]

VerificationTest[
  SetReplaceAll[{1}, {1 -> 2}, 1.5],
  SetReplaceAll[{1}, {1 -> 2}, 1.5],
  {SetReplaceAll::nonIntegerIterations}
]

(* Implementation *)

VerificationTest[ 
  SetReplaceAll[{1, 2, 3}, n_ :> -n],
  {-1, -2, -3}
]

VerificationTest[
  SetReplaceAll[{1, 2, 3}, n_ :> -n, 2],
  {1, 2, 3}
]

VerificationTest[
  SetReplaceAll[{1, 2, 3}, {n_, m_} :> {-m, -n}],
  {3, -2, -1}
]

VerificationTest[
  SetReplaceAll[{1, 2, 3}, {n_, m_} :> {-m, -n}, 2],
  {-1, 2, -3}
]

VerificationTest[
  Most @ SetReplaceAll[
      {1, 2, 3, 4}, {2 -> {3, 4}, {v1_, v2_} :> Module[{x}, {v1, v2, x}]}],
  {4, 3, 4, 1, 3}
]

VerificationTest[
  MatchQ[SetReplaceAll[
      {1, 2, 3, 4},
      {2 -> {3, 4}, {v1_, v2_} :> Module[{x}, {v1, v2, x}]},
      2], {4, 3, _, 4, 1, _, 3, _, _}],
  True
]

VerificationTest[
  Length @ SetReplaceAll[
    {{0, 1}, {0, 2}, {0, 3}}, 
    ToPatternRules[
      {{0, 1}, {0, 2}, {0, 3}} ->
      {{4, 5}, {5, 4}, {4, 6}, {6, 4}, {5, 6}, {6, 5}, {4, 1}, {5, 2}, {6, 3}}],
    4],
  3^5
]

VerificationTest[
  Length @ SetReplaceAll[
    {{0, 0}, {0, 0}, {0, 0}}, 
    ToPatternRules[
      {{0, 1}, {0, 2}, {0, 3}} ->
      {{4, 5}, {5, 4}, {4, 6}, {6, 4}, {5, 6}, {6, 5}, {4, 1}, {5, 2}, {6, 3}}],
    4],
  3^5
]

VerificationTest[
  Length @ SetReplaceAll[
    {{0, 1}, {0, 2}, {0, 3}}, 
    ToPatternRules[
      {{0, 1}, {0, 2}, {0, 3}} ->
      {{4, 5}, {5, 4}, {4, 6}, {6, 4}, {5, 6}, {6, 5},
       {4, 1}, {5, 2}, {6, 3}, {1, 6}, {3, 4}}],
    3],
  107
]

VerificationTest[
  Length @ SetReplaceAll[
    {{0, 1}, {0, 2}, {0, 3}},
    ToPatternRules[
      {{0, 1}, {0, 2}, {0, 3}} ->
      {{4, 5}, {5, 4}, {4, 6}, {6, 4}, {5, 6}, {6, 5},
       {4, 1}, {5, 2}, {6, 3}, {1, 6}, {3, 4}}],
    3,
    Method -> "LowLevel"],
  Length @ SetReplaceAll[
    {{0, 1}, {0, 2}, {0, 3}},
    ToPatternRules[
      {{0, 1}, {0, 2}, {0, 3}} ->
      {{4, 5}, {5, 4}, {4, 6}, {6, 4}, {5, 6}, {6, 5},
       {4, 1}, {5, 2}, {6, 3}, {1, 6}, {3, 4}}],
    3,
    Method -> "Symbolic"]
]

VerificationTest[
  SetReplaceAll[
    {{0, 1}, {1, 2}, {2, 3}, {3, 4}},
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    2,
    Method -> "LowLevel"],
  {{0, 4}}
]

EndTestSection[]
