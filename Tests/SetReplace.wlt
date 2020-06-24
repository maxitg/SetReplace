<|
	"SetReplace" -> <|
		"init" -> (
			Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];
		),
		"tests" -> {
			(* Symbol Leak *)

			testSymbolLeak[
				SetReplace[Range[10], {a_, b_} :> {a + b, a - b, a b}, 1000]
			],

			(* Argument checks *)

			(** Argument count **)

			testUnevaluated[
				SetReplace[],
				{SetReplace::argt}
			],

			testUnevaluated[
				SetReplace[Method -> "LowLevel"],
				{SetReplace::argt}
			],

			(** Set is a list **)

			testUnevaluated[
				SetReplace[1, 1 -> 2],
				{SetReplace::setNotList}
			],

			testUnevaluated[
				SetReplace[1, 1 -> 2, Method -> "LowLevel"],
				{SetReplace::setNotList}
			],

			(** Rules are valid **)

			testUnevaluated[
				SetReplace[{1}, 1],
				{SetReplace::invalidRules}
			],

			testUnevaluated[
				SetReplace[{1}, 1, Method -> "LowLevel"],
				{SetReplace::invalidRules}
			],

			testUnevaluated[
				SetReplace[{1}, {1}],
				{SetReplace::invalidRules}
			],

			(** Step count is valid **)

			testUnevaluated[
				SetReplace[{1}, {1 -> 2}, -1],
				{SetReplace::nonIntegerIterations}
			],

			testUnevaluated[
				SetReplace[{1}, {1 -> 2}, -1, Method -> "LowLevel"],
				{SetReplace::nonIntegerIterations}
			],

			testUnevaluated[
				SetReplace[{1}, {1 -> 2}, 1.5],
				{SetReplace::nonIntegerIterations}
			],

			(** Options are valid **)

			testUnevaluated[
				SetReplace[{{0}}, {{0}} -> {{1}}, # -> 123],
				{SetReplace::optx}
			] & /@ {"$$$InvalidOption###", "EventSelectionFunction"},

			(** Method is valid **)

			testUnevaluated[
				SetReplace[{{0}}, {{0}} -> {{1}}, Method -> "$$$InvalidMethod###"],
				{SetReplace::invalidMethod}
			],

			(** TimeConstraint is valid **)

			With[{rule = ToPatternRules[{{1, 2}} -> {{1, 3}, {3, 2}}]}, testUnevaluated[
			  SetReplace[{{0, 0}}, rule, 100, TimeConstraint -> #],
			  {SetReplace::timc}
			] & /@ {0, -1, "x"}],

			(* Implementation *)

			(** Simple examples **)

			VerificationTest[
				SetReplace[{}, {} :> {}],
				{}
			],

			VerificationTest[
				SetReplace[{1, 2, 3}, 2 -> 5],
				{1, 3, 5}
			],

			VerificationTest[
				SetReplace[{1, 2, 3}, 2 :> 5],
				{1, 3, 5}
			],

			VerificationTest[
				SetReplace[{1, 2, 3}, {2 :> 5, 3 :> 6}, 2],
				{1, 5, 6}
			],

			VerificationTest[
				SetReplace[{1, 2, 3}, {2 -> 5, 3 :> 6}, 2],
				{1, 5, 6}
			],

			VerificationTest[
				SetReplace[{1, 2, 3}, {2 -> 5, 3 :> 6}, 10],
				{1, 5, 6}
			],

			VerificationTest[
				SetReplace[{1, 2, 3}, {3, 2} -> 5],
				{1, 5}
			],

			VerificationTest[
				SetReplace[{1, 2, 3}, 4 -> 5],
				{1, 2, 3}
			],

			VerificationTest[
				SetReplace[{{1}}, {{1}} :> {}],
				{}
			],

			VerificationTest[
				SetReplace[{{1}}, {{1}} :> {}, Method -> "LowLevel"],
				{}
			],

			VerificationTest[
				SetReplace[{{1}}, {{1}} :> {}, Method -> "Symbolic"],
				{}
			],

			VerificationTest[
				SetReplace[{{1}}, {{1}} :> {}, Method -> Automatic],
				{}
			],

			VerificationTest[
				SetReplace[{{1}, {2}}, {{1}, {2}} :> {{3}}],
				{{3}}
			],

			VerificationTest[
				SetReplace[{{2}, {1}}, {{1}, {2}} :> {{3}}],
				{{3}}
			],

			VerificationTest[
				Module[{extraEdge},
			 		extraEdge =
			 			SetReplace[{{0, 1}}, {{a_, b_}} :> Module[{$0}, {{a, $0}, {$0, b}}]];
			 		SetReplace[extraEdge, {{a_, b_}, {b_, c_}} :> {{a, c}}]
			 	],
				{{0, 1}}
			],

			VerificationTest[
				SetReplace[{0}, 0 :> Module[{v}, v]],
				{Unique[]},
				SameTest -> (Dimensions[#1] == Dimensions[#2] &)
			],

			VerificationTest[
				SetReplace[{{2, 2}, 1}, ToPatternRules[{{{3, 3}, 1} -> {3, 1, 3}}]],
				{2, 1, 2}
			],

			VerificationTest[
				SetReplace[{{{2, 2}, 1}}, ToPatternRules[{{{3, 3}, 1} -> {3, 1, 3}}]],
				{{{2, 2}, 1}}
			],

			(*** infinite number of steps is supported ***)
			VerificationTest[
				SetReplace[{{1, 2}, {2, 3}}, {{a_, b_}, {b_, c_}} :> {{a, c}}, Infinity, Method -> "LowLevel"],
				{{1, 3}}
			],

			(** Examples not supported by LowLevel implementation **)

			(*** not a hypergraph ***)
			testUnevaluated[
				SetReplace[{1}, {1 -> 2}, Method -> "LowLevel"],
				{SetReplace::lowLevelNotImplemented}
			],

			(*** rule is not local ***)
			testUnevaluated[
				SetReplace[{{1, 2}, {3, 4}}, {{1, 2}, {3, 4}} -> {{1, 3}, {2, 4}}, Method -> "LowLevel"],
				{SetReplace::lowLevelNotImplemented}
			],

			(*** nothing -> something ***)
			testUnevaluated[
				SetReplace[{{1, 2}, {3, 4}}, {} -> {{1, 3}, {2, 4}}, Method -> "LowLevel"],
				{SetReplace::lowLevelNotImplemented}
			],

			(* TimeConstraint *)

			VerificationTest[
				SetReplace[{{0, 0}}, ToPatternRules[{{1, 2}} -> {{1, 3}, {3, 2}}], 100000, Method -> #, TimeConstraint -> 0.1],
				$Aborted
			] & /@ $SetReplaceMethods,

			VerificationTest[
				TimeConstrained[SetReplace[{{0, 0}}, ToPatternRules[{{1, 2}} -> {{1, 3}, {3, 2}}], 100000, Method -> #], 0.1],
				$Aborted
			] & /@ $SetReplaceMethods
		}
	|>
|>
