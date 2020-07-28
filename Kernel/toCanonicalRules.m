(* ::Package:: *)

(* ::Title:: *)
(*toCanonicalRules*)


(* ::Text:: *)
(*Rules can be specified in various ways, in particular, single rule instead of a list, with or without a module, etc. This function is needed to standardize that:*)


(* ::ItemNumbered:: *)
(*Rules should always be specified as a list of rules instead of a single rule.*)


(* ::ItemNumbered:: *)
(*RuleDelayed should be used instead of Rule.*)


(* ::ItemNumbered:: *)
(*Module should be used on the right-hand side of the rule, even if with the empty first argument.*)


(* ::ItemNumbered:: *)
(*Left- and right-hand side of the rules should explicitly be lists, possibly specifying sets of a single element.*)


Package["SetReplace`"]


PackageScope["toCanonicalRules"]


(* ::Section:: *)
(*Implementation*)


(* ::Text:: *)
(*If there is a single rule, we put it in a list*)


toCanonicalRules[rules_List] := toCanonicalRule /@ rules


toCanonicalRules[rule : Except[_List]] := toCanonicalRules[{rule}]


(* ::Text:: *)
(*Force RuleDelayed*)


toCanonicalRule[input_ -> output_] := toCanonicalRule[input :> output]


(* ::Text:: *)
(*Force Module*)


toCanonicalRule[input_ :> output : Except[_Module]] :=
  toCanonicalRule[input :> Module[{}, output]]


(* ::Text:: *)
(*If input or output are not lists, we assume it is a single element set, so we put it into a single element list.*)


toCanonicalRule[input_ :> output_] /; !ListQ[input] :=
  toCanonicalRule[{input} :> output]


toCanonicalRule[input_ :> Module[vars_List, expr : Except[_List]]] :=
  input :> Module[vars, {expr}]


(* ::Text:: *)
(*After all of that's done, drop toCanonicalRule*)


toCanonicalRule[input_ :> Module[vars_List, expr_List]] := input :> Module[vars, expr]
