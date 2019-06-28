#ifndef Set_hpp
#define Set_hpp

#include <functional>
#include <memory>
#include <vector>

#include "Expression.hpp"
#include "Rule.hpp"

namespace SetReplace {
    class Set {
    public:
        enum Error {Aborted};

        Set(const std::vector<Rule>& rules, const std::vector<Expression>& initialExpressions, const std::function<bool()> shouldAbort);
        
        int replace();
        int replace(const int stepCount);
        
        std::vector<Expression> expressions() const;
        std::vector<std::pair<RuleID, std::vector<Expression>>> matches() const;
        
    private:
        class Implementation;
        std::shared_ptr<Implementation> implementation_;
    };
}

#endif /* Set_hpp */
