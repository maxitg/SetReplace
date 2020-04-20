#ifndef Rule_hpp
#define Rule_hpp

#include "IDTypes.hpp"

namespace SetReplace {
    /** @brief Substitution rule used in the evolution.
     */
    struct Rule {
        std::vector<AtomsVector> inputs;
        std::vector<AtomsVector> outputs;
    };
}

#endif /* Rule_hpp */
