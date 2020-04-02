Package["SetReplace`"]

PackageExport["WolframModelRuleValue"]
PackageExport["$WolframModelRuleProperties"]

(* Documentation *)

WolframModelRuleValue::usage = usageString[
  "WolframModelRuleValue[`r`, `p`] yields a value for property `p` of Wolfram model rule `r`.",
  "WolframModelRuleValue[`r`] yields values of all available properties."];

SyntaxInformation[WolframModelRuleValue] = {"ArgumentsPattern" -> {_, _.}};

$WolframModelRuleProperties = {
  "ConnectedInput", "ConnectedOutput", "ConnectedInputOutputUnion", "MaximumArity", "RuleNodeCounts",
  "RuleNodesDroppedAdded"};

With[{properties = $WolframModelRuleProperties},
  FE`Evaluate[FEPrivate`AddSpecialArgCompletion["WolframModelRuleValue" -> {0, properties}]]];

(* Implementation *)

WolframModelRuleValue[args___] := Module[{result = Catch[wolframModelRuleValue[args]]},
  result /; result =!= $Failed
]

wolframModelRuleValue[args___] /; !Developer`CheckArgumentCount[WolframModelRuleValue[args], 1, 2] := Throw[$Failed]

wolframModelRuleValue[rule_, properties_List] := Check[wolframModelRuleValue[rule, #], Throw[$Failed]] & /@ properties

wolframModelRuleValue[rule_] :=
  Association @ Thread[$WolframModelRuleProperties -> wolframModelRuleValue[rule, $WolframModelRuleProperties]]

WolframModelRuleValue::unknownProperty = "Property `1` should be one of $WolframModelRuleProperties.";

wolframModelRuleValue[rule_, property_String : Except[Alternatives @@ $WolframModelRuleProperties]] := (
  Message[WolframModelRuleValue::unknownProperty, property];
  Throw[$Failed];
)

WolframModelRuleValue::invalidProperty = "Property `1` should be either a String or a List of properties.";

wolframModelRuleValue[rule_, property : Except[_List | _String]] := (
  Message[WolframModelRuleValue::invalidProperty, property];
  Throw[$Failed];
)

(* Connectedness *)

wolframModelRuleValue[rules_List, property : "ConnectedInput" | "ConnectedOutput" | "ConnectedInputOutputUnion"] :=
  And @@ (wolframModelRuleValue[#, property] &) /@ rules

wolframModelRuleValue[rule_Rule, "ConnectedInput"] := connectedHypergraphQ[First[rule]]

wolframModelRuleValue[rule_Rule, "ConnectedOutput"] := connectedHypergraphQ[Last[rule]]

wolframModelRuleValue[rule_Rule, "ConnectedInputOutputUnion"] := connectedHypergraphQ[Flatten[List @@ rule, 1]]

(* Arity *)

wolframModelRuleValue[rules_List, "MaximumArity"] := Max[wolframModelRuleValue[#, "MaximumArity"] & /@ rules]

wolframModelRuleValue[rule_Rule, "MaximumArity"] :=
  Max[maximumHypergraphArity /@ toCanonicalHypergraphForm /@ List @@ rule]

maximumHypergraphArity[edges_List] := Max[Length /@ edges]

(* Node Counts *)

wolframModelRuleValue[rules_List, "RuleNodeCounts"] := wolframModelRuleValue[#, "RuleNodeCounts"] & /@ rules

wolframModelRuleValue[rule_Rule, "RuleNodeCounts"] := Length @* vertexList /@ rule

(* Nodes dropped and added *)

wolframModelRuleValue[rules_List, "RuleNodesDroppedAdded"] :=
  wolframModelRuleValue[#, "RuleNodesDroppedAdded"] & /@ rules

wolframModelRuleValue[rule_Rule, "RuleNodesDroppedAdded"] :=
  Length /@ ({Complement[#1, #2], Complement[#2, #1]} &) @@ vertexList /@ List @@ rule
