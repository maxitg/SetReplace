Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["HypergraphSubstitutionSystem"]

importLibSetReplaceFunction[
  "setInitialize" -> cpp$setInitialize,
  {Integer,                  (* set ID *)
   {Integer, 1, "Constant"}, (* rules *)
   {Integer, 1, "Constant"}, (* event selection functions for rules *)
   {Integer, 1, "Constant"}, (* initial set *)
   Integer,                  (* event selection function *)
   {Integer, 1, "Constant"}, (* ordering function index, forward / reverse, function, forward / reverse, ... *)
   Integer,                  (* event deduplication *)
   Integer},                 (* random seed *)
  "Void"];

importLibSetReplaceFunction[
  "setReplace" -> cpp$setReplace,
  {Integer,                   (* set ID *)
   {Integer, 1, "Constant"}}, (* {events, generations, atoms, max expressions per atom, expressions} *)
  "Void"];

generateHypergraphSubstitutionSystem[HypergraphSubstitutionSystem[rawRules___],
                                    rawEventSelection_,
                                    rawTokenDeduplication_,
                                    rawEventOrdering_,
                                    rawStoppingCondition_,
                                    rawInit_] :=
  Module[{
      rules, maxGeneration, maxDestroyerEvents, eventOrdering,
      timeConstraint, maxEvents, maxVertices, maxVertexDegree, maxEdges, init,
      objHandle, objID, globalIndex, terminationReason
    },
    (* TODO(daniel): Check $libSetReplaceAvailable *)
    If[!$libSetReplaceAvailable, Return @ $Failed];

    rules = parseRules[rawRules];
    {maxGeneration, maxDestroyerEvents} = Values @ rawEventSelection;
    parseTokenDeduplication[rawTokenDeduplication];
    eventOrdering = parseEventOrdering[rawEventOrdering];
    {timeConstraint, maxEvents, maxVertices, maxVertexDegree, maxEdges} = Values @ rawStoppingCondition;
    init = parseInit[rawInit];

    objHandle = CreateManagedLibraryExpression["SetReplace", SetReplace`HypergraphSubstitutionSystemHandle];
    objID = ManagedLibraryExpressionID[objHandle, "SetReplace"];

    globalIndex = hypergraphSubstitutionSystemInit[objID, rules, init, maxDestroyerEvents, eventOrdering];

    terminationReason = Undefined;
    TimeConstrained[
      CheckAbort[
        cpp$setReplace[
          objID,
          Replace[{maxEvents, maxGeneration, maxVertices, maxVertexDegree, maxEdges},
                  {Infinity | (_ ? MissingQ) -> $maxInt64},
                  {1}]]
      ,
        (* TODO(daniel): Handle returnOnAbortQ. Perhaps using Block? *)
        If[!returnOnAbortQ, Abort[], terminationReason = $Aborted]
      ]
    ,
      timeConstraint,
      If[!returnOnAbortQ, Return[$Aborted], terminationReason = $timeConstraint]
    ];

    (* NOTE(daniel): We either need to save global index or the initial state to convert it to WMEvolutionObject *)
    Multihistory[
      {HypergraphSubstitutionSystem, 0},
      <|"Rules" -> rawRules,
        "GlobalAtomsIndexMap" -> globalIndex,
        "ObjectHandle" -> objHandle,
        "TerminationReason" -> terminationReason|>]
  ];

hypergraphSubstitutionSystemInit[objID_, rules_, init_, maxDestroyerEvents_, eventOrdering_] :=
  Module[{setAtoms, atomsInRules, globalAtoms, globalIndex, mappedSet, localIndices, mappedRules},
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

    (* NOTE(daniel): Arguments below have missing functionality *)
    cpp$setInitialize[
      objID,
      encodeNestedLists[List @@@ mappedRules],
      Echo @ ConstantArray[Replace[maxDestroyerEvents, {_ -> 0}], Length @ rules],
      Echo @ encodeNestedLists[mappedSet],
      Echo @ Replace[maxDestroyerEvents, Infinity -> $maxInt64],
      Catenate[Replace[eventOrdering, $orderingFunctionCodes, {2}]],
      0,
      RandomInteger[{0, $maxUInt32}]
    ];

    globalIndex
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

$eventOrderingFunctions = <|
  "OldestEdge" -> {$sortedExpressionIDs, $forward},  (* SortedInputTokenIndices *)
  "LeastOldEdge" -> {$sortedExpressionIDs, $backward},
  "LeastRecentEdge" -> {$reverseSortedExpressionIDs, $forward},
  "NewestEdge" -> {$reverseSortedExpressionIDs, $backward},
  "RuleOrdering" -> {$expressionIDs, $forward},  (* InputTokenIndices *)
  "ReverseRuleOrdering" -> {$expressionIDs, $backward},
  "RuleIndex" -> {$ruleIndex, $forward},  (* RuleIndex *)
  "ReverseRuleIndex" -> {$ruleIndex, $backward},
  "Random" -> Nothing, (* Random is done automatically in C++ if no more sorting is available *)
  "Any" -> {$any, $forward} (* OrderingDirection here doesn't do anything *)
|>;

$orderingFunctionCodes = <|
  $sortedExpressionIDs -> 0,
  $reverseSortedExpressionIDs -> 1,
  $expressionIDs -> 2,
  $ruleIndex -> 3,
  $any -> 4,
  $forward -> 0,
  $backward -> 1
|>;

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

(* The following code turns a nested list into a single list, prepending sizes of each sublist. I.e., {{a}, {b, c, d}}
   becomes {2, 1, a, 3, b, c, d}, where the first 2 is the length of the entire list, and 1 and 3 are the lengths of
   sublists. *)
(* This format is used to pass both rules and set data into libSetReplace over LibraryLink *)

encodeNestedLists[list_List] := Flatten @ {Length @ list, encodeNestedLists /@ list};
encodeNestedLists[arg_] := arg;

(* Check if we have simple anonymous rules and use C++ library in that case *)

ruleAtoms[left_ :> right_] := ModuleScope[
  leftVertices = Union @ Catenate[left[[1]]];
  leftAtoms = Select[leftVertices, AtomQ];
  patterns = Complement[leftVertices, leftAtoms];
  patternSymbols = Map[Hold, patterns, {2}][[All, 1]];
  createdAtoms = Map[Hold, Hold[right], {3}][[1, 1]];
  rightAtoms = Complement[
    Union @ Catenate @ Map[Hold, Hold[right], {4}][[1, 2]],
    Join[patternSymbols, createdAtoms]];
  (* {global, local} *)
  {Union @ Join[Hold /@ leftAtoms, rightAtoms],
    Union @ Join[patternSymbols, createdAtoms]}
];

ruleAtomsToIndices[left_ :> right_, globalIndex_, localIndex_] := ModuleScope[
  newLeft = Replace[
    left[[1]],
    {x_ ? AtomQ :> globalIndex[Hold[x]],
      x_Pattern :> localIndex[Map[Hold, x, {1}][[1]]]},
    {2}];
  newRight = Replace[
    Map[Hold, Hold[right], {4}][[1, 2]],
    x_ :> Lookup[localIndex, x, globalIndex[x]],
    {2}];
  newLeft -> newRight
];

(* Decoding *)

(* HypergraphSubstitutionSystem *)

SetUsage @ "
HypergraphSubstitutionSystem[$$] is a rewriting system that replaces hyperedges \
with elements matching pattern$1, pattern$2, $$ by a list produced by evaluating output$, where pattern$i can be matched in \
any order.
";

SyntaxInformation[HypergraphSubstitutionSystem] = {"ArgumentsPattern" -> {rules_}};

declareMultihistoryGenerator[
  generateHypergraphSubstitutionSystem,
  HypergraphSubstitutionSystem,
  <|"MaxGeneration" -> {Infinity, "NonNegativeIntegerOrInfinity"},
    "MaxDestroyerEvents" -> {Infinity, "NonNegativeIntegerOrInfinity"}|>,
  Keys @ $eventOrderingFunctions,
  <|"TimeConstraint" -> {Infinity, "NonNegativeIntegerOrInfinity"},
    "MaxEvents" -> {Infinity, "NonNegativeIntegerOrInfinity"},
    "MaxVertices" -> {Infinity, "NonNegativeIntegerOrInfinity"},
    "MaxVertexDegree" -> {Infinity, "NonNegativeIntegerOrInfinity"},
    "MaxEdges" -> {Infinity, "NonNegativeIntegerOrInfinity"}|>];
