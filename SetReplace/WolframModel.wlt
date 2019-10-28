BeginTestSection["WolframModel"]

(* Argument checks *)

(** Argument counts, simple rule and inits **)

VerificationTest[
  WolframModel,
  WolframModel
]

VerificationTest[
  WolframModel[],
  WolframModel[],
  {WolframModel::argb}
]

VerificationTest[
  WolframModel[x],
  WolframModel[x],
  {WolframModel::invalidRules}
]

VerificationTest[
  WolframModel[x, y],
  WolframModel[x, y],
  {WolframModel::invalidRules}
]

VerificationTest[
  WolframModel[x, y, z],
  WolframModel[x, y, z],
  {WolframModel::invalidRules}
]

VerificationTest[
  WolframModel[x, y, z, w],
  WolframModel[x, y, z, w],
  {WolframModel::invalidRules}
]

VerificationTest[
  WolframModel[x, y, z, w, a],
  WolframModel[x, y, z, w, a],
  {WolframModel::argb}
]

VerificationTest[
  WolframModel[x, y, z, w, a, b],
  WolframModel[x, y, z, w, a, b],
  {WolframModel::argb}
]

VerificationTest[
  WolframModel[f -> 3],
  WolframModel[f -> 3],
  {WolframModel::argb}
]

VerificationTest[
  WolframModel[x, f -> 3],
  WolframModel[x, f -> 3],
  {WolframModel::invalidRules}
]

VerificationTest[
  WolframModel[x, y, f -> 3],
  WolframModel[x, y, f -> 3],
  {WolframModel::invalidRules}
]

VerificationTest[
  WolframModel[x, y, z, f -> 3],
  WolframModel[x, y, z, f -> 3],
  {WolframModel::invalidRules}
]

VerificationTest[
  WolframModel[x, y, z, w, f -> 3],
  WolframModel[x, y, z, w, f -> 3],
  {WolframModel::invalidRules}
]

VerificationTest[
  WolframModel[x, y, z, w, a, f -> 3],
  WolframModel[x, y, z, w, a, f -> 3],
  {WolframModel::argb}
]

VerificationTest[
  WolframModel[x, y, z, w, a, b, f -> 3],
  WolframModel[x, y, z, w, a, b, f -> 3],
  {WolframModel::argb}
]

VerificationTest[
  WolframModel[1 -> 2],
  WolframModel[1 -> 2]
]

VerificationTest[
  WolframModel[1 -> 2, f -> 2],
  WolframModel[1 -> 2, f -> 2],
  {WolframModel::optx}
]

VerificationTest[
  WolframModel[1 -> 2, f -> 2][1],
  WolframModel[1 -> 2, f -> 2][1],
  {WolframModel::optx}
]

VerificationTest[
  WolframModel[1 -> 2, f -> 2][{1}],
  WolframModel[1 -> 2, f -> 2][{1}],
  {WolframModel::optx}
]

VerificationTest[
  WolframModel[1 -> 2, Method -> "LowLevel"][{1}],
  WolframModel[1 -> 2, Method -> "LowLevel"][{1}],
  {WolframModel::lowLevelNotImplemented}
]

VerificationTest[
  WolframModel[1 -> 2, Method -> "$$$InvalidMethod$$$"][{1}],
  WolframModel[1 -> 2, Method -> "$$$InvalidMethod$$$"][{1}],
  {WolframModel::invalidMethod}
]

VerificationTest[
  WolframModel[1 -> 2, 4],
  WolframModel[1 -> 2, 4],
  {WolframModel::invalidState}
]

VerificationTest[
  WolframModel[1 -> 2, 4, g -> 2],
  WolframModel[1 -> 2, 4, g -> 2],
  {WolframModel::invalidState}
]

VerificationTest[
  WolframModel[1 -> 2][4],
  WolframModel[1 -> 2][4],
  {WolframModel::invalidState}
]

VerificationTest[
  WolframModel[1 -> 2, g -> 2][4],
  WolframModel[1 -> 2, g -> 2][4],
  {WolframModel::optx}
]

