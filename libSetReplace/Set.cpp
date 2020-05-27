#include "Set.hpp"

#include <algorithm>
#include <limits>
#include <memory>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

namespace SetReplace {
class Set::Implementation {
 private:
  // Rules fundamentally cannot be changed during evaluation, don't try to remove const.
  // If rules do need to be changed, create another instance of Set and copy the expressions over.
  const std::vector<Rule> rules_;

  // Determines the limiting conditions for the evaluation.
  StepSpecification stepSpec_;
  EventSelectionFunction eventSelectionFunction_;
  TerminationReason terminationReason_ = TerminationReason::NotTerminated;

  std::unordered_map<ExpressionID, SetExpression> expressions_;
  std::vector<RuleID> eventRuleIDs_ = {-1};

  Atom nextAtom_ = 1;
  ExpressionID nextExpressionID_ = 0;

  int64_t destroyedExpressionsCount_ = 0;

  // In another words, expressions counts by atom.
  // Note, we cannot use atomsIndex_, because it does not keep last generation expressions.
  std::unordered_map<Atom, int64_t> atomDegrees_;

  // Largest generation produced so far.
  // Note, this is not the same as max of generations of all expressions,
  // because there might exist an event that deletes expressions, but does not create any new ones.
  Generation largestGeneration_ = 0;

  AtomsIndex atomsIndex_;

  Matcher matcher_;

  std::vector<ExpressionID> unindexedExpressions_;

 public:
  Implementation(const std::vector<Rule>& rules,
                 const std::vector<AtomsVector>& initialExpressions,
                 const EventSelectionFunction& eventSelectionFunction,
                 const Matcher::OrderingSpec& orderingSpec,
                 const unsigned int randomSeed)
      : Implementation(rules,
                       initialExpressions,
                       eventSelectionFunction,
                       orderingSpec,
                       randomSeed,
                       [this](const int64_t expressionID) { return expressions_.at(expressionID).atoms; }) {}

  int64_t replaceOnce(const std::function<bool()> shouldAbort) {
    terminationReason_ = TerminationReason::NotTerminated;

    if (eventRuleIDs_.size() > static_cast<size_t>(stepSpec_.maxEvents)) {
      terminationReason_ = TerminationReason::MaxEvents;
      return 0;
    }

    indexNewExpressions([this, &shouldAbort]() {
      const bool isAborted = shouldAbort();
      if (isAborted) terminationReason_ = TerminationReason::Aborted;
      return isAborted;
    });
    if (matcher_.empty()) {
      if (largestGeneration_ == stepSpec_.maxGenerationsLocal) {
        terminationReason_ = TerminationReason::MaxGenerationsLocal;
      } else {
        terminationReason_ = TerminationReason::FixedPoint;
      }
      return 0;
    }
    const MatchPtr match = matcher_.nextMatch();

    const auto& ruleInputs = rules_[match->rule].inputs;
    std::vector<AtomsVector> inputExpressions;
    inputExpressions.reserve(match->inputExpressions.size());
    for (const auto& expressionID : match->inputExpressions) {
      inputExpressions.emplace_back(expressions_.at(expressionID).atoms);
    }

    auto explicitRuleInputs = ruleInputs;
    Matcher::substituteMissingAtomsIfPossible(ruleInputs, inputExpressions, &explicitRuleInputs);

    // Identify output atoms that appear in the input, that still leaves newly created atoms as patterns.
    auto explicitRuleOutputs = rules_[match->rule].outputs;
    Matcher::substituteMissingAtomsIfPossible(ruleInputs, inputExpressions, &explicitRuleOutputs);

    for (const auto function : {&Implementation::willExceedAtomLimits, &Implementation::willExceedExpressionsLimit}) {
      const auto willExceedAtomLimitsStatus = (this->*function)(explicitRuleInputs, explicitRuleOutputs);
      if (willExceedAtomLimitsStatus != TerminationReason::NotTerminated) {
        terminationReason_ = willExceedAtomLimitsStatus;
        return 0;
      }
    }

    // At this point, we are committed to modifying the set.

    // This goes first, as if the event selection function is invalid, we want to fail before modifying anything else.
    if (eventSelectionFunction_ == EventSelectionFunction::GlobalSpacelike) {
      matcher_.removeMatchesInvolvingExpressions(match->inputExpressions);
      atomsIndex_.removeExpressions(match->inputExpressions);
    } else if (eventSelectionFunction_ == EventSelectionFunction::None) {
      matcher_.deleteMatch(match);
    } else {
      throw Error::InvalidEventSelectionFunction;
    }

    // Name newly created atoms as well, now all atoms in the output are explicitly named.
    const auto namedRuleOutputs = nameAnonymousAtoms(explicitRuleOutputs);

    Generation outputGeneration = 0;
    for (const auto& inputExpression : match->inputExpressions) {
      outputGeneration = std::max(outputGeneration, expressions_[inputExpression].generation + 1);
    }
    largestGeneration_ = std::max(largestGeneration_, outputGeneration);

    const EventID eventID = static_cast<EventID>(eventRuleIDs_.size());
    addExpressions(namedRuleOutputs, eventID, outputGeneration);
    assignDestroyerEvent(match->inputExpressions, eventID);
    eventRuleIDs_.push_back(match->rule);

    return 1;
  }

