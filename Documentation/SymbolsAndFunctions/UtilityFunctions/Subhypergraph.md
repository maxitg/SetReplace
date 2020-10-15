### Subhypergraph

**`Subhypergraph`** is a small utility function that selects hyperedges that only contain vertices from the requested list.

```wl
In[]:= Subhypergraph[{{1, 1, 1}, {1, 2}, {2, 3, 3}, {2, 3, 4}}, {2, 3, 4}]
Out[]= {{2, 3, 3}, {2, 3, 4}}
```
**`WeakSubhypergraph`** is the weak version of the previous function, where hyperedges are selected if they contain any vertex from the requested list.

```wl
In[]:= WeakSubhypergraph[{{1, 1}, {2, 3}, {3, 4, 4}}, {1, 3}]
Out[]= {{1, 1}, {2, 3}, {3, 4, 4}}
```