VerificationTest[
  WolframModel[1 -> 2][4, g -> 2],
  WolframModel[1 -> 2][4, g -> 2],
  {WolframModel::argx}
]

VerificationTest[
  WolframModel[1 -> 2][{1}],
  {_ ? AtomQ},
  SameTest -> MatchQ
]

VerificationTest[
  WolframModel[1 -> 2, {1}],
  _WolframModelEvolutionObject,
  SameTest -> MatchQ
]

VerificationTest[
  WolframModel[1 -> 2, f -> 2][{1}],
  WolframModel[1 -> 2, f -> 2][{1}],
  {WolframModel::optx}
]

VerificationTest[
  WolframModel[1 -> 2][{1}, f -> 2],
  WolframModel[1 -> 2][{1}, f -> 2],
  {WolframModel::argx}
]

VerificationTest[
  WolframModel[1 -> 2][{1}, x],
  WolframModel[1 -> 2][{1}, x],
  {WolframModel::argx}
]

VerificationTest[
  WolframModel[1 -> 2, x][{1}],
  WolframModel[1 -> 2, x][{1}],
  {WolframModel::invalidState}
]

VerificationTest[
  WolframModel[1 -> 2, Method -> "$$$InvalidMethod$$$"][{1}],
  WolframModel[1 -> 2, Method -> "$$$InvalidMethod$$$"][{1}],
  {WolframModel::invalidMethod}
]

VerificationTest[
  WolframModel[1 -> 2, Method -> "Symbolic"][{1}],
  {_ ? AtomQ},
  SameTest -> MatchQ
]

VerificationTest[
  WolframModel[1 -> 2][{1}, Method -> "Symbolic"],
  WolframModel[1 -> 2][{1}, Method -> "Symbolic"],
  {WolframModel::argx}
]

(** PatternRules **)

VerificationTest[
  WolframModel[<|"PatternRules" -> 1 -> 2|>][{1}],
  {2}
]

VerificationTest[
  WolframModel[<|"PatternRule" -> 1 -> 2|>],
  WolframModel[<|"PatternRule" -> 1 -> 2|>],
  {WolframModel::invalidRules}
]

VerificationTest[
  WolframModel[<|"PatternRule" -> 1 -> 2|>][{1}],
  WolframModel[<|"PatternRule" -> 1 -> 2|>][{1}],
  {WolframModel::invalidRules}
]

VerificationTest[
  WolframModel[<|"PatternRules" -> 1 -> 2, "f" -> 2|>],
  WolframModel[<|"PatternRules" -> 1 -> 2, "f" -> 2|>],
  {WolframModel::invalidRules}
]

VerificationTest[
  WolframModel[<|"PatternRules" -> 1 -> 2, "f" -> 2|>][{1}],
  WolframModel[<|"PatternRules" -> 1 -> 2, "f" -> 2|>][{1}],
  {WolframModel::invalidRules}
]

VerificationTest[
  WolframModel[<|"PatternRules" -> 1 -> 2|>],
  WolframModel[<|"PatternRules" -> 1 -> 2|>]
]

VerificationTest[
  WolframModel[<|"PatternRules" -> {1 -> 2, a_ :> Module[{b}, b]}|>][{1}],
  {2}
]

VerificationTest[
  WolframModel[<|"PatternRules" -> {1 -> 2, a_ :> Module[{b}, b]}|>][{2}],
  {_ ? AtomQ},
  SameTest -> MatchQ
]

VerificationTest[
  WolframModel[<|"PatternRules" -> {1 -> 2, a_ :> Module[{b}, b]}|>, {1}],
  _WolframModelEvolutionObject,
  SameTest -> MatchQ
]

VerificationTest[
  WolframModel[<|"PatternRules" -> {1 -> 2, a_ :> Module[{b}, b]}|>, {1}, x],
  WolframModel[<|"PatternRules" -> {1 -> 2, a_ :> Module[{b}, b]}|>, {1}, x],
  {WolframModel::invalidSteps}
]

(** Steps **)

VerificationTest[
  WolframModel[1 -> 2, {1}, 2]["GenerationsCount"],
  2
]

VerificationTest[
  WolframModel[1 -> 2, {1}, 2, x],
  WolframModel[1 -> 2, {1}, 2, x],
  {WolframModel::invalidProperty}
]

