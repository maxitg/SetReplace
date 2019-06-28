#ifndef Match_hpp
#define Match_hpp

#include <vector>

#include "Expression.hpp"
#include "Rule.hpp"

namespace SetReplace {
    struct Match {
        RuleID ruleID;
        std::vector<ExpressionID> expressionIDs;
        
        bool operator<(const Match& other) const;
    };
}

#endif /* Match_hpp */
