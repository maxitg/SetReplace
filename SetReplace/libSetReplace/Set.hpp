#ifndef Set_hpp
#define Set_hpp

#include <functional>
#include <memory>
#include <vector>

#include "Event.hpp"
#include "Expression.hpp"
#include "Rule.hpp"

namespace SetReplace {
    /** @brief Set is the set of expressions (i.e., the graph, the Universe) that is being evolved.
     */
    class Set {
    public:
        /** @brief Type of the error occurred during evaluation.
         */
        enum Error {Aborted, DisconnectedInputs, NonPositiveAtoms};
        
        /** @brief Creates a new set with a given set of evolution rules, and initial condition.
         * @param rules substittion rules used for evolution. Note, these rules cannot be changed.
         * @param initialExpressions initial condition, which will be indexed at constraction, so this operation is not instant.
         * @param shouldAbort function that should return true if Wolfram Language abort is in progress.
         * @param maxGeneration largest generation created. Events will never be created which have this generation expressions as inputs.
         */
        Set(const std::vector<Rule>& rules,
            const std::vector<AtomsVector>& initialExpressions,
            const std::function<bool()> shouldAbort,
            const Generation maxGeneration = std::numeric_limits<Generation>::max());
        
        /** @brief Perform a single substitution, create the corresponding event, and output expressions.
         * @return 1 if substitution was made, 0 if no matches were found.
         */
        int replaceOnce();
        
        /** @brief Run replaceOnce() substitutionCount times.
         * @return The number of subtitutions made, could be between 0 and substitutionCount.
         */
        int replace(const int substitutionCount = std::numeric_limits<int>::max());
        
        /** @brief List of all expressions in the set, past and present.
         */
        std::vector<SetExpression> expressions() const;
        
        /** @brief List of all past events.
         * @details Not that does not include matches for future events that have not been actualized yet.
         */
        std::vector<Event> events() const;
        
    private:
        class Implementation;
        std::shared_ptr<Implementation> implementation_;
    };
}

#endif /* Set_hpp */
