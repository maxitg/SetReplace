#include "Expression.hpp"

#include <algorithm>
#include <unordered_map>

namespace SetReplace {
    class AtomsIndex::Implementation {
    private:
        const std::function<AtomsVector(ExpressionIndex)> getAtomsVector_;
        std::unordered_map<Atom, std::unordered_set<ExpressionIndex>> index_;
        
    public:
        Implementation(const std::function<AtomsVector(ExpressionIndex)>& getAtomsVector) : getAtomsVector_(getAtomsVector) {}
        
        void removeExpressions(const std::vector<ExpressionIndex>& expressionIndices) {
            std::unordered_set<ExpressionIndex> expressionsToDelete;
            for (const auto& expression : expressionIndices) {
                expressionsToDelete.insert(expression);
            }
            
            std::unordered_set<Atom> involedAtoms;
            for (const auto& expression : expressionIndices) {
                for (const auto& atom : getAtomsVector_(expression)) {
                    involedAtoms.insert(atom);
                }
            }
            
            for (const auto& atom : involedAtoms) {
                auto expressionIterator = index_[atom].begin();
                while (expressionIterator != index_[atom].end()) {
                    if (expressionsToDelete.count(*expressionIterator)) {
                        expressionIterator = index_[atom].erase(expressionIterator);
                    } else {
                        ++expressionIterator;
                    }
                }
                if (index_[atom].empty()) {
                    index_.erase(atom);
                }
            }
        }
        
        void addExpressions(const std::vector<ExpressionIndex>& expressionIndices) {
            for (const auto expressionIndex : expressionIndices) {
                for (const auto atom : getAtomsVector_(expressionIndex)) {
                    index_[atom].insert(expressionIndex);
                }
            }
        }
        
        const std::unordered_set<ExpressionIndex> expressionsContainingAtom(const Atom atom) const {
            if (index_.count(atom)) {
                return index_.at(atom);
            } else {
                return {};
            }
        }
    };
    
    AtomsIndex::AtomsIndex(const std::function<AtomsVector(ExpressionIndex)>& getAtomsVector) {
        implementation_ = std::make_shared<Implementation>(getAtomsVector);
    }
    
    void AtomsIndex::removeExpressions(const std::vector<ExpressionIndex>& expressionIndices) {
        implementation_->removeExpressions(expressionIndices);
    }
    
    void AtomsIndex::addExpressions(const std::vector<ExpressionIndex> &expressionIndices) {
        implementation_->addExpressions(expressionIndices);
    }
    
    const std::unordered_set<ExpressionIndex> AtomsIndex::expressionsContainingAtom(const Atom atom) const {
        return implementation_->expressionsContainingAtom(atom);
    }
}
