###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Options](../WolframModelAndWolframModelEvolutionObject.md#options) >

# "VertexNamingFunction"

**`"VertexNamingFunction"`** controls the names chosen for vertices, particularly the newly created ones. It can take three values: [`None`](https://reference.wolfram.com/language/ref/None.html), [`Automatic`](https://reference.wolfram.com/language/ref/Automatic.html), and [`All`](https://reference.wolfram.com/language/ref/All.html).

[`None`](https://reference.wolfram.com/language/ref/None.html) does not do anything, the vertices in the initial condition are left as-is, and the newly created vertices use symbol names as, i.e., `Module[{v}, v]` could generate:

```wl
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}},
 {{v1, v1}}, 2, "StatesList", "VertexNamingFunction" -> None]
Out[] = {{{v1, v1}}, {{v1, v256479}, {v1, v256479}, {v256479, v1}}, {{v1,
   v256480}, {v1, v256480}, {v256480, v256479}, {v1, v256481}, {v1,
   v256481}, {v256481, v256479}, {v256479, v256482}, {v256479,
   v256482}, {v256482, v1}}}
```

[`All`](https://reference.wolfram.com/language/ref/All.html) renames all vertices as sequential integers, including the ones in the the initial condition, and including ones manually generated in [pattern rules](../WolframModelAndWolframModelEvolutionObject.md#pattern-rules):

```wl
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}},
 {{v1, v1}}, 2, "StatesList", "VertexNamingFunction" -> All]
Out[] = {{{1, 1}}, {{1, 2}, {1, 2}, {2, 1}}, {{1, 3}, {1, 3}, {3, 2}, {1,
   4}, {1, 4}, {4, 2}, {2, 5}, {2, 5}, {5, 1}}}
```

[`Automatic`](https://reference.wolfram.com/language/ref/Automatic.html) only renames newly created vertices with non-previously-used integers, and leaves the initial condition as-is. It does nothing in the case of [pattern rules](../WolframModelAndWolframModelEvolutionObject.md#pattern-rules).

```wl
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}},
 {{v1, v1}}, 2, "StatesList", "VertexNamingFunction" -> Automatic]
Out[] = {{{v1, v1}}, {{v1, 1}, {v1, 1}, {1, v1}}, {{v1, 2}, {v1, 2}, {2,
   1}, {v1, 3}, {v1, 3}, {3, 1}, {1, 4}, {1, 4}, {4, v1}}}
```
