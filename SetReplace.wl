(* ::Package:: *)

(* ::Title:: *)
(*Implementation of*)
(*Set Substitution System*)


(* ::Text:: *)
(*See https://github.com/maxitg/set-replace.*)


BeginPackage["SetReplace`"];


UnorderedSet::usage =
	"UnorderedSet[\!\(\*SubscriptBox[\(e\), \(1\)]\), "~~
	"\!\(\*SubscriptBox[\(e\), \(2\)]\), \[Ellipsis]] is an unordered collection of elements.";


SetReplace::usage =
	"SetReplace[s, {\!\(\*SubscriptBox[\(i\), \(1\)]\) \[Rule] "~~
	"\!\(\*SubscriptBox[\(o\), \(1\)]\), \!\(\*SubscriptBox[\(i\), \(2\)]\) \[Rule] "~~
	"\!\(\*SubscriptBox[\(o\), \(2\)]\), \[Ellipsis]}] attempts to replace a subset "~~
	"\!\(\*SubscriptBox[\(i\), \(1\)]\) of s with \!\(\*SubscriptBox[\(o\), \(1\)]\). "~~
	"If not found, replaces \!\(\*SubscriptBox[\(i\), \(2\)]\) with "~~
	"\!\(\*SubscriptBox[\(o\), \(2\)]\), etc.";


Begin["`Private`"];


End[];


EndPackage[];
