###### [Generators](README.md)

# EventSelectionParameters

**`EventSelectionParameters`** allows one to obtain the list of event selection parameters that can be used with a
[computational system](/Documentation/Systems/README.md):

```wl
In[] := EventSelectionParameters[MultisetSubstitutionSystem]
Out[] = {"MaxGeneration", "MaxDestroyerEvents", "MinEventInputs", "MaxEventInputs"}
```

The values returned by this function can be used as keys for the corresponding arguments of [generators](README.md).

## Selection Parameters

Selection parameters control which matches will be instantiated during the evolution. Unlike the
[stopping conditions](StoppingConditionParameters.md), these constraints are local. In other words, the evaluation does
not terminate if any of these constraints are encountered. Instead, only particular matches will be skipped.

### MaxGeneration

Roughly speaking, **generation** corresponds to how many "steps" it took to get to a particular token or event starting
from the initial state. More precisely, the generation of the tokens in the initial state is defined to be zero. The
generation of an event is defined as the maximum of the generations of its inputs plus one. The generation of a token is
the same as the generation of its creator event.

<!--- TODO: add a picture showing generations of tokens and events -->
