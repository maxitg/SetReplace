#ifndef Match_hpp
#define Match_hpp

#include <vector>

#include "Expression.hpp"

namespace SetReplace {
    struct Match {
        int ruleID;
        std::vector<ExpressionID> expressionIDs;
        
        bool operator<(const Match& other) const;
    };
}

#endif /* Match_hpp */
