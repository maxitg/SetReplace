<|
  "performance" -> <|
    "init" -> (
      $init = {{0, 0}, {0, 0}, {0, 0}};
      $rule =
        {{{a_, b_}, {a_, c_}, {a_, d_}} :>
          Module[{$0, $1, $2}, {
            {$0, $1}, {$1, $2}, {$2, $0}, {$0, $2}, {$2, $1}, {$1, $0},
            {$0, b}, {$1, c}, {$2, d}, {b, $2}, {d, $0}}]};

      $largeSet = Hold[WolframModel[
        {{1, 2, 3}} -> {{5, 6, 1}, {6, 4, 2}, {4, 5, 3}},
        {{0, 0, 0}},
        7,
        "FinalState"]];

      {$normalPlotTiming, $normalPlotMemory} =
        AbsoluteTiming[MaxMemoryUsed[GraphPlot[Rule @@@ Catenate[Partition[#, 2, 1] & /@ ReleaseHold[$largeSet]]]]];

      $edgeTypes = {"Ordered", "Cyclic"};
      $hyperedgeRenderings = {"Subgraphs", "Polygons"};
    ),
    "tests" -> {
      With[{init = $init, rule = $rule}, {
        (** C++ performance **)
  
          VerificationTest[
            Head[SetReplace[
              init,
              rule,
              1000]],
            List,
            TimeConstraint -> 10,
            MemoryConstraint -> 5*^6
          ],
  
          (** WL performance **)
  
          VerificationTest[
            Head[SetReplace[
              init,
              rule,
              #,
              Method -> "Symbolic"]],
            List,
            TimeConstraint -> 60,
            MemoryConstraint -> 5*^6
          ] & /@ {14, 100},
  
          (** Naming function performance **)
  
          VerificationTest[
            Head[WolframModel[
              <|"PatternRules" -> rule|>,
              init,
              <|"MaxEvents" -> 1000|>,
              "FinalState",
              "NodeNamingFunction" -> All]],
            List,
            TimeConstraint -> 10,
            MemoryConstraint -> 10*^6
        ]
      }],

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
      ],

      (** WolframModelPlot **)

      Table[
        With[{edgeType = edgeType, hyperedgeRendering = hyperedgeRendering, $largeSet = $largeSet}, VerificationTest[
          With[{largeSet = ReleaseHold[$largeSet]},
          Head[WolframModelPlot[largeSet, edgeType, "HyperedgeRendering" -> hyperedgeRendering]]],
          Graphics,
          TimeConstraint -> (5 $normalPlotTiming),
          MemoryConstraint -> (10 $normalPlotMemory)] /. HoldPattern[ReleaseHold[Hold[set_]]] -> set],
        {edgeType, $edgeTypes},
        {hyperedgeRendering, $hyperedgeRenderings}]
    },
    "options" -> {
      "Parallel" -> False
    }
  |>
|>
