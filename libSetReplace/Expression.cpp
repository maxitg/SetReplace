#include "Expression.hpp"

#include <algorithm>
#include <unordered_map>

namespace SetReplace {
    class AtomsIndex::Implementation {
    private:
        const std::function<AtomsVector(ExpressionID)> getAtomsVector_;
        std::unordered_map<Atom, std::unordered_set<ExpressionID>> index_;
        
    public:
        Implementation(const std::function<AtomsVector(ExpressionID)>& getAtomsVector) : getAtomsVector_(getAtomsVector) {}
        
        void removeExpressions(const std::vector<ExpressionID>& expressionIDs) {
            std::unordered_set<ExpressionID> expressionsToDelete;
            for (const auto& expression : expressionIDs) {
                expressionsToDelete.insert(expression);
            }
            
            std::unordered_set<Atom> involvedAtoms;
            for (const auto& expression : expressionIDs) {
                for (const auto& atom : getAtomsVector_(expression)) {
                    involvedAtoms.insert(atom);
                }
            }
            
            for (const auto& atom : involvedAtoms) {
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
        
        void addExpressions(const std::vector<ExpressionID>& expressionIDs) {
            for (const auto expressionID : expressionIDs) {
                for (const auto atom : getAtomsVector_(expressionID)) {
                    index_[atom].insert(expressionID);
                }
            }
        }
        
        const std::unordered_set<ExpressionID> expressionsContainingAtom(const Atom atom) const {
            if (index_.count(atom)) {
                return index_.at(atom);
            } else {
                return {};
            }
        }
    };
    
    AtomsIndex::AtomsIndex(const std::function<AtomsVector(ExpressionID)>& getAtomsVector) {
        implementation_ = std::make_shared<Implementation>(getAtomsVector);
    }
    
    void AtomsIndex::removeExpressions(const std::vector<ExpressionID>& expressionIDs) {
        implementation_->removeExpressions(expressionIDs);
    }
    
    void AtomsIndex::addExpressions(const std::vector<ExpressionID>& expressionIDs) {
        implementation_->addExpressions(expressionIDs);
    }
    
    const std::unordered_set<ExpressionID> AtomsIndex::expressionsContainingAtom(const Atom atom) const {
        return implementation_->expressionsContainingAtom(atom);
    }
}
