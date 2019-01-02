BeginTestSection["SetReplace"]

(* SetReplace *)

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
	SetReplace[],
	SetReplace[],
	{SetReplace::argt}
]

VerificationTest[
	SetReplace[1, 1 -> 2],
	SetReplace[1, 1 -> 2],
	{SetReplace::setNotList}
]

VerificationTest[
	SetReplace[{1}, 1],
	SetReplace[{1}, 1],
	{SetReplace::invalidRules}
]

VerificationTest[
	SetReplace[{1}, {1}],
	SetReplace[{1}, {1}],
	{SetReplace::invalidRules}
]

VerificationTest[
	SetReplace[{1}, {1 -> 2}, -1],
	SetReplace[{1}, {1 -> 2}, -1],
	{SetReplace::nonIntegerIterations}
]

VerificationTest[
	SetReplace[{1}, {1 -> 2}, 1.5],
	SetReplace[{1}, {1 -> 2}, 1.5],
	{SetReplace::nonIntegerIterations}
]

(* SetReplaceList *)

VerificationTest[
	SetReplaceList[{1, 2, 3}, {2 -> 5, 3 :> 6}, 10],
	{{1, 2, 3}, {1, 3, 5}, {1, 5, 6}, {1, 5, 6}}
]

VerificationTest[
	SetReplaceList[{1, 2, 3}, {2 -> 5, 3 :> 6}, 1],
	{{1, 2, 3}, {1, 3, 5}}
]

VerificationTest[
	SetReplaceList[{1}],
	SetReplaceList[{1}],
	{SetReplaceList::argr}
]

VerificationTest[
	SetReplaceList[1, 1 -> 2, 2],
	SetReplaceList[1, 1 -> 2, 2],
	{SetReplace::setNotList}
]

VerificationTest[
	SetReplaceList[{1}, {1}, 1],
	SetReplaceList[{1}, {1}, 1],
	{SetReplace::invalidRules}
]

VerificationTest[
	SetReplaceList[{1}, {1 -> 2}, -1],
	SetReplaceList[{1}, {1 -> 2}, -1],
	{SetReplace::nonIntegerIterations}
]

(* SetReplaceFixedPoint *)

VerificationTest[
	SetReplaceFixedPoint[{1, 1, 1}, {1 -> 2}],
	{2, 2, 2}
]

VerificationTest[
	SetReplaceFixedPoint[{0.5}, {n_ :> 1 - n}],
	{0.5}
]

VerificationTest[
	SetReplaceFixedPoint[{1}],
	SetReplaceFixedPoint[{1}],
	{SetReplaceFixedPoint::argr}
]

VerificationTest[
	SetReplaceFixedPoint[1, 1 -> 2],
	SetReplaceFixedPoint[1, 1 -> 2],
	{SetReplace::setNotList}
]

VerificationTest[
	SetReplaceFixedPoint[{1}, {1}],
	SetReplaceFixedPoint[{1}, {1}],
	{SetReplace::invalidRules}
]

(* SetReplaceFixedPointList *)

VerificationTest[
	SetReplaceFixedPointList[{1, 1, 1}, {1 -> 2}],
	{{1, 1, 1}, {1, 1, 2}, {1, 2, 2}, {2, 2, 2}, {2, 2, 2}}
]

VerificationTest[
	SetReplaceFixedPointList[{0.5}, {n_ :> 1 - n}],
	{{0.5}, {0.5}}
]

VerificationTest[
	SetReplaceFixedPointList[{1}],
	SetReplaceFixedPointList[{1}],
	{SetReplaceFixedPointList::argr}
]

VerificationTest[
	SetReplaceFixedPointList[1, 1 -> 2],
	SetReplaceFixedPointList[1, 1 -> 2],
	{SetReplace::setNotList}
]

VerificationTest[
	SetReplaceFixedPointList[{1}, {1}],
	SetReplaceFixedPointList[{1}, {1}],
	{SetReplace::invalidRules}
]

(* HypergraphPlot *)

VerificationTest[
	HypergraphPlot[],
	HypergraphPlot[],
	{HypergraphPlot::argx}
]

VerificationTest[
	HypergraphPlot[{{1, 2}}, {{1, 2}}],
	HypergraphPlot[{{1, 2}}, {{1, 2}}],
	{HypergraphPlot::argx}
]

VerificationTest[
	HypergraphPlot[1],
	HypergraphPlot[1],
	{HypergraphPlot::invalidEdges}
]

VerificationTest[
	HypergraphPlot[{1, 2}],
	HypergraphPlot[{1, 2}],
	{HypergraphPlot::invalidEdges}
]

VerificationTest[
	HypergraphPlot[{{1, 3}, 2}],
	HypergraphPlot[{{1, 3}, 2}],
	{HypergraphPlot::invalidEdges}
]

VerificationTest[
	GraphQ[HypergraphPlot[{{1, 3}, {2, 4}}]]
]

VerificationTest[
	GraphQ[HypergraphPlot[{{1, 3}, 6, {2, 4}}]],
	False,
	{HypergraphPlot::invalidEdges}
]

(* FromAnonymousRules *)

VerificationTest[
	FromAnonymousRules[],
	FromAnonymousRules[],
	{FromAnonymousRules::argx}
]

VerificationTest[
	FromAnonymousRules[1, 2],
	FromAnonymousRules[1, 2],
	{FromAnonymousRules::argx}
]

VerificationTest[
	FromAnonymousRules[1],
	FromAnonymousRules[1],
	{FromAnonymousRules::notRules}
]

VerificationTest[
	SetReplace[{{"v1", "v2"}}, FromAnonymousRules[{{1, 2}} -> {{1}}]],
	{{"v1"}}
]

