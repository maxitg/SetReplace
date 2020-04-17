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
            const std::unordered_set<ExpressionID> expressionsToDelete(expressionIDs.begin(), expressionIDs.end());
            
            std::unordered_set<Atom> involvedAtoms;
            for (const auto& expression : expressionIDs) {
                const auto atomsVector = getAtomsVector_(expression);
                // Increase set capacity to reduce number of memory allocations
                involvedAtoms.reserve(involvedAtoms.size() + atomsVector.size());
                for (const auto& atom : atomsVector) {
                    involvedAtoms.insert(atom);
                }
            }
            
            for (const auto& atom : involvedAtoms) {
                auto& currentExpressions = index_[atom];
                for (const auto& expression : expressionsToDelete) {
                    if (currentExpressions.empty()) {
                        break;
                    }
                    currentExpressions.erase(expression);
                }
                if (currentExpressions.empty()) {
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
            const auto resultIterator = index_.find(atom);
            return resultIterator != index_.end() ? resultIterator->second : std::unordered_set<ExpressionID>();
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
