BeginTestSection["WolframModelEvolutionObject"]

(** Argument checks **)

(* Corrupt object *)

VerificationTest[
  WolframModelEvolutionObject[],
  WolframModelEvolutionObject[],
  {WolframModelEvolutionObject::argx}
]

VerificationTest[
  WolframModelEvolutionObject[<||>],
  WolframModelEvolutionObject[<||>],
  {WolframModelEvolutionObject::corrupt}
]

VerificationTest[
  WolframModelEvolutionObject[<|a -> 1, b -> 2|>],
  WolframModelEvolutionObject[<|a -> 1, b -> 2|>],
  {WolframModelEvolutionObject::corrupt}
]

(* Incorrect property arguments *)

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["$$$UnknownProperty$$$,,,"],
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["$$$UnknownProperty$$$,,,"],
  {WolframModelEvolutionObject::unknownProperty}
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["GenerationsCount", 3],
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["GenerationsCount", 3],
  {WolframModelEvolutionObject::pargx}
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["GenerationsCount", 3, 3],
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["GenerationsCount", 3, 3],
  {WolframModelEvolutionObject::pargx}
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["Generation", 3, 3],
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["Generation", 3, 3],
  {WolframModelEvolutionObject::pargx}
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["Generation"],
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["Generation"],
  {WolframModelEvolutionObject::pargx}
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent"],
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent"],
  {WolframModelEvolutionObject::pargx}
]

(* Incorrect step arguments *)

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", 16],
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", 16],
  {WolframModelEvolutionObject::eventTooLarge}
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", -17],
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", -17],
  {WolframModelEvolutionObject::eventTooLarge}
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", 1.2],
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", 1.2],
  {WolframModelEvolutionObject::eventNotInteger}
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", "good"],
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", "good"],
  {WolframModelEvolutionObject::eventNotInteger}
]

(* Incorrect generation arguments *)

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["Generation", 5],
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["Generation", 5],
  {WolframModelEvolutionObject::generationTooLarge}
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["Generation", -6],
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["Generation", -6],
  {WolframModelEvolutionObject::generationTooLarge}
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["Generation", 2.3],
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["Generation", 2.3],
  {WolframModelEvolutionObject::generationNotInteger}
]

(** Boxes **)

VerificationTest[
  Head @ ToBoxes @ WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4],
  InterpretationBox
]

(** Implementation of properties **)

(* Properties *)

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["Properties"],
  ListQ,
  SameTest -> (#2[#1] &)
]

(* Rules *)

VerificationTest[
  WolframModel[
    <|"PatternRules" -> {{a_, b_}, {b_, c_}} :> {{a, c}}|>,
    Partition[Range[17], 2, 1],
    4]["Rules"],
  <|"PatternRules" -> {{a_, b_}, {b_, c_}} :> {{a, c}}|>
]

VerificationTest[
  WolframModel[
    {{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}} -> {{1, 3}, {3, 2}}},
    Partition[Range[17], 2, 1],
    4]["Rules"],
  {{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}} -> {{1, 3}, {3, 2}}}
]

VerificationTest[
  WolframModel[1 -> 2, {1}, 4]["Rules"],
  1 -> 2
]

(* GenerationsCount *)

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["GenerationsCount"],
  4
]

(* EventsCount *)

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["EventsCount"],
  15
]

(* SetAfterEvent *)

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", 0],
  Partition[Range[17], 2, 1]
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", 1],
  Join[Partition[Range[3, 17], 2, 1], {{1, 3}}]
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", 2],
  Join[Partition[Range[5, 17], 2, 1], {{1, 3}, {3, 5}}]
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", 14],
  {{1, 9}, {9, 17}}
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", -2],
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", 14]
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", 15],
  {{1, 17}}
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", -1],
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", 15]
]

(* Generation *)

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["Generation", 0],
  Partition[Range[17], 2, 1]
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["Generation", 1],
  Partition[Range[1, 17, 2], 2, 1]
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["Generation", 2],
  Partition[Range[1, 17, 4], 2, 1]
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["Generation", 3],
  {{1, 9}, {9, 17}}
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["Generation", -2],
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["Generation", 3]
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["Generation", 4],
  {{1, 17}}
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["Generation", -1],
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["Generation", 4]
]

(* AtomsCountFinal *)

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["AtomsCountFinal"],
  2
]

VerificationTest[
  WolframModel[
    1 -> 2,
    {1},
    5]["AtomsCountFinal"],
  1
]

