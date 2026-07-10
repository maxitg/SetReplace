Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageScope["tokenDeduplicationClasses"]

(* Computes equivalence classes of expressions (tokens), events and atoms of an evolution object that can be merged
   without changing the possible evolution. Two tokens are merged if the multihistories obtained by deleting their
   causal pasts are isomorphic with an isomorphism mapping one token to the other, and all atom renamings performed by
   the isomorphism are between independent atoms (atoms that never occur together in a spacelike set of tokens).
   Deduplication works both between branches and in time, so periodic evolutions collapse into cycles. *)

importLibSetReplaceFunction[
  "tokenDeduplicationClasses" -> cpp$tokenDeduplicationClasses,
  {{Integer, 1, "Constant"},  (* tokens *)
   {Integer, 1, "Constant"},  (* events *)
   Integer,                   (* complete generations *)
   Integer},                  (* named unit count *)
  {Integer, 1}];              (* token, event and atom classes *)

declareMessage[General::tokenDeduplicationUnavailable, "Token deduplication requires libSetReplace to be loaded."];

declareMessage[General::tokenDeduplicationFailed, "Token deduplication failed for the given evolution object."];

encodeTokenLists[lists_List] := Join[{Length[lists]}, Catenate[Join[{Length[#]}, #] & /@ lists]];

(* Events of this generation or smaller are assumed to be completely evolved, and the correspondence between merged
   tokens is verified exactly within them. Since the future of a multihistory is determined by its tokens, parts of
   the correspondence beyond these generations will be reproduced once the evolution is continued. For evolutions
   truncated mid-generation (e.g., by "MaxEvents"), even the last complete generation can have missing events, so it
   is not required to match either. *)

completeGenerationsCount[evolution : WolframModelEvolutionObject[data_]] := ModuleScope[
  reachedGeneration = Replace[data[$maxCompleteGeneration], _ ? MissingQ :> evolution["TotalGenerationsCount"]];
  reachedGeneration + Switch[data[$terminationReason],
    $fixedPoint, 1,
    $maxGenerationsLocal, 0,
    _, -1]
];

(* Tokens of pattern-rules systems can be arbitrary expressions rather than lists of atoms. Elements of list tokens,
   and non-list tokens as a whole, are treated as opaque units. The $wholeTokenUnit wrapper keeps a non-list token
   from being confused with a single-element list token (e.g., 0 with {0}). *)

tokenUnits[content_List] := content;
tokenUnits[content_] := {$wholeTokenUnit[content]};

(* Units the deduplication is not allowed to identify with one another: atoms of the initial condition are part of
   the problem specification, and in pattern-rules systems the rules can reference arbitrary subexpressions, so all
   units are protected there. Tokens containing named units can still be deduplicated, and created atoms can still be
   identified with named ones, in which case the named atom is used as the class representative. *)

namedUnits[data_, unitLists_] := If[MatchQ[data[$rules], KeyValuePattern["PatternRules" -> _]],
  Union[Catenate[unitLists]]
,
  Union[Catenate[unitLists[[data[$eventOutputs][[1]]]]]]
];

tokenDeduplicationClasses[evolution : WolframModelEvolutionObject[data_]] := ModuleScope[
  If[!$libSetReplaceAvailable, throw[Failure["tokenDeduplicationUnavailable", <||>]]];
  unitLists = tokenUnits /@ data[$atomLists];
  named = namedUnits[data, unitLists];
  (* named units get the smallest indices, which both communicates their count to libSetReplace and makes them class
     representatives *)
  orderedUnits = Join[named, Complement[Union[Catenate[unitLists]], named]];
  unitIndex = Association[Thread[orderedUnits -> Range[Length[orderedUnits]]]];
  encodedTokens = encodeTokenLists[Map[unitIndex, unitLists, {2}]];
  encodedEvents = Join[
    {Length[data[$eventRuleIDs]]},
    Catenate[MapThread[
      Join[{#1}, {Length[#2]}, #2 - 1, {Length[#3]}, #3 - 1] &,
      (* the initial event has rule ID 0 in the evolution object and -1 in libSetReplace *)
      {data[$eventRuleIDs] - 1, data[$eventInputs], data[$eventOutputs]}]]];
  result = cpp$tokenDeduplicationClasses[
    encodedTokens, encodedEvents, completeGenerationsCount[evolution], Length[named]];
  If[!ListQ[result], throw[Failure["tokenDeduplicationFailed", <||>]]];
  tokenCount = result[[1]];
  expressionClasses = result[[2 ;; tokenCount + 1]] + 1;
  eventCount = result[[tokenCount + 2]];
  (* event indices are the same as in the evolution object: the initial event is 0, and substitution events start
     from 1 *)
  eventClasses = result[[tokenCount + 3 ;; tokenCount + 2 + eventCount]];
  atomPairs = Partition[result[[tokenCount + eventCount + 4 ;;]], 2];
  atomClasses = Association[(orderedUnits[[#1]] -> orderedUnits[[#2]]) & @@@ atomPairs];
  <|"ExpressionClasses" -> expressionClasses, "EventClasses" -> eventClasses, "AtomClasses" -> atomClasses|>
];
