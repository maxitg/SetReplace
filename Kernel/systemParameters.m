Package["SetReplace`"]

(* Event-selection parameters *)

declareSystemParameter[##, _ ? (GreaterEqualThan[0])] & @@@ {
  {"MaxGeneration", Infinity},
  {"MaxDestroyerEvents", Infinity},
  {"MinEventInputs", 0},
  {"MaxEventInputs", Infinity}
};

(* Stopping-condition parameters *)

declareSystemParameter["MaxEvents", Infinity, _ ? (GreaterEqualThan[0])];
