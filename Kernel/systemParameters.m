Package["SetReplace`"]

(* Event-selection parameters *)

PackageExport["MaxGeneration"]
PackageExport["MaxDestroyerEvents"]
PackageExport["MinEventInputs"]
PackageExport["MaxEventInputs"]

declareSystemParameter[#, #2, _ ? (GreaterEqualThan[0]), #3] & @@@ {
  {MaxGeneration, Infinity, "is a parameter specifying the maximum generations of tokens that will be created."},
  {MaxDestroyerEvents, Infinity, "..."},
  {MinEventInputs, 0, "..."},
  {MaxEventInputs, Infinity, "..."}
};

(* Stopping-condition parameters *)

PackageExport["MaxEvents"]

declareSystemParameter[MaxEvents, Infinity, _ ? (GreaterEqualThan[0]), "..."];
