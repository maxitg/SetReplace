Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["TokenEventGraph"]
PackageExport["MultihistoryToken"]
PackageExport["MultihistoryEvent"]

SetUsage @ "
TokenEventGraph[multihistory$] yields the token-event graph of a multihistory$.
* Token-event graph is a bipartite graph showing input and output tokens of every event.
";

(* TODO: automatically create tooltip labels *)
(* TODO: Automatic labels should do Placed[#, After] & *)
Options[TokenEventGraph] = Options[tokenEventGraph] = Options[Graph];

SyntaxInformation[TokenEventGraph] = {
  "ArgumentsPattern" -> {multihistory_, OptionsPattern[]},
  "OptionNames" -> Options[TokenEventGraph][[All, 1]]};

declareRawProperty[tokenEventGraph, SetReplaceType[MultisetSubstitutionSystem, 0], TokenEventGraph];

(* TODO: check arguments count *)
(* TODO: check option correctness *)
tokenEventGraph[opts : OptionsPattern[]][Multihistory[_, data_]] := ModuleScope[
  inputsToEvents = Catenate[Thread /@ Thread[
    Map[MultihistoryToken, Rest @ Normal[data["EventInputs"]], {2}] ->
      MultihistoryEvent /@ Range[data["EventInputs"]["Length"] - 1]]];
  eventsToOutputs = Catenate[Thread /@ Thread[
    MultihistoryEvent /@ Range[data["EventOutputs"]["Length"] - 1] ->
      Map[MultihistoryToken, Rest @ Normal[data["EventOutputs"]], {2}]]];
  Graph[
    Join[inputsToEvents, eventsToOutputs],
    opts,
    (* TODO: rename styles in SetReplaceStyleData *)
    (* TODO: implement layout *)
    VertexStyle -> Replace[OptionValue[VertexStyle], Automatic -> {
      _MultihistoryToken -> style[$lightTheme][$expressionVertexStyle],
      _MultihistoryEvent -> style[$lightTheme][$causalGraphVertexStyle]}],
    EdgeStyle -> Replace[OptionValue[EdgeStyle], Automatic -> style[$lightTheme][$causalGraphEdgeStyle]]]
];
