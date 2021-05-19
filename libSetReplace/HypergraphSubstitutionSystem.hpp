#ifndef LIBSETREPLACE_HYPERGRAPHSUBSTITUTIONSYSTEM_HPP_
#define LIBSETREPLACE_HYPERGRAPHSUBSTITUTIONSYSTEM_HPP_

#include <functional>
#include <limits>
#include <memory>
#include <vector>

#include "AtomsIndex.hpp"
#include "HypergraphMatcher.hpp"
#include "Rule.hpp"
#include "TokenEventGraph.hpp"

namespace SetReplace {
/** @brief HypergraphSubstitutionSystem is a kind of the multiset substitution system where tokens are ordered sequences
 * of atoms.
 */
class HypergraphSubstitutionSystem {
 public:
  /** @brief Type of the error occurred during evaluation.
   */
  enum class Error {
    Aborted,
    DisconnectedInputs,
    NonPositiveAtoms,
    AtomCountOverflow,
    FinalStateStepSpecificationForMultihistory
  };

  static constexpr int64_t stepLimitDisabled = std::numeric_limits<int64_t>::max();

  /** @brief Specification of conditions upon which to stop evaluation.
   * @details Each of these is UpTo, i.e., the evaluation is terminated when the first of these, fixed point, or an
   * abort is reached.
   * @var maxEvents Total number of events to produce.
   * @var maxGenerationsLocal Total number of generations. Local means the tokens of max generation will never even
   * be matched, which means the evaluation order might be different than if the equivalent number of events is
   * specified, and non-default evaluation order is used.
   * @var maxFinalAtoms The evaluation will be aborted at the first attempt to apply an event, which will cause the
   * number of atoms in the final state to go over the limit.
   * @var maxFinalAtomDegree Same as above, but for the maximum number of tokens a single atom is involved in.
   * @var maxFinalTokens Same as for the atoms above, but for tokens.
   */
  struct StepSpecification {
    int64_t maxEvents = stepLimitDisabled;
    int64_t maxGenerationsLocal = stepLimitDisabled;
    int64_t maxFinalAtoms = stepLimitDisabled;
    int64_t maxFinalAtomDegree = stepLimitDisabled;
    int64_t maxFinalTokens = stepLimitDisabled;
  };

  /** @brief Status of evaluation / termination reason if evaluation is finished.
   */
  enum class TerminationReason {
    NotTerminated = 0,
    MaxEvents = 1,
    MaxGenerationsLocal = 2,
    MaxFinalAtoms = 3,
    MaxFinalAtomDegree = 4,
    MaxFinalTokens = 5,
    Complete = 6,
    Aborted = 7,
    TimeConstrained = 8,
  };

  /** @brief Creates a new hypergraph system with given evaluation rules, and initial condition.
   * @param rules substitution rules used for evaluation. Note, these rules cannot be changed.
   * @param initialTokens initial state. It will be lazily indexed before the first replacement.
   * @param maxDestroyerEvents maximum number of allowed destroyer events per token.
   * @param orderingSpec in which order to apply events.
   * @param eventIdentification defines which events should be treated as identical.
   * @param randomSeed the seed to use for selecting matches in random evaluation case.
   */
  HypergraphSubstitutionSystem(const std::vector<Rule>& rules,
                               const std::vector<AtomsVector>& initialTokens,
                               uint64_t maxDestroyerEvents,
                               const HypergraphMatcher::OrderingSpec& orderingSpec,
                               const HypergraphMatcher::EventDeduplication& eventIdentification,
                               unsigned int randomSeed = 0);

  /** @brief Perform a single substitution, create the corresponding event, and output tokens.
   * @param shouldAbort function that should return true if abort is requested.
   * @return 1 if substitution was made, 0 if no matches were found.
   */
  int64_t replaceOnce(const std::function<bool()>& shouldAbort);

  /** @brief Run replaceOnce() stepSpec.maxEvents times, or until the next token violates constraints imposed by
   * stepSpec.
   * @param shouldAbort function that should return true if abort is requested.
   * @param timeConstraint number of seconds before stopping the execution.
   * @return The number of subtitutions made, could be between 0 and stepSpec.maxEvents.
   */
  int64_t replace(const StepSpecification& stepSpec,
                  const std::function<bool()>& shouldAbort,
                  const double timeConstraint);

  /** @brief List of all tokens in the system, past and present.
   */
  std::vector<AtomsVector> tokens() const;

  /** @brief Returns the largest generation that has both been reached, and has no matches that would produce
   * tokens with that or lower generation.
   * @details Takes O(matches count) + as long as it would take to do the next step (because new tokens need to be
   * indexed).
   */
  Generation maxCompleteGeneration(const std::function<bool()>& shouldAbort);

  /** @brief Yields termination reason for the previous evaluation, or TerminationReason::NotTerminated if no evaluation
   * was done yet.
   */
  TerminationReason terminationReason() const;

  /** @brief Yields rule IDs corresponding to each event.
   */
  const std::vector<Event>& events() const;

 private:
  class Implementation;
  std::shared_ptr<Implementation> implementation_;
};
}  // namespace SetReplace

#endif  // LIBSETREPLACE_HYPERGRAPHSUBSTITUTIONSYSTEM_HPP_