  int64_t replace(const StepSpecification stepSpec, const std::function<bool()>& shouldAbort) {
    updateStepSpec(stepSpec);
    int64_t count = 0;
    while (true) {
      if (replaceOnce(shouldAbort)) {
        ++count;
      } else {
        return count;
      }
    }
  }

  std::vector<SetExpression> expressions() const {
    std::vector<std::pair<ExpressionID, SetExpression>> idsAndExpressions(expressions_.begin(), expressions_.end());
    std::sort(idsAndExpressions.begin(), idsAndExpressions.end(), [](const auto& a, const auto& b) {
      return a.first < b.first;
    });
    std::vector<SetExpression> result;
    result.reserve(idsAndExpressions.size());
    for (const auto& idAndExpression : idsAndExpressions) {
      result.emplace_back(idAndExpression.second);
    }
    return result;
  }

  Generation maxCompleteGeneration(const std::function<bool()>& shouldAbort) {
    indexNewExpressions(shouldAbort);
    return std::min(smallestGeneration(matcher_.allMatches()), largestGeneration_);
  }

  TerminationReason terminationReason() const { return terminationReason_; }

  const std::vector<RuleID>& eventRuleIDs() const { return eventRuleIDs_; }

 private:
  Implementation(std::vector<Rule> rules,
                 const std::vector<AtomsVector>& initialExpressions,
                 const EventSelectionFunction& eventSelectionFunction,
                 const Matcher::OrderingSpec& orderingSpec,
                 const unsigned int randomSeed,
                 const std::function<AtomsVector(ExpressionID)>& getAtomsVector)
      : rules_(std::move(rules)),
        eventSelectionFunction_(eventSelectionFunction),
        atomsIndex_(getAtomsVector),
        matcher_(rules_, &atomsIndex_, getAtomsVector, orderingSpec, randomSeed) {
    for (const auto& expression : initialExpressions) {
      for (const auto& atom : expression) {
        if (atom <= 0) throw Error::NonPositiveAtoms;
        nextAtom_ = std::max(nextAtom_ - 1, atom);
        incrementNextAtom();
      }
    }
    addExpressions(initialExpressions, initialConditionEvent, initialGeneration);
  }

  Atom incrementNextAtom() {
    if (nextAtom_ == std::numeric_limits<Atom>::max()) {
      throw Error::AtomCountOverflow;
    }
    return ++nextAtom_;
  }

