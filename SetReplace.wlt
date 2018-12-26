BeginTestSection["SetReplace"]

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

EndTestSection[]
