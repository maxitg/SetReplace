BeginTestSection["WolframModel"]

(* Argument checks *)

(** Argument count **)

VerificationTest[
  WolframModel[],
  WolframModel[],
  {WolframModel::argm}
]

VerificationTest[
  WolframModel[Method -> "C++"],
  WolframModel[Method -> "C++"],
  {WolframModel::argm}
]

(** Set is a list **)

VerificationTest[
  WolframModel[1 -> 2, 1],
  WolframModel[1 -> 2, 1],
  {WolframModel::invalidState}
]

VerificationTest[
  WolframModel[1 -> 2, 1, Method -> "C++"],
  WolframModel[1 -> 2, 1, Method -> "C++"],
  {WolframModel::invalidState}
]

(** Rules are valid **)

VerificationTest[
  WolframModel[1, {1}],
  WolframModel[1, {1}],
  {WolframModel::invalidRules}
]

VerificationTest[
  WolframModel[1, {1}, Method -> "C++"],
  WolframModel[1, {1}, Method -> "C++"],
  {WolframModel::invalidRules}
]

VerificationTest[
  WolframModel[{1}, {1}],
  WolframModel[{1}, {1}],
  {WolframModel::invalidRules}
]

(** Step count is valid **)

VerificationTest[
  WolframModel[{1 -> 2}, {1}, -1],
  WolframModel[{1 -> 2}, {1}, -1],
  {WolframModel::invalidSteps}
]

VerificationTest[
  WolframModel[{1 -> 2}, {1}, -1, Method -> "C++"],
  WolframModel[{1 -> 2}, {1}, -1, Method -> "C++"],
  {WolframModel::invalidSteps}
]

VerificationTest[
  WolframModel[{1 -> 2}, {1}, 1.5],
  WolframModel[{1 -> 2}, {1}, 1.5],
  {WolframModel::invalidSteps}
]

(** Method is valid **)

VerificationTest[
  WolframModel[{{0}} -> {{1}}, {{0}}, Method -> StringJoin[ToString /@ $SetReplaceMethods]],
  WolframModel[{{0}} -> {{1}}, {{0}}, Method -> StringJoin[ToString /@ $SetReplaceMethods]],
  {WolframModel::invalidMethod}
]

(* Implementation *)

(** Simple examples **)

VerificationTest[
  WolframModel[{1} -> {1}, {1}]["EventsCount"],
  1
]

VerificationTest[
  WolframModel[<|"PatternRules" -> (1 -> 2)|>, {1, 2, 3}][-1],
  {2, 3, 2}
]

VerificationTest[
  WolframModel[<|"PatternRules" -> (2 -> 5)|>, {1, 2, 3}][-1],
  {1, 3, 5}
]

VerificationTest[
  WolframModel[<|"PatternRules" -> (2 :> 5)|>, {1, 2, 3}][-1],
  {1, 3, 5}
]

VerificationTest[
  WolframModel[<|"PatternRules" -> {2 :> 5, 3 :> 6}|>, {1, 2, 3}][-1],
  {1, 5, 6}
]

VerificationTest[
  WolframModel[<|"PatternRules" -> {2 -> 5, 3 :> 6}|>, {1, 2, 3}][-1],
  {1, 5, 6}
]

VerificationTest[
  WolframModel[<|"PatternRules" -> {2 -> 5, 3 :> 6}|>, {1, 2, 3}, 2]["GenerationsCount"],
  1
]

VerificationTest[
  WolframModel[<|"PatternRules" -> {2 -> 5, 3 :> 6}|>, {1, 2, 3}, 2][-1],
  {1, 5, 6}
]

VerificationTest[
  WolframModel[<|"PatternRules" -> ({3, 2} -> 5)|>, {1, 2, 3}][-1],
  {1, 5}
]

VerificationTest[
  WolframModel[<|"PatternRules" -> (4 -> 5)|>, {1, 2, 3}]["EventsCount"],
  0
]

VerificationTest[
  WolframModel[<|"PatternRules" -> ({{1}} :> {})|>, {{1}}][-1],
  {}
]

VerificationTest[
  WolframModel[<|"PatternRules" -> ({{1}} :> {})|>, {{1}}, Method -> "C++"][-1],
  {}
]

VerificationTest[
  WolframModel[<|"PatternRules" -> ({{1}} :> {})|>, {{1}}, Method -> "WolframLanguage"][-1],
  {}
]

VerificationTest[
  WolframModel[<|"PatternRules" -> ({{1}} :> {})|>, {{1}}, Method -> Automatic][-1],
  {}
]

VerificationTest[
  WolframModel[<|"PatternRules" -> ({{1}, {2}} :> {{3}})|>, {{1}, {2}}][-1],
  {{3}}
]

VerificationTest[
  WolframModel[<|"PatternRules" -> ({{1}, {2}} :> {{3}})|>, {{2}, {1}}][-1],
  {{3}}
]

