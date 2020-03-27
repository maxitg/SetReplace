#ifndef Set_hpp
#define Set_hpp

#include <functional>
#include <memory>
#include <vector>

#include "Expression.hpp"
#include "Match.hpp"
#include "Rule.hpp"

namespace SetReplace {
    /** @brief Set is the set of expressions (i.e., the graph, the Universe) that is being evolved.
     */
    class Set {
    public:
        /** @brief Type of the error occurred during evaluation.
         */
        enum class Error {Aborted, DisconnectedInputs, NonPositiveAtoms, AtomCountOverflow};
        
        /** @brief Specification of conditions upon which to stop evaluation.
         * @details Each of these is UpTo, i.e., the evolution is terminated when the first of these, fixed point, or an abort is reached.
         * @var maxEvents Total number of events to produce.
         * @var maxGenerationsLocal Total number of generations. Local means the expressions of max generation will never even be matched, which means the evaluation order might be different than if the equivalent number of events is specified, and non-default evaluation order is used.
         * @var maxFinalAtoms The evaluation will be aborted at the first attempt to apply an event, which will cause the number of atoms in the final state to go over the limit.
         * @var maxFinalAtomDegree Same as above, but for the maximum number of expressions a single atom is involved in.
         * @var maxFinalExpressions Same as for the atoms above, but for expressions.
         */
        struct StepSpecification {
            int64_t maxEvents = 0;
            int64_t maxGenerationsLocal = 0;
            int64_t maxFinalAtoms = 0;
            int64_t maxFinalAtomDegree = 0;
            int64_t maxFinalExpressions = 0;
        };
        
        /** @brief Status of evaluation / termination reason if evaluation is finished.
         */
        enum class TerminationReason {
            NotTerminated = 0,
            MaxEvents = 1,
            MaxGenerationsLocal = 2,
            MaxFinalAtoms = 3,
            MaxFinalAtomDegree = 4,
            MaxFinalExpressions = 5,
            FixedPoint = 6,
            Aborted = 7};

        /** @brief Creates a new set with a given set of evolution rules, and initial condition.
         * @param rules substittion rules used for evolution. Note, these rules cannot be changed.
         * @param initialExpressions initial condition. It will be lazily indexed before the first replacement.
         * @param orderingSpec in which order to apply events.
         * @param randomSeed the seed to use for selecting matches in random evaluation case.
         */
        Set(const std::vector<Rule>& rules,
            const std::vector<AtomsVector>& initialExpressions,
            const Matcher::OrderingSpec orderingSpec,
            const unsigned int randomSeed = 0);
        
        /** @brief Perform a single substitution, create the corresponding event, and output expressions.
         * @param shouldAbort function that should return true if Wolfram Language abort is in progress.
         * @return 1 if substitution was made, 0 if no matches were found.
         */
        int64_t replaceOnce(const std::function<bool()> shouldAbort);
        
        /** @brief Run replaceOnce() stepSpec.maxEvents times, or until the next expression violates constraints imposed by stepSpec.
         * @param shouldAbort function that should return true if Wolfram Language abort is in progress.
         * @return The number of subtitutions made, could be between 0 and stepSpec.maxEvents.
         */
        int64_t replace(const StepSpecification stepSpec, const std::function<bool()> shouldAbort);
        
        /** @brief List of all expressions in the set, past and present.
         */
        std::vector<SetExpression> expressions() const;
        
        /** @brief Returns the largest generation that has both been reached, and has no matches that would produce expressions with that or lower generation.
         * @details Takes O(matches count) + as long as it would take to do the next step (because new expressions need to be indexed).
         */
        Generation maxCompleteGeneration(const std::function<bool()> shouldAbort);
        
        /** @brief Yields termination reason for the previous evaluation, or TerminationReason::NotTerminated if no evaluation was done yet.
         */
        TerminationReason terminationReason() const;
        
        /** @brief Yields rule IDs corresponding to each event.
         */
        const std::vector<RuleID>& eventRuleIDs() const;

    private:
        class Implementation;
        std::shared_ptr<Implementation> implementation_;
    };
}

#endif /* Set_hpp */
