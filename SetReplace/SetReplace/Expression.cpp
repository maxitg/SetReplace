#include "Expression.hpp"

namespace SetReplace {
    class Expression::Implementation {
    private:
        const std::vector<AtomID> atoms_;
    public:
        Implementation(const std::vector<int>& atoms) : atoms_(atoms) {}
        
        std::vector<AtomID> atoms() const {
            return atoms_;
        }
    };
    
    Expression::Expression(const std::vector<int>& atoms) {
        implementation_ = std::make_shared<Implementation>(atoms);
    }
    
    std::vector<Expression::AtomID> Expression::atoms() const {
        return implementation_->atoms();
    }
}
