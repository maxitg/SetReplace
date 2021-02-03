Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["WolframModelRuleValue"]
PackageExport["$WolframModelRuleProperties"]

(* Documentation *)

SetUsage @ "
WolframModelRuleValue[rule$, property$] yields a value for property property$ of Wolfram model rule rule$.
WolframModelRuleValue[rule$] yields values of all available properties.
";

SetUsage @ "
$WolframModelRuleProperties gives the list of all available rule properties.
";

SyntaxInformation[WolframModelRuleValue] = {"ArgumentsPattern" -> {rule_, property_.}};

$WolframModelRuleProperties = Sort @ {
  "ConnectedInput", "ConnectedOutput", "ConnectedInputOutputUnion", "MaximumArity", "NodeCounts", "NodesDroppedAdded",
  "Signature", "TraditionalSignature", "TransformationCount"};

With[{properties = $WolframModelRuleProperties},
  FE`Evaluate[FEPrivate`AddSpecialArgCompletion["WolframModelRuleValue" -> {0, properties}]]];

(* Implementation *)

WolframModelRuleValue[args___] := ModuleScope[
  result = Catch[wolframModelRuleValue[args]];
  result /; result =!= $Failed
];

wolframModelRuleValue[args___] /; !Developer`CheckArgumentCount[WolframModelRuleValue[args], 1, 2] := Throw[$Failed];

$rulePattern = Rule[_, _] | {Rule[_, _]...};

wolframModelRuleValue[rule : $rulePattern, properties_List] :=
  Check[wolframModelRuleValue[rule, #], Throw[$Failed]] & /@ properties;

wolframModelRuleValue[rule : $rulePattern] :=
  Association @ Thread[$WolframModelRuleProperties -> wolframModelRuleValue[rule, $WolframModelRuleProperties]];

WolframModelRuleValue::invalidRule = "The rule specification `1` should either be a Rule or a List of rules.";

wolframModelRuleValue[rule : Except[$rulePattern], _ : {}] := (
  Message[WolframModelRuleValue::invalidRule, rule];
  Throw[$Failed];
);

WolframModelRuleValue::unknownProperty = "Property `1` should be one of $WolframModelRuleProperties.";

wolframModelRuleValue[rule : $rulePattern, property : Except[Alternatives @@ $WolframModelRuleProperties, _String]] := (
  Message[WolframModelRuleValue::unknownProperty, property];
  Throw[$Failed];
);

WolframModelRuleValue::invalidProperty = "Property `1` should be either a String or a List of properties.";

wolframModelRuleValue[rule : $rulePattern, property : Except[_List | _String]] := (
  Message[WolframModelRuleValue::invalidProperty, property];
  Throw[$Failed];
);

(* Connectedness *)

wolframModelRuleValue[
    rules : {Rule[_, _]...}, property : "ConnectedInput" | "ConnectedOutput" | "ConnectedInputOutputUnion"] :=
  And @@ (wolframModelRuleValue[#, property] &) /@ rules;

wolframModelRuleValue[input_ -> _, "ConnectedInput"] := connectedHypergraphQ[input];

wolframModelRuleValue[_ -> output_, "ConnectedOutput"] := connectedHypergraphQ[output];

wolframModelRuleValue[input_ -> output_, "ConnectedInputOutputUnion"] :=
  connectedHypergraphQ[Flatten[{input, output}, 1]];

(* Listable properties *)

wolframModelRuleValue[
    rules : {Rule[_, _]...},
    property : "NodeCounts" | "NodesDroppedAdded" | "Signature" | "TraditionalSignature"] :=
  wolframModelRuleValue[#, property] & /@ rules;

(* Arity *)

wolframModelRuleValue[rules : {Rule[_, _]...}, "MaximumArity"] :=
  Max[wolframModelRuleValue[#, "MaximumArity"] & /@ rules, 0];

wolframModelRuleValue[input_ -> output_, "MaximumArity"] :=
  Max[maximumHypergraphArity /@ toCanonicalHypergraphForm /@ {input, output}, 0];

maximumHypergraphArity[edges_List] := Max[Length /@ edges, 0];

(* Node Counts *)

wolframModelRuleValue[rule : Rule[_, _], "NodeCounts"] := Length @* vertexList /@ rule;

(* Nodes dropped and added *)

wolframModelRuleValue[input_ -> output_, "NodesDroppedAdded"] :=
  Length /@ ({Complement[#1, #2], Complement[#2, #1]} &) @@ vertexList /@ {input, output};

(* Rule signature *)

wolframModelRuleValue[rule : Rule[_, _], "Signature"] := hypergraphSignature /@ toCanonicalHypergraphForm /@ rule;

hypergraphSignature[edges_] := SortBy[Reverse /@ Tally[Length /@ edges], Last];

wolframModelRuleValue[rule : Rule[_, _], "TraditionalSignature"] :=
  Switch[Length[#], 0, "\[EmptySet]", 1, First[#], _, Row[#]] & /@
    Apply[Subscript, wolframModelRuleValue[rule, "Signature"], {2}];

(* Rule count *)

wolframModelRuleValue[rule : Rule[_, _], "TransformationCount"] := wolframModelRuleValue[{rule}, "TransformationCount"];

wolframModelRuleValue[rules : {Rule[_, _]...}, "TransformationCount"] := Length[rules];
