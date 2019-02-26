#ifndef Rule_hpp
#define Rule_hpp

#include <vector>

#include "Expression.hpp"

namespace SetReplace {
    struct Rule {
        std::vector<Expression> inputs;
        std::vector<Expression> outputs;
    };
}

#endif /* Rule_hpp */
