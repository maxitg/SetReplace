#include "Event.hpp"

#include <algorithm>

namespace SetReplace {
class CausalGraph::Implementation {
  // the first event is the "fake" initialization event
  std::vector<Event> events_;
  std::vector<EventID> creatorEvents_;

  // needed to return the largest generation in O(1)
  Generation largestGeneration_ = 0;

  static constexpr RuleID initialConditionRule = -1;

 public:
  explicit Implementation(const int initialExpressionsCount) {
    events_.push_back({initialConditionRule, {}, createExpressions(initialConditionEvent, initialExpressionsCount), 0});
  }

  std::vector<ExpressionID> addEvent(const RuleID ruleID,
                                     const std::vector<ExpressionID>& inputExpressions,
                                     const int outputExpressionsCount) {
    const auto newExpressions = createExpressions(events_.size(), outputExpressionsCount);
    const Generation generation = newEventGeneration(inputExpressions);
    events_.push_back({ruleID, inputExpressions, newExpressions, generation});
    largestGeneration_ = std::max(largestGeneration_, generation);
    return newExpressions;
  }

  std::vector<Event> events() const { return std::vector<Event>(events_.begin() + 1, events_.end()); }

  size_t eventsCount() const { return events_.size() - 1; }

  std::vector<ExpressionID> allExpressionIDs() const { return idsRange(0, creatorEvents_.size()); }

  size_t expressionsCount() const { return creatorEvents_.size(); }

  Generation expressionGeneration(const ExpressionID id) const { return events_[creatorEvents_[id]].generation; }

  Generation largestGeneration() const { return largestGeneration_; }

 private:
  std::vector<ExpressionID> createExpressions(const EventID creatorEvent, const int count) {
    const size_t beginIndex = creatorEvents_.size();
    creatorEvents_.insert(creatorEvents_.end(), count, creatorEvent);
    return idsRange(beginIndex, creatorEvents_.size());
  }

  static std::vector<ExpressionID> idsRange(const ExpressionID beginIndex, const ExpressionID endIndex) {
    std::vector<ExpressionID> result;
    result.reserve(endIndex - beginIndex);
    for (ExpressionID i = beginIndex; i < endIndex; ++i) {
      result.push_back(i);
    }
    return result;
  }

  Generation newEventGeneration(const std::vector<ExpressionID>& inputExpressions) const {
    Generation newEventGeneration = 0;
    for (const auto& inputExpression : inputExpressions) {
      newEventGeneration = std::max(newEventGeneration, events_[creatorEvents_[inputExpression]].generation + 1);
    }
    return newEventGeneration;
  }
};

CausalGraph::CausalGraph(const int initialExpressionsCount)
    : implementation_(std::make_shared<Implementation>(initialExpressionsCount)) {}

std::vector<ExpressionID> CausalGraph::addEvent(const RuleID ruleID,
                                                const std::vector<ExpressionID>& inputExpressions,
                                                const int outputExpressionsCount) {
  return implementation_->addEvent(ruleID, inputExpressions, outputExpressionsCount);
}

std::vector<Event> CausalGraph::events() const { return implementation_->events(); }

size_t CausalGraph::eventsCount() const { return implementation_->eventsCount(); }

std::vector<ExpressionID> CausalGraph::allExpressionIDs() const { return implementation_->allExpressionIDs(); }

size_t CausalGraph::expressionsCount() const { return implementation_->expressionsCount(); }

Generation CausalGraph::expressionGeneration(const ExpressionID id) const {
  return implementation_->expressionGeneration(id);
}

Generation CausalGraph::largestGeneration() const { return implementation_->largestGeneration(); }
}  // namespace SetReplace
