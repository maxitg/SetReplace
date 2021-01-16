Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageScope["setSubstitutionSystem$wl"]

(* This is the implementation of setSubstitutionSystem in Wolfram Language. Works better with larger vertex degrees,
   but is otherwise much slower. Supports arbitrary pattern rules with conditions. Does not support multiway systems. *)

(* We are going to transform set substitution rules into a list of n! normal rules, where elements of the input subset
   are arranged in every possible order with blank null sequences in between. *)

allLeftHandSidePermutations[input_Condition :> output_List] := ModuleScope[
  inputLength = Length @ input[[1]];

  inputPermutations = Permutations @ input[[1]];
  heldOutput = Thread @ Hold @ output;

  With[{right = heldOutput, condition = input[[2]]}, (* condition is already held before it's passed here *)
    # /; condition :> right & /@ inputPermutations] /. Hold[expr_] :> expr
];

(* Now, if there are new vertices that need to be created, we will disassemble the Module remembering which variables
   it applies to, and then reassemble it for the output. *)

allLeftHandSidePermutations[input_Condition :> output_Module] := ModuleScope[
  ruleInputOriginal = input[[1]];
  ruleCondition = heldPart[input, 2];
  heldModule = mapHold[output, {0, 1}];
  moduleInputContents = heldModule[[1, 2]];
  With[{ruleInputFinal = #[[1]],
      moduleArguments = heldModule[[1, 1]],
      moduleOutputContents = (Hold /@ #)[[2]]},
    ruleInputFinal :> Module[moduleArguments, moduleOutputContents]
  ] & /@ allLeftHandSidePermutations[
      ruleInputOriginal /; ruleCondition :> Evaluate @ moduleInputContents /.
        Hold[expr_] :> expr] //.
    Hold[expr_] :> expr
];

(* toNormalRules turns set substitution rules into normal Wolfram Language rules for use in, i.e., Replace. *)

(* If there are multiple rules, we want to turn them into one because we need to maintain a specific
   (oldest-expressions-first) evolution order. *)

(* The idea is to find the shortest matching sequence from the beginning of the set using Shortest of Alternatives
   among all rules arranged in all possible orders. *)

(* For example, the two rules
     {{{a_, b_}} /; True :> Module[{c}, {{a, c}, {c, b}}],
     {{a_, b_}, {b_, c_}} /; True :> Module[{}, {{a, c}}]}
   would turn into something like
     {match : Shortest[(rule1 : PatternSequence[untouched1___, {a_, b_}] /; True) |
                       (rule2 : PatternSequence[untouched1___, {a_, b_}, untouched2___, {b_, c_}] /; True) |
                       (rule2 : PatternSequence[untouched1___, {b_, c_}, untouched2___, {a_, b_}] /; True)],
      untouched3___} :>
     Catenate[{{untouched1, untouched2, untouched3},
               Replace[{rule1}, {match} :> Module[{c}, {{a, c}, {c, b}}]],
               Replace[{rule2}, {match} :> Module[{}, {{a, c}}]]}] *)

(* untouched are the expressions that were not used in this event. Note that the Replace[...] arguments of Catenate
   effectively choose which rule should be used because all but one of the rule patterns will be empty sequences. *)

toNormalRules[rules_List] := ModuleScope[
  ruleNames = Table[Unique["rule", {Temporary}], Length[rules]];
  separateNormalRules = allLeftHandSidePermutations /@ rules;
  longestRuleLength = Max[Map[Length, separateNormalRules[[All, All, 1, 1]], {2}]];
  untouchedNames = Table[Unique["untouched", {Temporary}], longestRuleLength + 1];
  finalMatchName = Unique["match", {Temporary}];
  input = With[{match = finalMatchName}, List[
    match : Shortest[Alternatives @@ Catenate[Transpose @ PadRight[
      MapIndexed[
        With[{patternName = ruleNames[[#2[[1]]]]},
          Function[{patternContent, condition},
            inertCondition[patternName : patternContent, condition] /. inertCondition -> Condition] @@@ #] &,
        Map[
          With[{input = #[[1]], condition = heldPart[#, 2]},
            PatternSequence @@ If[input == {}, input, Riffle[
              input,
              Pattern[#, ___] & /@ untouchedNames,
              {1, 2 Length[input] - 1, 2}]] /; condition
          ] &,
          separateNormalRules[[All, All, 1]],
          {2}]],
      Automatic,
      nothing] /. nothing -> Nothing]],
    With[{lastPatternName = Last @ untouchedNames}, Pattern[lastPatternName, ___]]]];
  output = Hold @ Catenate @ # & @ Prepend[
    With[{ruleName = #[[1]], outputRule = #[[2]]},
      Hold[Replace[{ruleName}, outputRule]]] & /@
        Transpose[{
          ruleNames,
          With[{outputExpression = (Hold /@ #)[[2]]},
              {finalMatchName} :> outputExpression] & /@
            separateNormalRules[[All, 1]]}],
    untouchedNames];
  With[{evaluatedOutput = output}, input :> evaluatedOutput] //. Hold[expr_] :> expr
];

(* This function just does the replacements, but it does not keep track of any metadata (generations and events).
   Returns {finalState, terminationReason}, and sows deleted expressions. *)

setReplace$wl[set_, rules_, stepSpec_, vertexIndex_, returnOnAbortQ_, timeConstraint_] := ModuleScope[
  eventsCount = 0;
  normalRules = toNormalRules @ rules;
  previousResult = set;
  Catch[
    TimeConstrained[
      CheckAbort[
        {FixedPoint[
          AbortProtect[Module[{newResult, deletedExpressions, events},
            If[eventsCount++ == Lookup[stepSpec, $maxEvents, Infinity],
              Throw[{previousResult, $maxEvents}, $$setReplaceResult];
            ];
            {newResult, {deletedExpressions, events}} = Reap[
              Catch[
                Replace[#, normalRules],
                $$reachedAtomDegreeLimit,
                Throw[{previousResult, $maxFinalVertexDegree}, $$setReplaceResult] &],
              {$$deletedExpressions, $$events}];
            If[vertexCount[vertexIndex] > Lookup[stepSpec, $maxFinalVertices, Infinity],
              Throw[{previousResult, $maxFinalVertices}, $$setReplaceResult];
            ];
            If[Length[newResult] > Lookup[stepSpec, $maxFinalExpressions, Infinity],
              Throw[{previousResult, $maxFinalExpressions}, $$setReplaceResult];
            ];
            Map[Sow[#, $$deletedExpressions] &, deletedExpressions, {2}];
            Map[Sow[#, $$events] &, events, {2}];
            previousResult = newResult]] &,
          List @@ set], $fixedPoint},
        If[returnOnAbortQ,
          {previousResult, $Aborted},
          Abort[]
        ]],
      timeConstraint,
      If[returnOnAbortQ,
        {previousResult, $timeConstraint},
        Return[$Aborted]
      ]],
    $$setReplaceResult
  ]
];

(* We need to not only perform the evolution, but also keep track of the metadata such as generation numbers, creator
   events, etc. The way we do it is by implementing the metadata tracking itself as pattern rules.
   Each expression becomes the list {id, generation, original expression (atoms)} *)

(* Then a rule
     {{a_, b_}, {b_, c_}} /; True :> Module[{d}, {{a, d}, {d, b}}]
   becomes something like
     {{id1_, generation1_ ? (#1 < maxGeneration &), inputExpression1 : {a_, b_}},
      {id2_, generation2_ ? (#1 < maxGeneration &), inputExpression2 : {b_, c_}}} /; True :>
     Module[{
         d, newExpressionIDs = Table[getNextExpression[], 2]},
       {Sow[{ruleID, {id1, id2} -> newExpressionIDs, 1 + Max[0, generation1, generation2]}, $$events]; Nothing,
        Sow[{id1, generation1, inputExpression1}, $$deletedExpressions];
        deleteFromVertexIndex[vertexIndex, inputExpression1]; Nothing,
        Sow[{id2, generation2, inputExpression2}, $$deletedExpressions];
        deleteFromVertexIndex[vertexIndex, inputExpression2]; Nothing,
        {newExpressionIDs[[1]],
         1 + Max[0, generation1, generation2],
         addToVertexIndex[vertexIndex, {a, d}, maxVertexDegree]},
        {newExpressionIDs[[2]],
         1 + Max[0, generation1, generation2],
         addToVertexIndex[vertexIndex, {d, b}, maxVertexDegree]}}] *)

(* This function adds metadata management to the rules. I.e., the rules will not only perform the replacements, but will
   also keep track of generations, events, etc. *)

addMetadataManagement[
      input_Condition :> output_Module,
      ruleID_,
      getNextExpression_,
      maxGeneration_,
      maxVertexDegree_,
      vertexIndex_] := ModuleScope[
  inputIDs = Table[Unique["id", {Temporary}], Length[input[[1]]]];
  wholeInputPatternNames = Table[Unique["inputExpression", {Temporary}], Length[input[[1]]]];
  inputGenerations = Table[Unique["generation", {Temporary}], Length[input[[1]]]];
  With[{
      heldModule = mapHold[output, {0, 1}]},
    With[{
        moduleArguments = Append[
          ReleaseHold @ Map[Hold, heldModule[[1, 1]], {2}],
          With[{outputExpressionCount = Length[heldModule[[1, 2]][[1]]]},
            Hold[newExpressionIDs = Table[getNextExpression[], outputExpressionCount]]]],
        moduleOutput = heldModule[[1, 2]]},
      With[{
          newModuleContents = Join[
            (* event *)
            (* Given that these look just like normal expressions,
              which just output Nothing at the end,
              they pass just fine through all the transformation. *)
            {With[{event = {ruleID, inputIDs -> newExpressionIDs, Max[0, inputGenerations] + 1}},
              Hold[Sow[event, $$events]; Nothing]]},
            (* old expressions *)
            (* don't put them in the main set, sow them instead,
              that's much faster. *)
            With[{expr = #[[3]]},
                Hold[Sow[#, $$deletedExpressions]; deleteFromVertexIndex[vertexIndex, expr]; Nothing]] & /@
              Transpose[{
                inputIDs,
                inputGenerations,
                wholeInputPatternNames}],
            (* new expressions *)
            ReleaseHold @ MapIndexed[
              Function[
                {expr, index},
                {Hold[newExpressionIDs[[index[[-1]]]]],
                 Max[0, inputGenerations] + 1,
                 Hold[addToVertexIndex[vertexIndex, expr, maxVertexDegree]]},
                HoldAll],
              moduleOutput,
              {2}]],
          originalInput = input[[1]],
          condition = heldPart[input, 2]},
        {Pattern[Evaluate[#[[1]]], Blank[]],
         Pattern[Evaluate[#[[2]]], Blank[]] ? (# < maxGeneration &),
         Pattern[Evaluate[#[[4]]], #[[3]]]} & /@
            Transpose[{
              inputIDs,
              inputGenerations,
              originalInput,
              wholeInputPatternNames}] /; condition :>
          Module[moduleArguments, newModuleContents]]] //.
            Hold[expr_] :> expr]
];

$generationMetadataIndex = 2; (* {id, generation, atoms} *)

(* Determines maximal completed generation by trying to run the rules and checking the generation of the first match
   obtained. Note, matching is necessary to determine that because it's impossible to determine if the last generation
   is done otherwise. *)

maxCompleteGeneration[output_, rulesNoMetadata_] := ModuleScope[
  patternToMatch = toNormalRules[
    addMetadataManagement[#, Infinity, Infinity &, Infinity, Infinity, $noIndex] & /@ rulesNoMetadata];
  matches = Reap[
    FirstCase[
      SortBy[output, #[[$generationMetadataIndex]] &], patternToMatch, Sow[$noMatch, $$deletedExpressions], {0}],
    $$deletedExpressions][[2]];
  Switch[matches,
    {{$noMatch}},
      Infinity,
    {}, (* nothing -> something rule *)
      0,
    _,
      Max[matches[[1, All, $generationMetadataIndex]]]
  ]
];

(* This function renames all rule inputs to avoid collisions with outputs from other rules. *)

renameRuleInputs[patternRules_] := Catch[Module[{pattern, inputAtoms, newInputAtoms},
  SetAttributes[pattern, HoldFirst];
  inputAtoms = Union[
    Quiet[
      Cases[
        # /. Pattern -> pattern,
        p : pattern[s_, rest___] :> If[MatchQ[Hold[s], Hold[_Symbol]],
          Hold[s],
          With[{originalP = p /. pattern -> Pattern}, Message[Pattern::patvar, originalP]]; Throw[$Failed]],
        All],
      {RuleDelayed::rhs}]];
  newInputAtoms = Table[Unique["inputAtom", {Temporary}], Length[inputAtoms]];
  # /. (((HoldPattern[#1] /. Hold[s_] :> s) -> #2) & @@@ Thread[inputAtoms -> newInputAtoms])
] & /@ patternRules];

(* This yields unique elements in the expressions upto level 1. *)

expressionVertices[expr_] := If[ListQ[expr], Union[expr], Throw[expr, $$nonListExpression]];

(* The following is used to keep track of how many times vertices appear in the set.
   All operations here should evaluate in O(1). *)

Attributes[$vertexIndex] = {HoldAll};

initVertexIndex[$vertexIndex[index_], set_] := (
  index = Counts[Catenate[expressionVertices /@ set]];
  set
);

initVertexIndex[$noIndex, set_] := set;

deleteFromVertexIndex[$vertexIndex[index_], expr_] := (
  Scan[
    index[#] = Lookup[index, Key[#], 0] - 1;
    If[index[#] == 0, index[#] =.]; &,
    expressionVertices[expr]];
  expr
);

deleteFromVertexIndex[$noIndex, expr_] := expr;

addToVertexIndex[$vertexIndex[index_], expr_, limit_] := (
  Scan[
    index[#] = Lookup[index, Key[#], 0] + 1;
    If[index[#] > limit, Throw[#, $$reachedAtomDegreeLimit]]; &,
    expressionVertices[expr]];
  expr
);

addToVertexIndex[$noIndex, expr_, limit_] := expr;

vertexCount[$vertexIndex[index_]] := Length[index];

vertexCount[$noIndex] := 0;

(* This function runs a modified version of the set substitution system that also keeps track of metadata such as
   generations and events. It uses setReplace$wl to evaluate that modified system. *)

setSubstitutionSystem$wl[
      caller_, rules_, init_, stepSpec_, returnOnAbortQ_, timeConstraint_] := ModuleScope[
  nextExpressionID = 1;
  nextExpression = nextExpressionID++ &;
  (* {id, generation, atoms} *)
  initWithMetadata = {nextExpression[], 0, #} & /@ init;
  renamedRules = renameRuleInputs[toCanonicalRules[rules]];
  If[renamedRules === $Failed, Return[$Failed]];
  vertexIndex = If[MissingQ[stepSpec[$maxFinalVertices]] && MissingQ[stepSpec[$maxFinalVertexDegree]],
    $noIndex,
    $vertexIndex[expressionsCountsPerVertex]];
  initVertexIndex[vertexIndex, init];

  rulesWithMetadata = MapIndexed[
    addMetadataManagement[
      #,
      #2[[1]],
      nextExpression,
      Lookup[stepSpec, $maxGenerationsLocal, Infinity],
      Lookup[stepSpec, $maxFinalVertexDegree, Infinity],
      vertexIndex] &,
    renamedRules];
  outputWithMetadata = Catch[
    Reap[
      setReplace$wl[initWithMetadata, rulesWithMetadata, stepSpec, vertexIndex, returnOnAbortQ, timeConstraint],
      {$$deletedExpressions, $$events}],
    $$nonListExpression,
    (Message[caller::nonListExpressions, #];
      Return[$Failed]) &]; (* {{finalState, terminationReason}, {{deletedExpressions}, {events}}} *)
  If[outputWithMetadata[[1]] === $Aborted, Return[$Aborted]];
  allExpressions = SortBy[
    Join[
      outputWithMetadata[[1, 1]],
      If[outputWithMetadata[[2, 1]] == {}, {}, outputWithMetadata[[2, 1, 1]]]],
    First];
  initialEvent = {0, {} -> initWithMetadata[[All, 1]], 0};
  allEvents = Join[{initialEvent}, If[outputWithMetadata[[2, 2]] == {}, {}, outputWithMetadata[[2, 2, 1]]]];
  generationsCount = Max[allEvents[[All, 3]], 0];
  maxCompleteGenerationResult = CheckAbort[
    Min[maxCompleteGeneration[outputWithMetadata[[1, 1]], renamedRules], generationsCount],
    If[returnOnAbortQ,
      Missing["Unknown", $Aborted],
      Return[$Aborted]
    ]];

  WolframModelEvolutionObject[<|
    $version -> 3,
    $libSetReplaceSet -> Missing["SymbolicEvolution"],
    $rules -> rules,
    $maxCompleteGeneration -> maxCompleteGenerationResult,
    $terminationReason -> Replace[
      outputWithMetadata[[1, 2]],
      $fixedPoint ->
        If[generationsCount == Lookup[stepSpec, $maxGenerationsLocal, Infinity],
          $maxGenerationsLocal,
          $fixedPoint]],
    $atomLists -> allExpressions[[All, 3]],
    $eventRuleIDs -> allEvents[[All, 1]],
    $eventInputs -> allEvents[[All, 2, 1]],
    $eventOutputs -> allEvents[[All, 2, 2]],
    $eventGenerations -> allEvents[[All, 3]]|>]
];
