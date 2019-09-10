BeginTestSection["SetSubstitutionSystem"]

(* Argument checks *)

(** Argument count **)

VerificationTest[
  SetSubstitutionSystem[],
  SetSubstitutionSystem[],
  {SetSubstitutionSystem::argt}
]

VerificationTest[
  SetSubstitutionSystem[Method -> "C++"],
  SetSubstitutionSystem[Method -> "C++"],
  {SetSubstitutionSystem::argt}
]

(** Set is a list **)

VerificationTest[
  SetSubstitutionSystem[1 -> 2, 1],
  SetSubstitutionSystem[1 -> 2, 1],
  {SetSubstitutionSystem::setNotList}
]

VerificationTest[
  SetSubstitutionSystem[1 -> 2, 1, Method -> "C++"],
  SetSubstitutionSystem[1 -> 2, 1, Method -> "C++"],
  {SetSubstitutionSystem::setNotList}
]

(** Rules are valid **)

VerificationTest[
  SetSubstitutionSystem[1, {1}],
  SetSubstitutionSystem[1, {1}],
  {SetSubstitutionSystem::invalidRules}
]

VerificationTest[
  SetSubstitutionSystem[1, {1}, Method -> "C++"],
  SetSubstitutionSystem[1, {1}, Method -> "C++"],
  {SetSubstitutionSystem::invalidRules}
]

VerificationTest[
  SetSubstitutionSystem[{1}, {1}],
  SetSubstitutionSystem[{1}, {1}],
  {SetSubstitutionSystem::invalidRules}
]

(** Step count is valid **)

VerificationTest[
  SetSubstitutionSystem[{1 -> 2}, {1}, -1],
  SetSubstitutionSystem[{1 -> 2}, {1}, -1],
  {SetSubstitutionSystem::nonIntegerIterations}
]

VerificationTest[
  SetSubstitutionSystem[{1 -> 2}, {1}, -1, Method -> "C++"],
  SetSubstitutionSystem[{1 -> 2}, {1}, -1, Method -> "C++"],
  {SetSubstitutionSystem::nonIntegerIterations}
]

VerificationTest[
  SetSubstitutionSystem[{1 -> 2}, {1}, 1.5],
  SetSubstitutionSystem[{1 -> 2}, {1}, 1.5],
  {SetSubstitutionSystem::nonIntegerIterations}
]

(** Method is valid **)

VerificationTest[
  SetSubstitutionSystem[{{0}} -> {{1}}, {{0}}, Method -> StringJoin[ToString /@ $SetReplaceMethods]],
  SetSubstitutionSystem[{{0}} -> {{1}}, {{0}}, Method -> StringJoin[ToString /@ $SetReplaceMethods]],
  {SetSubstitutionSystem::invalidMethod}
]

(* Implementation *)

(** Simple examples **)

VerificationTest[
  SetSubstitutionSystem[{1} :> {1}, {1}]["EventsCount"],
  1
]

VerificationTest[
  SetSubstitutionSystem[2 -> 5, {1, 2, 3}][-1],
  {1, 3, 5}
]

VerificationTest[
  SetSubstitutionSystem[2 :> 5, {1, 2, 3}][-1],
  {1, 3, 5}
]

VerificationTest[
  SetSubstitutionSystem[{2 :> 5, 3 :> 6}, {1, 2, 3}][-1],
  {1, 5, 6}
]

VerificationTest[
  SetSubstitutionSystem[{2 -> 5, 3 :> 6}, {1, 2, 3}][-1],
  {1, 5, 6}
]

VerificationTest[
  SetSubstitutionSystem[{2 -> 5, 3 :> 6}, {1, 2, 3}, 2]["GenerationsCount"],
  1
]

VerificationTest[
  SetSubstitutionSystem[{2 -> 5, 3 :> 6}, {1, 2, 3}, 2][-1],
  {1, 5, 6}
]

VerificationTest[
  SetSubstitutionSystem[{3, 2} -> 5, {1, 2, 3}][-1],
  {1, 5}
]

VerificationTest[
  SetSubstitutionSystem[4 -> 5, {1, 2, 3}]["EventsCount"],
  0
]

VerificationTest[
  SetSubstitutionSystem[{{1}} :> {}, {{1}}][-1],
  {}
]

VerificationTest[
  SetSubstitutionSystem[{{1}} :> {}, {{1}}, Method -> "C++"][-1],
  {}
]

VerificationTest[
  SetSubstitutionSystem[{{1}} :> {}, {{1}}, Method -> "WolframLanguage"][-1],
  {}
]

VerificationTest[
  SetSubstitutionSystem[{{1}} :> {}, {{1}}, Method -> Automatic][-1],
  {}
]

VerificationTest[
  SetSubstitutionSystem[{{1}, {2}} :> {{3}}, {{1}, {2}}][-1],
  {{3}}
]

VerificationTest[
  SetSubstitutionSystem[{{1}, {2}} :> {{3}}, {{2}, {1}}][-1],
  {{3}}
]

VerificationTest[
  SetSubstitutionSystem[
    {x_List ? (Length[#] == 3 &), y_List ? (Length[#] == 6 &)} :> {x, y, Join[x, y]},
    {"This" -> "that", {2, 3, 4}, {2, 5}, {1, 2, 3, 4, 5, 6}},
    2][0],
  {"This" -> "that", {2, 3, 4}, {2, 5}, {1, 2, 3, 4, 5, 6}}
]

VerificationTest[
  SetSubstitutionSystem[
    {x_List ? (Length[#] == 3 &), y_List ? (Length[#] == 6 &)} :> {x, y, Join[x, y]},
    {"This" -> "that", {2, 3, 4}, {2, 5}, {1, 2, 3, 4, 5, 6}},
    2][-1],
  {"This" -> "that", {2, 5}, {2, 3, 4, 1, 2, 3, 4, 5, 6}, {2, 3, 4}, {1, 2, 3, 4, 5, 6}, {2, 3, 4, 1, 2, 3, 4, 5, 6}}
]

VerificationTest[
  SetSubstitutionSystem[{{a_, b_}, {b_, c_}} :> {{a, c}}, {{1, 2}, {2, 3}, {3, 4}, {4, 5}}, 2][1],
  {{1, 3}, {3, 5}}
]

VerificationTest[
  SetSubstitutionSystem[{{a_, b_}, {b_, c_}} :> {{a, c}}, {{1, 2}, {2, 3}, {3, 4}, {4, 5}}, 2][1],
  SetSubstitutionSystem[{{a_, b_}, {b_, c_}} :> {{a, c}}, {{1, 2}, {2, 3}, {3, 4}, {4, 5}}, 1][-1]
]

VerificationTest[
  SetSubstitutionSystem[{{a_, b_}, {b_, c_}} :> {{a, c}}, {{1, 2}, {2, 3}, {3, 4}, {4, 5}}, 2][-1],
  {{1, 5}}
]

EndTestSection[]


BeginTestSection["$SetReplaceMethods"]

VerificationTest[
  ListQ[$SetReplaceMethods]
]

VerificationTest[
  AllTrue[
    $SetReplaceMethods,
    SetReplace[{{0}}, {{0}} -> {{1}}, Method -> #] === {{1}} &]
]

EndTestSection[]