VerificationTest[
  WolframModel[
    <|"PatternRules" -> ({x_List ? (Length[#] == 3 &), y_List ? (Length[#] == 6 &)} :> {x, y, Join[x, y]})|>,
    {"This" -> "that", {2, 3, 4}, {2, 5}, {1, 2, 3, 4, 5, 6}},
    2][0],
  {"This" -> "that", {2, 3, 4}, {2, 5}, {1, 2, 3, 4, 5, 6}}
]

VerificationTest[
  WolframModel[
    <|"PatternRules" -> ({x_List ? (Length[#] == 3 &), y_List ? (Length[#] == 6 &)} :> {x, y, Join[x, y]})|>,
    {"This" -> "that", {2, 3, 4}, {2, 5}, {1, 2, 3, 4, 5, 6}},
    2][-1],
  {"This" -> "that", {2, 5}, {2, 3, 4, 1, 2, 3, 4, 5, 6}, {2, 3, 4}, {1, 2, 3, 4, 5, 6}, {2, 3, 4, 1, 2, 3, 4, 5, 6}}
]

VerificationTest[
  WolframModel[
    <|"PatternRules" -> ({x_List /; (Length[x] == 3), y_List /; (Length[y] == 6)} :> {x, y, Join[x, y]})|>,
    {"This" -> "that", {2, 3, 4}, {2, 5}, {1, 2, 3, 4, 5, 6}},
    2][0],
  {"This" -> "that", {2, 3, 4}, {2, 5}, {1, 2, 3, 4, 5, 6}}
]

VerificationTest[
  WolframModel[
    <|"PatternRules" -> ({x_List /; (Length[x] == 3), y_List /; (Length[y] == 6)} :> {x, y, Join[x, y]})|>,
    {"This" -> "that", {2, 3, 4}, {2, 5}, {1, 2, 3, 4, 5, 6}},
    2][-1],
  {"This" -> "that", {2, 5}, {2, 3, 4, 1, 2, 3, 4, 5, 6}, {2, 3, 4}, {1, 2, 3, 4, 5, 6}, {2, 3, 4, 1, 2, 3, 4, 5, 6}}
]

VerificationTest[
  WolframModel[<|"PatternRules" -> ({{a_, b_}, {b_, c_}} :> {{a, c}})|>, {{1, 2}, {2, 3}, {3, 4}, {4, 5}}, 2][1],
  {{1, 3}, {3, 5}}
]

VerificationTest[
  WolframModel[<|"PatternRules" -> ({{a_, b_}, {b_, c_}} :> {{a, c}})|>, {{1, 2}, {2, 3}, {3, 4}, {4, 5}}, 2][1],
  WolframModel[<|"PatternRules" -> ({{a_, b_}, {b_, c_}} :> {{a, c}})|>, {{1, 2}, {2, 3}, {3, 4}, {4, 5}}, 1][-1]
]

VerificationTest[
  WolframModel[<|"PatternRules" -> ({{a_, b_}, {b_, c_}} :> {{a, c}})|>, {{1, 2}, {2, 3}, {3, 4}, {4, 5}}, 2][-1],
  {{1, 5}}
]

VerificationTest[
  WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 2}}, 10]["GenerationsCount"],
  10
]

VerificationTest[
  WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 2}}, 10]["EventsCount"],
  1023
]

VerificationTest[
  WolframModel[{{1}} -> {}, {{1}, {2}, {3}, {4}, {5}}, Infinity]["GenerationsCount"],
  1
]

VerificationTest[
  WolframModel[{{1}} -> {}, {{1}, {2}, {3}, {4}, {5}}, Infinity]["EventsCount"],
  5
]

VerificationTest[
  WolframModel[{{1}} -> {}, {{1}, {2}, {3}, {4}, {5}}, Infinity][-1],
  {}
]

VerificationTest[
  WolframModel[{{1}} -> {{1}}, {{1}, {2}, {3}, {4}, {5}}, 0]["GenerationsCount"],
  0
]

VerificationTest[
  WolframModel[{{1}} -> {{1}}, {{1}, {2}, {3}, {4}, {5}}, 0]["EventsCount"],
  0
]

VerificationTest[
  WolframModel[
    {{{1}} -> {}, {{1, 2}} -> {{1}}},
    {{1, 2}, {2}, {3}, {4}, {5}},
    2]["GenerationsCount"],
  2
]

VerificationTest[
  WolframModel[
    {{{1}} -> {}, {{1, 2}} -> {{1}}},
    {{1, 2}, {2}, {3}, {4}, {5}},
    2]["EventsCount"],
  6
]

VerificationTest[
  WolframModel[
    <|"PatternRules" -> {{{1}} -> {{2}}}|>,
    {{1}, {1}, {1}},
    1,
    Method -> "C++"],
  WolframModel[
    <|"PatternRules" -> {{{1}} -> {{2}}}|>,
    {{1}, {1}, {1}},
    1,
    Method -> "WolframLanguage"]
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
