<|
  "tokenDeduplication" -> <|
    "tests" -> {
      (* A periodic evolution collapses into a cycle. Consecutive tokens share atoms and cannot merge, so the minimal
         period is 2. *)
      VerificationTest[
        WolframModel[{{1, 2}} -> {{2, 3}}, {{1, 2}}, <|"MaxEvents" -> 6|>]["TokenDeduplicationClasses"],
        <|"ExpressionClasses" -> {1, 2, 1, 2, 1, 2, 1},
          "EventClasses" -> {0, 1, 2, 1, 2, 1, 2},
          "AtomClasses" -> <|3 -> 1, 4 -> 2, 5 -> 1, 6 -> 2, 7 -> 1, 8 -> 2|>|>
      ],

      VerificationTest[
        AcyclicGraphQ[
          WolframModel[{{1, 2}} -> {{2, 3}}, {{1, 2}}, <|"MaxEvents" -> 6|>]["DeduplicatedExpressionsEventsGraph"]],
        False
      ],

      VerificationTest[
        VertexCount[
          WolframModel[{{1, 2}} -> {{2, 3}}, {{1, 2}}, <|"MaxEvents" -> 6|>]["DeduplicatedExpressionsEventsGraph"]],
        4
      ],

      (* Branchlike-separated tokens with identical contents and futures merge, but the events creating them do not *)
      VerificationTest[
        WolframModel[{{1, 2}, {2, 3}} -> {{1, 3}},
                     {{1, 2}, {2, 3}, {3, 4}},
                     Infinity,
                     "EventSelectionFunction" -> "MultiwaySpacelike"]["TokenDeduplicationClasses"],
        <|"ExpressionClasses" -> {1, 2, 3, 4, 5, 6, 6},
          "EventClasses" -> {0, 1, 2, 3, 4},
          "AtomClasses" -> <||>|>
      ],

      (* Atoms appearing together in a state are never identified, so identically-evolving parallel chains stay
         separate *)
      VerificationTest[
        WolframModel[{{1}} -> {{1}}, {{1}, {2}}, <|"MaxEvents" -> 4|>][
          "TokenDeduplicationClasses"]["ExpressionClasses"],
        {1, 2, 1, 2, 1, 2}
      ],

      (* The deduplicated graph of the parallel chains consists of two disjoint self-loops *)
      VerificationTest[
        ConnectedGraphQ[UndirectedGraph[
          WolframModel[{{1}} -> {{1}}, {{1}, {2}}, <|"MaxEvents" -> 4|>]["DeduplicatedExpressionsEventsGraph"]]],
        False
      ],

      (* Periodic multiway evolutions collapse to a quotient of fixed size, independent of the number of generations.
         In particular, the event horizon must not be glued directly to the initial condition, which would produce
         loops that grow with the number of generations. *)
      VerificationTest[
        Table[
          Through[{VertexCount, EdgeCount}[
            WolframModel[{{1, 2}, {2, 3}} -> {{1, 3}, {2, 3}}, {{1, 2}, {2, 1}}, gens,
                         "EventSelectionFunction" -> "MultiwaySpacelike"]["DeduplicatedExpressionsEventsGraph"]]],
          {gens, {3, 10}}],
        {{10, 16}, {10, 16}}
      ],

      (* An identity rule recreates the same state forever, so the quotient is the same fixed-size object at any
         number of generations, even though tokens are re-consumed by later sibling-branch events whose counterparts
         for their copies are beyond the horizon *)
      VerificationTest[
        Table[
          Through[{VertexCount, EdgeCount}[
            WolframModel[{{1, 2}, {2, 3}} -> {{1, 2}, {2, 3}}, {{1, 2}, {2, 3}, {3, 1}}, gens,
                         "EventSelectionFunction" -> "MultiwaySpacelike"]["DeduplicatedExpressionsEventsGraph"]]],
          {gens, 3}],
        {{6, 12}, {6, 12}, {6, 12}}
      ],

      (* Events consuming multiple tokens of the same class keep an input edge per token, so in- and out-degrees of
         deduplicated events always match the rule arities *)
      VerificationTest[
        With[{
            graph = WolframModel[{{1, 2, 3}, {4, 2, 5}} -> {{1, 1, 4}, {3, 2, 1}, {6, 2, 5}},
                                 {{1, 1, 1}, {1, 1, 1}},
                                 <|"MaxEvents" -> 2|>,
                                 "EventSelectionFunction" ->
                                   "MultiwaySpacelike"]["DeduplicatedExpressionsEventsGraph"]},
          Union[{VertexInDegree[graph, #], VertexOutDegree[graph, #]} & /@ Cases[VertexList[graph], {"Event", _}]]],
        {{2, 3}}
      ],

      (* Pattern rules: tokens are arbitrary expressions and act as named atoms, so they are never renamed, but
         identical ones still merge, rolling periodic evolutions into cycles *)
      VerificationTest[
        WolframModel[<|"PatternRules" -> {{0} -> {1}, {0} -> {2}, {1} -> {3}, {2} -> {4}, {3} -> {2}, {4} -> {1}}|>,
                     {0}, 10]["TokenDeduplicationClasses"],
        <|"ExpressionClasses" -> {1, 2, 3, 4, 5, 2, 3, 4, 5, 2, 3},
          "EventClasses" -> {0, 1, 2, 3, 4, 5, 2, 3, 4, 5, 2},
          "AtomClasses" -> <||>|>
      ],

      VerificationTest[
        AcyclicGraphQ[
          WolframModel[<|"PatternRules" -> {{0} -> {1}, {0} -> {2}, {1} -> {3}, {2} -> {4}, {3} -> {2}, {4} -> {1}}|>,
                       {0}, 10]["DeduplicatedExpressionsEventsGraph"]],
        False
      ],

      (* Symbolic method evolutions are supported as well *)
      VerificationTest[
        WolframModel[{{1, 2}} -> {{2, 3}}, {{1, 2}}, <|"MaxEvents" -> 4|>, Method -> "Symbolic"][
          "TokenDeduplicationClasses"]["ExpressionClasses"],
        {1, 2, 1, 2, 1}
      ],

      (* All tokens of this complete evolution share atoms with each other, so nothing merges *)
      VerificationTest[
        WolframModel[{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {2, 3}}, Infinity,
                     "EventSelectionFunction" -> "MultiwaySpacelike"]["TokenDeduplicationClasses"][
          "ExpressionClasses"],
        {1, 2, 3}
      ],

      (* Options of ExpressionsEventsGraph are supported *)
      VerificationTest[
        Options[
          WolframModel[{{1, 2}} -> {{2, 3}}, {{1, 2}}, <|"MaxEvents" -> 6|>][
            "DeduplicatedExpressionsEventsGraph", Background -> Black],
          Background],
        {Background -> Black}
      ]
    }
  |>
|>
