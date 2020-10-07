#include <gtest/gtest.h>

#include "Set.hpp"

namespace SetReplace {

constexpr auto doNotAbort = []() { return false; };

Matcher::OrderingSpec orderingSpec = {
    {Matcher::OrderingFunction::SortedExpressionIDs, Matcher::OrderingDirection::Normal},
    {Matcher::OrderingFunction::ReverseSortedExpressionIDs, Matcher::OrderingDirection::Normal},
    {Matcher::OrderingFunction::ExpressionIDs, Matcher::OrderingDirection::Normal},
    {Matcher::OrderingFunction::RuleIndex, Matcher::OrderingDirection::Normal}};

TEST(Set, profileSingleInputRule) {
  Set set({{{{-1, -2}}, {{-1, -3}, {-1, -3}, {-3, -2}}}},
          {{1, 1}},
          Set::SystemType::Singleway,
          orderingSpec,
          Matcher::EventDeduplication::None);
  EXPECT_EQ(set.replace(Set::StepSpecification{1000}, doNotAbort), 1000);
}

TEST(Set, profileMediumRule) {
  Set set({{{{-1, -2, -3}, {-4, -3, -5}, {-3, -6}},
            {{-6, -7, -8}, {-6, -9, -10}, {-11, -8, -10}, {-5, -2, -9}, {-9, -9}, {-1, -9}, {-7, -5}, {-8, -5}}}},
          {{1, 1, 1}, {1, 1, 1}, {1, 1}},
          Set::SystemType::Singleway,
          orderingSpec,
          Matcher::EventDeduplication::None);
  EXPECT_EQ(set.replace(Set::StepSpecification{5000}, doNotAbort), 5000);
}

TEST(Set, profileSequentialRule) {
  Set set({{{{-1, -2, -2}, {-3, -2, -4}}, {{-5, -4, -4}, {-4, -3, -5}, {-3, -5, -1}}}},
          {{1, 1, 1}, {1, 1, 1}},
          Set::SystemType::Singleway,
          orderingSpec,
          Matcher::EventDeduplication::None);
  EXPECT_EQ(set.replace(Set::StepSpecification{10000}, doNotAbort), 10000);
}

TEST(Set, profileLargeRule) {
  Set set({{{{-1, -2}, {-2, -1}, {-1, -3}, {-2, -3}, {-3, -1}, {-3, -2}},
            {{-1, -2},
             {-2, -1},
             {-1, -3},
             {-2, -3},
             {-3, -1},
             {-3, -2},
             {-1, -4},
             {-2, -4},
             {-3, -4},
             {-4, -1},
             {-4, -2},
             {-4, -3}}}},
          {{1, 1}, {1, 1}, {1, 1}, {1, 1}, {1, 1}, {1, 1}},
          Set::SystemType::Singleway,
          orderingSpec,
          Matcher::EventDeduplication::None);
  EXPECT_EQ(set.replace(Set::StepSpecification{4}, doNotAbort), 4);
}

TEST(Set, profileExponentialMatchCountRule) {
  Set set({{{{-1}, {-1}, {-1}}, {{-1}, {-1}, {-1}, {-1}}}},
          {{1}, {1}, {1}},
          Set::SystemType::Singleway,
          orderingSpec,
          Matcher::EventDeduplication::None);
  EXPECT_EQ(set.replace(Set::StepSpecification{18}, doNotAbort), 18);
}

TEST(Set, profileCAEmulator) {
  Rule rule1 = {
      {{-18, -18, -3}, {-3, -19, -3}, {-3, -3, -3, -3, -3}},
      {{-1, -1, -1, -12},
       {-1, -1, -14, -1},
       {-1, -10, -10},
       {-1, -1, -5},
       {-5, -5, -5, -5, -5},
       {-5, -4, -5},
       {-1, -19, -1},
       {-1},
       {-4, -12, -12},
       {-4},
       {-17, -14, -14},
       {-17},
       {-18, -18, -17}},
  };

  Rule rule2 = {{{-18, -16, -18}, {-16, -16, -20}, {-16, -16}},
                {{-1, -1, -14, -1},
                 {-1, -1, -1, -12},
                 {-1, -10, -10},
                 {-1, -6, -1},
                 {-6, -6},
                 {-6, -6, -17},
                 {-1, -1, -20},
                 {-1},
                 {-17, -14, -14},
                 {-17},
                 {-4, -12, -12},
                 {-4},
                 {-18, -4, -18}}};

  Rule rule3 = {{{-1, -1, -2},
                 {-2, -11, -11},
                 {-1, -15, -1},
                 {-15, -13, -13},
                 {-1, -1, -1, -12},
                 {-1, -1, -14, -1},
                 {-1, -10, -10},
                 {-1, -1, -1, -1, -1, -1},
                 {-2, -2, -2, -2, -2, -2},
                 {-15, -15, -15, -15, -15, -15}},
                {{-10, -10, -11},
                 {-10, -13, -10},
                 {-10, -7, -7},
                 {-10, -10, -10, -8},
                 {-10, -10, -9, -10},
                 {-10},
                 {-12},
                 {-14},
                 {-12, -8, -8},
                 {-14, -9, -9}}};

  Rule rule4 = {{{-1, -1, -2},
                 {-2, -11, -11},
                 {-1, -15, -1},
                 {-15, -13, -13},
                 {-1, -1, -1, -12},
                 {-1, -1, -14, -1},
                 {-1, -10, -10},
                 {-1, -1, -1, -1, -1, -1},
                 {-2, -2, -2, -2, -2, -2},
                 {-15}},
                {{-10, -10, -11},
                 {-10, -13, -10},
                 {-10, -7, -7},
                 {-10, -10, -10, -8},
                 {-10, -10, -9, -10},
                 {-10, -10, -10, -10, -10, -10},
                 {-12, -12, -12, -12, -12, -12},
                 {-14, -14, -14, -14, -14, -14},
                 {-12, -8, -8},
                 {-14, -9, -9}}};

  Rule rule5 = {{{-1, -1, -2},
                 {-2, -11, -11},
                 {-1, -15, -1},
                 {-15, -13, -13},
                 {-1, -1, -1, -12},
                 {-1, -1, -14, -1},
                 {-1, -10, -10},
                 {-1},
                 {-2, -2, -2, -2, -2, -2},
                 {-15, -15, -15, -15, -15, -15}},
                {{-10, -10, -11},
                 {-10, -13, -10},
                 {-10, -7, -7},
                 {-10, -10, -10, -8},
                 {-10, -10, -9, -10},
                 {-10, -10, -10, -10, -10, -10},
                 {-12, -12, -12, -12, -12, -12},
                 {-14, -14, -14, -14, -14, -14},
                 {-12, -8, -8},
                 {-14, -9, -9}}};

  Rule rule6 = {{{-1, -1, -2},
                 {-2, -11, -11},
                 {-1, -15, -1},
                 {-15, -13, -13},
                 {-1, -1, -1, -12},
                 {-1, -1, -14, -1},
                 {-1, -10, -10},
                 {-1},
                 {-2, -2, -2, -2, -2, -2},
                 {-15}},
                {{-10, -10, -11},
                 {-10, -13, -10},
                 {-10, -7, -7},
                 {-10, -10, -10, -8},
                 {-10, -10, -9, -10},
                 {-10},
                 {-12},
                 {-14},
                 {-12, -8, -8},
                 {-14, -9, -9}}};

  Rule rule7 = {{{-1, -1, -2},
                 {-2, -11, -11},
                 {-1, -15, -1},
                 {-15, -13, -13},
                 {-1, -1, -1, -12},
                 {-1, -1, -14, -1},
                 {-1, -10, -10},
                 {-1},
                 {-2},
                 {-15, -15, -15, -15, -15, -15}},
                {{-10, -10, -11},
                 {-10, -13, -10},
                 {-10, -7, -7},
                 {-10, -10, -10, -8},
                 {-10, -10, -9, -10},
                 {-10, -10, -10, -10, -10, -10},
                 {-12, -12, -12, -12, -12, -12},
                 {-14, -14, -14, -14, -14, -14},
                 {-12, -8, -8},
                 {-14, -9, -9}}};

  Rule rule8 = {{{-1, -1, -2},
                 {-2, -11, -11},
                 {-1, -15, -1},
                 {-15, -13, -13},
                 {-1, -1, -1, -12},
                 {-1, -1, -14, -1},
                 {-1, -10, -10},
                 {-1},
                 {-2},
                 {-15}},
                {{-10, -10, -11},
                 {-10, -13, -10},
                 {-10, -7, -7},
                 {-10, -10, -10, -8},
                 {-10, -10, -9, -10},
                 {-10},
                 {-12},
                 {-14},
                 {-12, -8, -8},
                 {-14, -9, -9}}};

  std::vector<Rule> rules{std::move(rule1),
                          std::move(rule2),
                          std::move(rule3),
                          std::move(rule4),
                          std::move(rule5),
                          std::move(rule6),
                          std::move(rule7),
                          std::move(rule8)};

  std::vector<AtomsVector> initialExpressions = {{3, 3, 3, 6},
                                                 {3, 3, 7, 3},
                                                 {3, 5, 5},
                                                 {3, 3, 1},
                                                 {3, 2, 3},
                                                 {3, 3, 3, 3, 3, 3},
                                                 {4, 6, 6},
                                                 {4, 4, 4, 4, 4, 4},
                                                 {8, 7, 7},
                                                 {8, 8, 8, 8, 8, 8},
                                                 {1, 4, 1},
                                                 {1, 1, 1, 1, 1},
                                                 {2, 2, 8},
                                                 {2, 2}};

  Set set(rules, initialExpressions, Set::SystemType::Singleway, orderingSpec, Matcher::EventDeduplication::None);
  EXPECT_EQ(set.replace(Set::StepSpecification{250}, doNotAbort), 250);
}

}  // namespace SetReplace