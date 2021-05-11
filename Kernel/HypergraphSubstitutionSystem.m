Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["HypergraphSubstitutionSystem"]

SetUsage @ "
HypergraphSubstitutionSystem[$$] $$
";

SyntaxInformation[HypergraphSubstitutionSystem] = {"ArgumentsPattern" -> {rules_}};

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

declareMultihistoryGenerator[
  generateHypergraphSubstitutionSystem,
  HypergraphSubstitutionSystem,
  <|"MaxGeneration" -> {Infinity, "NonNegativeIntegerOrInfinity"},
    "MaxDestroyerEvents" -> {Infinity, "NonNegativeIntegerOrInfinity"}|>,
  Keys @ $eventOrderingFunctions,
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
      rules, maxGeneration, maxDestroyerEvents, maxEvents, maxVertices, maxVertexDegree, maxEdges, init,
      setAtoms, atomsInRules, globalAtoms, globalIndex, mappedSet, localIndices, mappedRules,
      objHandle, objID
    },
    (* @TODO: Check $libSetReplaceAvailable *)

    rules = parseRules[rawRules];
    {maxGeneration, maxDestroyerEvents} = Values @ rawEventSelection;
    parseTokenDeduplication[rawTokenDeduplication];
    parseEventOrdering[Echo @ rawEventOrdering];
    {maxEvents, maxVertices, maxVertexDegree, maxEdges} = Values @ rawStoppingCondition;
    init = parseInit[rawInit];

    (* @TODO: Add comments *)
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
      Catenate[Replace[$eventOrderingFunctions[rawEventOrdering], $orderingFunctionCodes, {2}]],
      0,
      RandomInteger[{0, $maxUInt32}]
    ];

    cpp$setReplace[
      objID,
      stepSpec /@ {
        $maxEvents, $maxGenerationsLocal, $maxFinalVertices, $maxFinalVertexDegree, $maxFinalExpressions} /.
          {Infinity | (_ ? MissingQ) -> $maxInt64}];

    Multihistory[
      {HypergraphSubstitutionSystem, 0},
      <|"Rules" -> rawRules,
        "ExpressionID" -> objID|>]
  ];

(* libSetReplace *)

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

importLibSetReplaceFunction[
  "setExpressions" -> cpp$setExpressions,
  {Integer},     (* set ID *)
  {Integer, 1}]; (* expressions *)

importLibSetReplaceFunction[
  "setEvents" -> cpp$setEvents,
  {Integer},     (* set ID *)
  {Integer, 1}]; (* expressions *)

importLibSetReplaceFunction[
  "maxCompleteGeneration" -> cpp$maxCompleteGeneration,
  {Integer}, (* set ID *)
  Integer];  (* generation *)

importLibSetReplaceFunction[
  "terminationReason" -> cpp$terminationReason,
  {Integer}, (* set ID *)
  Integer];  (* reason *)

(* Encoding *)

$maxInt64 = 2^63 - 1;
$maxUInt32 = 2^32 - 1;

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

(* The following code turns a nested list into a single list, prepending sizes of each sublist. I.e., {{a}, {b, c, d}}
   becomes {2, 1, a, 3, b, c, d}, where the first 2 is the length of the entire list, and 1 and 3 are the lengths of
   sublists. *)
(* This format is used to pass both rules and set data into libSetReplace over LibraryLink *)

encodeNestedLists[list_List] := Flatten @ {Length @ list, encodeNestedLists /@ list};
encodeNestedLists[arg_] := arg;

$orderingFunctionCodes = <|
  $sortedExpressionIDs -> 0,
  $reverseSortedExpressionIDs -> 1,
  $expressionIDs -> 2,
  $ruleIndex -> 3,
  $any -> 4,
  $forward -> 0,
  $backward -> 1
|>;

(* Decoding *)

(* Parsing *)

(** Rules **)

$singleRulePattern = _Rule | _RuleDelayed;
parseRules[rawRules_] := With[{canonicalRules = toCanonicalRules[rawRules]},
  canonicalRules /; MatchQ[canonicalRules, {___ ? simpleRuleQ}]
];
declareMessage[General::invalidHypergraphRules, "Rules `rules` is not a valid hypergraph substitution rule."];
parseRules[rawRules_] := throw[Failure["invalidHypergraphRules", <|"rules" -> rawRules|>]];
parseRules[rawRules___] /; !CheckArguments[HypergraphSubstitutionSystem[rawRules], 1] := throw[Failure[None, <||>]];

(** TokenDeduplication **)

parseTokenDeduplication[None] := None;
(* NOTE: Will this clash with other messages? *)
declareMessage[General::tokenDeduplicationNotImplemented,
              "Token deduplication is not implemented for Hypergraph Substitution System."];
parseTokenDeduplication[_] := throw[Failure["tokenDeduplicationNotImplemented", <||>]];

(** EventOrdering **)

(* @NOTE: Does this require a more elaborate check? *)
parseEventOrdering[ordering_List] := ordering;
(* @NOTE: Is General below correct? *)
(*
declareMessage[General::eventOrderingNotImplemented,
              "Only " <> $supportedEventOrdering <> " event ordering is implemented at this time."]; *)
parseEventOrdering[_] := throw[Failure["eventOrderingNotImplemented", <||>]];

(** Init **)

parseInit[init_ ? hypergraphQ] := init;
declareMessage[General::hypergraphInitNotList,
              "Hypergraph Substitution System init `init` is not a valid hypergraph."];
parseInit[init_] := throw[Failure["hypergraphInitNotList", <|"init" -> init|>]];
