###### [Symbols and Functions](/README.md#symbols-and-functions) > Utility Functions >

# RandomHypergraph

**`RandomHypergraph`** generates a random hypergraph. The first argument specifies either the hypergraph "complexity" or its signature. The second (optional) argument is the maximum possible number of distinct vertices of said hypergraph.

Pass a positive integer `n` to generate a hypergraph where the total of all hyperedge arities is `n`:

```wl
In[] := RandomHypergraph[15]
Out[] = {{5, 14, 13}, {8}, {4}, {7, 13}, {15}, {13, 12, 4, 14}, {14, 2}, {12}}
```

```wl
In[] := Total[Length /@ %]
Out[] = 15
```

Generate a random hypergraph with the same complexity but with at most 20 distinct vertices:
```wl
In[] := RandomHypergraph[15, 20]
Out[] = {{14, 17, 11, 10}, {6}, {13, 12, 17}, {1}, {1, 12}, {3, 20, 12, 17}}
```

Pass `sig` to generate a hypergraph with `sig` as its signature:
```wl
In[] := RandomHypergraph[{5, 2}]
Out[] = {{4, 3}, {2, 8}, {5, 7}, {9, 5}, {4, 7}}
```

A signature with multiple arities also works:
```wl
In[] := RandomHypergraph[{{5, 2}, {4, 3}}]
Out[] = {{10, 22}, {18, 6}, {3, 19}, {1, 14}, {21, 2}, {11, 19, 20}, {11, 8, 3}, {18, 20, 3}, {3, 17, 17}}
```

Restrict this hypergraph to have `{1, 2}` as its vertex list:
```wl
In[] := RandomHypergraph[{{5, 2}, {4, 3}}, 2]
Out[] = {{1, 1}, {1, 2}, {1, 2}, {2, 1}, {2, 1}, {2, 2, 2}, {1, 1, 2}, {1, 1, 2}, {1, 1, 1}}
```
