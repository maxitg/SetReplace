(* ::Package:: *)

(* ::Title:: *)
(*setSubstitutionSystem*)


(* ::Text:: *)
(*This is a main function of the package. This function calls either C++ or Wolfram Language implementation, and can*)
(*produce a WolframModelEvolutionObject that contains information about evolution of the network step-by-step.*)
(*All SetReplace* and WolframModel functions use argument checks and implementation done here.*)


Package["SetReplace`"]


PackageExport["$SetReplaceMethods"]


PackageScope["setReplaceRulesQ"]
PackageScope["stepCountQ"]
PackageScope["setSubstitutionSystem"]


PackageScope["$stepSpecKeys"]
PackageScope["$maxEvents"]
PackageScope["$maxGenerationsLocal"]
PackageScope["$maxFinalVertices"]
PackageScope["$maxFinalVertexDegree"]
PackageScope["$maxFinalExpressions"]


(* ::Section:: *)
(*Documentation*)


$SetReplaceMethods::usage = usageString[
	"$SetReplaceMethods gives the list of available values for Method option of ",
	"SetReplace and related functions."];


(* ::Section:: *)
(*Argument Checks*)


(* ::Text:: *)
(*Argument checks here produce messages for the caller which is specified as an argument. That is because*)
(*setSubstitutionSystem is used by all SetReplace* and WolframModel functions, which need to produce their own*)
(*messages.*)


(* ::Subsection:: *)
(*Set is a list*)


setSubstitutionSystem[
		rules_, set_, stepSpec_, caller_, returnOnAbortQ_, o : OptionsPattern[]] := 0 /;
	!ListQ[set] &&
	makeMessage[caller, "setNotList", set]


(* ::Subsection:: *)
(*Rules are valid*)


setReplaceRulesQ[rules_] :=
	MatchQ[rules, {(_Rule | _RuleDelayed)..} | _Rule | _RuleDelayed]


setSubstitutionSystem[
		rules_, set_, stepSpec_, caller_, returnOnAbortQ_, o : OptionsPattern[]] := 0 /;
	!setReplaceRulesQ[rules] &&
	makeMessage[caller, "invalidRules", rules]


(* ::Subsection:: *)
(*Step count is valid*)


$stepSpecKeys = <|
	$maxEvents -> "MaxEvents",
	(* local means the evolution will keep running until no further matches can be made exceeding the max generation.
		This might result in a different evolution order. *)
	$maxGenerationsLocal -> "MaxGenerations",
	(* these are any level-2 expressions in the set, not just atoms. *)
	$maxFinalVertices -> "MaxVertices",
	$maxFinalVertexDegree -> "MaxVertexDegree",
	$maxFinalExpressions -> "MaxEdges"|>;


$stepSpecNamesInErrorMessage = <|
	$maxEvents -> "number of replacements",
	$maxGenerationsLocal -> "number of generations",
	$maxFinalVertices -> "number of vertices",
	$maxFinalVertexDegree -> "vertex degree",
	$maxFinalExpressions -> "number of edges"|>;


stepCountQ[n_] := IntegerQ[n] && n >= 0 || n == \[Infinity]


