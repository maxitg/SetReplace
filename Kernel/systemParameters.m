Package["SetReplace`"]

declareSystemParameter @@@ {
  {"MaxGeneration", Infinity, _ ? (GreaterEqualThan[0])},
  {"MaxDestroyerEvents", Infinity, _ ? (GreaterEqualThan[0])},
  {"MinEventInputs", 0, _ ? (GreaterEqualThan[0])},
  {"MaxEventInputs", Infinity, _ ? (GreaterEqualThan[0])},
  {"MaxEvents", Infinity, _ ? (GreaterEqualThan[0])}
};
