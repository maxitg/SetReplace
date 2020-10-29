###### [Symbols and Functions](/README.md#symbols-and-functions) > Utility Functions >

# IsomorphicHypergraphQ

**`IsomorphicHypergraphQ`** is the natural extension of [`IsomorphicGraphQ`](https://reference.wolfram.com/language/ref/IsomorphicGraphQ.html) for hypergraphs. It yields [`True`](https://reference.wolfram.com/language/ref/True.html) for [isomorphic](https://en.wikipedia.org/wiki/Hypergraph#Isomorphism_and_equality) (ordered) hypergraphs, and [`False`](https://reference.wolfram.com/language/ref/False.html) otherwise:

```wl
In[]:= IsomorphicHypergraphQ[
  {{a, e, d}, {d, c}, {c, b}, {b, a}},
  {{2, 4}, {4, 5, 1}, {1, 3}, {3, 2}}]
Out[]= True
```

```wl
In[]:= IsomorphicHypergraphQ[
  {{a, e, d}, {d, c}, {c, b}, {b, a}},
  {{2, 4}, {4, 3, 1}, {1, 3}, {5, 2}}]
Out[]= False
```