stepSpecQ[caller_, set_, spec_] :=
	(* Check everything is a non-negative integer. *)
	And @@ KeyValueMap[
			If[stepCountQ[#2],
				True,
				makeMessage[caller, "nonIntegerIterations", $stepSpecNamesInErrorMessage[#1], #2]; False] &,
			spec] &&
	(* Check vertices make sense if vertex constraints are specified. *)
	If[(MissingQ[spec[$maxFinalVertices]] && MissingQ[spec[$maxFinalVertexDegree]]) || AllTrue[set, ListQ],
		True,
		makeMessage[
				caller, "nonListExpressions", SelectFirst[set, Not @* ListQ]]; False] &&
	(* Check initial condition does not violate the limits already. *)
	And @@ (
			If[Lookup[spec, #1, Infinity] >= #2,
				True,
				makeMessage[caller, "tooSmallStepLimit", $stepSpecNamesInErrorMessage[#1], spec[#1], #2]; False] & @@@ {
		{$maxFinalVertices, If[MissingQ[spec[$maxFinalVertices]], 0, Length[Union[Catenate[set]]]]},
		{$maxFinalVertexDegree, If[MissingQ[spec[$maxFinalVertexDegree]], 0, Max[Counts[Catenate[Union /@ set]]]]},
		{$maxFinalExpressions, Length[set]}})


(* ::Subsection:: *)
(*Method is valid*)


$cppMethod = "LowLevel";
$wlMethod = "Symbolic";


$SetReplaceMethods = {Automatic, $cppMethod, $wlMethod};


setSubstitutionSystem[
		rules_, set_, stepSpec_, caller_, returnOnAbortQ_, o : OptionsPattern[]] := 0 /;
	!MatchQ[OptionValue[Method], Alternatives @@ $SetReplaceMethods] &&
	makeMessage[caller, "invalidMethod"]


(* ::Subsection:: *)
(*TimeConstraint is valid*)


setSubstitutionSystem[
		rules_, set_, stepSpec_, caller_, returnOnAbortQ_, o : OptionsPattern[]] := 0 /;
	!MatchQ[OptionValue[TimeConstraint], _ ? (# > 0 &)] &&
	Message[caller::timc, OptionValue[TimeConstraint]]


(* ::Section:: *)
(*Implementation*)


(* ::Subsection:: *)
(*simpleRuleQ*)


(* ::Text:: *)
(*This is the rule that can be understood by C++ code. Will be generalized in the future until simply returns True.*)


simpleRuleQ[
		left : {{__ ? (AtomQ[#]
			|| MatchQ[#, _Pattern?(AtomQ[#[[1]]] && #[[2]] === Blank[] &)] &)}..}
		:> right : Module[{___ ? AtomQ}, {{___ ? AtomQ}...}]] := Module[{p},
	ConnectedGraphQ @ Graph[
		Flatten[Apply[
				UndirectedEdge,
				(Partition[#, 2, 1] & /@ (Append[#, #[[1]]] &) /@ left),
				{2}]]
			/. x_Pattern :> p[x[[1]]]]
]


simpleRuleQ[left_ :> right : Except[_Module]] :=
	simpleRuleQ[left :> Module[{}, right]]


simpleRuleQ[___] := False


(* ::Subsection:: *)
(*setSubstitutionSystem*)


(* ::Text:: *)
(*This function accepts both the number of generations and the number of steps as an input, and runs until the first*)
(*of the two is reached. it also takes a caller function as an argument, which is used for message generation.*)


Options[setSubstitutionSystem] = {Method -> Automatic, TimeConstraint -> Infinity};


(* ::Text:: *)
(*Switching code between WL and C++ implementations*)


setSubstitutionSystem[
			rules_ ? setReplaceRulesQ,
			set_List,
			stepSpec_,
			caller_,
			returnOnAbortQ_,
			o : OptionsPattern[]] /; stepSpecQ[caller, set, stepSpec] := Module[{
		method = OptionValue[Method],
		timeConstraint = OptionValue[TimeConstraint],
		canonicalRules,
		failedQ = False},
	If[(timeConstraint > 0) =!= True, Return[$Failed]];
	canonicalRules = toCanonicalRules[rules];
	If[MatchQ[method, Automatic | $cppMethod]
			&& MatchQ[set, {{___}...}]
			&& MatchQ[canonicalRules, {___ ? simpleRuleQ}],
		If[$cppSetReplaceAvailable,
			Return[
				setSubstitutionSystem$cpp[rules, set, stepSpec, returnOnAbortQ, timeConstraint]]]];
	If[MatchQ[method, $cppMethod],
		failedQ = True;
		If[!$cppSetReplaceAvailable,
			makeMessage[caller, "noLowLevel"],
			makeMessage[caller, "lowLevelNotImplemented"]]];
	If[failedQ || !MatchQ[OptionValue[Method], Alternatives @@ $SetReplaceMethods],
		$Failed,
		setSubstitutionSystem$wl[caller, rules, set, stepSpec, returnOnAbortQ, timeConstraint]]
]
