BeginTestSection["correctness"]

(** C++ / WL implementation consistancy **)

$sameSetQ[x_, y_] := Module[{xAtoms, yAtoms},
  {xAtoms, yAtoms} = DeleteDuplicates[Flatten[#]] & /@ {x, y};
  If[Length[xAtoms] != Length[yAtoms], Return[False]];
  (x /. Thread[xAtoms -> yAtoms]) === y
]

$systemsToTest = {
  {{{0, 1}}, ToPatternRules[{{0, 1}} -> {{0, 2}, {2, 1}}], 100, 6},
  {{{1}}, ToPatternRules[{{{1}} -> {{1}}}], 100, 100},
  {{{1}}, ToPatternRules[{{{1}} -> {{2}}}], 100, 100},
  {{{1}}, ToPatternRules[{{{1}} -> {{2}, {1, 2}}}], 100, 6},
  {{{1}}, ToPatternRules[{{{1}} -> {{1}, {2}, {1, 1}}}], 100, 6},
  {{{1}}, ToPatternRules[{{{1}} -> {{1}, {2}, {1, 2}}}], 100, 6},
  {{{1}}, ToPatternRules[{{{1}} -> {{1}, {2}, {1, 3}}}], 100, 6},
  {{{1}}, ToPatternRules[{{{1}} -> {{2}, {2}, {1, 2}}}], 100, 6},
  {{{1}}, ToPatternRules[{{{1}} -> {{2}, {3}, {1, 2}}}], 100, 6},
  {{{1}}, ToPatternRules[{{{1}} -> {{2}, {3}, {1, 2, 4}}}], 100, 6},
  {{{1}}, ToPatternRules[{{{1}} -> {{2}, {2}, {2}, {1, 2}}}], 100, 4},
  {{{1}, {1}, {1}}, ToPatternRules[{{{1}} -> {{2}, {1, 2}}}], 100, 34},
  {{{1, 1}}, ToPatternRules[{{{1, 2}} -> {{1, 3}, {2, 3}}}], 100, 6},
  {{{0, 1}, {0, 2}, {0, 3}},
    {{{a_, b_}, {a_, c_}, {a_, d_}} :>
      Module[{$0, $1, $2}, {
        {$0, $1}, {$1, $2}, {$2, $0}, {$0, $2}, {$2, $1}, {$1, $0},
        {$0, b}, {$1, c}, {$2, d}}]},
    30,
    3},
  {{{0, 0}, {0, 0}, {0, 0}},
    {{{a_, b_}, {a_, c_}, {a_, d_}} :>
      Module[{$0, $1, $2}, {
        {$0, $1}, {$1, $2}, {$2, $0}, {$0, $2}, {$2, $1}, {$1, $0},
        {$0, b}, {$1, c}, {$2, d}}]},
    30,
    3},
  {{{0, 1}, {0, 2}, {0, 3}},
    {{{a_, b_}, {a_, c_}, {a_, d_}} :>
      Module[{$0, $1, $2}, {
        {$0, $1}, {$1, $2}, {$2, $0}, {$0, $2}, {$2, $1}, {$1, $0},
        {$0, b}, {$1, c}, {$2, d}, {b, $2}, {d, $0}}]},
    30,
    3},
  {{{0, 0}, {0, 0}, {0, 0}},
    {{{a_, b_}, {a_, c_}, {a_, d_}} :>
      Module[{$0, $1, $2}, {
        {$0, $1}, {$1, $2}, {$2, $0}, {$0, $2}, {$2, $1}, {$1, $0},
        {$0, b}, {$1, c}, {$2, d}, {b, $2}, {d, $0}}]},
    30,
    3}
};

(* Fixed number of events *)

VerificationTest[
  SetReplace[##, Method -> "Symbolic"],
  SetReplace[##, Method -> "LowLevel"],
  SameTest -> $sameSetQ
] & @@@ $systemsToTest[[All, {1, 2, 3}]]

(* Fixed number of generations *)

VerificationTest[
  SetReplaceAll[##, Method -> "Symbolic"],
  SetReplaceAll[##, Method -> "LowLevel"],
  SameTest -> $sameSetQ
] & @@@ $systemsToTest[[All, {1, 2, 4}]]

(* Causal graphs consistency *)

VerificationTest[
  WolframModel[<|"PatternRules" -> #1|>, #2, #3, "CausalGraph", Method -> "Symbolic"],
  WolframModel[<|"PatternRules" -> #1|>, #2, #3, "CausalGraph", Method -> "LowLevel"]
] & @@@ $systemsToTest[[All, {2, 1, 4}]]

(** Causal graphs properties check **)

VerificationTest[
  AcyclicGraphQ[WolframModel[<|"PatternRules" -> #1|>, #2, #3, "CausalGraph"]]
] & @@@ $systemsToTest[[All, {2, 1, 4}]]

VerificationTest[
  LoopFreeGraphQ[WolframModel[<|"PatternRules" -> #1|>, #2, #3, "CausalGraph"]]
] & @@@ $systemsToTest[[All, {2, 1, 4}]]

VerificationTest[
  VertexCount[WolframModel[<|"PatternRules" -> #1|>, #2, #3, "CausalGraph"]],
  WolframModel[<|"PatternRules" -> #1|>, #2, #3, "EventsCount"]
] & @@@ $systemsToTest[[All, {2, 1, 4}]]

(** Complex matching **)

graphsForMatching = {
  {{1, 2}, {2, 3}, {3, 4}, {4, 5}},
  {{1, 2}, {2, 3}, {3, 4}, {4, 1}},
  {{1, 2}, {2, 3}, {3, 4}, {1, 5}},
  {{2, 3}, {3, 1}, {4, 2}, {4, 5}},
  {{1, 5}, {2, 1}, {2, 3}, {2, 4}, {2, 5}, {3, 1}, {4, 2}, {4, 5}}
};
methods = {"LowLevel", "Symbolic"};

Table[VerificationTest[
  SetReplace[
    graph,
    ToPatternRules[graph -> {}],
    1,
    Method -> method],
  {}
], {graph, graphsForMatching}, {method, methods}]

VerificationTest[
  SetReplace[
    {{1, 2}, {2, 3, 4}},
    ToPatternRules[{{2, 3, 4}, {1, 2}} -> {}],
    1,
    Method -> #],
  {}
] & /@ methods

VerificationTest[
  SetReplace[
    {{1, 2}, {2, 2, 3}},
    ToPatternRules[{{2, 3, 4}, {1, 2}} -> {}],
    1,
    Method -> #],
  {}
] & /@ methods

VerificationTest[
  SetReplace[
    {{1, 2}, {2, 1, 3}},
    ToPatternRules[{{2, 3, 4}, {1, 2}} -> {}],
    1,
    Method -> #],
  {}
] & /@ methods

VerificationTest[
  SetReplace[
    {{1, 2}, {1, 1, 3}},
    ToPatternRules[{{2, 3, 4}, {1, 2}} -> {}],
    1,
    Method -> #],
  {{1, 2}, {1, 1, 3}}
] & /@ methods

VerificationTest[
  SetReplace[
    {{1, 2}, {2, 1}},
    ToPatternRules[{{1, 2}, {2, 3}} -> {{1, 3}}],
    1,
    Method -> #],
  {{1, 1}}
] & /@ methods

(** Random tests **)

graphFromHyperedges[edges_] := Graph[
  UndirectedEdge @@@ Flatten[Partition[#, 2, 1] & /@ edges, 1]];

randomConnectedGraphs[edgeCount_, edgeLength_, graphCount_] := (
  #[[All, 1]] & @ Select[#[[2]] &] @ ParallelMap[
    {#, ConnectedGraphQ @ graphFromHyperedges @ #} &,
    BlockRandom[
      Table[
        With[{k = edgeCount}, Table[RandomInteger[edgeLength k], k, edgeLength]],
        graphCount],
      RandomSeeding -> ToString[{"randomConnectedGraphs", edgeCount, edgeLength, graphCount}]]]
)

(* Here we generate random graphs and try replacing them to nothing *)
randomSameGraphMatchTest[edgeCount_, edgeLength_, graphCount_, method_] := Module[{
    tests},
  tests = randomConnectedGraphs[edgeCount, edgeLength, graphCount];
  Union[
    ParallelMap[
        SetReplace[#[[1]], ToPatternRules[#[[2]] -> {}], Method -> method] &,
        BlockRandom[
          {#, RandomSample[#]} & /@ tests,
          RandomSeeding -> ToString[{"randomSameGraphMatchTest", edgeCount, edgeLength, graphCount, method}]]]]
      === {{}}
]

VerificationTest[
  randomSameGraphMatchTest[10, 2, 10000, "LowLevel"],
  True
]

VerificationTest[
  randomSameGraphMatchTest[10, 3, 5000, "LowLevel"],
  True
]

VerificationTest[
  randomSameGraphMatchTest[10, 6, 1000, "LowLevel"],
  True
]

VerificationTest[
  randomSameGraphMatchTest[6, 2, 5000, "Symbolic"],
  True
]

VerificationTest[
  randomSameGraphMatchTest[6, 3, 500, "Symbolic"],
  True
]

VerificationTest[
  randomSameGraphMatchTest[6, 10, 100, "Symbolic"],
  True
]

(* Here we generate pairs of different graphs, and check they are not being matched *)
randomDistinctGraphMatchTest[
      edgeCount_, edgeLength_, graphCount_, method_] := Module[{
    tests},
  tests = Select[!IsomorphicGraphQ @@ (graphFromHyperedges /@ #) &]
    @ Partition[
      Select[SimpleGraphQ @* graphFromHyperedges]
        @ randomConnectedGraphs[edgeCount, edgeLength, graphCount],
      2];
  Not[Or @@ ParallelMap[
    (* degenerate graphs can still match if not isomorphic, i.e., {{0, 0}} will match {{0, 1}},
       that's why we need to try replacing both ways *)
    SetReplace[#[[1]], ToPatternRules[#[[2]] -> {}], Method -> method] == {}
      && SetReplace[#[[2]], ToPatternRules[#[[1]] -> {}], Method -> method] == {} &,
    tests]]
]

VerificationTest[
  randomDistinctGraphMatchTest[10, 2, 10000, "LowLevel"],
  True
]

VerificationTest[
  randomDistinctGraphMatchTest[10, 3, 10000, "LowLevel"],
  True
]

VerificationTest[
  randomDistinctGraphMatchTest[10, 6, 10000, "LowLevel"],
  True
]

VerificationTest[
  randomDistinctGraphMatchTest[6, 2, 5000, "Symbolic"],
  True
]

VerificationTest[
  randomDistinctGraphMatchTest[6, 3, 5000, "Symbolic"],
  True
]

VerificationTest[
  randomDistinctGraphMatchTest[6, 6, 5000, "Symbolic"],
  True
]

(* Here we make initial condition degenerate, and check it still matches, i.e.,
   {{0, 0}} should still match {{0, 1}} *)
randomDegenerateGraphMatchTest[
      edgeCount_, edgeLength_, graphCount_, method_] := Module[{
    tests},
  tests = randomConnectedGraphs[edgeCount, edgeLength, graphCount];
Union[
  ParallelMap[
      SetReplace[
        #[[1]] /. #[[2]] -> #[[3]],
        ToPatternRules[#[[4]] -> {}],
        Method -> method] &,
      BlockRandom[
        {#, RandomChoice[Flatten[#]], RandomChoice[Flatten[#]], RandomSample[#]} & /@ tests,
        RandomSeeding -> ToString[{"randomDegenerateGraphMatchTest", edgeCount, edgeLength, graphCount, method}]]]]
    === {{}}
]

VerificationTest[
  randomDegenerateGraphMatchTest[10, 2, 10000, "LowLevel"],
  True
]

VerificationTest[
  randomDegenerateGraphMatchTest[10, 3, 5000, "LowLevel"],
  True
]

VerificationTest[
  randomDegenerateGraphMatchTest[10, 6, 1000, "LowLevel"],
  True
]

VerificationTest[
  randomDegenerateGraphMatchTest[6, 2, 5000, "Symbolic"],
  True
]

VerificationTest[
  randomDegenerateGraphMatchTest[6, 3, 500, "Symbolic"],
  True
]

VerificationTest[
  randomDegenerateGraphMatchTest[6, 10, 100, "Symbolic"],
  True
]

EndTestSection[]
