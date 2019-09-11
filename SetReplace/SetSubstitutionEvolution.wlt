BeginTestSection["SetSubstitutionEvolution"]

(** Argument checks **)

(* Corrupt object *)

VerificationTest[
  SetSubstitutionEvolution[],
  SetSubstitutionEvolution[],
  {SetSubstitutionEvolution::argx}
]

VerificationTest[
  SetSubstitutionEvolution[<||>],
  SetSubstitutionEvolution[<||>],
  {SetSubstitutionEvolution::corrupt}
]

VerificationTest[
  SetSubstitutionEvolution[<|a -> 1, b -> 2|>],
  SetSubstitutionEvolution[<|a -> 1, b -> 2|>],
  {SetSubstitutionEvolution::corrupt}
]

(* Incorrect property arguments *)

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["$$$UnknownProperty$$$,,,"],
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["$$$UnknownProperty$$$,,,"],
  {SetSubstitutionEvolution::unknownProperty}
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["GenerationsCount", 3],
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["GenerationsCount", 3],
  {SetSubstitutionEvolution::pargx}
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["GenerationsCount", 3, 3],
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["GenerationsCount", 3, 3],
  {SetSubstitutionEvolution::pargx}
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["Generation", 3, 3],
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["Generation", 3, 3],
  {SetSubstitutionEvolution::pargx}
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["Generation"],
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["Generation"],
  {SetSubstitutionEvolution::pargx}
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent"],
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent"],
  {SetSubstitutionEvolution::pargx}
]

(* Incorrect step arguments *)

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", 16],
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", 16],
  {SetSubstitutionEvolution::eventTooLarge}
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", -17],
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", -17],
  {SetSubstitutionEvolution::eventTooLarge}
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", 1.2],
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", 1.2],
  {SetSubstitutionEvolution::eventNotInteger}
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", "good"],
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", "good"],
  {SetSubstitutionEvolution::eventNotInteger}
]

(* Incorrect generation arguments *)

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["Generation", 5],
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["Generation", 5],
  {SetSubstitutionEvolution::generationTooLarge}
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["Generation", -6],
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["Generation", -6],
  {SetSubstitutionEvolution::generationTooLarge}
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["Generation", 2.3],
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["Generation", 2.3],
  {SetSubstitutionEvolution::generationNotInteger}
]

(** Boxes **)

VerificationTest[
  Head @ ToBoxes @ SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4],
  InterpretationBox
]

(** Implementation of properties **)

(* Properties *)

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["Properties"],
  ListQ,
  SameTest -> (#2[#1] &)
]

(* Rules *)

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["Rules"],
  {{a_, b_}, {b_, c_}} :> {{a, c}}
]

(* GenerationsCount *)

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["GenerationsCount"],
  4
]

(* EventsCount *)

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["EventsCount"],
  15
]

(* SetAfterEvent *)

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", 0],
  Partition[Range[17], 2, 1]
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", 1],
  Join[Partition[Range[3, 17], 2, 1], {{1, 3}}]
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", 2],
  Join[Partition[Range[5, 17], 2, 1], {{1, 3}, {3, 5}}]
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", 14],
  {{1, 9}, {9, 17}}
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", -2],
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", 14]
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", 15],
  {{1, 17}}
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", -1],
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["SetAfterEvent", 15]
]

(* Generation *)

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["Generation", 0],
  Partition[Range[17], 2, 1]
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["Generation", 1],
  Partition[Range[1, 17, 2], 2, 1]
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["Generation", 2],
  Partition[Range[1, 17, 4], 2, 1]
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["Generation", 3],
  {{1, 9}, {9, 17}}
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["Generation", -2],
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["Generation", 3]
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["Generation", 4],
  {{1, 17}}
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["Generation", -1],
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["Generation", 4]
]

(* AtomsCountFinal *)

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["AtomsCountFinal"],
  2
]

(* AtomsCountTotal *)

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["AtomsCountTotal"],
  17
]

(* ExpressionsCountFinal *)

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["ExpressionsCountFinal"],
  1
]

(* ExpressionsCountTotal *)

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["ExpressionsCountTotal"],
  16 + 8 + 4 + 2 + 1
]

(* CausalGraph *)

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["CausalGraph", 1],
   SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["CausalGraph", 1],
  {SetSubstitutionEvolution::nonopt}
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["CausalGraph", 1, "str" -> 3],
   SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["CausalGraph", 1, "str" -> 3],
  {SetSubstitutionEvolution::nonopt}
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["CausalGraph", "BadOpt" -> "NotExist"],
   SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["CausalGraph", "BadOpt" -> "NotExist"],
  {SetSubstitutionEvolution::optx}
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["CausalGraph"],
  Graph[Range[15], {
    1 -> 9, 2 -> 9, 3 -> 10, 4 -> 10, 5 -> 11, 6 -> 11, 7 -> 12, 8 -> 12,
    9 -> 13, 10 -> 13, 11 -> 14, 12 -> 14,
    13 -> 15, 14 -> 15
  }]
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    4]["CausalGraph", VertexLabels -> "Name", GraphLayout -> "SpringElectricalEmbedding"],
  Graph[Range[15], {
    1 -> 9, 2 -> 9, 3 -> 10, 4 -> 10, 5 -> 11, 6 -> 11, 7 -> 12, 8 -> 12,
    9 -> 13, 10 -> 13, 11 -> 14, 12 -> 14,
    13 -> 15, 14 -> 15
  }, VertexLabels -> "Name", GraphLayout -> "SpringElectricalEmbedding"]
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    1]["CausalGraph"],
  Graph[Range[8], {}]
]

VerificationTest[
  SetSubstitutionSystem[
    {{a_, b_}, {b_, c_}} :> {{a, c}},
    Partition[Range[17], 2, 1],
    2]["CausalGraph"],
  Graph[Range[12], {1 -> 9, 2 -> 9, 3 -> 10, 4 -> 10, 5 -> 11, 6 -> 11, 7 -> 12, 8 -> 12}]
]

$largeEvolution = SetSubstitutionSystem[
  FromAnonymousRules[
    {{0, 1}, {0, 2}, {0, 3}} ->
      {{4, 5}, {5, 6}, {6, 4}, {4, 6}, {6, 5}, {5, 4},
      {4, 1}, {5, 2}, {6, 3},
      {1, 6}, {3, 4}}],
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
  SetSubstitutionSystem[
    FromAnonymousRules[
      {{0, 1}, {0, 2}, {0, 3}} ->
        {{4, 5}, {5, 6}, {6, 4}, {4, 6}, {6, 5}, {5, 4},
        {4, 1}, {5, 2}, {6, 3},
        {1, 6}, {3, 4}}],
    {{0, 0}, {0, 0}, {0, 0}},
    3,
    Method -> "WolframLanguage"]["CausalGraph"],
  SetSubstitutionSystem[
    FromAnonymousRules[
      {{0, 1}, {0, 2}, {0, 3}} ->
        {{4, 5}, {5, 6}, {6, 4}, {4, 6}, {6, 5}, {5, 4},
        {4, 1}, {5, 2}, {6, 3},
        {1, 6}, {3, 4}}],
    {{0, 0}, {0, 0}, {0, 0}},
    3,
    Method -> "C++"]["CausalGraph"]
]

EndTestSection[]
