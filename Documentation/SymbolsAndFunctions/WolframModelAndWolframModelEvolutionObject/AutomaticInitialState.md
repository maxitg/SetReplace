### Automatic Initial State

An initial state consisting of an appropriate number of (hyper) self-loops can be automatically produced for anonymous (non-pattern) rules. Here we evolve the system for 0 steps and ask the evolution object for the 0-th generation aka the initial state:

```wl
In[] := WolframModel[{{1, 2}, {1, 2}} -> {{3, 2}, {3, 2}, {2, 1}, {1, 3}},
  Automatic, 0][0]
Out[] = {{1, 1}, {1, 1}}
```

That even works for multiple rules in which case the loops are chosen in such a way that any of the rules can match:

```wl
In[] := WolframModel[{{{1, 2}, {1, 2}} ->
    {{3, 2}, {3, 2}, {2, 1, 3}, {2, 3}},
   {{2, 1, 3}, {2, 3}} -> {{2, 1}, {1, 3}}}, Automatic, 0][0]
Out[] = {{1, 1}, {1, 1}, {1, 1, 1}}
```

Note that because different patterns can be matched to the same symbol, this initial state is guaranteed to match the rules at least once (no guarantees after that).
