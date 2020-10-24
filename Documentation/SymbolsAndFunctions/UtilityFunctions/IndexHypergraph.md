###### [Symbols and Functions](/README.md#symbols-and-functions) > Utility Functions >

# IndexHypergraph

**`IndexHypergraph`** replaces the vertices of the hypergraph by its vertex indices:

```wl
In[]:= IndexHypergraph[{{x, y, z}, {w, y}, {z, {x}, {{y}}}}]
Out[]= {{2, 3, 4}, {1, 3}, {4, 5, 6}}
```

Replace the vertices with integers starting from -10:

```wl
In[]:= IndexHypergraph[{{x, y, z}, {w, y}, {z, {x}, {{y}}}}, -10]
Out[]= {{-9, -8, -7}, {-10, -8}, {-7, -6, -5}}
```