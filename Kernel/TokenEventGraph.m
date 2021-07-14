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
(* TODO: disable Placed[After] for non-automatic layouts *)
Options[TokenEventGraph] = Options[tokenEventGraph] = Options[Graph];

SyntaxInformation[TokenEventGraph] = {
  "ArgumentsPattern" -> {multihistory_, OptionsPattern[]},
  "OptionNames" -> Options[TokenEventGraph][[All, 1]]};

declareRawProperty[tokenEventGraph, SetReplaceType[MultisetSubstitutionSystem, 0], TokenEventGraph];

(*
VertexLabels -> Replace[OptionValue[VertexLabels], Automatic -> {
      MultihistoryToken[n_] :> Placed[{data["Expressions"]["Part", n], Row[{"Index: ", n}]}, {After, Tooltip}],
      If[Length[data["Rules"]] > 1, MultihistoryEvent[n_] :> data["EventRuleIndices"]["Part", n + 1]]}]
*)

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
    (* TODO: add a list of vertices *)
    Join[inputsToEvents, eventsToOutputs],
    (* TODO: rename styles in SetReplaceStyleData *)
    (* TODO: implement layout *)
    VertexStyle -> Replace[OptionValue[VertexStyle], Automatic -> {
      _MultihistoryToken -> style[$lightTheme][$expressionVertexStyle],
      _MultihistoryEvent -> style[$lightTheme][$causalGraphVertexStyle]}],
    EdgeStyle -> Replace[OptionValue[EdgeStyle], Automatic -> style[$lightTheme][$causalGraphEdgeStyle]],
    VertexLabels -> parseVertexLabels[data][OptionValue[VertexLabels]],
    opts]
];

parseVertexLabels[data_][Automatic] := {
  MultihistoryToken[n_] :> Placed[{data["Expressions"]["Part", n], Row[{"Index: ", n}]}, {After, Tooltip}],
  If[Length[data["Rules"]] > 1, MultihistoryEvent[n_] :> data["EventRuleIndices"]["Part", n + 1]]};

parseVertexLabels[data_][rules_List] := parseVertexLabels[data] /@ rules;

parseVertexLabels[data_][func_Function] := parseVertexLabels[data][_ -> func];

parseVertexLabels[data_][(ruleSymbol : Rule | RuleDelayed)[pattern_, func_Function]] := ruleSymbol[
  Pattern[vertex, pattern],
  generateLabel[data, func][vertex]];

generateLabel[data_, func_][MultihistoryToken[n_]] := func[<|
  "Index" :> n,
  "TokenContents" :> data["Expressions"]["Part", n],
  "RuleIndex" :> ""|>];

generateLabel[data_, func_][MultihistoryEvent[n_]] := func[<|
  "Index" :> n,
  "TokenContents" :> "",
  "RuleIndex" :> data["EventRuleIndices"]["Part", n + 1]|>];

parseVertexLabels[data_][arg_] := arg;