VerificationTest[
	SetReplace[
		{{"v1", "v2"}, {"v2", "v3"}},
		FromAnonymousRules[{{1, 2}, {2, 3}} -> {{1, 3}}]],
	{{"v1", "v3"}}
]

VerificationTest[
	SetReplace[
		{{"v1", "v2"}, {"v2", "v3"}},
		FromAnonymousRules[{
			{{1, 2}, {2, 3}} -> {{1, 3}},
			{{1, 2}} -> {{1, 1, 2, 2}}}], 2],
	{{"v1", "v1", "v3", "v3"}}
]

VerificationTest[
	SetReplace[
		SetReplace[{{"v1", "v2"}}, FromAnonymousRules[{{1, 2}} -> {{1, 2, 3}}]],
		{{"v1", "v2", z_}} :> {{"v1", "v2"}}],
	{{"v1", "v2"}}
]

VerificationTest[
	SetReplace[
		SetReplace[{{"v1", "v2"}}, FromAnonymousRules[{{1, 2}} -> {{1, 2, 3}}]],
		{{"v1", "v2", z_}} :> {{"v1", "v2"}}],
	{{"v1", "v2"}}
]

VerificationTest[
	Module[{v1 = v2 = v3 = v4 = v5 = 1},
		SetReplace[{z + z^z, y + y^y}, FromAnonymousRules[x + x^x -> x]]
	],
	{y + y^y, z}
]

VerificationTest[
	FromAnonymousRules[{{} -> {}}],
	{{} :> {}}
]

VerificationTest[
	SetReplace[{{1, 2}, {2, 3}}, FromAnonymousRules[{{} -> {}}], 3],
	{{1, 2}, {2, 3}}
]

VerificationTest[
	SetReplace[
		{{10 -> 30} -> 20, {30, 40}},
		FromAnonymousRules[{{1 -> 3} -> 2, {3, 4}} -> {{1, 2, 3}, {3, 4, 5}}]][[1]],
	{10, 20, 30}
]

VerificationTest[
	SetReplace[{{{2, 2}, 1}},
		FromAnonymousRules[{
			{{Graph[{3 -> 4}], Graph[{3 -> 4}]}, Graph[{1 -> 2}]} ->
			{Graph[{3 -> 4}], Graph[{1 -> 2}], Graph[{3 -> 4}]}}]],
	{{2, 1, 2}}
]

(* SetReplaceAll *)

VerificationTest[
	SetReplaceAll[],
	SetReplaceAll[],
	{SetReplaceAll::argt}
]

VerificationTest[
	SetReplaceAll[1, 1 -> 2],
	SetReplaceAll[1, 1 -> 2],
	{SetReplace::setNotList}
]

VerificationTest[
	SetReplaceAll[{1}, 1],
	SetReplaceAll[{1}, 1],
	{SetReplace::invalidRules}
]

VerificationTest[
	SetReplaceAll[{1}, {1}],
	SetReplaceAll[{1}, {1}],
	{SetReplace::invalidRules}
]

VerificationTest[
	SetReplaceAll[{1}, {1 -> 2}, -1],
	SetReplaceAll[{1}, {1 -> 2}, -1],
	{SetReplace::nonIntegerIterations}
]

VerificationTest[
	SetReplaceAll[{1}, {1 -> 2}, 1.5],
	SetReplaceAll[{1}, {1 -> 2}, 1.5],
	{SetReplace::nonIntegerIterations}
]

VerificationTest[	
	SetReplaceAll[{1, 2, 3}, n_ :> -n],
	{-1, -2, -3}
]

VerificationTest[
	SetReplaceAll[{1, 2, 3}, n_ :> -n, 2],
	{1, 2, 3}
]

VerificationTest[
	SetReplaceAll[{1, 2, 3}, {n_, m_} :> {-m, -n}],
	{3, -2, -1}
]

VerificationTest[
	SetReplaceAll[{1, 2, 3}, {n_, m_} :> {-m, -n}, 2],
	{-1, 2, -3}
]

VerificationTest[
	Most @ SetReplaceAll[
			{1, 2, 3, 4}, {2 -> {3, 4}, {v1_, v2_} :> Module[{x}, {v1, v2, x}]}],
	{4, 3, 4, 1, 3}
]

VerificationTest[
	MatchQ[SetReplaceAll[
			{1, 2, 3, 4},
			{2 -> {3, 4}, {v1_, v2_} :> Module[{x}, {v1, v2, x}]},
			2], {4, 3, _, 4, 1, _, 3, _, _}],
	True
]

VerificationTest[
	Length @ SetReplaceAll[
		{{0, 1}, {0, 2}, {0, 3}}, 
		FromAnonymousRules[
			{{0, 1}, {0, 2}, {0, 3}} ->
			{{4, 5}, {5, 4}, {4, 6}, {6, 4}, {5, 6}, {6, 5}, {4, 1}, {5, 2}, {6, 3}}],
		4],
	3^5
]

VerificationTest[
	Length @ SetReplaceAll[
		{{0, 0}, {0, 0}, {0, 0}}, 
		FromAnonymousRules[
			{{0, 1}, {0, 2}, {0, 3}} ->
			{{4, 5}, {5, 4}, {4, 6}, {6, 4}, {5, 6}, {6, 5}, {4, 1}, {5, 2}, {6, 3}}],
		4],
	3^5
]

VerificationTest[
	Length @ SetReplaceAll[
		{{0, 1}, {0, 2}, {0, 3}}, 
		FromAnonymousRules[
			{{0, 1}, {0, 2}, {0, 3}} ->
			{{4, 5}, {5, 4}, {4, 6}, {6, 4}, {5, 6}, {6, 5},
			 {4, 1}, {5, 2}, {6, 3}, {1, 6}, {3, 4}}],
		3],
	107
]

EndTestSection[]
