Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["AtomicStateSystem"]

SetUsage @ "
AtomicStateSystem[{pattern$1 :> output$1, pattern$2 :> output$2, $$}] is a rewriting system that matches pattern$i to \
entire states and replaces them with output$i.
AtomicStateSystem should be used as the first argument in functions such as GenerateMultihistory.
";

SyntaxInformation[AtomicStateSystem] = {"ArgumentsPattern" -> {rules_}};

declareMultihistoryGenerator[
  generateAtomicStateSystem,
  AtomicStateSystem,
  <|"MaxGeneration" -> {Infinity, "NonNegativeIntegerOrInfinity"},
    "MaxDestroyerEvents" -> {Infinity, "NonNegativeIntegerOrInfinity"}|>,
  {"InputIndex", "RuleIndex"},
  <|"MaxEvents" -> {Infinity, "NonNegativeIntegerOrInfinity"}|>,
  None];

declareMessage[General::atomicStateTokenDeduplicationNotImplemented,
               "Token deduplication is not implemented for Atomic State System."];

$supportedEventOrdering = {"InputIndex", "RuleIndex"};

declareMessage[General::atomicStateEventOrderingNotImplemented,
               "Only " <> ToString[$supportedEventOrdering] <> " event ordering is implemented at this time."];

generateAtomicStateSystem[AtomicStateSystem[rules___], (* BlankNullSequence is needed to catch invalid arg counts *)
                          eventSelection_,
                          tokenDeduplication_,
                          eventOrdering_,
                          stoppingCondition_,
                          init_] := ModuleScope[
  If[tokenDeduplication =!= None, throw[Failure["atomicStateTokenDeduplicationNotImplemented", <||>]]];
  If[eventOrdering =!= {"InputIndex", "RuleIndex"}, throw[Failure["atomicStateEventOrderingNotImplemented", <||>]]];

  toAtomicStateMultihistory[rules] @ generateMultihistory[
    MultisetSubstitutionSystem[toMultisetRules[rules]],
    <|"MaxGeneration" -> eventSelection["MaxGeneration"],
      "MaxDestroyerEvents" -> eventSelection["MaxDestroyerEvents"],
      "MinEventInputs" -> 1,
      "MaxEventInputs" -> 1|>,
    None,
    {"InputCount", "SortedInputTokenIndices", "InputTokenIndices", "RuleIndex", "InstantiationIndex"},
    stoppingCondition,
    {init}]
];

(* Parsing *)

$singleRulePattern = _Rule | _RuleDelayed;
toMultisetRules[atomicRules : $singleRulePattern] := toMultisetRules @ {atomicRules};
toMultisetRules[atomicRules : {$singleRulePattern...}] := Map[List, atomicRules, {2}];
declareMessage[General::invalidAtomicStateRules, "Rules `rules` must be a Rule, a RuleDelayed or a List of them."];
toMultisetRules[atomicRules_] := throw[Failure["invalidAtomicStateRules", <|"rules" -> atomicRules|>]];
toMultisetRules[atomicRules___] /; !CheckArguments[AtomicStateSystem[atomicRules], 1] := throw[Failure[None, <||>]];

(* Conversion to Atomic State Multihistory *)
(* Not done as a normal translation because it should fail if rules have multiple inputs/outputs. *)

toAtomicStateMultihistory[rules_][multisetMultihistory_] :=
  Multihistory[{AtomicStateSystem, 0}, <|"Rules" -> rules, "MultisetMultihistory" -> multisetMultihistory|>];

(* Conversion to Multiset Multihistory *)

declareTypeTranslation[toMultisetMultihistory, {AtomicStateSystem, 0}, {MultisetSubstitutionSystem, 0}];

toMultisetMultihistory[Multihistory[_, data_]] := data["MultisetMultihistory"];
