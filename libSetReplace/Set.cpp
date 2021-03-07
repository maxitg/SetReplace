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
  StepSpecification stepSpec_ = {0, 0, 0, 0, 0};  // don't evolve unless asked to.
  const uint64_t maxDestroyerEvents_;
  TerminationReason terminationReason_ = TerminationReason::NotTerminated;

  std::unordered_map<ExpressionID, AtomsVector> expressions_;
  CausalGraph causalGraph_;

  Atom nextAtom_ = 1;

  int64_t destroyedExpressionsCount_ = 0;

  // In another words, expressions counts by atom.
  // Note, we cannot use atomsIndex_, because it does not keep last generation expressions.
  std::unordered_map<Atom, int64_t> atomDegrees_;

  AtomsIndex atomsIndex_;

  Matcher matcher_;

  std::vector<ExpressionID> unindexedExpressions_;

 public:
  Implementation(const std::vector<Rule>& rules,
                 const std::vector<AtomsVector>& initialExpressions,
                 const uint64_t maxDestroyerEvents,
                 const Matcher::OrderingSpec& orderingSpec,
                 const Matcher::EventDeduplication& eventDeduplication,
                 const unsigned int randomSeed)
      : Implementation(
            rules,
            initialExpressions,
            maxDestroyerEvents,
            orderingSpec,
            eventDeduplication,
            randomSeed,
            [this](const ExpressionID& expressionID) -> const AtomsVector& { return expressions_.at(expressionID); },
            [this](const ExpressionID& first, const ExpressionID& second) -> SeparationType {
              return causalGraph_.expressionsSeparation(first, second);
            }) {}

  int64_t replaceOnce(const std::function<bool()> shouldAbort, bool resetStepSpec = false) {
    if (resetStepSpec) {
      updateStepSpec(StepSpecification{});
    }
    terminationReason_ = TerminationReason::NotTerminated;

    if (causalGraph_.eventsCount() >= static_cast<size_t>(stepSpec_.maxEvents)) {
      terminationReason_ = TerminationReason::MaxEvents;
      return 0;
    }

    indexNewExpressions([this, &shouldAbort]() {
      const bool isAborted = shouldAbort();
      if (isAborted) terminationReason_ = TerminationReason::Aborted;
      return isAborted;
    });
    if (matcher_.empty()) {
      if (causalGraph_.largestGeneration() == stepSpec_.maxGenerationsLocal) {
        terminationReason_ = TerminationReason::MaxGenerationsLocal;
      } else {
        terminationReason_ = TerminationReason::FixedPoint;
      }
      return 0;
    }
    const MatchPtr match = matcher_.nextMatch();

    const auto explicitRuleInputs = matcher_.matchInputAtomsVectors(match);
    const auto explicitRuleOutputs = matcher_.matchOutputAtomsVectors(match);

    // only makes sense to have final state step limits for a singleway system.
    if (!isMultiway()) {
      for (const auto function : {&Implementation::willExceedAtomLimits, &Implementation::willExceedExpressionsLimit}) {
        const auto willExceedAtomLimitsStatus = (this->*function)(explicitRuleInputs, explicitRuleOutputs);
        if (willExceedAtomLimitsStatus != TerminationReason::NotTerminated) {
          terminationReason_ = willExceedAtomLimitsStatus;
          return 0;
        }
      }
    }

    // At this point, we are committed to modifying the set.

    // Name newly created atoms as well, now all atoms in the output are explicitly named.
    const auto namedRuleOutputs = nameAnonymousAtoms(explicitRuleOutputs);

    const auto outputExpressionIDs =
        causalGraph_.addEvent(match->rule, match->inputExpressions, static_cast<int>(namedRuleOutputs.size()));

    addExpressions(outputExpressionIDs, namedRuleOutputs);

    if (maxDestroyerEvents_ == 1) {  // @TODO: maxDestroyerEvents_ == 0
      matcher_.removeMatchesInvolvingExpressions(match->inputExpressions);
      atomsIndex_.removeExpressions(match->inputExpressions);
      // The following only make sense for singleway systems.
      destroyedExpressionsCount_ += match->inputExpressions.size();
      updateAtomDegrees(&atomDegrees_, match->inputExpressions, -1);
    } else if (maxDestroyerEvents_ == std::numeric_limits<int64_t>::max()) {
      matcher_.deleteMatch(match);
    } else {
      // Only remove expressions whose destroyer events count exceed the maximum.
      matcher_.deleteMatch(match);
      std::vector<ExpressionID> inputExpressionsToRemove;
      for (const auto& id : match->inputExpressions) {
        if (causalGraph_.destroyerEventsCount(id) >= maxDestroyerEvents_) {
          inputExpressionsToRemove.push_back(id);
        }
      }
      matcher_.removeMatchesInvolvingExpressions(inputExpressionsToRemove);
      atomsIndex_.removeExpressions(inputExpressionsToRemove);
    }

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

  std::vector<AtomsVector> expressions() const {
    std::vector<std::pair<ExpressionID, AtomsVector>> idsAndExpressions(expressions_.begin(), expressions_.end());
    std::sort(idsAndExpressions.begin(), idsAndExpressions.end(), [](const auto& a, const auto& b) {
      return a.first < b.first;
    });
    std::vector<AtomsVector> result;
    result.reserve(idsAndExpressions.size());
    for (const auto& idAndExpression : idsAndExpressions) {
      result.emplace_back(idAndExpression.second);
    }
    return result;
  }

  Generation maxCompleteGeneration(const std::function<bool()>& shouldAbort) {
    indexNewExpressions(shouldAbort);
    return std::min(smallestGeneration(matcher_.allMatches()), causalGraph_.largestGeneration());
  }

  TerminationReason terminationReason() const { return terminationReason_; }

  const std::vector<Event>& events() const { return causalGraph_.events(); }

 private:
  Implementation(const std::vector<Rule>& rules,
                 const std::vector<AtomsVector>& initialExpressions,
                 const uint64_t maxDestroyerEvents,
                 const Matcher::OrderingSpec& orderingSpec,
                 const Matcher::EventDeduplication& eventDeduplication,
                 const unsigned int randomSeed,
                 const GetAtomsVectorFunc& getAtomsVector,
                 const GetExpressionsSeparationFunc& getExpressionsSeparation)
      : rules_(optimizeRules(rules, maxDestroyerEvents)),
        maxDestroyerEvents_(maxDestroyerEvents),
        causalGraph_(static_cast<int>(initialExpressions.size()), separationTrackingMethod(maxDestroyerEvents, rules)),
        atomsIndex_(getAtomsVector),
        matcher_(rules_,
                 &atomsIndex_,
                 getAtomsVector,
                 getExpressionsSeparation,
                 orderingSpec,
                 eventDeduplication,
                 randomSeed) {
    for (const auto& expression : initialExpressions) {
      for (const auto& atom : expression) {
        if (atom <= 0) throw Error::NonPositiveAtoms;
        nextAtom_ = std::max(nextAtom_ - 1, atom);
        incrementNextAtom();
      }
    }
    addExpressions(causalGraph_.allExpressionIDs(), initialExpressions);
  }

  std::vector<Rule> optimizeRules(std::vector<Rule> rules, int64_t maxDestroyerEvents) {
    if (maxDestroyerEvents == 1) {
      /* EventSelectionFunction is set to All when maxDestroyerEvents is 1 because all concurrently matched
        expressions are always spacelike, and All is much faster to evaluate. */
      std::vector<Rule> newRules;
      newRules.reserve(rules.size());
      for (const auto& rule : rules) {
        newRules.push_back(Rule{rule.inputs, rule.outputs, EventSelectionFunction::All});
      }
      return newRules;
    } else {
      return rules;
    }
  }

  Atom incrementNextAtom() {
    if (nextAtom_ == std::numeric_limits<Atom>::max()) {
      throw Error::AtomCountOverflow;
    }
    return ++nextAtom_;
  }

  void updateStepSpec(const StepSpecification newStepSpec) {
    throwIfInvalidStepSpec(newStepSpec);
    const auto previousMaxGeneration = stepSpec_.maxGenerationsLocal;
    stepSpec_ = newStepSpec;
    if (newStepSpec.maxGenerationsLocal > previousMaxGeneration) {
      for (const auto& idAndExpression : expressions_) {
        if (causalGraph_.expressionGeneration(idAndExpression.first) == previousMaxGeneration) {
          unindexedExpressions_.push_back(idAndExpression.first);
        }
      }
    }
  }

  void throwIfInvalidStepSpec(const StepSpecification& stepSpec) const {
    if (isMultiway()) {
      // cannot support final state step limiters for a multiway system.
      const std::vector<int64_t> finalStateStepLimits = {
          stepSpec.maxFinalAtoms, stepSpec.maxFinalAtomDegree, stepSpec.maxFinalExpressions};
      for (const auto stepLimit : finalStateStepLimits) {
        if (stepLimit != stepLimitDisabled) throw Error::FinalStateStepSpecificationForMultiwaySystem;
      }
    }
  }

  void indexNewExpressions(const std::function<bool()>& shouldAbort) {
    // Atoms index must be updated first, because the matcher uses it to discover expressions.
    atomsIndex_.addExpressions(unindexedExpressions_);
    matcher_.addMatchesInvolvingExpressions(unindexedExpressions_, shouldAbort);
    unindexedExpressions_.clear();
  }

  bool isMultiway() const { return maxDestroyerEvents_ > 1; }

  TerminationReason willExceedAtomLimits(const std::vector<AtomsVector>& explicitRuleInputs,
                                         const std::vector<AtomsVector>& explicitRuleOutputs) const {
    if (stepSpec_.maxFinalAtoms == stepLimitDisabled && stepSpec_.maxFinalAtomDegree == stepLimitDisabled) {
      return TerminationReason::NotTerminated;
    }

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
    if (stepSpec_.maxFinalExpressions == stepLimitDisabled) {
      return TerminationReason::NotTerminated;
    }

    const int64_t currentExpressionsCount = causalGraph_.expressionsCount() - destroyedExpressionsCount_;
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

  void addExpressions(const std::vector<ExpressionID>& ids, const std::vector<AtomsVector>& expressions) {
    if (ids.empty()) return;

    for (size_t index = 0; index < ids.size(); ++index) {
      expressions_.insert(std::make_pair(ids[index], expressions[index]));

      // If generation is at least maxGeneration_, we will never use these expressions as inputs, so no need adding them
      // to the index.
      if (causalGraph_.expressionGeneration(ids[index]) < stepSpec_.maxGenerationsLocal) {
        unindexedExpressions_.push_back(ids[index]);
      }
    }

    // atom degrees are only used for final state step limiters
    if (!isMultiway()) updateAtomDegrees(&atomDegrees_, expressions, +1);
  }

  void updateAtomDegrees(std::unordered_map<Atom, int64_t>* atomDegrees,
                         const std::vector<ExpressionID>& deltaExpressionIDs,
                         const int64_t deltaCount) const {
    std::vector<AtomsVector> expressions;
    expressions.reserve(deltaExpressionIDs.size());
    for (const auto id : deltaExpressionIDs) {
      expressions.emplace_back(expressions_.at(id));
    }
    updateAtomDegrees(atomDegrees, expressions, deltaCount);
  }

  Generation smallestGeneration(const std::vector<MatchPtr>& matches) const {
    Generation smallestSoFar = std::numeric_limits<Generation>::max();
    for (const auto& match : matches) {
      Generation largestForTheMatch = 0;
      for (const ExpressionID id : match->inputExpressions) {
        largestForTheMatch = std::max(largestForTheMatch, causalGraph_.expressionGeneration(id));
      }
      smallestSoFar = std::min(smallestSoFar, largestForTheMatch);
    }
    return smallestSoFar;
  }

  static CausalGraph::SeparationTrackingMethod separationTrackingMethod(const uint64_t maxDestroyerEvents,
                                                                        const std::vector<Rule>& rules) {
    if (maxDestroyerEvents == 1) {
      // No need of tracking the separation between expressions if these are removed after each destroyer event.
      return CausalGraph::SeparationTrackingMethod::None;
    }
    for (const auto& rule : rules) {
      if (rule.eventSelectionFunction != EventSelectionFunction::All) {
        return CausalGraph::SeparationTrackingMethod::DestroyerChoices;
      }
    }
    return CausalGraph::SeparationTrackingMethod::None;
  }
};

Set::Set(const std::vector<Rule>& rules,
         const std::vector<AtomsVector>& initialExpressions,
         uint64_t maxDestroyerEvents,
         const Matcher::OrderingSpec& orderingSpec,
         const Matcher::EventDeduplication& eventDeduplication,
         unsigned int randomSeed)
    : implementation_(std::make_shared<Implementation>(
          rules, initialExpressions, maxDestroyerEvents, orderingSpec, eventDeduplication, randomSeed)) {}

int64_t Set::replaceOnce(const std::function<bool()>& shouldAbort) {
  return implementation_->replaceOnce(shouldAbort, true);
}

int64_t Set::replace(const StepSpecification& stepSpec, const std::function<bool()>& shouldAbort) {
  return implementation_->replace(stepSpec, shouldAbort);
}

std::vector<AtomsVector> Set::expressions() const { return implementation_->expressions(); }

Generation Set::maxCompleteGeneration(const std::function<bool()>& shouldAbort) {
  return implementation_->maxCompleteGeneration(shouldAbort);
}

Set::TerminationReason Set::terminationReason() const { return implementation_->terminationReason(); }

const std::vector<Event>& Set::events() const { return implementation_->events(); }
}  // namespace SetReplace
