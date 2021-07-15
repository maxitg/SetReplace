Package["SetReplace`"]

(* Event-selection parameters *)

PackageExport["MaxGeneration"]
PackageExport["MaxDestroyerEvents"]
PackageExport["MinEventInputs"]
PackageExport["MaxEventInputs"]
PackageExport["MaxEvents"]

declareSystemParameter[#, #2, _ ? (GreaterEqualThan[0]), #3] & @@@ {
  {MaxGeneration,
   Infinity,
   "is an event-selection parameter specifying the maximum generation of created tokens.\n" <>
   "* Tokens in init$ are assumed to have generation 0.\n" <>
   "* A generation of an event and its output tokens is defined as the largest generation of its inputs plus one."},
  {MaxDestroyerEvents,
   Infinity,
   "is an event-selection parameter specifying the number of events that can use a single token as their input.\n" <>
   "* Setting this to 1 limits evaluation to a single history."},
  {MinEventInputs, 0, "is an event-selection parameter specifying the minimum number of input tokens of events."},
  {MaxEventInputs, Infinity, "is an event-selection parameter specifying the maximum number of input tokens of events."}
};

(* Stopping-condition parameters *)

declareSystemParameter[
  MaxEvents,
  Infinity,
  _ ? (GreaterEqualThan[0]),
  "is a stopping-condition parameter that stops evaluation after a specified number of events."];
