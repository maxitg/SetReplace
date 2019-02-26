#include "Set.hpp"

#include <unordered_map>

namespace SetReplace {
    class Set::Implementation {
    private:
        const std::vector<Rule> rules_;
        
        using ExpressionID = int;
        std::unordered_map<ExpressionID, Expression> expressions_;
        int nextExpressionID = 0;
        
        std::unordered_map<Expression::AtomID, std::vector<ExpressionID>> atomsIndex_;
        
    public:
        Implementation(const std::vector<Rule>& rules, const std::vector<Expression>& initialExpressions) : rules_(rules) {
            addExpressions(initialExpressions);
        }
        
        void replace() {
            // TODO: not implemented
        }
        
        void replace(const int stepCount) {
            // TODO: not implemented
        }
        
        std::vector<Expression> expressions() const {
            std::vector<Expression> result;
            for (const auto& idExpression : expressions_) {
                result.push_back(idExpression.second);
            }
            return result;
        }
        
    private:
        void addExpressions(const std::vector<Expression>& expressions) {
            const auto ids = assignExpressionIDs(expressions);
            addToAtomsIndex(ids);
            addMatchings(ids);
        }
        
        std::vector<ExpressionID> assignExpressionIDs(const std::vector<Expression>& expressions) {
            std::vector<ExpressionID> ids;
            for (const auto& expression : expressions) {
                ids.push_back(nextExpressionID);
                expressions_.insert(std::make_pair(nextExpressionID++, expression));
            }
            return ids;
        }
        
        void addToAtomsIndex(const std::vector<ExpressionID>& ids) {
            for (const auto expressionID : ids) {
                for (const auto atom : expressions_.at(expressionID).atoms()) {
                    atomsIndex_[atom].push_back(expressionID);
                }
            }
        }
        
        void addMatchings(const std::vector<ExpressionID>& ids) {
            
        }
    };
    
    Set::Set(const std::vector<Rule>& rules, const std::vector<Expression>& initialExpressions) {
        implementation_ = std::make_shared<Implementation>(rules, initialExpressions);
    }
    
    Set Set::replace() {
        implementation_->replace();
        return *this;
    }
    
    Set Set::replace(const int stepCount) {
        implementation_->replace(stepCount);
        return *this;
    }
    
    std::vector<Expression> Set::expressions() const {
        return implementation_->expressions();
    }
}
