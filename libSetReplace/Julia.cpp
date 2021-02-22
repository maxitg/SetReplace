#include "Julia.hpp"

#include <string>
#include <vector>

#include "Set.hpp"

namespace SetReplace {
/*Rule makeRule(jlcxx::ArrayRef<jlcxx::ArrayRef<int>> juliaInputs, jlcxx::ArrayRef<jlcxx::ArrayRef<int>> juliaOutputs,
EventSelectionFunction eventSelectionFunction) { std::vector<AtomsVector> inputs; for (const auto expr : juliaInputs) {
    inputs.push_back({});
    for (const auto atom : expr) {
      inputs.back().push_back(atom);
    }
  }

  std::vector<AtomsVector> outputs;
  for (const auto expr : juliaOutputs) {
    outputs.push_back({});
    for (const auto atom : expr) {
      outputs.back().push_back(atom);
    }
  }

  return {inputs, outputs, eventSelectionFunction};
}*/

JLCXX_MODULE define_julia_module(jlcxx::Module& types) {  // NOLINT
  types.add_bits<EventSelectionFunction>("EventSelectionFunction", jlcxx::julia_type("CppEnum"));
  types.set_const("All", EventSelectionFunction::All);
  types.set_const("Spacelike", EventSelectionFunction::Spacelike);

  types.add_type<Rule>("Rule");

  // types.method("makeRule", &makeRule);

  /*mod.add_type<Set>("Set")
      .constructor<const std::vector<Rule>&,
                   const std::vector<AtomsVector>&,
                   const Set::SystemType&,
                   const Matcher::OrderingSpec&,
                   const Matcher::EventDeduplication&,
                   int>()
      .method("replaceOnce", &Set::replaceOnce)
      .method("replace", &Set::replace);*/
}
}  // namespace SetReplace
