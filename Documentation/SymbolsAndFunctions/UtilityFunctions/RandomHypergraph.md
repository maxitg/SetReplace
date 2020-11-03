###### [Symbols and Functions](/README.md#symbols-and-functions) > Utility Functions >

# RandomHypergraph

**`RandomHypergraph`** generates a random hypergraph.

Pass a non-negative integer `n` to generate a hypergraph that has `n` as its total number of hyperedge parts, i.e. its "complexity":

```wl
In[]:= SeedRandom[123];
hg = RandomHypergraph[8]
Total[Length /@ hg]

Out[]= {{4, 7, 4}, {4}, {8}, {4}, {2}, {5}}
Out[]= 8
```

Pass `{n, sig}` to generate a hypergraph with at most `n` vertices and with `sig` as its signature:
```wl
In[]:= RandomHypergraph[{10, {5, 2}}]
Out[]= {{4, 1}, {8, 4}, {2, 5}, {6, 10}, {10, 5}}
```

```wl
In[]:= RandomHypergraph[{10, {{5, 2}, {4, 3}}}]
Out[]= {{5, 5}, {1, 10}, {3, 1}, {8, 10}, {10, 6}, {8, 9, 7}, {7, 3, 10}, {6, 9, 2}, {4, 3, 3}}
```
