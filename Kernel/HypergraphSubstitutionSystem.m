Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["HypergraphSubstitutionSystem"]

SetUsage @ "
HypergraphSubstitutionSystem[$$] $$
";

SyntaxInformation[HypergraphSubstitutionSystem] = {"ArgumentsPattern" -> {rules_}};

declareMultihistoryGenerator[
  generateHypergraphSubstitutionSystem,
  HypergraphSubstitutionSystem,
  <|"MaxGeneration" -> {Infinity, "NonNegativeIntegerOrInfinity"},
    "MaxDestroyerEvents" -> {Infinity, "NonNegativeIntegerOrInfinity"}|>,
  (* HACK *) {"OldestEdge", "LeastOldEdge", "LeastRecentEdge", "NewestEdge", "RuleOrdering", "ReverseRuleOrdering", "RuleIndex", "ReverseRuleIndex", "Random", "Any"},
  <|"MaxEvents" -> {Infinity, "NonNegativeIntegerOrInfinity"},
    "MaxVertices" -> {Infinity, "NonNegativeIntegerOrInfinity"},
    "MaxVertexDegree" -> {Infinity, "NonNegativeIntegerOrInfinity"},
    "MaxEdges" -> {Infinity, "NonNegativeIntegerOrInfinity"}|>];

generateHypergraphSubstitutionSystem[HypergraphSubstitutionSystem[rawRules___],
                                    rawEventSelection_,
                                    rawTokenDeduplication_,
                                    rawEventOrdering_,
                                    rawStoppingCondition_,
                                    rawInit_] :=
  Module[{
      rules, maxGeneration, maxDestroyerEvents, eventOrdering,
      maxEvents, maxVertices, maxVertexDegree, maxEdges, init,
      setAtoms, atomsInRules, globalAtoms, globalIndex, mappedSet, localIndices, mappedRules,
      objHandle, objID
    },
    (* TODO(daniel): Check $libSetReplaceAvailable *)

    rules = parseRules[rawRules];
    {maxGeneration, maxDestroyerEvents} = Values @ rawEventSelection;
    parseTokenDeduplication[rawTokenDeduplication];
    eventOrdering = parseEventOrdering[rawEventOrdering];
    {maxEvents, maxVertices, maxVertexDegree, maxEdges} = Values @ rawStoppingCondition;
    init = parseInit[rawInit];

    setAtoms = Hold /@ Union[Catenate[init]];
    atomsInRules = ruleAtoms /@ rules;
    globalAtoms = Union @ Join[setAtoms, Catenate[atomsInRules[[All, 1]]]];
    globalIndex = AssociationThread[globalAtoms -> Range[Length[globalAtoms]]];
    mappedSet = Map[globalIndex, Map[Hold, init, {2}], {2}];
    localIndices = AssociationThread[#[[2]] -> - Range[Length[#[[2]]]]] & /@ atomsInRules;
    mappedRules = Table[
      ruleAtomsToIndices[
        rules[[K]],
        globalIndex,
        localIndices[[K]]],
      {K, Length[rules]}];

    objHandle = CreateManagedLibraryExpression["SetReplace", managedHypergraphSubstitutionSystem];
    objID = ManagedLibraryExpressionID[objHandle, "SetReplace"];
    (* @TODO: Arguments below have missing functionality *)
    cpp$setInitialize[
      objID,
      encodeNestedLists[List @@@ mappedRules],
      ConstantArray[Replace[maxDestroyerEvents, {_ -> 0}], Length @ rules],
      encodeNestedLists[mappedSet],
      Replace[maxDestroyerEvents, Infinity -> $maxInt64],
      Catenate[Replace[eventOrdering, $orderingFunctionCodes, {2}]],
      0,
      RandomInteger[{0, $maxUInt32}]
    ];

    cpp$setReplace[
      objID,
      {maxEvents, maxGeneration, maxVertices, maxVertexDegree, maxEdges} /. {Infinity | (_ ? MissingQ) -> $maxInt64}];

    Multihistory[
      {HypergraphSubstitutionSystem, 0},
      <|"Rules" -> rawRules,
        "ObjectHandle" -> objHandle,
        "GlobalIndex" -> globalIndex|>]
  ];

(* Parsing *)

(** Rules **)

parseRules[rawRules_] /; wolframModelRulesSpecQ[rawRules] :=
  Module[{patternRules, canonicalRules},
    patternRules = fromRulesSpec[rawRules];
    canonicalRules = toCanonicalRules[patternRules];
    canonicalRules /; MatchQ[canonicalRules, {___ ? simpleRuleQ}]
  ];
declareMessage[General::invalidHypergraphRules, "Rules `rules` is not a valid hypergraph substitution rule."];
parseRules[rawRules_] := throw[Failure["invalidHypergraphRules", <|"rules" -> rawRules|>]];
parseRules[rawRules___] /; !CheckArguments[HypergraphSubstitutionSystem[rawRules], 1] := throw[Failure[None, <||>]];

(** TokenDeduplication **)

parseTokenDeduplication[None] := None;
(* NOTE(daniel): Will this clash with other messages? *)
declareMessage[General::tokenDeduplicationNotImplemented,
              "Token deduplication is not implemented for Hypergraph Substitution System."];
parseTokenDeduplication[_] := throw[Failure["tokenDeduplicationNotImplemented", <||>]];

(** EventOrdering **)

(* NOTE(daniel): Does this require a more elaborate check? *)
parseEventOrdering[ordering_] :=
  With[{parsed = parseEventOrderingFunction[HypergraphSubstitutionSystem, ordering]},
    parsed /; parsed =!= $Failed
  ];
(* NOTE(daniel): General is used below so that it also works for GenerateSingleHistory or GenerateAllHistory *)
(*
declareMessage[General::eventOrderingNotImplemented,
              "Only " <> $supportedEventOrdering <> " event ordering is implemented at this time."]; *)
parseEventOrdering[_] := throw[Failure["eventOrderingNotImplemented", <||>]];

(** Init **)

parseInit[init_ ? hypergraphQ] := init;
declareMessage[General::hypergraphInitNotList,
              "Hypergraph Substitution System init `init` is not a valid hypergraph."];
parseInit[init_] := throw[Failure["hypergraphInitNotList", <|"init" -> init|>]];

(* Encoding *)

(* Decoding *)
