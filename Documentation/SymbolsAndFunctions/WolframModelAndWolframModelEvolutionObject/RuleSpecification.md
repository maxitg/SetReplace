### Rule Specification

#### Multiple Rules

Multiple rules can simply be specified as a list of rules:

```wl
In[] := WolframModel[{{{1, 1, 2}} -> {{2, 2, 1}, {2, 3, 2}, {1, 2, 3}},
  {{1, 2, 1}, {3, 4, 2}} -> {{4, 3, 2}}}, {{1, 1, 1}}, 4]
```

<img src="READMEImages/EvolutionObjectFromMultipleRules.png" width="488">

To see which rules were used for each replacement:

<img src="READMEImages/AllEventsRuleIndicesOfEvolutionObject.png" width="708">

```wl
Out[] = {1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2, 1, 2}
```

#### Pattern Rules

Pattern rules (i.e., the kind of rules used in the [`SetReplace`](../SetReplace*.md) function) can be specified as well. As an example, previously described call to [`SetReplaceList`](../SetReplace*.md) can be reproduced as

```wl
In[] := WolframModel[<|"PatternRules" -> {a_, b_} :> a + b|>,
 {1, 2, 5, 3, 6}, Infinity, "AllEventsStatesList"]
Out[] = {{1, 2, 5, 3, 6}, {5, 3, 6, 3}, {6, 3, 8}, {8, 9}, {17}}
```

One can even add conditions spanning multiple expressions:

```wl
In[] := WolframModel[<|"PatternRules" -> {a_, b_} /; a > b :> a - b|>,
 {1, 1, 5, 3, 6}, Infinity, "AllEventsStatesList"]
Out[] = {{1, 1, 5, 3, 6}, {1, 3, 6, 4}, {6, 4, 2}, {2, 2}}
```
