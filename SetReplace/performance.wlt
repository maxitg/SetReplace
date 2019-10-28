BeginTestSection["performance"]

(** C++ performance **)

$init = {{0, 0}, {0, 0}, {0, 0}};

$rule =
  {{{a_, b_}, {a_, c_}, {a_, d_}} :>
    Module[{$0, $1, $2}, {
      {$0, $1}, {$1, $2}, {$2, $0}, {$0, $2}, {$2, $1}, {$1, $0},
      {$0, b}, {$1, c}, {$2, d}, {b, $2}, {d, $0}}]};

VerificationTest[
  SetReplace[
    $init,
    $rule,
    1000],
  {0},
  SameTest -> (ListQ[#1] && ListQ[#2] &),
  TimeConstraint -> 3,
  MemoryConstraint -> 5*^6
]

(** WL performance **)

VerificationTest[
  SetReplace[
    $init,
    $rule,
    100,
    Method -> "Symbolic"],
  {0},
  SameTest -> (ListQ[#1] && ListQ[#2] &),
  TimeConstraint -> 60,
  MemoryConstraint -> 5*^6
]

(** Naming function performance **)

VerificationTest[
  WolframModel[
    <|"PatternRules" -> $rule|>,
    $init,
    <|"Events" -> 1000|>,
    "FinalState",
    "NodeNamingFunction" -> All],
  {0},
  SameTest -> (ListQ[#1] && ListQ[#2] &),
  TimeConstraint -> 3,
  MemoryConstraint -> 5*^6
]

(** C++ aborting **)

(* assumes example below runs slow, may need to be replaced in the future *)
VerificationTest[
  (* it is possible for evaluation to finish slightly earlier than the constraint, hence the min of 0.8;
     timing varies around +-0.05, so using tolerance 0.2 to avoid random failures *)
  AbsoluteTiming[TimeConstrained[SetReplace[
      {{0}},
      ToPatternRules[{{{0}} -> {{0}, {0}, {0}}, {{0}, {0}, {0}} -> {{0}}}],
      30], 1]][[1]],
  1.0,
  SameTest -> (Abs[#1 - #2] < 0.2 &),
  TimeConstraint -> 3
]

EndTestSection[]
