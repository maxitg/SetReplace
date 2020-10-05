#include "Set.hpp"

#include <vector>

#include <gtest/gtest.h>

#include "Match.hpp"
#include "Rule.hpp"

namespace SetReplace {

constexpr auto doNotAbort = []() { return false; };

TEST(Set, replaceOnce) {
  Matcher::OrderingSpec orderingSpec = {
      {Matcher::OrderingFunction::SortedExpressionIDs, Matcher::OrderingDirection::Normal},
      {Matcher::OrderingFunction::ReverseSortedExpressionIDs, Matcher::OrderingDirection::Normal},
      {Matcher::OrderingFunction::ExpressionIDs, Matcher::OrderingDirection::Normal},
      {Matcher::OrderingFunction::RuleIndex, Matcher::OrderingDirection::Normal}};

  Set set({{{{-1}}, {{-1, -1}}}}, {{1}}, {}, orderingSpec, Matcher::EventDeduplication::None, 0);
  EXPECT_EQ(set.replaceOnce(doNotAbort), 1);
}

}  // namespace SetReplace
