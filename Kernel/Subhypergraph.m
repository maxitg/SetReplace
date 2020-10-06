(* ::Package:: *)

(* ::Title:: *)
(*Subhypergraph*)


(* ::Text:: *)
(*Subhypergraph is an utility function that selects hyperedges that only contain vertices from the requested list.*)


Package["SetReplace`"]


PackageExport["Subhypergraph"]
PackageExport["WeakSubhypergraph"]


(* ::Section:: *)
(*Documentation*)


Subhypergraph::usage = usageString[
	"Subhypergraph[`h`, `vertices`] selects hyperedges from `h` that are subsets of `vertices`.",
	"\n",
	"Subhypergraph[`vertices`] represents the operator form for a hypergraph."];


WeakSubhypergraph::usage = usageString[
	"WeakSubhypergraph[`h`, `vertices`] that selects any hyperedge from `h` whose elements are contained in `vertices`.",
	"\n",
	"WeakSubhypergraph[`vertices`] represents the operator form for a hypergraph."];


(* ::Section:: *)
(*SyntaxInformation*)


SyntaxInformation[Subhypergraph] =
	{"ArgumentsPattern" -> {_, _.}};


SyntaxInformation[WeakSubhypergraph] =
	{"ArgumentsPattern" -> {_, _.}};


(* ::Section:: *)
(*Implementation*)


(* ::Subsection:: *)
(*Helper*)


hypergraphQ = MatchQ[#, {___List}]&;


(* ::Subsection:: *)
(*Normal form*)


Subhypergraph[h_ ? hypergraphQ, vertices_List] := Select[h, SubsetQ[vertices, #] &]


WeakSubhypergraph[h_ ? hypergraphQ, vertices_List] := Select[h, ContainsAny[#, vertices] &]


(* ::Subsection:: *)
(*Operator form*)


Subhypergraph[vertices_List][h_ ? hypergraphQ] := Subhypergraph[h, vertices]


WeakSubhypergraph[vertices_List][h_ ? hypergraphQ] := WeakSubhypergraph[h, vertices]


(* ::Section:: *)
(*Argument Checks*)


(* ::Subsection:: *)
(*Argument count*)


Subhypergraph[args___] := 0 /;
	!Developer`CheckArgumentCount[Subhypergraph[args], 1, 2] && False


Subhypergraph[args0___][args1___] := 0 /;
	Length[{args1}] != 1 &&
	Message[Subhypergraph::argx, "Subhypergraph[...]", Length[{args1}], 1]


WeakSubhypergraph[args___] := 0 /;
	!Developer`CheckArgumentCount[WeakSubhypergraph[args], 1, 2] && False


WeakSubhypergraph[args0___][args1___] := 0 /;
	Length[{args1}] != 1 &&
	Message[WeakSubhypergraph::argx, "WeakSubhypergraph[...]", Length[{args1}], 1]


(* ::Subsection:: *)
(*Incorrect arguments messages*)


(* ::Subsubsection:: *)
(*Hypergraph*)


General::invalidHypergraph =
	"The argument at position `1` in `2` is not a valid hypergraph.";


expr: Subhypergraph[h_ ? (Not @* hypergraphQ), _] := 0 /;
	Message[Subhypergraph::invalidHypergraph, 1, HoldForm@expr]


expr: WeakSubhypergraph[h_ ? (Not @* hypergraphQ), _] := 0 /;
	Message[WeakSubhypergraph::invalidHypergraph, 1, HoldForm@expr]


(* ::Subsubsection:: *)
(*Vertices*)


Subhypergraph[h_ , v : Except[_List]] := 0 /; False


WeakSubhypergraph[h_ , v : Except[_List]] := 0 /; False
