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

(*** infinite number of steps not supported ***)
VerificationTest[
	SetReplace[{{1, 2}, {2, 3}}, {{a_, b_}, {b_, c_}} :> {{a, c}}, Infinity, Method -> "C++"],
	SetReplace[{{1, 2}, {2, 3}}, {{a_, b_}, {b_, c_}} :> {{a, c}}, Infinity, Method -> "C++"],
	{SetReplace::cppInfinite}
]

(** C++ / WL implementation consistancy **)

$sameSetQ[x_, y_] := Module[{xAtoms, yAtoms},
	{xAtoms, yAtoms} = DeleteDuplicates[Flatten[#]] & /@ {x, y};
	If[Length[xAtoms] != Length[yAtoms], Return[False]];
	(x /. Thread[xAtoms -> yAtoms]) === y
]

$systemsToTest = {
	{{{0, 1}}, FromAnonymousRules[{{0, 1}} -> {{0, 2}, {2, 1}}], 100},
	{{{1}}, FromAnonymousRules[{{{1}} -> {{1}}}], 100},
	{{{1}}, FromAnonymousRules[{{{1}} -> {{2}}}], 100},
	{{{1}}, FromAnonymousRules[{{{1}} -> {{2}, {1, 2}}}], 100},
	{{{1}}, FromAnonymousRules[{{{1}} -> {{1}, {2}, {1, 1}}}], 100},
	{{{1}}, FromAnonymousRules[{{{1}} -> {{1}, {2}, {1, 2}}}], 100},
	{{{1}}, FromAnonymousRules[{{{1}} -> {{1}, {2}, {1, 3}}}], 100},
	{{{1}}, FromAnonymousRules[{{{1}} -> {{2}, {2}, {1, 2}}}], 100},
	{{{1}}, FromAnonymousRules[{{{1}} -> {{2}, {3}, {1, 2}}}], 100},
	{{{1}}, FromAnonymousRules[{{{1}} -> {{2}, {3}, {1, 2, 4}}}], 100},
	{{{1}}, FromAnonymousRules[{{{1}} -> {{2}, {2}, {2}, {1, 2}}}], 100},
	{{{1}, {1}, {1}}, FromAnonymousRules[{{{1}} -> {{2}, {1, 2}}}], 100},
	{{{1, 1}}, FromAnonymousRules[{{{1, 2}} -> {{1, 3}, {2, 3}}}], 100},
	{{{0, 1}, {0, 2}, {0, 3}},
		{{{a_, b_}, {a_, c_}, {a_, d_}} :>
			Module[{$0, $1, $2}, {
				{$0, $1}, {$1, $2}, {$2, $0}, {$0, $2}, {$2, $1}, {$1, $0},
				{$0, b}, {$1, c}, {$2, d}}]},
		30},
  {{{0, 0}, {0, 0}, {0, 0}},
		{{{a_, b_}, {a_, c_}, {a_, d_}} :>
			Module[{$0, $1, $2}, {
				{$0, $1}, {$1, $2}, {$2, $0}, {$0, $2}, {$2, $1}, {$1, $0},
				{$0, b}, {$1, c}, {$2, d}}]},
		30},
	{{{0, 1}, {0, 2}, {0, 3}},
		{{{a_, b_}, {a_, c_}, {a_, d_}} :>
			Module[{$0, $1, $2}, {
				{$0, $1}, {$1, $2}, {$2, $0}, {$0, $2}, {$2, $1}, {$1, $0},
				{$0, b}, {$1, c}, {$2, d}, {b, $2}, {d, $0}}]},
		30},
  {{{0, 0}, {0, 0}, {0, 0}},
		{{{a_, b_}, {a_, c_}, {a_, d_}} :>
			Module[{$0, $1, $2}, {
				{$0, $1}, {$1, $2}, {$2, $0}, {$0, $2}, {$2, $1}, {$1, $0},
				{$0, b}, {$1, c}, {$2, d}, {b, $2}, {d, $0}}]},
		30}
};

VerificationTest[
	SetReplace[##, Method -> "WolframLanguage"],
	SetReplace[##, Method -> "C++"],
	SameTest -> $sameSetQ
] & @@@ $systemsToTest

(** C++ performance **)

VerificationTest[
	SetReplace[
		{{0, 0}, {0, 0}, {0, 0}},
		{{{a_, b_}, {a_, c_}, {a_, d_}} :>
			Module[{$0, $1, $2}, {
				{$0, $1}, {$1, $2}, {$2, $0}, {$0, $2}, {$2, $1}, {$1, $0},
				{$0, b}, {$1, c}, {$2, d}, {b, $2}, {d, $0}}]},
		1000],
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
	0.8 < Timing[TimeConstrained[SetReplace[
			{{0}},
  		FromAnonymousRules[{{{0}} -> {{0}, {0}, {0}}, {{0}, {0}, {0}} -> {{0}}}],
  		30], 1]][[1]] < 1.2
]

(** Complex matching **)

graphsForMatching = {
	{{1, 2}, {2, 3}, {3, 4}, {4, 5}},
	{{1, 2}, {2, 3}, {3, 4}, {4, 1}},
	{{1, 2}, {2, 3}, {3, 4}, {1, 5}},
	{{2, 3}, {3, 1}, {4, 2}, {4, 5}},
	{{1, 5}, {2, 1}, {2, 3}, {2, 4}, {2, 5}, {3, 1}, {4, 2}, {4, 5}}
};
methods = {"C++", "WolframLanguage"};

Table[VerificationTest[
	SetReplace[
		graph,
		FromAnonymousRules[graph -> {}],
		1,
		Method -> method],
	{}
], {graph, graphsForMatching}, {method, methods}]

VerificationTest[
	SetReplace[
		{{1, 2}, {2, 3, 4}},
		FromAnonymousRules[{{2, 3, 4}, {1, 2}} -> {}],
		1,
		Method -> #],
	{}
] & /@ methods

VerificationTest[
	SetReplace[
		{{1, 2}, {2, 2, 3}},
		FromAnonymousRules[{{2, 3, 4}, {1, 2}} -> {}],
		1,
		Method -> #],
	{}
] & /@ methods

VerificationTest[
	SetReplace[
		{{1, 2}, {2, 1, 3}},
		FromAnonymousRules[{{2, 3, 4}, {1, 2}} -> {}],
		1,
		Method -> #],
	{}
] & /@ methods

VerificationTest[
	SetReplace[
		{{1, 2}, {1, 1, 3}},
		FromAnonymousRules[{{2, 3, 4}, {1, 2}} -> {}],
		1,
		Method -> #],
	{{1, 2}, {1, 1, 3}}
] & /@ methods

VerificationTest[
	SetReplace[
		{{1, 2}, {2, 1}},
		FromAnonymousRules[{{1, 2}, {2, 3}} -> {{1, 3}}],
		1,
		Method -> #],
	{{1, 1}}
] & /@ methods

(** Random tests **)

graphFromHyperedges[edges_] := Graph[
	UndirectedEdge @@@ Flatten[Partition[#, 2, 1] & /@ edges, 1]];

randomConnectedGraphs[edgeCount_, edgeLength_, graphCount_] := (
	Select[ConnectedGraphQ @* graphFromHyperedges]
		@ Table[
			With[{k = edgeCount}, Table[RandomInteger[edgeLength k], k, edgeLength]],
			graphCount]
)

DistributeDefinitions["SetReplace`"];

(* Here we generate random graphs and try replacing them to nothing *)
randomSameGraphMatchTest[edgeCount_, edgeLength_, graphCount_, method_] := BlockRandom[Module[{
		tests},
	tests = randomConnectedGraphs[edgeCount, edgeLength, graphCount];
	Union[
		ParallelMap[
				SetReplace[#, FromAnonymousRules[RandomSample[#] -> {}], Method -> method] &,
				tests]]
			=== {{}}
]]

VerificationTest[
	randomSameGraphMatchTest[10, 2, 10000, "C++"],
	True
]

VerificationTest[
	randomSameGraphMatchTest[10, 3, 5000, "C++"],
	True
]

VerificationTest[
	randomSameGraphMatchTest[10, 6, 1000, "C++"],
	True
]

VerificationTest[
	randomSameGraphMatchTest[6, 2, 5000, "WolframLanguage"],
	True
]

VerificationTest[
	randomSameGraphMatchTest[6, 3, 500, "WolframLanguage"],
	True
]

VerificationTest[
	randomSameGraphMatchTest[6, 10, 100, "WolframLanguage"],
	True
]

(* Here we generate pairs of different graphs, and check they are not being matched *)
randomDistinctGraphMatchTest[
			edgeCount_, edgeLength_, graphCount_, method_] := BlockRandom[Module[{
		tests},
	tests = Select[!IsomorphicGraphQ @@ (graphFromHyperedges /@ #) &]
		@ Partition[
			Select[SimpleGraphQ @* graphFromHyperedges]
				@ randomConnectedGraphs[edgeCount, edgeLength, graphCount],
			2];
	Not[Or @@ ParallelMap[
		(* degenerate graphs can still match if not isomorphic, i.e., {{0, 0}} will match {{0, 1}},
			 that's why we need to try replacing both ways *)
		SetReplace[#[[1]], FromAnonymousRules[#[[2]] -> {}], Method -> method] == {}
			&& SetReplace[#[[2]], FromAnonymousRules[#[[1]] -> {}], Method -> method] == {} &,
		tests]]
]]

VerificationTest[
	randomDistinctGraphMatchTest[10, 2, 10000, "C++"],
	True
]

VerificationTest[
	randomDistinctGraphMatchTest[10, 3, 10000, "C++"],
	True
]

VerificationTest[
	randomDistinctGraphMatchTest[10, 6, 10000, "C++"],
	True
]

VerificationTest[
	randomDistinctGraphMatchTest[6, 2, 5000, "WolframLanguage"],
	True
]

VerificationTest[
	randomDistinctGraphMatchTest[6, 3, 5000, "WolframLanguage"],
	True
]

VerificationTest[
	randomDistinctGraphMatchTest[6, 6, 5000, "WolframLanguage"],
	True
]

(* Here we make initial condition degenerate, and check it still matches, i.e.,
	 {{0, 0}} should still match {{0, 1}} *)
randomDegenerateGraphMatchTest[
			edgeCount_, edgeLength_, graphCount_, method_] := BlockRandom[Module[{
		tests},
	tests = randomConnectedGraphs[edgeCount, edgeLength, graphCount];
Union[
	ParallelMap[
			SetReplace[
				# /. RandomChoice[Flatten[#]] -> RandomChoice[Flatten[#]],
				FromAnonymousRules[RandomSample[#] -> {}],
				Method -> method] &,
			tests]]
		=== {{}}
]]

VerificationTest[
	randomDegenerateGraphMatchTest[10, 2, 10000, "C++"],
	True
]

VerificationTest[
	randomDegenerateGraphMatchTest[10, 3, 5000, "C++"],
	True
]

VerificationTest[
	randomDegenerateGraphMatchTest[10, 6, 1000, "C++"],
	True
]

VerificationTest[
	randomDegenerateGraphMatchTest[6, 2, 5000, "WolframLanguage"],
	True
]

VerificationTest[
	randomDegenerateGraphMatchTest[6, 3, 500, "WolframLanguage"],
	True
]

VerificationTest[
	randomDegenerateGraphMatchTest[6, 10, 100, "WolframLanguage"],
	True
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
