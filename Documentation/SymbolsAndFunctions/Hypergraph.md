###### [Symbols and Functions](/README.md#symbols-and-functions) >

# Hypergraph

[HypergraphQ](#hypergraphq) | [HypergraphSymmetry](#hypergraphsymmetry)

**`Hypergraph[...]`** represents a hypergraph object:

```wl
In[] := Hypergraph[{{1, 1, 2}}]
```

<img src="/Documentation/Images/Hypergraph.png" width="484.2">

`Hypergraph` follows the footsteps of [Graph](http://reference.wolfram.com/language/ref/Graph.html), in that the `Hypergraph` symbol acts both as a constructor and as an object.

The second argument of `Hypergraph` specifies the global [symmetry](#hypergraphsymmetry) of its hyperedges.

```wl
In[] := Hypergraph[{{1, 1, 2}}, "Cyclic"]
```

<img src="/Documentation/Images/HypergraphCyclic.png" width="502.2">

If left unspecified, the default symmetry is `"Ordered"`:

```wl
In[] := Hypergraph[{{1, 1, 2}}] === Hypergraph[{{1, 1, 2}}, "Ordered"]
Out[] = True
```

`Hypergraph` objects are atomic raw objects:

```wl
In[] := AtomQ[Hypergraph[{{1, 1, 1}}]]
Out[] = True
```

Given their atomic nature, [parts](http://reference.wolfram.com/language/ref/Part.html) of a `Hypergraph` object cannot be extracted:

```wl
In[] := Hypergraph[{{1, 1, 1}}][[1]]
```

<img src="/Documentation/Images/HypergraphPartError.png" width="803.4">

For this reason, the following accesor functions are supported:

```wl
In[] := hg = Hypergraph[{{1, 1, 2}, {2, 5, 4, 3}, {3, 6}}, "Unordered"];
```

- [`EdgeList`](http://reference.wolfram.com/language/ref/EdgeList.html) - the list of (hyper)edges in the hypergraph:

  ```wl
  In[] := EdgeList[hg]
  Out[] = {{1, 1, 2}, {2, 5, 4, 3}, {3, 6}}
  ```

- [`VertexList`](http://reference.wolfram.com/language/ref/VertexList.html)- the list of vertices and in the hypergraph:

  ```wl
  In[] := VertexList[hg]
  Out[] = {1, 2, 5, 4, 3, 6}
  ```

- [`HypergraphSymmetry`](#hypergraphsymmetry) - the hypergraph symmetry:
  ```wl
  In[]:= HypergraphSymmetry[hg]
  Out[]= "Unordered"
  ```

## HypergraphQ

**`HypergraphQ[hg]`** returns True if `hg` is a valid [`Hypergraph`](#hypergraph) object and False otherwise:

```wl
In[] := HypergraphQ[Hypergraph[{{1, 1, 2}}]]
Out[] = True
```

```wl
In[] := Quiet @ HypergraphQ[Hypergraph[1]]
Out[] = False
```

## HypergraphSymmetry