  void updateStepSpec(const StepSpecification newStepSpec) {
    const auto previousMaxGeneration = stepSpec_.maxGenerationsLocal;
    stepSpec_ = newStepSpec;
    if (newStepSpec.maxGenerationsLocal > previousMaxGeneration) {
      for (const auto& idAndExpression : expressions_) {
        if (idAndExpression.second.generation == previousMaxGeneration) {
          unindexedExpressions_.push_back(idAndExpression.first);
        }
      }
    }
  }

  void indexNewExpressions(const std::function<bool()>& shouldAbort) {
    // Atoms index must be updated first, because the matcher uses it to discover expressions.
    atomsIndex_.addExpressions(unindexedExpressions_);
    matcher_.addMatchesInvolvingExpressions(unindexedExpressions_, shouldAbort);
    unindexedExpressions_.clear();
  }

  TerminationReason willExceedAtomLimits(const std::vector<AtomsVector>& explicitRuleInputs,
                                         const std::vector<AtomsVector>& explicitRuleOutputs) const {
    const int64_t currentAtomsCount = static_cast<int64_t>(atomDegrees_.size());

    std::unordered_map<Atom, int64_t> atomDegreeDeltas;
    updateAtomDegrees(&atomDegreeDeltas, explicitRuleInputs, -1, false);
    updateAtomDegrees(&atomDegreeDeltas, explicitRuleOutputs, +1, false);

    int64_t newAtomsCount = currentAtomsCount;
    for (const auto& atomAndDegreeDelta : atomDegreeDeltas) {
      const Atom atom = atomAndDegreeDelta.first;
      const int64_t degreeDelta = atomAndDegreeDelta.second;
      const int64_t currentDegree = static_cast<int64_t>(atomDegrees_.count(atom)) ? atomDegrees_.at(atom) : 0;
      if (currentDegree == 0 && degreeDelta > 0) {
        ++newAtomsCount;
      } else if (currentDegree > 0 && currentDegree + degreeDelta == 0) {
        --newAtomsCount;
      }

      // Check atom degree.
      if (currentDegree + degreeDelta > stepSpec_.maxFinalAtomDegree) {
        return TerminationReason::MaxFinalAtomDegree;
      }
    }

    if (newAtomsCount > stepSpec_.maxFinalAtoms) {
      return TerminationReason::MaxFinalAtoms;
    } else {
      return TerminationReason::NotTerminated;
    }
  }

  static void updateAtomDegrees(std::unordered_map<Atom, int64_t>* atomDegrees,
                                const std::vector<AtomsVector>& deltaExpressions,
                                const int64_t deltaCount,
                                bool deleteIfZero = true) {
    for (const auto& expression : deltaExpressions) {
      const std::unordered_set<Atom> expressionAtoms(expression.begin(), expression.end());
      for (const auto& atom : expressionAtoms) {
        (*atomDegrees)[atom] += deltaCount;
        if (deleteIfZero && (*atomDegrees)[atom] == 0) {
          atomDegrees->erase(atom);
        }
      }
    }
  }

  TerminationReason willExceedExpressionsLimit(const std::vector<AtomsVector>& explicitRuleInputs,
                                               const std::vector<AtomsVector>& explicitRuleOutputs) const {
    const int64_t currentExpressionsCount = nextExpressionID_ - destroyedExpressionsCount_;
    const int64_t newExpressionsCount = currentExpressionsCount - static_cast<int64_t>(explicitRuleInputs.size()) +
                                        static_cast<int64_t>(explicitRuleOutputs.size());
    if (newExpressionsCount > stepSpec_.maxFinalExpressions) {
      return TerminationReason::MaxFinalExpressions;
    } else {
      return TerminationReason::NotTerminated;
    }
  }

  std::vector<AtomsVector> nameAnonymousAtoms(const std::vector<AtomsVector>& atomVectors) {
    std::unordered_map<Atom, Atom> names;
    std::vector<AtomsVector> result = atomVectors;
    for (auto& expression : result) {
      for (auto& atom : expression) {
        if (atom < 0 && names.count(atom) == 0) {
          names[atom] = incrementNextAtom();
        }
        if (atom < 0) {
          atom = names[atom];
        }
      }
    }

    return result;
  }

