Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["TokenEventGraph"]
PackageExport["MultihistoryToken"]
PackageExport["MultihistoryEvent"]

SetUsage @ "
TokenEventGraph[multihistory$] yields the token-event graph of multihistory$.
";

Options[TokenEventGraph] = Options[tokenEventGraph] = Options[Graph];

SyntaxInformation[TokenEventGraph] = {
  "ArgumentsPattern" -> {multihistory_, OptionsPattern[]},
  "OptionNames" -> Options[TokenEventGraph][[All, 1]]};

declareRawProperty[tokenEventGraph, {MultisetSubstitutionSystem, 0}, TokenEventGraph];

tokenEventGraph[opts : OptionsPattern[]][multihistory_] /;
    recognizedOptionsQ[TokenEventGraph[opts], TokenEventGraph, {opts}] || throw[Failure[None, <||>]] := ModuleScope[
  (* TODO: needs to be implemented directly *)
  wolframModelObject = SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @ multihistory;
  data = multihistory[[2]];
  Switch[data["Scope"],
    "Histories",
      wolframModelObject["ExpressionsEventsGraph", opts],
    "EventSet",
      wolframModelObject["ExpressionsEventsGraph",
                         GraphLayout -> Replace[OptionValue[GraphLayout], Automatic -> "SpringElectricalEmbedding"],
                         opts]
  ]
];
