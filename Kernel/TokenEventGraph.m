Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["TokenEventGraph"]
PackageExport["MultihistoryToken"]
PackageExport["MultihistoryEvent"]

SetUsage @ "
TokenEventGraph[multihistory$] yields the token-event graph of a multihistory$.
* Token-event graph is a bipartite graph showing input and output tokens of every event.
";

Options[TokenEventGraph] = Options[tokenEventGraph] = Normal @ Merge[{Options[Graph], {Background -> Automatic}}, Last];

SyntaxInformation[TokenEventGraph] = {
  "ArgumentsPattern" -> {multihistory_, OptionsPattern[]},
  "OptionNames" -> Options[TokenEventGraph][[All, 1]]};

declareRawProperty[tokenEventGraph, SetReplaceType[MultisetSubstitutionSystem, 0], TokenEventGraph];

tokenEventGraph[opts : OptionsPattern[]][Multihistory[_, data_]] := ModuleScope[
  checkIfKnownOptions[tokenEventGraph, {opts}];
  tokenCount = data["Expressions"]["Length"];
  eventCount = data["EventOutputs"]["Length"] - 1;
  inputsToEvents = Catenate[Thread /@ Thread[
    Map[MultihistoryToken, Rest @ Normal[data["EventInputs"]], {2}] -> MultihistoryEvent /@ Range[eventCount]]];
  eventsToOutputs = Catenate[Thread /@ Thread[
    MultihistoryEvent /@ Range[eventCount] -> Map[MultihistoryToken, Rest @ Normal[data["EventOutputs"]], {2}]]];
  vertexList = Join[MultihistoryToken /@ Range[tokenCount], MultihistoryEvent /@ Range[eventCount]];
  result = Graph[
    vertexList,
    Join[inputsToEvents, eventsToOutputs],
    VertexStyle -> parseVertexStyleRules[data][OptionValue[VertexStyle]],
    EdgeStyle -> Replace[OptionValue[EdgeStyle], Automatic -> style[$lightTheme][$causalEdgeStyle]],
    VertexLabels -> parseLabelRules[data][OptionValue[VertexLabels]],
    GraphLayout -> Replace[
      OptionValue[GraphLayout],
      Automatic :> {
        "LayeredDigraphEmbedding",
        "VertexLayerPosition" -> Replace[
          vertexList,
          parseElementRules[data, 0, 0][
            {_MultihistoryToken -> -(2 * "Generation"), _MultihistoryEvent -> -(2 * "Generation" - 1)}],
          {1}]}],
    Background -> Replace[OptionValue[Background], Automatic -> style[$lightTheme][$tokenEventGraphBackground]],
    opts];
  If[!GraphQ[result], throw[Failure[None, <||>]]];
  result
];

declareMessage[TokenEventGraph::unexpectedArguments,
               "Only Multihistory and options are expected as TokenEventGraph arguments in `expr`"];
tokenEventGraph[___][_] := throw[Failure["unexpectedArguments", <||>]];

parseVertexStyleRules[data_][Automatic] := parseVertexStyleRules[data] @ {};

parseVertexStyleRules[data_][arg_] :=
  parseElementRules[data, style[$lightTheme][$tokenVertexStyle], style[$lightTheme][$eventVertexStyle]][arg];

parseLabelRules[data_][Automatic] := parseLabelRules[data] @ {
  _MultihistoryToken -> Placed[{"Content", Row[{"Index: ", "Index"}]}, {After, Tooltip}],
  _MultihistoryEvent ->
    Placed[{If[Length[data["Rules"]] > 1, "RuleIndex", ""], Row[{"Index: ", "Index"}]}, {After, Tooltip}]
};

parseLabelRules[data_][arg_] := parseElementRules[data, "", ""][arg];

parseElementRules[data_, default__][arg_] := parseElementRules[data, default][_ -> arg];

parseElementRules[data_, default__][rule : _Rule | _RuleDelayed] := parseElementRules[data, default][{rule}];

tokenPropertyRules[data_, n_] := <|
  "Index" -> n,
  "Content" :> data["Expressions"]["Part", n],
  "RuleIndex" -> "",
  "Generation" :> data["EventGenerations"]["Part", data["ExpressionCreatorEvents"]["Part", n]]
|>;

eventPropertyRules[data_, n_] := <|
  "Index" -> n,
  "Content" :>
    Rule @@ (data["Expressions"]["Part", #] & /@ data[#]["Part", n + 1] & /@ {"EventInputs", "EventOutputs"}),
  "RuleIndex" :> data["EventRuleIndices"]["Part", n + 1],
  "Generation" :> data["EventGenerations"]["Part", n + 1]
|>;

parseElementRules[data_, defaultToken_, defaultEvent_][rules : {(_Rule | _RuleDelayed)...}] :=
  #1[n_] :> Replace[#1[n], Append[rules /. #2[data, n], _ -> #3]] & @@@
    {{MultihistoryToken, tokenPropertyRules, defaultToken}, {MultihistoryEvent, eventPropertyRules, defaultEvent}};
