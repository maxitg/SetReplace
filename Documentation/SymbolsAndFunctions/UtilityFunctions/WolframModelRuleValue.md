###### [Symbols and Functions](/README.md#symbols-and-functions) > Utility Functions >

# WolframModelRuleValue

[Transformation Count](#transformation-count) | [Arity](#arity) | [Node Counts](#node-counts) | [Connectedness](#connectedness)

**`WolframModelRuleValue`** computes simple properties of rules, which can be determined without running the evolution. Only anonymous (not pattern) rules are supported at the moment. The full list of supported properties can be obtained with **`$WolframModelRuleProperties`**:

```wl
In[] := $WolframModelRuleProperties
Out[] = {"ConnectedInput", "ConnectedInputOutputUnion", "ConnectedOutput",
  "MaximumArity", "NodeCounts", "NodesDroppedAdded", "Signature",
  "TraditionalSignature", "TransformationCount"}
```

## Transformation Count

**`TransformationCount`** is a very simple property that returns the number of rules in the system:

```wl
In[] := WolframModelRuleValue[{{{1, 1, 2}} -> {{2, 2, 1}, {2, 3, 2}, {1, 2,
     3}},
  {{1, 2, 1}, {3, 4, 2}} -> {{4, 3, 2}}}, "TransformationCount"]
Out[] = 2
```

## Arity

Arity is the length of an edge. The maximum length of any edge in the rules can be determined with **`MaximumArity`**:

```wl
In[] := WolframModelRuleValue[{{1, 2, 3}, {4, 5, 6}, {2, 5}, {5, 2}} ->
  {{7, 1, 8}, {9, 3, 10}, {11, 4, 12}, {13, 6, 14}, {7, 13}, {13,
    7}, {8, 10}, {10, 8}, {9, 11}, {11, 9}, {12, 14}, {14,
    12}}, "MaximumArity"]
Out[] = 3
```

For the summary of arities for all edges, one can use **`RuleSignature`**:

```wl
In[] := WolframModelRuleValue[{{1, 2, 3}, {4, 5, 6}, {2, 5}, {5, 2}} ->
  {{7, 1, 8}, {9, 3, 10}, {11, 4, 12}, {13, 6, 14}, {7, 13}, {13,
    7}, {8, 10}, {10, 8}, {9, 11}, {11, 9}, {12, 14}, {14,
    12}}, "TraditionalSignature"]
```

<img src="/Documentation/Images/TraditionalSignature.png" width="139">

In this example, there are 2 binary and 2 ternary edges in the input, and 8 binary and 4 ternary edges in the output. The more machine-readable form of this can be obtained with **`Signature`** property:

```wl
In[] := WolframModelRuleValue[{{1, 2, 3}, {4, 5, 6}, {2, 5}, {5, 2}} ->
  {{7, 1, 8}, {9, 3, 10}, {11, 4, 12}, {13, 6, 14}, {7, 13}, {13,
    7}, {8, 10}, {10, 8}, {9, 11}, {11, 9}, {12, 14}, {14,
    12}}, "Signature"]
Out[] = {{2, 2}, {2, 3}} -> {{8, 2}, {4, 3}}
```

## Node Counts

One can count the vertices involved in the left- and right-hand sides of the rule with **`"NodeCounts"`**. For example, this rule has 5 vertices in the input, and 6 in the output:

```wl
In[] := WolframModelRuleValue[{{1, 2, 3}, {2, 4, 5}} -> {{5, 6, 1}, {6, 4,
    2}, {4, 5, 3}}, "NodeCounts"]
Out[] = 5 -> 6
```

**`NodesDroppedAdded`** gives the counts of vertices that appear only on the left- and right-hand sides of the rule. Here for example, the first rule creates a vertex, and the second rule drops a vertex:

```wl
In[] := WolframModelRuleValue[{{{1, 1, 2}} -> {{2, 2, 1}, {2, 3, 2}, {1, 2,
     3}},
  {{1, 2, 1}, {3, 4, 2}} -> {{4, 3, 2}}}, "NodesDroppedAdded"]
Out[] = {{0, 1}, {1, 0}}
```

Keep in mind that rule dropping a vertex does not imply this vertex would be deleted from the state, as there may be other edges containing this vertex.

## Connectedness

There are three types of rule connectedness.

**`ConnectedInput`** checks if the left-hand side of the rule is a connected hypergraph. If it's [`True`](https://reference.wolfram.com/language/ref/True.html), the rule is local, and [`"LowLevel"` implementation](../WolframModelAndWolframModelEvolutionObject/Options/Method.md) can be used for it:

```wl
In[] := WolframModelRuleValue[{{1, 2, 3}, {3, 4, 5}} -> {{2, 3, 1}, {4, 3,
    2}, {5, 6, 7}}, "ConnectedInput"]
Out[] = True
```

**`ConnectedOutput`** does the same for the output:

```wl
In[] := WolframModelRuleValue[{{1, 2, 3}, {3, 4, 5}} -> {{2, 3, 1}, {4, 3,
    2}, {5, 6, 7}}, "ConnectedOutput"]
Out[] = False
```

**`ConnectedInputOutputUnion`** yields [`True`](https://reference.wolfram.com/language/ref/True.html) if the input is connected to the output. Note that it does not require either the input or the output to be connected within themselves, but neither of them can have pieces disconnected from the rest of the rule:

```wl
In[] := WolframModelRuleValue[{{1, 2, 3}, {3, 4, 5}} -> {{2, 3, 1}, {4, 3,
    2}, {5, 6, 7}}, "ConnectedInputOutputUnion"]
Out[] = True
```

For multiple-rule systems, each rule needs to be connected for these properties to yield [`True`](https://reference.wolfram.com/language/ref/True.html):

```wl
In[] := WolframModelRuleValue[{{{1, 2}} -> {{1, 3}, {3, 2}},
  {{1, 2}} -> {{1, 2}, {3, 3}}}, "ConnectedOutput"]
Out[] = False
```
