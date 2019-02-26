#include "Rule.hpp"

namespace SetReplace {
    class Rule::Implementation {
    public:
        Implementation(const std::vector<Expression>& inputs, const std::vector<Expression>& outputs) {}
    };
    
    Rule::Rule(const std::vector<Expression>& inputs, const std::vector<Expression>& outputs) {
        implementation_ = std::make_shared<Implementation>(inputs, outputs);
    }
}
