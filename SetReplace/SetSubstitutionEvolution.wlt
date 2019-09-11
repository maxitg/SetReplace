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
  {SetSubstitutionEvolution::unknownArg}
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
  {SetSubstitutionEvolution::unknownArg}
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

EndTestSection[]
