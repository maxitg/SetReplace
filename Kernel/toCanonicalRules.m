Package["SetReplace`"]

PackageScope["toCanonicalRules"]

(* Rules can be specified in various ways, in particular, a single rule instead of a list, with or without a Module,
   etc. This function is needed to canonicalize that so that the rules are easy to parse:
  1. Rules should always be specified as a list of rules instead of a single rule.
  2. RuleDelayed should be used instead of Rule.
  3. Condition should be used on the left-hand side ({atom1, atom2, ...} /; condition) even if condition === True.
  4. Module should be used on the right-hand side of the rule, even with the empty first argument.
  5. Left- and right-hand sides of the rules should explicitly be lists, even if sets only have one element. *)

(* If there is a single rule, we put it in a list *)

toCanonicalRules[rules_List] := toCanonicalRule /@ (rules /. Condition -> inertCondition)

toCanonicalRules[rule : Except[_List]] := toCanonicalRules[{rule}]

(* Force RuleDelayed *)

toCanonicalRule[input_ -> output_] := toCanonicalRule[input :> output]

(* Force Condition *)

toCanonicalRule[input : Except[_inertCondition] :> output_] := toCanonicalRule[inertCondition[input, True] :> output]

(* Force Module *)

toCanonicalRule[input_ :> output : Except[_Module]] := toCanonicalRule[input :> Module[{}, output]]

(* If input or output are not lists, we assume it is a single element set, so we put it into a single element list *)

SetAttributes[inertCondition, HoldRest];

toCanonicalRule[inertCondition[inputExprs : Except[_List], condition_] :> output_] :=
  toCanonicalRule[inertCondition[{inputExprs}, condition] :> output]

toCanonicalRule[input_ :> Module[newAtoms_List, outputExprs : Except[_List]]] :=
  toCanonicalRule[input :> Module[newAtoms, {outputExprs}]]

(* After all of that's done, drop toCanonicalRule *)

toCanonicalRule[rule : (inertCondition[inputExprs_List, condition_] :> Module[newAtoms_List, outputExprs_List])] :=
  rule /. inertCondition -> Condition
