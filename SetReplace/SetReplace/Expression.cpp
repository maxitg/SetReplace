#include "Event.hpp"
#include "Expression.hpp"

namespace SetReplace {
    size_t Expression::SetIteratorHash::operator()(std::set<Event>::const_iterator it) const {
        return std::hash<int64_t>()((int64_t)&(*it));
    }
    
    bool Expression::isInTheFutureOf(const Expression &other) const {
        // TODO(maxitg): This implementation is not correct. It is possible to be causally independent of an actualized event.
        for (const auto& eventAfterOther : other.succedingEvents) {
            if (eventAfterOther->actualized()) { // expression could be deleted if single branch
                return true;
            }
        }
        return false;
    }
}
