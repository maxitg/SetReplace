#ifndef Set_hpp
#define Set_hpp

#include <functional>
#include <memory>
#include <vector>

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
         * @param initialExpressions initial condition. It will be lazily indexed before the first replacement.
         */
        Set(const std::vector<Rule>& rules,
            const std::vector<AtomsVector>& initialExpressions);
        
        /** @brief Perform a single substitution, create the corresponding event, and output expressions.
         * @param shouldAbort function that should return true if Wolfram Language abort is in progress.
         * @return 1 if substitution was made, 0 if no matches were found.
         */
        int replaceOnce(const std::function<bool()> shouldAbort);
        
        /** @brief Run replaceOnce() substitutionCount times, or until the next expression produced has generation larger than maxGeneration.
         * @param shouldAbort function that should return true if Wolfram Language abort is in progress.
         * @return The number of subtitutions made, could be between 0 and substitutionCount.
         */
        int replace(const Generation maxGeneration, const int substitutionCount, const std::function<bool()> shouldAbort);
        
        /** @brief List of all expressions in the set, past and present.
         */
        std::vector<SetExpression> expressions() const;
        
    private:
        class Implementation;
        std::shared_ptr<Implementation> implementation_;
    };
}

#endif /* Set_hpp */
