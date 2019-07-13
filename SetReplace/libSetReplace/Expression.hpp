#ifndef Expression_hpp
#define Expression_hpp

#include <vector>

namespace SetReplace {
    using AtomID = int;
    using ExpressionID = int;
    using Expression = std::vector<AtomID>;
}

#endif /* Expression_hpp */
