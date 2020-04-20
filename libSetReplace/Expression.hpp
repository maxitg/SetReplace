#ifndef Expression_hpp
#define Expression_hpp

#include "IDTypes.hpp"

#include <functional>
#include <memory>
#include <unordered_set>

namespace SetReplace {
    
    /** @brief Expression, as a part of the set, i.e., (hyper)edges in the graph.
     */
    struct SetExpression {
        /** @brief Ordered list of atoms the expression contains.
         */
        AtomsVector atoms;
        
        /** @brief Substitution event that has this expression as part of its output.
         */
        EventID creatorEvent;
        
        /** @brief Substitution event that has this expression as part of its input.
         */
        EventID destroyerEvent = finalStateEvent;
        
        /** @brief Layer of the causal network this expression belongs to.
         */
        Generation generation;
    };
    
    /** @brief AtomsIndex keeps references to set expressions accessible by atoms, which is useful for matching.
     */
    class AtomsIndex {
    public:
        /** @brief Creates an empty index.
         * @param getAtomsVector datasource function that returns the list of atoms for a requested expression.
         */
        AtomsIndex(std::function<AtomsVector(ExpressionID)> getAtomsVector);
        ~AtomsIndex();
        
        /** @brief Removes expressions with specified IDs from the index.
         */
        void removeExpressions(const std::vector<ExpressionID>& expressionIDs);
        
        /** @brief Adds expressions with specified IDs to the index.
         */
        void addExpressions(const std::vector<ExpressionID>& expressionIDs);
        
        /** @brief Returns the list of expressions containing a specified atom.
         */
        std::unordered_set<ExpressionID> expressionsContainingAtom(const Atom atom) const;
        
        const std::function<AtomsVector(ExpressionID)>& getAtomsVector() const;
        
    private:
        class Implementation;
        std::unique_ptr<Implementation> implementation_;
    };
}

#endif /* Expression_hpp */
