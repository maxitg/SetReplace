BeginTestSection["SetReplace"]

(* Argument checks *)

(** Argument count **)

VerificationTest[
	SetReplace[],
	SetReplace[],
	{SetReplace::argt}
]

VerificationTest[
	SetReplace[Method -> "LowLevel"],
	SetReplace[Method -> "LowLevel"],
	{SetReplace::argt}
]

(** Set is a list **)

VerificationTest[
	SetReplace[1, 1 -> 2],
	SetReplace[1, 1 -> 2],
	{SetReplace::setNotList}
]

VerificationTest[
	SetReplace[1, 1 -> 2, Method -> "LowLevel"],
	SetReplace[1, 1 -> 2, Method -> "LowLevel"],
	{SetReplace::setNotList}
]

(** Rules are valid **)

VerificationTest[
	SetReplace[{1}, 1],
	SetReplace[{1}, 1],
	{SetReplace::invalidRules}
]

VerificationTest[
	SetReplace[{1}, 1, Method -> "LowLevel"],
	SetReplace[{1}, 1, Method -> "LowLevel"],
	{SetReplace::invalidRules}
]

VerificationTest[
	SetReplace[{1}, {1}],
	SetReplace[{1}, {1}],
	{SetReplace::invalidRules}
]

(** Step count is valid **)

VerificationTest[
	SetReplace[{1}, {1 -> 2}, -1],
	SetReplace[{1}, {1 -> 2}, -1],
	{SetReplace::nonIntegerIterations}
]

VerificationTest[
	SetReplace[{1}, {1 -> 2}, -1, Method -> "LowLevel"],
	SetReplace[{1}, {1 -> 2}, -1, Method -> "LowLevel"],
	{SetReplace::nonIntegerIterations}
]

VerificationTest[
	SetReplace[{1}, {1 -> 2}, 1.5],
	SetReplace[{1}, {1 -> 2}, 1.5],
	{SetReplace::nonIntegerIterations}
]

(** Method is valid **)

VerificationTest[
	SetReplace[{{0}}, {{0}} -> {{1}}, Method -> StringJoin[ToString /@ $SetReplaceMethods]],
	SetReplace[{{0}}, {{0}} -> {{1}}, Method -> StringJoin[ToString /@ $SetReplaceMethods]],
	{SetReplace::invalidMethod}
]

(* Implementation *)

(** Simple examples **)

VerificationTest[
	SetReplace[{}, {} :> {}],
	{}
]

VerificationTest[
	SetReplace[{1, 2, 3}, 2 -> 5],
	{1, 3, 5}
]

VerificationTest[
	SetReplace[{1, 2, 3}, 2 :> 5],
	{1, 3, 5}
]

VerificationTest[
	SetReplace[{1, 2, 3}, {2 :> 5, 3 :> 6}, 2],
	{1, 5, 6}
]

VerificationTest[
	SetReplace[{1, 2, 3}, {2 -> 5, 3 :> 6}, 2],
	{1, 5, 6}
]

VerificationTest[
	SetReplace[{1, 2, 3}, {2 -> 5, 3 :> 6}, 10],
	{1, 5, 6}
]

VerificationTest[
	SetReplace[{1, 2, 3}, {3, 2} -> 5],
	{1, 5}
]

VerificationTest[
	SetReplace[{1, 2, 3}, 4 -> 5],
	{1, 2, 3}
]

VerificationTest[
	SetReplace[{{1}}, {{1}} :> {}],
	{}
]

VerificationTest[
	SetReplace[{{1}}, {{1}} :> {}, Method -> "LowLevel"],
	{}
]

VerificationTest[
	SetReplace[{{1}}, {{1}} :> {}, Method -> "Symbolic"],
	{}
]

VerificationTest[
	SetReplace[{{1}}, {{1}} :> {}, Method -> Automatic],
	{}
]

VerificationTest[
	SetReplace[{{1}, {2}}, {{1}, {2}} :> {{3}}],
	{{3}}
]

VerificationTest[
	SetReplace[{{2}, {1}}, {{1}, {2}} :> {{3}}],
	{{3}}
]

VerificationTest[
	Module[{extraEdge},
 		extraEdge =
 			SetReplace[{{0, 1}}, {{a_, b_}} :> Module[{$0}, {{a, $0}, {$0, b}}]];
 		SetReplace[extraEdge, {{a_, b_}, {b_, c_}} :> {{a, c}}]
 	],
	{{0, 1}}
]

VerificationTest[
	SetReplace[{0}, 0 :> Module[{v}, v]],
	{Unique[]},
	SameTest -> (Dimensions[#1] == Dimensions[#2] &)
]

VerificationTest[
	SetReplace[{{2, 2}, 1}, ToPatternRules[{{{3, 3}, 1} -> {3, 1, 3}}]],
	{2, 1, 2}
]

VerificationTest[
	SetReplace[{{{2, 2}, 1}}, ToPatternRules[{{{3, 3}, 1} -> {3, 1, 3}}]],
	{{{2, 2}, 1}}
]

(*** infinite number of steps is supported ***)
VerificationTest[
	SetReplace[{{1, 2}, {2, 3}}, {{a_, b_}, {b_, c_}} :> {{a, c}}, Infinity, Method -> "LowLevel"],
	{{1, 3}}
]

(** Examples not supported by LowLevel implementation **)

(*** not a hypergraph ***)
VerificationTest[
	SetReplace[{1}, {1 -> 2}, Method -> "LowLevel"],
	SetReplace[{1}, {1 -> 2}, Method -> "LowLevel"],
	{SetReplace::lowLevelNotImplemented}
]

(*** rule is not local ***)
VerificationTest[
	SetReplace[{{1, 2}, {3, 4}}, {{1, 2}, {3, 4}} -> {{1, 3}, {2, 4}}, Method -> "LowLevel"],
	SetReplace[{{1, 2}, {3, 4}}, {{1, 2}, {3, 4}} -> {{1, 3}, {2, 4}}, Method -> "LowLevel"],
	{SetReplace::lowLevelNotImplemented}
]

(*** nothing -> something ***)
VerificationTest[
	SetReplace[{{1, 2}, {3, 4}}, {} -> {{1, 3}, {2, 4}}, Method -> "LowLevel"],
	SetReplace[{{1, 2}, {3, 4}}, {} -> {{1, 3}, {2, 4}}, Method -> "LowLevel"],
	{SetReplace::lowLevelNotImplemented}
]

EndTestSection[]
