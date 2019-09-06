(* ::Package:: *)

(* ::Title:: *)
(*makeMessage*)


(* ::Text:: *)
(*Many functions in the package eventually just call setSubstitutionSystem, as such they reuse many of very similar messages. It is therefore useful to have a function that would define a message of a given type for a given function, and then produce this message.*)


(* ::Text:: *)
(*This way, one does not have to define the same messages over and over again for all functions.*)


Package["SetReplace`"]


PackageScope["makeMessage"]


(* ::Section:: *)
(*Implementation*)


makeMessage[function_, type_String, args___] := (
	MessageName[function, type] = messageTemplate[type];
	Message[MessageName[function, type], function, args]
)


(* ::Section:: *)
(*Message templates*)


messageTemplate["setNotList"] =
	"The set specification `2` should be a List.";


messageTemplate["invalidRules"] =
	"The rule specification `2` should be either a Rule, RuleDelayed, or " ~~
	"a List of them.";


messageTemplate["nonIntegerIterations"] =
	"The number of `2` `3` should be an integer or infinity.";


messageTemplate["invalidMethod"] =
	"Method should be one of " <> ToString[$SetReplaceMethods, InputForm] <> ".";


messageTemplate["cppNotImplemented"] =
	"C++ implementation is only available for local rules, " <>
	"and only for sets of lists (hypergraphs).";


messageTemplate["noCpp"] =
	"C++ implementation was not compiled for your system type.";
