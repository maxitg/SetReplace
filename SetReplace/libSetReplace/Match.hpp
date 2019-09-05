#ifndef Match_hpp
#define Match_hpp

#include <vector>
#include <set>

#include "IDTypes.hpp"
#include "Expression.hpp"
#include "Rule.hpp"

namespace SetReplace {
    /** @brief Match is a potential event that has not actualized yet.
     */
    struct Match {
        /** @brief ID for the rule this match corresponds to.
         */
        RuleID rule;
        
        /** @brief Expression matching the rule inputs.
         */
        std::vector<ExpressionID> inputExpressions;
        
        /** @brief Matches that will be evaluated earlier are defined to be smaller.
         */
        bool operator<(const Match& other) const;
    };
    
    /** @brief Matcher takes rules, atoms index, and a list of expressions, and returns all possible matches.
     * @details This contains the lowest-level code, and the main functionality of the library. Uses atomsIndex to discover expressions, thus if an expression is absent from the atomsIndex, it would not appear in any matches.
     */
    class Matcher {
    public:
        /** @brief Type of the error occurred during evaluation.
         */
        enum Error {Aborted, DisconnectedInputs, NoMatches};
        
        /** @brief Creates a new matcher object.
         * @details This is an O(1) operation, does not do any matching yet.
         */
        Matcher(const std::vector<Rule>& rules,
                AtomsIndex& atomsIndex,
                const std::function<AtomsVector(ExpressionID)> getAtomsVector,
                const std::function<bool()> shouldAbort);
        
        /** @brief Finds and adds to the index all matches involving specified expressions.
         * @details Calls shouldAbort() frequently, and throws Error::Aborted if that returns true. Otherwise might take significant time to evaluate depending on the system.
         */
        void addMatchesInvolvingExpressions(const std::vector<ExpressionID>& expressionIDs);
        
        /** @brief Removes matches containing specified expression IDs from the index.
         */
        void removeMatchesInvolvingExpressions(const std::vector<ExpressionID>& expressionIDs);
        
        /** @brief Returns the number of matches currently available.
         */
        int matchCount() const;
        
        /** @brief Returns the match that should be substituted next.
         * @details Throws Error::NoMatches if there are no matches.
         */
        Match nextMatch() const;
        
        /** @brief Replaces patterns in atomsToReplace with explicit atoms.
         * @param inputPatterns patterns corresponding to patternMatches.
         * @param patternMatches explicit atoms corresponding to patterns in inputPatterns.
         * @param atomsToReplace patterns, which would be replaced the same way as inputPatterns are matched to patternMatches.
         */
        static bool substituteMissingAtomsIfPossible(const std::vector<AtomsVector> inputPatterns,
                                                     const std::vector<AtomsVector> patternMatches,
                                                     std::vector<AtomsVector>& atomsToReplace);
        
    private:
        class Implementation;
        std::shared_ptr<Implementation> implementation_;
    };
}

#endif /* Match_hpp */