VerificationTest[
  WolframModel[1 -> 2, {1}, 2.2],
  WolframModel[1 -> 2, {1}, 2.2],
  {WolframModel::invalidSteps}
]

VerificationTest[
  WolframModel[1 -> 2, {1}, "sdfsdf"],
  WolframModel[1 -> 2, {1}, "sdfsdf"],
  {WolframModel::invalidSteps}
]

VerificationTest[
  WolframModel[1 -> 2, {1}, 0]["EventsCount"],
  0
]

VerificationTest[
  WolframModel[1 -> 2, {1}, -1],
  WolframModel[1 -> 2, {1}, -1],
  {WolframModel::invalidSteps}
]

VerificationTest[
  WolframModel[{{0, 1}} -> {{0, 2}, {2, 1}}, {{0, 1}}, 3] /@ {"GenerationsCount", "EventsCount"},
  {3, 7}
]

VerificationTest[
  WolframModel[{{0, 1}} -> {{0, 2}, {2, 1}}, {{0, 1}}, <|"Generations" -> 3|>] /@ {"GenerationsCount", "EventsCount"},
  {3, 7}
]

VerificationTest[
  WolframModel[{{0, 1}} -> {{0, 2}, {2, 1}}, {{0, 1}}, <|"Events" -> 6|>] /@ {"GenerationsCount", "EventsCount"},
  {3, 6}
]

VerificationTest[
  WolframModel[{{0, 1}} -> {{0, 2}, {2, 1}}, {{0, 1}}, <|"Generations" -> 3, "Events" -> 6|>] /@ {"GenerationsCount", "EventsCount"},
  {3, 6}
]

VerificationTest[
  WolframModel[{{0, 1}} -> {{0, 2}, {2, 1}}, {{0, 1}}, <|"Generations" -> 2, "Events" -> 6|>] /@ {"GenerationsCount", "EventsCount"},
  {2, 3}
]

VerificationTest[
  WolframModel[{{0, 1}, {1, 2}} -> {{0, 2}}, {{0, 1}, {1, 2}, {2, 3}, {3, 4}}, <||>] /@ {"GenerationsCount", "EventsCount"},
  {2, 3}
]

VerificationTest[
  WolframModel[{{0, 1}, {1, 2}} -> {{0, 2}}, {{0, 1}, {1, 2}, {2, 3}, {3, 4}}, <|"x" -> 2|>],
  WolframModel[{{0, 1}, {1, 2}} -> {{0, 2}}, {{0, 1}, {1, 2}, {2, 3}, {3, 4}}, <|"x" -> 2|>],
  {WolframModel::invalidSteps}
]

VerificationTest[
  WolframModel[{{0, 1}, {1, 2}} -> {{0, 2}}, {{0, 1}, {1, 2}, {2, 3}, {3, 4}}, <|"x" -> 2, "Generations" -> 2|>],
  WolframModel[{{0, 1}, {1, 2}} -> {{0, 2}}, {{0, 1}, {1, 2}, {2, 3}, {3, 4}}, <|"x" -> 2, "Generations" -> 2|>],
  {WolframModel::invalidSteps}
]

VerificationTest[
  WolframModel[{{0, 1}} -> {{0, 2}, {2, 1}}, {{0, 1}}, <|"Generations" -> \[Infinity], "Events" -> 12|>] /@ {"GenerationsCount", "EventsCount"},
  {4, 12}
]

(** Properties **)

VerificationTest[
  WolframModel[1 -> 2, {1}, 2, "CausalGraph"],
  Graph[{1, 2}, {1 -> 2}]
]

VerificationTest[
  WolframModel[1 -> 2, {1}, 2, "123"],
  WolframModel[1 -> 2, {1}, 2, "123"],
  {WolframModel::invalidProperty}
]

VerificationTest[
  WolframModel[1 -> 2, {1}, 2, "Generation"],
  WolframModel[1 -> 2, {1}, 2, "Generation"],
  {WolframModel::invalidProperty}
]

