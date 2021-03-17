Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["GenerateMultihistory"]
(* TODO: Implement SetReplaceTypeGenerator[], SetReplaceGeneratorType[], SetReplaceSystems[] *)
(* TODO: Also implement functions to look up available selection, deduplication, ordering and stopping keys for generators *)

SetUsage @ "
GenerateMultihistory[system$, eventSelectionSpec$, tokenDeduplicationSpec$, eventOrderingSpec$, \
stoppingConditionSpec$][init$] yields a Multihistory object of the evaluation of a specified system$.
A list of all supported systems can be obtained with SetReplaceSystems[].
eventSelectionSpec$ is an Association defining constraints on the events that will be generated. The keys that can be \
used depend on the system$, some examples include 'MaxGeneration' and 'MaxDestroyerEvents'. A list for a particular \
system can be obtained with EventSelectionParameters[Head[system$]].
tokenDeduplicationSpec$ can be set to None or All.
eventOrderingSpec$ can be set to 'UniformRandom', 'Any', or a list of partial event ordering functions. The list of \
supported functions can be obtained with EventOrderingFunctions[Head[system$]].
stoppingConditionSpec$ is an Association specifying conditions that, if satisfied, will cause the evaluation to stop \
immediately. The list of choices can be obtained with StoppingConditionParameters[Head[system$]].
";
