(* ::Package:: *)

(* ::Title:: *)
(*SetReplaceAll*)


(* ::Text:: *)
(*The idea for SetReplaceAll is to keep performing SetReplace on the graph until no replacement can be done without touching the same edge twice.*)


(* ::Text:: *)
(*Note, it's not doing replacement until all edges are touched at least once. That may not always be possible. We just don't want to touch edges twice in a single step.*)


Package["SetReplace`"]


PackageExport["SetReplaceAll"]


(* ::Section:: *)
(*Documentation*)


SetReplaceAll::usage = usageString[
	"SetReplaceAll[`s`, `r`] performs SetReplace[`s`, `r`] as many times as it takes ",
	"until no replacement can be done without touching the same edge twice.",
	"\n",
	"SetReplaceAll[`s`, `r`, `n`] performes the same operation `n` times, i.e., any ",
	"edge will at most be replaced `n` times."];


(* ::Section:: *)
(*Syntax Information*)


SyntaxInformation[SetReplaceAll] = {"ArgumentsPattern" -> {_, _, _., OptionsPattern[]}};


(* ::Section:: *)
(*Argument Checks*)


(* ::Subsection:: *)
(*Argument count*)


SetReplaceAll[args___] := 0 /;
	!Developer`CheckArgumentCount[SetReplaceAll[args], 2, 3] && False


(* ::Section:: *)
(*Options*)


Options[SetReplaceAll] = {
	Method -> Automatic,
	TimeConstraint -> Infinity,
	"EventOrderingFunction" -> Automatic};


(* ::Section:: *)
(*Implementation*)


(* ::Text:: *)
(*We just run SetSubstitutionSystem for the specified number of generations, and take the last set.*)


expr : SetReplaceAll[
		set_, rules_, generations : Except[_ ? OptionQ] : 1, o : OptionsPattern[]] /;
			recognizedOptionsQ[expr, SetReplaceAll, {o}] :=
	Module[{result},
		result = Check[
			setSubstitutionSystem[
				rules, set, <|$maxGenerationsLocal -> generations|>, SetReplaceAll, False, o],
			$Failed];
		If[result === $Aborted, result, result[-1]] /; result =!= $Failed
	]