VerificationTest[
  WolframModel[1 -> 2, {1}, 2, #] & /@ $WolframModelProperties // Length,
  Length[$WolframModelProperties]
]

VerificationTest[
  WolframModel[1 -> 2, {1}, 2, $WolframModelProperties] // Length,
  WolframModel[1 -> 2, {1}, 2, #] & /@ $WolframModelProperties // Length
]

VerificationTest[
  WolframModel[1 -> 2, {1}, 2, 2],
  WolframModel[1 -> 2, {1}, 2, 2],
  {WolframModel::invalidProperty}
]

VerificationTest[
  WolframModel[1 -> 2, {1}, 2, {2, 3}],
  WolframModel[1 -> 2, {1}, 2, {2, 3}],
  {WolframModel::invalidProperty}
]

VerificationTest[
  WolframModel[1 -> 2, {1}, 2, {"CausalGraph", 3}],
  WolframModel[1 -> 2, {1}, 2, {"CausalGraph", 3}],
  {WolframModel::invalidProperty}
]

VerificationTest[
  WolframModel[1 -> 2, {1}, 2, {3, "CausalGraph"}],
  WolframModel[1 -> 2, {1}, 2, {3, "CausalGraph"}],
  {WolframModel::invalidProperty}
]

VerificationTest[
  WolframModel[1 -> 2, {1}, 2, {"CausalGraph", "CausalGraph"}],
  ConstantArray[Graph[{1, 2}, {1 -> 2}], 2]
]

VerificationTest[
  WolframModel[1 -> 2, {1}, 2, "Rules"],
  WolframModel[1 -> 2, {1}, 2, "Rules"],
  {WolframModel::invalidProperty}
]

VerificationTest[
  WolframModel[1 -> 2, {1}, 2, "Properties"],
  WolframModel[1 -> 2, {1}, 2, "Properties"],
  {WolframModel::invalidProperty}
]

(** Missing arguments **)

VerificationTest[
  WolframModel[1 -> 2, {1}, 1 -> 2, 2 -> 3],
  WolframModel[1 -> 2, {1}, 1 -> 2, 2 -> 3],
  {WolframModel::invalidSteps}
]

VerificationTest[
  WolframModel[1 -> 2, {1}, "sdfds" -> 2, "xcvxcv" -> 3],
  WolframModel[1 -> 2, {1}, "sdfds" -> 2, "xcvxcv" -> 3],
  {WolframModel::optx}
]

VerificationTest[
  WolframModel[{1}, 1 -> 2],
  WolframModel[{1}, 1 -> 2],
  {WolframModel::invalidRules}
]

VerificationTest[
  WolframModel[1, 1 -> 2],
  WolframModel[1, 1 -> 2],
  {WolframModel::invalidRules}
]

VerificationTest[
  WolframModel[1 -> 2, "CausalGraph"],
  WolframModel[1 -> 2, "CausalGraph"],
  {WolframModel::invalidState}
]

VerificationTest[
  WolframModel[1 -> 2, {1}, "CausalGraph"],
  Graph[{1}, {}]
]

VerificationTest[
  WolframModel[1 -> 2, {1}, "CausalGraph", 1],
  WolframModel[1 -> 2, {1}, "CausalGraph", 1],
  {WolframModel::invalidSteps}
]

VerificationTest[
  WolframModel[1 -> 2, 1, "CausalGraph"],
  WolframModel[1 -> 2, 1, "CausalGraph"],
  {WolframModel::invalidState}
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
  WolframModel[<|"PatternRules" -> ({{1}} :> {})|>, {{1}}, Method -> "LowLevel"][-1],
  {}
]

VerificationTest[
  WolframModel[<|"PatternRules" -> ({{1}} :> {})|>, {{1}}, Method -> "Symbolic"][-1],
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
    Method -> "LowLevel"],
  WolframModel[
    <|"PatternRules" -> {{{1}} -> {{2}}}|>,
    {{1}, {1}, {1}},
    1,
    Method -> "Symbolic"]
]

VerificationTest[
  WolframModel[
    {{v[1], v[2]}, {v[2], v[3]}} -> {{v[1], v[3]}},
    {{v[1], v[2]}, {v[2], v[3]}},
    "FinalState",
    Method -> "Symbolic"],
  {{v[1], v[3]}}
]

VerificationTest[
  WolframModel[
    {{v[1], v[2]}, {v[2], v[3]}} -> {{v[1], v[3]}},
    {{v[1], v[2]}, {v[2], v[3]}},
    "FinalState",
    Method -> "LowLevel"],
  {{v[1], v[3]}}
]

VerificationTest[
  WolframModel[
    {{1, 3}} -> {{1, 2}, {2, 3}},
    {{0, 0}},
    2,
    "FinalState"],
  {{1, 3}, {3, 2}, {2, 4}, {4, 1}}
]

VerificationTest[
  WolframModel[
    {{1, 3}} -> {{1, 2}, {2, 3}},
    {{0, 0}},
    2,
    "FinalState",
    "NodeNamingFunction" -> #],
  {{1, 3}, {3, 2}, {2, 4}, {4, 1}}
] & /@ {Automatic, All}

VerificationTest[
  WolframModel[
    {{1, 3}} -> {{1, 2}, {2, 3}},
    {{0, 0}},
    2,
    "FinalState",
    "NodeNamingFunction" -> None],
  {{0, x_Symbol}, {x_Symbol, y_Symbol}, {y_Symbol, z_Symbol}, {z_Symbol, 0}},
  SameTest -> MatchQ
]

VerificationTest[
  WolframModel[
    <|"PatternRules" -> {{a_, b_}} :> Module[{c}, {{a, c}, {c, b}}]|>,
    {{0, 0}},
    2,
    "FinalState",
    "NodeNamingFunction" -> All],
  {{1, 3}, {3, 2}, {2, 4}, {4, 1}}
]

VerificationTest[
  WolframModel[
    <|"PatternRules" -> {{a_, b_}} :> Module[{c}, {{a, c}, {c, b}}]|>,
    {{0, 0}},
    2,
    "FinalState",
    "NodeNamingFunction" -> #],
  {{0, x_Symbol}, {x_Symbol, y_Symbol}, {y_Symbol, z_Symbol}, {z_Symbol, 0}},
  SameTest -> MatchQ
] & /@ {Automatic, None}

VerificationTest[
  WolframModel[
    <|"PatternRules" -> {{a_, b_}} :> Module[{c}, {{a, c}, {c, b}}]|>,
    {{0, 0}},
    2,
    "FinalState"],
  {{0, x_Symbol}, {x_Symbol, y_Symbol}, {y_Symbol, z_Symbol}, {z_Symbol, 0}},
  SameTest -> MatchQ
]

$namingTestModel = {
  {{0, 1}, {0, 2}, {0, 3}} ->
    {{4, 5}, {5, 4}, {4, 6}, {6, 4}, {5, 6},
      {6, 5}, {4, 1}, {5, 2}, {6, 3}, {1, 6}, {3, 4}},
  {{0, 0},
  {0, 0}, {0, 0}},
  5,
  "FinalState"};

VerificationTest[
  # == Range[Length[#]] & @ Union @ Flatten[
    WolframModel[##, "NodeNamingFunction" -> All] & @@
      $namingTestModel]
]

VerificationTest[
  (#[[1]] /. Thread[Rule @@ Flatten /@ #]) == #[[2]] & @ (Table[
    WolframModel[##, "NodeNamingFunction" -> namingFunction] & @@ $namingTestModel,
    {namingFunction, {All, None}}])
]

(*** For anonymous rules, all level-2 expressions must be atomized, similar to ToPatternRules behavior ***)
VerificationTest[
  WolframModel[
    {{s[1], s[2]}} -> {{s[1], s[3]}, {s[3], s[2]}},
    {{s[1], s[2]}},
    1,
    "FinalState"],
  {{1, 3}, {3, 2}}
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


BeginTestSection["$WolframModelProperties"]

VerificationTest[
  ListQ[$WolframModelProperties]
]

VerificationTest[
  AllTrue[
    $WolframModelProperties,
    Head[WolframModel[{{0}} -> {{1}}, {{0}}, 1, #]] =!= WolframModel &]
]

EndTestSection[]
