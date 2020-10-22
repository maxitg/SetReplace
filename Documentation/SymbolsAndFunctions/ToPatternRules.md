###### [Symbols and Functions](/README.md#symbols-and-functions) > 

# ToPatternRules

**`ToPatternRules`** is a convenience function used to quickly enter rules such as the one mentioned previously:

```wl
{{v1_, v2_, v3_}, {v2_, v4_, v5_}} :>
 Module[{v6}, {{v5, v6, v1}, {v6, v4, v2}, {v4, v5, v3}}]
```

This is the type of rule we study the most, and it satisfies the following set of conditions:

* Both input and output subsets consist of ordered lists of atomic vertices.
* The input (left-hand side) only contains patterns, it never refers to explicit vertex names.
* The name of the vertex is only used to identify it, it does not contain any additional information. In particular, there are no conditions on the left-hand side of the rule (neither on the entire subset nor on individual vertices or edges), except for the implicit condition of the same vertices appearing multiple times.
* The output may contain new vertices (the ones that don't appear on the left-hand side), in which case [`Module`](https://reference.wolfram.com/language/ref/Module.html) is used to create them.

`ToPatternRules` provides a more straightforward way to specify such rules by automatically assuming that all level-2 expressions on the left-hand side are patterns, and vertices used on the right that don't appear on the left are new and should be created with a [`Module`](https://reference.wolfram.com/language/ref/Module.html). For example, the rule above can simply be written as

```wl
In[] := ToPatternRules[{{v1, v2, v3}, {v2, v4, v5}} ->
  {{v5, v6, v1}, {v6, v4, v2}, {v4, v5, v3}}]
Out[] = {{v1_, v2_, v3_}, {v2_, v4_, v5_}} :>
 Module[{v6}, {{v5, v6, v1}, {v6, v4, v2}, {v4, v5, v3}}]
```

or even simpler as

```wl
In[] := ToPatternRules[{{1, 2, 3}, {2, 4, 5}} ->
  {{5, 6, 1}, {6, 4, 2}, {4, 5, 3}}]
Out[] = {{v1_, v2_, v3_}, {v2_, v4_, v5_}} :>
 Module[{v6}, {{v5, v6, v1}, {v6, v4, v2}, {v4, v5, v3}}]
```

This last form of the rule is the one that we use most often and is also the one [`WolframModel`](WolframModelAndWolframModelEvolutionObject/WolframModelAndWolframModelEvolutionObject.md) accepts by default.

`ToPatternRules` is listable in a trivial way:

```wl
In[] := ToPatternRules[{{{1, 2}} -> {{1, 2}, {2, 3}},
  {{1, 2}} -> {{1, 3}, {3, 2}}}]
Out[] = {{{v1_, v2_}} :> Module[{v3}, {{v1, v2}, {v2, v3}}],
 {{v1_, v2_}} :> Module[{v3}, {{v1, v3}, {v3, v2}}]}
```
