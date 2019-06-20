#include "Match.hpp"

#include <algorithm>

namespace SetReplace {
    namespace {
        int compareVectors(const std::vector<ExpressionID>& first, const std::vector<ExpressionID>& second) {
            for (int i = 0; i < std::min(first.size(), second.size()); ++i) {
                if (first[i] < second[i]) return -1;
                else if (first[i] > second[i]) return +1;
            }
            
            if (first.size() < second.size()) return -1;
            else if (first.size() > second.size()) return 1;
            else return 0;
        }
        
        int compareSortedIDs(const Match& first, const Match& second) {
            std::vector<ExpressionID> thisExpressions = first.expressionIDs;
            std::sort(thisExpressions.begin(), thisExpressions.end());
            
            std::vector<ExpressionID> otherExpressions = second.expressionIDs;
            std::sort(otherExpressions.begin(), otherExpressions.end());
            
            return compareVectors(thisExpressions, otherExpressions);
        }
        
        int compareUnsortedIDs(const Match& first, const Match& second) {
            return compareVectors(first.expressionIDs, second.expressionIDs);
        }
    }
    
    bool Match::operator<(const Match& other) const {
        // First rule goes first
        if (ruleID != other.ruleID) return ruleID < other.ruleID;

        // Then, find which Match has oldest (lowest ID) expressions
        int sortedComparison = compareSortedIDs(*this, other);
        if (sortedComparison != 0) return sortedComparison < 0;

        // Finally, if sets of expressions are the same, use smaller permutation
        return compareUnsortedIDs(*this, other) < 0;
    }
}
