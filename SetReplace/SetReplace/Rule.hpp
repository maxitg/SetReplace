#ifndef Rule_hpp
#define Rule_hpp

#include <memory>

#include "Expression.hpp"

namespace SetReplace {
    class Rule {
    public:
        Rule(const std::vector<Expression>& inputs, const std::vector<Expression>& outputs);
    private:
        class Implementation;
        std::shared_ptr<Implementation> implementation_;
    };
}

#endif /* Rule_hpp */
