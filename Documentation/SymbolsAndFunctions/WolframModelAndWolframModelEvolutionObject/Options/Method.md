###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Options](../WolframModelAndWolframModelEvolutionObject.md#options) >

# Method

There are two implementations (**`Method`** s) available: one written in Wolfram Language (`Method -> "Symbolic"`), one
in C++ (`Method -> "LowLevel"`).

The Wolfram Language implementation permutes the left-hand sides of the rules in all possible ways and
uses [`Replace`](https://reference.wolfram.com/language/ref/Replace.html) a specified number of times to perform
evolution. This implementation works well for small graphs and small rule inputs, but it slows down with the number of
edges in the graph and has exponential complexity in rule size.

The C++ implementation, on the other hand, keeps an index of all possible rule matches and updates it after every
replacement. The reindexing algorithm looks only at the local region of the graph close to the rewrite site. Thus time
complexity does not depend on the graph size as long as vertex degrees are small. The downside is that it has
exponential complexity (both in time and memory) in the vertex degrees. Currently, it also does not work for non-local
rules (i.e., rule inputs that do not form a connected hypergraph) and rules that are not hypergraph rules (i.e., pattern
rules that have non-trivial nesting or conditions).

The C++ implementation is used by default for supported systems and is particularly useful if:

* Vertex degrees are expected to be small.
* Evolution needs to be done for a large number of steps `> 100`, it is possible to produce states with up to a million
  edges or more.

It should not be used, however, if vertex degrees can grow large. For example

```wl
In[] := AbsoluteTiming[
 WolframModel[{{{0}} -> {{0}, {0}, {0}}, {{0}, {0}, {0}} -> {{0}}},
  {{0}}, <|"MaxEvents" -> 30|>, Method -> "LowLevel"]]
```

<img src="/Documentation/Images/SlowLowLevelTiming.png" width="609">

takes almost 10 seconds in C++ implementation, and less than 1/10th of a second in the Wolfram Language implementation:

```wl
In[] := AbsoluteTiming[
 WolframModel[{{{0}} -> {{0}, {0}, {0}}, {{0}, {0}, {0}} -> {{0}}},
  {{0}}, <|"MaxEvents" -> 30|>, Method -> "Symbolic"]]
```

<img src="/Documentation/Images/FastSymbolicTiming.png" width="617">

Wolfram Language implementation should be used if:

* A large number of small rules with unknown behavior needs to be simulated for a small number of steps.
* Vertex degrees are expected to be large, rules are non-local, or pattern rules with non-trivial nesting or conditions
  are used.