VerificationTest[
  WolframModel[
    1 -> 1,
    {1},
    5]["AtomsCountFinal"],
  1
]

(* AtomsCountTotal *)

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["AtomsCountTotal"],
  17
]

VerificationTest[
  WolframModel[
    1 -> 2,
    {1},
    5]["AtomsCountTotal"],
  6
]

VerificationTest[
  WolframModel[
    1 -> 1,
    {1},
    5]["AtomsCountTotal"],
  1
]

(* ExpressionsCountFinal *)

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["ExpressionsCountFinal"],
  1
]

(* ExpressionsCountTotal *)

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["ExpressionsCountTotal"],
  16 + 8 + 4 + 2 + 1
]

(* CausalGraph *)

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["CausalGraph", 1],
   WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["CausalGraph", 1],
  {WolframModelEvolutionObject::nonopt}
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["CausalGraph", 1, "str" -> 3],
   WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["CausalGraph", 1, "str" -> 3],
  {WolframModelEvolutionObject::nonopt}
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["CausalGraph", "BadOpt" -> "NotExist"],
   WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["CausalGraph", "BadOpt" -> "NotExist"],
  {WolframModelEvolutionObject::optx}
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["CausalGraph"],
  Graph[Range[15], {
    1 -> 9, 2 -> 9, 3 -> 10, 4 -> 10, 5 -> 11, 6 -> 11, 7 -> 12, 8 -> 12,
    9 -> 13, 10 -> 13, 11 -> 14, 12 -> 14,
    13 -> 15, 14 -> 15
  }]
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    4]["CausalGraph", VertexLabels -> "Name", GraphLayout -> "SpringElectricalEmbedding"],
  Graph[Range[15], {
    1 -> 9, 2 -> 9, 3 -> 10, 4 -> 10, 5 -> 11, 6 -> 11, 7 -> 12, 8 -> 12,
    9 -> 13, 10 -> 13, 11 -> 14, 12 -> 14,
    13 -> 15, 14 -> 15
  }, VertexLabels -> "Name", GraphLayout -> "SpringElectricalEmbedding"]
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    1]["CausalGraph"],
  Graph[Range[8], {}]
]

VerificationTest[
  WolframModel[
    {{1, 2}, {2, 3}} -> {{1, 3}},
    Partition[Range[17], 2, 1],
    2]["CausalGraph"],
  Graph[Range[12], {1 -> 9, 2 -> 9, 3 -> 10, 4 -> 10, 5 -> 11, 6 -> 11, 7 -> 12, 8 -> 12}]
]

$largeEvolution = WolframModel[
  {{0, 1}, {0, 2}, {0, 3}} ->
    {{4, 5}, {5, 6}, {6, 4}, {4, 6}, {6, 5}, {5, 4},
    {4, 1}, {5, 2}, {6, 3},
    {1, 6}, {3, 4}},
  {{0, 0}, {0, 0}, {0, 0}},
  7];

VerificationTest[
  AcyclicGraphQ[$largeEvolution["CausalGraph"]]
]

VerificationTest[
  LoopFreeGraphQ[$largeEvolution["CausalGraph"]]
]

VerificationTest[
  Count[VertexInDegree[$largeEvolution["CausalGraph"]], 3],
  $largeEvolution["EventsCount"] - 1
]

VerificationTest[
  VertexCount[$largeEvolution["CausalGraph"]],
  $largeEvolution["EventsCount"]
]

VerificationTest[
  GraphDistance[$largeEvolution["CausalGraph"], 1, $largeEvolution["EventsCount"]],
  $largeEvolution["GenerationsCount"] - 1
]

VerificationTest[
  WolframModel[
    {{0, 1}, {0, 2}, {0, 3}} ->
      {{4, 5}, {5, 6}, {6, 4}, {4, 6}, {6, 5}, {5, 4},
      {4, 1}, {5, 2}, {6, 3},
      {1, 6}, {3, 4}},
    {{0, 0}, {0, 0}, {0, 0}},
    3,
    Method -> "WolframLanguage"]["CausalGraph"],
  WolframModel[
    {{0, 1}, {0, 2}, {0, 3}} ->
      {{4, 5}, {5, 6}, {6, 4}, {4, 6}, {6, 5}, {5, 4},
      {4, 1}, {5, 2}, {6, 3},
      {1, 6}, {3, 4}},
    {{0, 0}, {0, 0}, {0, 0}},
    3,
    Method -> "C++"]["CausalGraph"]
]

EndTestSection[]