  std::vector<ExpressionID> addExpressions(const std::vector<AtomsVector>& expressions,
                                           const EventID creatorEvent,
                                           const Generation generation) {
    auto ids = assignExpressionIDs(expressions, creatorEvent, generation);

    // If generation is at least maxGeneration_, we will never use these expressions as inputs, so no need adding them
    // to the index.
    if (generation < stepSpec_.maxGenerationsLocal) {
      unindexedExpressions_.insert(unindexedExpressions_.end(), ids.begin(), ids.end());
    }

    updateAtomDegrees(&atomDegrees_, expressions, +1);
    return ids;
  }

  std::vector<ExpressionID> assignExpressionIDs(const std::vector<AtomsVector>& expressions,
                                                const EventID creatorEvent,
                                                const Generation generation) {
    std::vector<ExpressionID> ids;
    ids.reserve(expressions.size());
    for (const auto& expression : expressions) {
      ids.push_back(nextExpressionID_);
      expressions_.insert(std::make_pair(nextExpressionID_++, SetExpression{expression, creatorEvent, {}, generation}));
    }
    return ids;
  }

  void assignDestroyerEvent(const std::vector<ExpressionID>& expressions, const EventID destroyerEvent) {
    for (const auto id : expressions) {
      if (expressions_.at(id).destroyerEvents.empty()) {
        ++destroyedExpressionsCount_;
      }
      expressions_.at(id).destroyerEvents.push_back(destroyerEvent);
    }
    updateAtomDegrees(&atomDegrees_, expressions, -1);
  }

  void updateAtomDegrees(std::unordered_map<Atom, int64_t>* atomDegrees,
                         const std::vector<ExpressionID>& deltaExpressionIDs,
                         const int64_t deltaCount) const {
    std::vector<AtomsVector> expressions;
    expressions.reserve(deltaExpressionIDs.size());
    for (const auto id : deltaExpressionIDs) {
      expressions.emplace_back(expressions_.at(id).atoms);
    }
    updateAtomDegrees(atomDegrees, expressions, deltaCount);
  }

  Generation smallestGeneration(const std::vector<MatchPtr>& matches) const {
    Generation smallestSoFar = std::numeric_limits<Generation>::max();
    for (const auto& match : matches) {
      Generation largestForTheMatch = 0;
      for (const ExpressionID id : match->inputExpressions) {
        largestForTheMatch = std::max(largestForTheMatch, expressions_.at(id).generation);
      }
      smallestSoFar = std::min(smallestSoFar, largestForTheMatch);
    }
    return smallestSoFar;
  }
};

Set::Set(const std::vector<Rule>& rules,
         const std::vector<AtomsVector>& initialExpressions,
         const EventSelectionFunction& eventSelectionFunction,
         const Matcher::OrderingSpec& orderingSpec,
         unsigned int randomSeed)
    : implementation_(std::make_shared<Implementation>(
          rules, initialExpressions, eventSelectionFunction, orderingSpec, randomSeed)) {}

int64_t Set::replaceOnce(const std::function<bool()>& shouldAbort) { return implementation_->replaceOnce(shouldAbort); }

int64_t Set::replace(const StepSpecification& stepSpec, const std::function<bool()>& shouldAbort) {
  return implementation_->replace(stepSpec, shouldAbort);
}

std::vector<SetExpression> Set::expressions() const { return implementation_->expressions(); }

Generation Set::maxCompleteGeneration(const std::function<bool()>& shouldAbort) {
  return implementation_->maxCompleteGeneration(shouldAbort);
}

Set::TerminationReason Set::terminationReason() const { return implementation_->terminationReason(); }

const std::vector<RuleID>& Set::eventRuleIDs() const { return implementation_->eventRuleIDs(); }
}  // namespace SetReplace
