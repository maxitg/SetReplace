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
  "RuleNodesDroppedAdded", "RuleSignature", "RuleSignatureTraditionalForm", "TransformationCount"};

With[{properties = $WolframModelRuleProperties},
  FE`Evaluate[FEPrivate`AddSpecialArgCompletion["WolframModelRuleValue" -> {0, properties}]]];

(* Implementation *)

WolframModelRuleValue[args___] := Module[{result = Catch[wolframModelRuleValue[args]]},
  result /; result =!= $Failed
]

wolframModelRuleValue[args___] /; !Developer`CheckArgumentCount[WolframModelRuleValue[args], 1, 2] := Throw[$Failed]

$rulePattern = Rule[_, _] | {Rule[_, _]...}

wolframModelRuleValue[rule : $rulePattern, properties_List] :=
  Check[wolframModelRuleValue[rule, #], Throw[$Failed]] & /@ properties

wolframModelRuleValue[rule : $rulePattern] :=
  Association @ Thread[$WolframModelRuleProperties -> wolframModelRuleValue[rule, $WolframModelRuleProperties]]

WolframModelRuleValue::invalidRule = "The rule specification `1` should either be a Rule or a List of rules.";

wolframModelRuleValue[rule : Except[$rulePattern], _ : {}] := (
  Message[WolframModelRuleValue::invalidRule, rule];
  Throw[$Failed];
)

WolframModelRuleValue::unknownProperty = "Property `1` should be one of $WolframModelRuleProperties.";

wolframModelRuleValue[rule : $rulePattern, property : Except[Alternatives @@ $WolframModelRuleProperties, _String]] := (
  Message[WolframModelRuleValue::unknownProperty, property];
  Throw[$Failed];
)

WolframModelRuleValue::invalidProperty = "Property `1` should be either a String or a List of properties.";

wolframModelRuleValue[rule : $rulePattern, property : Except[_List | _String]] := (
  Message[WolframModelRuleValue::invalidProperty, property];
  Throw[$Failed];
)

(* Connectedness *)

wolframModelRuleValue[
    rules : {Rule[_, _]...}, property : "ConnectedInput" | "ConnectedOutput" | "ConnectedInputOutputUnion"] :=
  And @@ (wolframModelRuleValue[#, property] &) /@ rules

wolframModelRuleValue[input_ -> _, "ConnectedInput"] := connectedHypergraphQ[input]

wolframModelRuleValue[_ -> output_, "ConnectedOutput"] := connectedHypergraphQ[output]

wolframModelRuleValue[input_ -> output_, "ConnectedInputOutputUnion"] :=
  connectedHypergraphQ[Flatten[{input, output}, 1]]

(* Listable properties *)

wolframModelRuleValue[
    rules : {Rule[_, _]...},
    property :
      "MaximumArity" | "RuleNodeCounts" | "RuleNodesDroppedAdded" | "RuleSignature" | "RuleSignatureTraditionalForm"] :=
  wolframModelRuleValue[#, property] & /@ rules

(* Arity *)

wolframModelRuleValue[input_ -> output_, "MaximumArity"] :=
  Max[maximumHypergraphArity /@ toCanonicalHypergraphForm /@ {input, output}]

maximumHypergraphArity[edges_List] := Max[Length /@ edges]

(* Node Counts *)

wolframModelRuleValue[rule : Rule[_, _], "RuleNodeCounts"] := Length @* vertexList /@ rule

(* Nodes dropped and added *)

wolframModelRuleValue[input_ -> output_, "RuleNodesDroppedAdded"] :=
  Length /@ ({Complement[#1, #2], Complement[#2, #1]} &) @@ vertexList /@ {input, output}

(* Rule signature *)

wolframModelRuleValue[rule : Rule[_, _], "RuleSignature"] := hypergraphSignature /@ toCanonicalHypergraphForm /@ rule

hypergraphSignature[edges_] := Reverse /@ Tally[Length /@ edges]

wolframModelRuleValue[rule : Rule[_, _], "RuleSignatureTraditionalForm"] :=
  Row /@ Apply[Subscript, wolframModelRuleValue[rule, "RuleSignature"], {2}]

(* Rule count *)

wolframModelRuleValue[rule : Rule[_, _], "TransformationCount"] := wolframModelRuleValue[{rule}, "TransformationCount"]

wolframModelRuleValue[rules : {Rule[_, _]...}, "TransformationCount"] := Length[rules]
