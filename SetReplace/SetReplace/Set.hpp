#ifndef Set_hpp
#define Set_hpp

#include <functional>
#include <memory>
#include <vector>

#include "Expression.hpp"

namespace SetReplace {
    /** @brief Set represents an unordered set that is the state of the set substitution system.
     * @details Set consists of expressions, which are ordered sequences of atoms.
     */
    class Set {
    public:
        /** @brief Specifies a runtime error that occured during evaluation.
         */
        enum Error {Aborted, InputsDisconnected};
        
        /** @brief Creates a new set with specified rules and initial condition.
         * @details Not instantaneous, because the rule matches index is created.
         */
        Set(const std::vector<Rule>& rules,
            const std::vector<AtomsVector>& initialExpressions,
            const bool checkConfluence,
            const std::function<bool()> shouldAbort);
        
        /** @brief Applies a single substitution multiple times.
         * @param count The number of new events that will be attempted to be created.
         * @return Number of events that were created. Note, could be smaller than count if rules do not match any more subsets.
         */
        int createEvents(const int count);
        
        /** @brief Applies substitutions until the next expressions created will have generation larger than maxGeneration.
         * @return The generation of the latest created expression. Note, could be smaller than maxGeneration in case that rules can no longer be applied.
         */
        int replaceUptoGeneration(const int maxGeneration);
        
        /** @brief List of all expressions (past and present) in the set.
         */
        const std::vector<Expression>& expressions() const;
        
        /** @brief List of all events in the causal net of the set.
         */
        const std::set<Event>& events() const;
        
        /** @brief Yields true if the system is confluent.
         * @details The system is defined as confluent if the causal network is unique, i.e., if every expression only has a single possible future event.
         */
        bool isConfluent() const;
        
        std::vector<AtomsVector> atomVectors();
        
    private:
        class Implementation;
        std::shared_ptr<Implementation> implementation_;
    };
}

#endif /* Set_hpp */
