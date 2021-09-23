Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["HypergraphSubstitutionSystem"]

PackageScope["generateHypergraphSubstitutionSystem"]

importLibSetReplaceFunction[
  "hypergraphSubstitutionSystemInitialize" -> cpp$hypergraphSubstitutionSystemInitialize,
  {Integer,                  (* set ID *)
   {Integer, 1, "Constant"}, (* rules *)
   {Integer, 1, "Constant"}, (* event selection functions for rules *)
   {Integer, 1, "Constant"}, (* initial set *)
   Integer,                  (* event selection function *)
   {Integer, 1, "Constant"}, (* ordering function index, forward / reverse, function, forward / reverse, ... *)
   Integer,                  (* event deduplication *)
   (* random seed, passed as two numbers because LibraryLink does not support unsigned ints *)
   {Integer, 1, "Constant"}},
  "Void"];

importLibSetReplaceFunction[
  "hypergraphSubstitutionSystemReplace" -> cpp$hypergraphSubstitutionSystemReplace,
  {Integer,                   (* set ID *)
   {Integer, 1, "Constant"},  (* {events, generations, atoms, max expressions per atom, expressions} *)
   Real},                     (* time constraint *)
  "Void"];

$unset = -1;
$maxUInt32 = 2^32 - 1;

generateHypergraphSubstitutionSystem[HypergraphSubstitutionSystem[rawRules___],
                                    rawEventSelection_,
                                    rawTokenDeduplication_,
                                    rawEventOrdering_,
                                    rawStoppingCondition_,
                                    rawInit_] :=
  Module[{
      rules, maxGeneration, maxDestroyerEvents, eventSeparation, eventOrdering,
      timeConstraint, maxEvents, maxVertices, maxVertexDegree, maxEdges, init,
      objHandle, objID, globalAtoms
    },
    (* TODO(daniel): Improve checking of $libSetReplaceAvailable *)
    If[!$libSetReplaceAvailable, Return @ $Failed];

    rules = parseRules[rawRules];
    {maxGeneration, maxDestroyerEvents, eventSeparation} = Values @ rawEventSelection;
    eventOrdering = parseEventOrdering[rawEventOrdering];
    {timeConstraint, maxEvents, maxVertices, maxVertexDegree, maxEdges} = Values @ rawStoppingCondition;
    init = parseInit[rawInit];

    objHandle = CreateManagedLibraryExpression["SetReplace", SetReplace`HypergraphSubstitutionSystemHandle];
    objID = ManagedLibraryExpressionID[objHandle, "SetReplace"];

    globalAtoms = hypergraphSubstitutionSystemInit[objID,
                                                   rules,
                                                   init,
                                                   maxDestroyerEvents,
                                                   eventOrdering,
                                                   rawTokenDeduplication,
                                                   eventSeparation];

    cpp$hypergraphSubstitutionSystemReplace[
      objID,
      {maxEvents, maxGeneration, maxVertices, maxVertexDegree, maxEdges} /. {Infinity | (_ ? MissingQ) -> $unset},
      timeConstraint /. Infinity -> $unset];

    (* NOTE(daniel): We either need to save global index or the initial state to convert it to WMEvolutionObject *)
    Multihistory[
      {HypergraphSubstitutionSystem, 0},
      <|"Rules" -> rawRules,
        "GlobalAtoms" -> globalAtoms,
        "ObjectHandle" -> objHandle|>]
  ];

hypergraphSubstitutionSystemInit[objID_,
                                 rules_,
                                 init_,
                                 maxDestroyerEvents_,
                                 eventOrdering_,
                                 tokenDeduplication_,
                                 eventSelection_] :=
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

    cpp$hypergraphSubstitutionSystemInitialize[
      objID,
      encodeNestedLists[List @@@ mappedRules],
      ConstantArray[eventSelection /. {"Any" -> 0, "Spacelike" -> 1}, Length @ rules],
      encodeNestedLists[mappedSet],
      Replace[maxDestroyerEvents, Infinity -> $unset],
      Catenate[Replace[eventOrdering, $orderingFunctionCodes, {2}]],
      $tokenDeduplicationCodes[tokenDeduplication],
      IntegerDigits[RandomInteger[{0, $maxUInt32}], 2^16, 2]
    ];

    globalAtoms
  ];

(* Parsing *)

(** Rules **)

(* parseRules[anonymousRules_ ? anonymousRulesQ] := ToPatternRules[anonymousRules]; *)
parseRules[rawRules_] /; setReplaceRulesQ[rawRules] :=
  Module[{canonicalRules},
    canonicalRules = toCanonicalRules[rawRules];
    canonicalRules /; MatchQ[canonicalRules, {___ ? simpleRuleQ}]
  ];
declareMessage[General::invalidHypergraphRules, "Rules `rules` is not a valid hypergraph substitution rule."];
parseRules[rawRules_] := throw[Failure["invalidHypergraphRules", <|"rules" -> rawRules|>]];
parseRules[rawRules___] /; !CheckArguments[HypergraphSubstitutionSystem[rawRules], 1] := throw[Failure[None, <||>]];

(** TokenDeduplication **)

(** EventOrdering **)

$eventOrderingFunctions = {
  "SortedInputTokenIndices" -> {$sortedExpressionIDs, $forward},
  -"SortedInputTokenIndices" -> {$sortedExpressionIDs, $backward},
  "ReverseSortedInputTokenIndices" -> {$reverseSortedExpressionIDs, $forward},
  -"ReverseSortedInputTokenIndices" -> {$reverseSortedExpressionIDs, $backward},
  "InputTokenIndices" -> {$expressionIDs, $forward},
  -"InputTokenIndices" -> {$expressionIDs, $backward},
  "RuleIndex" -> {$ruleIndex, $forward},
  -"RuleIndex" -> {$ruleIndex, $backward},
  "Any" -> {$any, $forward} (* OrderingDirection here doesn't do anything *)
};

parseEventOrdering[ordering : {(Alternatives @@ Keys[$eventOrderingFunctions])...}] /;
  !FreeQ[ordering, "Random"] :=
  parseEventOrdering[ordering[[1 ;; FirstPosition[ordering, "Random"][[1]] - 1]]];

parseEventOrdering[ordering : {(Alternatives @@ Keys[$eventOrderingFunctions])...}] /;
    !FreeQ[ordering, "Any"] && FirstPosition[ordering, "Any"][[1]] != Length[ordering] :=
    parseEventOrdering[ordering[[1 ;; FirstPosition[ordering, "Any"][[1]]]]];

parseEventOrdering[ordering : {(Alternatives @@ Keys[$eventOrderingFunctions])...}] /;
    FreeQ[ordering, "Random"] :=
  Replace[ordering, $eventOrderingFunctions, {1}];

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

$orderingFunctionCodes = <|
  $sortedExpressionIDs -> 0,
  $reverseSortedExpressionIDs -> 1,
  $expressionIDs -> 2,
  $ruleIndex -> 3,
  $any -> 4,
  $forward -> 0,
  $backward -> 1
|>;

$tokenDeduplicationCodes = <|
  None -> 0,
  "SameInputSetIsomorphicOutputs" -> 1
|>;

(* HypergraphSubstitutionSystem *)

SetUsage @ "
HypergraphSubstitutionSystem[$$] is a rewriting system that replaces hyperedges \
with elements matching pattern$1, pattern$2, $$ by a list produced by evaluating output$, where pattern$i can be \
matched in any order.
";

SyntaxInformation[HypergraphSubstitutionSystem] = {"ArgumentsPattern" -> {rules_}};

declareMultihistoryGenerator[
  generateHypergraphSubstitutionSystem,
  HypergraphSubstitutionSystem,
  <|"MaxGeneration"      -> {Infinity, "NonNegativeIntegerOrInfinity"},
    "MaxDestroyerEvents" -> {Infinity, "NonNegativeIntegerOrInfinity"},
    "EventSeparation"    -> {"Spacelike", {"Spacelike", "Any"}}|>,
  Keys @ $eventOrderingFunctions,
  <|"TimeConstraint"  -> {Infinity, "PositiveNumberOrInfinity"},
    "MaxEvents"       -> {Infinity, "NonNegativeIntegerOrInfinity"},
    "MaxVertices"     -> {Infinity, "NonNegativeIntegerOrInfinity"},
    "MaxVertexDegree" -> {Infinity, "NonNegativeIntegerOrInfinity"},
    "MaxEdges"        -> {Infinity, "NonNegativeIntegerOrInfinity"}|>,
  Keys @ $tokenDeduplicationCodes];
