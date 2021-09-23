# MaxGeneration

`MaxGeneration` is an event-selection parameter specifying the maximum generation of created tokens.

Roughly speaking, **generation** corresponds to how many "steps" it took to get to a particular token or event starting
from the initial state. More precisely, the generation of the tokens in the initial state is defined to be zero. The
generation of an event is defined as the maximum of the generations of its inputs plus one. The generation of a token is
the same as the generation of its creator event.

A neat feature of the `TokenEventGraph` property is that it arranges tokens and events in layers corresponding to their
generations. In the following example, the tokens and events are labeled with their generation numbers:

```wl
In[] := #["ExpressionsEventsGraph",
          VertexLabels -> Placed["Name", After, Replace[{{"Expression", n_} :> #["ExpressionGenerations"][[n]],
                                                         {"Event", n_} :> #["EventGenerations"][[n]]}]]] & @
  SetReplaceTypeConvert[WolframModelEvolutionObject] @
    GenerateMultihistory[MultisetSubstitutionSystem[{a__} /; Total[{a}] == 5 :> {Total[{a}] - 1, Total[{a}] + 1}],
                         MaxEvents -> 3] @ {1, 2, 3}
```

<img src="/Documentation/Images/TokenEventGraphGenerations.png" width="444.6">

Restricting the number of generations to one will prevent the last two events from occurring. Note, however, that
another event is created instead:

```wl
In[] := #["ExpressionsEventsGraph"] & @ SetReplaceTypeConvert[WolframModelEvolutionObject] @
  GenerateMultihistory[MultisetSubstitutionSystem[{a__} /; Total[{a}] == 5 :> {Total[{a}] - 1, Total[{a}] + 1}],
                       MaxGeneration -> 1, MaxEvents -> 3] @ {1, 2, 3}
```

<img src="/Documentation/Images/MaxGeneration.png" width="478.2">

`MaxGeneration` is an event selection parameter, not a stopping condition. That is, the evolution of the system won't
stop if a match (tentative event) with a generation greater than the constraint is encountered. Instead, it will ignore
those matches and instantiate only those that satisfy the generation constraint. This selection of events according to
their generation will (in most cases) affect the event order, as opposed to using stopping conditions, e.g.,
`MaxEvents`. For this reason, `MaxGenerations` (like other selection parameters) does not have a corresponding
termination reason.

```wl
In[] := #[[2, "TerminationReason"]] & @
  GenerateMultihistory[MultisetSubstitutionSystem[{a__} /; Total[{a}] == 5 :> {Total[{a}] - 1, Total[{a}] + 1}],
                       MaxGeneration -> 1] @ {1, 2, 3}
Out[] = "Complete"
```
