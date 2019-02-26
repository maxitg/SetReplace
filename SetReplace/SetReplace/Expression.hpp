#ifndef Expression_hpp
#define Expression_hpp

#include <memory>
#include <vector>

namespace SetReplace {
    class Expression {
    public:
        using AtomID = int;
        
        Expression(const std::vector<AtomID>& atoms);
        
        std::vector<AtomID> atoms() const;
    private:
        class Implementation;
        std::shared_ptr<Implementation> implementation_;
    };
}

#endif /* Expression_hpp */
