BeginTestSection["SetReplace"]

(* Argument checks *)

(** Argument count **)

VerificationTest[
	SetReplace[],
	SetReplace[],
	{SetReplace::argt}
]

VerificationTest[
	SetReplace[Method -> "C++"],
	SetReplace[Method -> "C++"],
	{SetReplace::argt}
]

(** Set is a list **)

VerificationTest[
	SetReplace[1, 1 -> 2],
	SetReplace[1, 1 -> 2],
	{SetReplace::setNotList}
]

VerificationTest[
	SetReplace[1, 1 -> 2, Method -> "C++"],
	SetReplace[1, 1 -> 2, Method -> "C++"],
	{SetReplace::setNotList}
]

(** Rules are valid **)

VerificationTest[
	SetReplace[{1}, 1],
	SetReplace[{1}, 1],
	{SetReplace::invalidRules}
]

VerificationTest[
	SetReplace[{1}, 1, Method -> "C++"],
	SetReplace[{1}, 1, Method -> "C++"],
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
	SetReplace[{1}, {1 -> 2}, -1, Method -> "C++"],
	SetReplace[{1}, {1 -> 2}, -1, Method -> "C++"],
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
	SetReplace[{{1}}, {{1}} :> {}, Method -> "C++"],
	{}
]

VerificationTest[
	SetReplace[{{1}}, {{1}} :> {}, Method -> "WolframLanguage"],
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
	SetReplace[{{1, 2}, {2, 3}}, {{a_, b_}, {b_, c_}} :> {{a, c}}, Infinity, Method -> "C++"],
	{{1, 3}}
]

(** Examples not supported by C++ implementation **)

(*** not a hypergraph ***)
VerificationTest[
	SetReplace[{1}, {1 -> 2}, Method -> "C++"],
	SetReplace[{1}, {1 -> 2}, Method -> "C++"],
	{SetReplace::cppNotImplemented}
]

(*** rule is not local ***)
VerificationTest[
	SetReplace[{{1, 2}, {3, 4}}, {{1, 2}, {3, 4}} -> {{1, 3}, {2, 4}}, Method -> "C++"],
	SetReplace[{{1, 2}, {3, 4}}, {{1, 2}, {3, 4}} -> {{1, 3}, {2, 4}}, Method -> "C++"],
	{SetReplace::cppNotImplemented}
]

(*** nothing -> something ***)
VerificationTest[
	SetReplace[{{1, 2}, {3, 4}}, {} -> {{1, 3}, {2, 4}}, Method -> "C++"],
	SetReplace[{{1, 2}, {3, 4}}, {} -> {{1, 3}, {2, 4}}, Method -> "C++"],
	{SetReplace::cppNotImplemented}
]

EndTestSection[]
