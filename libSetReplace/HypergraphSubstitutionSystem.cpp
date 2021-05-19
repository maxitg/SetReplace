#include "HypergraphSubstitutionSystem.hpp"

#include <time.h>

#include <algorithm>
#include <limits>
#include <memory>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

namespace SetReplace {
class HypergraphSubstitutionSystem::Implementation {
 private:
  // Rules cannot be changed during evaluation as the previously found and kept matches will become invalid.
  // If rules do need to be changed, create another instance of HypergraphSubstitutionSystem and copy the tokens over.
  const std::vector<Rule> rules_;

  // Determines the limiting conditions for the evaluation.
  StepSpecification stepSpec_ = {0, 0, 0, 0, 0};  // don't evolve unless asked to.
  const uint64_t maxDestroyerEvents_;
  TerminationReason terminationReason_ = TerminationReason::NotTerminated;

  std::unordered_map<TokenID, AtomsVector> tokens_;
  TokenEventGraph causalGraph_;

  Atom nextAtom_ = 1;

  int64_t destroyedTokenCount_ = 0;

  // In another words, token counts by atom.
  // Note, we cannot use atomsIndex_, because it does not keep last generation tokens.
  std::unordered_map<Atom, int64_t> atomDegrees_;

  AtomsIndex atomsIndex_;

  HypergraphMatcher matcher_;

  std::vector<TokenID> unindexedTokens_;

 public:
  Implementation(const std::vector<Rule>& rules,
                 const std::vector<AtomsVector>& initialTokens,
                 const uint64_t maxDestroyerEvents,
                 const HypergraphMatcher::OrderingSpec& orderingSpec,
                 const HypergraphMatcher::EventDeduplication& eventDeduplication,
                 const unsigned int randomSeed)
      : Implementation(
            rules,
            initialTokens,
            maxDestroyerEvents,
            orderingSpec,
            eventDeduplication,
            randomSeed,
            [this](const TokenID& tokenID) -> const AtomsVector& { return tokens_.at(tokenID); },
            [this](const TokenID& first, const TokenID& second) -> SeparationType {
              return causalGraph_.tokenSeparation(first, second);
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

    indexNewTokens([this, &shouldAbort]() {
      const bool isAborted = shouldAbort();
      if (isAborted) terminationReason_ = TerminationReason::Aborted;
      return isAborted;
    });
    if (matcher_.empty()) {
      if (causalGraph_.largestGeneration() == stepSpec_.maxGenerationsLocal) {
        terminationReason_ = TerminationReason::MaxGenerationsLocal;
      } else {
        terminationReason_ = TerminationReason::Complete;
      }
      return 0;
    }
    const MatchPtr match = matcher_.nextMatch();

    const auto explicitRuleInputs = matcher_.matchInputAtomsVectors(match);
    const auto explicitRuleOutputs = matcher_.matchOutputAtomsVectors(match);

    // only makes sense to have final state step limits for a single history.
    if (!hasMultipleHistories()) {
      for (const auto function : {&Implementation::willExceedAtomLimits, &Implementation::willExceedTokenLimit}) {
        const auto willExceedAtomLimitsStatus = (this->*function)(explicitRuleInputs, explicitRuleOutputs);
        if (willExceedAtomLimitsStatus != TerminationReason::NotTerminated) {
          terminationReason_ = willExceedAtomLimitsStatus;
          return 0;
        }
      }
    }

    // At this point, we are committed to modifying the system.

    // Name newly created atoms as well, now all atoms in the output are explicitly named.
    const auto namedRuleOutputs = nameAnonymousAtoms(explicitRuleOutputs);

    const auto outputTokenIDs =
        causalGraph_.addEvent(match->rule, match->inputTokens, static_cast<int>(namedRuleOutputs.size()));

    addTokens(outputTokenIDs, namedRuleOutputs);

    if (maxDestroyerEvents_ == 1) {
      matcher_.removeMatchesInvolvingTokens(match->inputTokens);
      atomsIndex_.removeTokens(match->inputTokens);
      // The following only make sense for single-history systems.
      destroyedTokenCount_ += match->inputTokens.size();
      updateAtomDegrees(&atomDegrees_, match->inputTokens, -1);
    } else if (maxDestroyerEvents_ == static_cast<uint64_t>(std::numeric_limits<int64_t>::max())) {
      matcher_.deleteMatch(match);
    } else {
      // Only remove tokens whose destroyer events count reached the maximum.
      matcher_.deleteMatch(match);
      std::vector<TokenID> inputTokensToRemove;
      for (const auto& id : match->inputTokens) {
        if (causalGraph_.destroyerEventsCount(id) >= maxDestroyerEvents_) {
          inputTokensToRemove.push_back(id);
        }
      }
      matcher_.removeMatchesInvolvingTokens(inputTokensToRemove);
      atomsIndex_.removeTokens(inputTokensToRemove);
    }

    return 1;
  }

  int64_t replace(const StepSpecification stepSpec,
                  const std::function<bool()>& shouldAbort,
                  double const timeConstraint) {
    updateStepSpec(stepSpec);
    int64_t count = 0;
    if (maxDestroyerEvents_ == 0) {
      return count;
    }
    time_t startTime = time(0);
    while (true) {
      if (replaceOnce(shouldAbort)) {
        ++count;
      } else {
        return count;
      }

      // Custom TimeConstraint function
      double secondsElapsed = difftime(time(0), startTime);
      if (secondsElapsed > timeConstraint) {
        terminationReason_ = TerminationReason::TimeConstrained;
        return count;
      }
    }
  }

  std::vector<AtomsVector> tokens() const {
    std::vector<std::pair<TokenID, AtomsVector>> idsAndTokens(tokens_.begin(), tokens_.end());
    std::sort(idsAndTokens.begin(), idsAndTokens.end(), [](const auto& a, const auto& b) { return a.first < b.first; });
    std::vector<AtomsVector> result;
    result.reserve(idsAndTokens.size());
    for (const auto& idAndToken : idsAndTokens) {
      result.emplace_back(idAndToken.second);
    }
    return result;
  }

  Generation maxCompleteGeneration(const std::function<bool()>& shouldAbort) {
    indexNewTokens(shouldAbort);
    return std::min(smallestGeneration(matcher_.allMatches()), causalGraph_.largestGeneration());
  }

  TerminationReason terminationReason() const { return terminationReason_; }

  const std::vector<Event>& events() const { return causalGraph_.events(); }

 private:
  Implementation(const std::vector<Rule>& rules,
                 const std::vector<AtomsVector>& initialTokens,
                 const uint64_t maxDestroyerEvents,
                 const HypergraphMatcher::OrderingSpec& orderingSpec,
                 const HypergraphMatcher::EventDeduplication& eventDeduplication,
                 const unsigned int randomSeed,
                 const GetAtomsVectorFunc& getAtomsVector,
                 const GetTokenSeparationFunc& getTokenSeparation)
      : rules_(optimizeRules(rules, maxDestroyerEvents)),
        maxDestroyerEvents_(maxDestroyerEvents),
        causalGraph_(static_cast<int>(initialTokens.size()), separationTrackingMethod(maxDestroyerEvents, rules)),
        atomsIndex_(getAtomsVector),
        matcher_(
            rules_, &atomsIndex_, getAtomsVector, getTokenSeparation, orderingSpec, eventDeduplication, randomSeed) {
    for (const auto& token : initialTokens) {
      for (const auto& atom : token) {
        if (atom <= 0) throw Error::NonPositiveAtoms;
        nextAtom_ = std::max(nextAtom_ - 1, atom);
        incrementNextAtom();
      }
    }
    addTokens(causalGraph_.allTokenIDs(), initialTokens);
  }

  std::vector<Rule> optimizeRules(const std::vector<Rule>& rules, uint64_t maxDestroyerEvents) {
    if (maxDestroyerEvents == 1) {
      // The real optimization happens later when we call separationTrackingMethod(1, rules) by setting
      // SeparationTrackingMethod to None.
      // EventSelectionFunction is set to All in each rule to prevent breaking: SeparationTrackingMethod::None causes
      // isSpacelikeSeparated(...) to be always false for any token pair, thus no new event whose rule is only
      // applied when tokens are spacelike separated would occur.
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
      for (const auto& idAndToken : tokens_) {
        if (causalGraph_.tokenGeneration(idAndToken.first) == previousMaxGeneration) {
          unindexedTokens_.push_back(idAndToken.first);
        }
      }
    }
  }

  void throwIfInvalidStepSpec(const StepSpecification& stepSpec) const {
    if (hasMultipleHistories()) {
      // cannot support final state step limiters for a multihistory.
      const std::vector<int64_t> finalStateStepLimits = {
          stepSpec.maxFinalAtoms, stepSpec.maxFinalAtomDegree, stepSpec.maxFinalTokens};
      for (const auto stepLimit : finalStateStepLimits) {
        if (stepLimit != stepLimitDisabled) throw Error::FinalStateStepSpecificationForMultihistory;
      }
    }
  }

  void indexNewTokens(const std::function<bool()>& shouldAbort) {
    // Atoms index must be updated first, because the matcher uses it to discover tokens.
    atomsIndex_.addTokens(unindexedTokens_);
    matcher_.addMatchesInvolvingTokens(unindexedTokens_, shouldAbort);
    unindexedTokens_.clear();
  }

  bool hasMultipleHistories() const { return maxDestroyerEvents_ > 1; }

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
                                const std::vector<AtomsVector>& deltaTokens,
                                const int64_t deltaCount,
                                bool deleteIfZero = true) {
    for (const auto& token : deltaTokens) {
      const std::unordered_set<Atom> tokenAtoms(token.begin(), token.end());
      for (const auto& atom : tokenAtoms) {
        (*atomDegrees)[atom] += deltaCount;
        if (deleteIfZero && (*atomDegrees)[atom] == 0) {
          atomDegrees->erase(atom);
        }
      }
    }
  }

  TerminationReason willExceedTokenLimit(const std::vector<AtomsVector>& explicitRuleInputs,
                                         const std::vector<AtomsVector>& explicitRuleOutputs) const {
    if (stepSpec_.maxFinalTokens == stepLimitDisabled) {
      return TerminationReason::NotTerminated;
    }

    const int64_t currentTokenCount = causalGraph_.tokenCount() - destroyedTokenCount_;
    const int64_t newTokenCount = currentTokenCount - static_cast<int64_t>(explicitRuleInputs.size()) +
                                  static_cast<int64_t>(explicitRuleOutputs.size());
    if (newTokenCount > stepSpec_.maxFinalTokens) {
      return TerminationReason::MaxFinalTokens;
    } else {
      return TerminationReason::NotTerminated;
    }
  }

  std::vector<AtomsVector> nameAnonymousAtoms(const std::vector<AtomsVector>& atomVectors) {
    std::unordered_map<Atom, Atom> names;
    std::vector<AtomsVector> result = atomVectors;
    for (auto& token : result) {
      for (auto& atom : token) {
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

  void addTokens(const std::vector<TokenID>& ids, const std::vector<AtomsVector>& tokens) {
    if (ids.empty()) return;

    for (size_t index = 0; index < ids.size(); ++index) {
      tokens_.insert(std::make_pair(ids[index], tokens[index]));

      // If generation is at least maxGeneration_, we will never use these tokens as inputs, so no need adding them
      // to the index.
      if (causalGraph_.tokenGeneration(ids[index]) < stepSpec_.maxGenerationsLocal) {
        unindexedTokens_.push_back(ids[index]);
      }
    }

    // atom degrees are only used for final state step limiters
    if (!hasMultipleHistories()) updateAtomDegrees(&atomDegrees_, tokens, +1);
  }

  void updateAtomDegrees(std::unordered_map<Atom, int64_t>* atomDegrees,
                         const std::vector<TokenID>& deltaTokenIDs,
                         const int64_t deltaCount) const {
    std::vector<AtomsVector> tokens;
    tokens.reserve(deltaTokenIDs.size());
    for (const auto id : deltaTokenIDs) {
      tokens.emplace_back(tokens_.at(id));
    }
    updateAtomDegrees(atomDegrees, tokens, deltaCount);
  }

  Generation smallestGeneration(const std::vector<MatchPtr>& matches) const {
    Generation smallestSoFar = std::numeric_limits<Generation>::max();
    for (const auto& match : matches) {
      Generation largestForTheMatch = 0;
      for (const TokenID id : match->inputTokens) {
        largestForTheMatch = std::max(largestForTheMatch, causalGraph_.tokenGeneration(id));
      }
      smallestSoFar = std::min(smallestSoFar, largestForTheMatch);
    }
    return smallestSoFar;
  }

  static TokenEventGraph::SeparationTrackingMethod separationTrackingMethod(const uint64_t maxDestroyerEvents,
                                                                            const std::vector<Rule>& rules) {
    if (maxDestroyerEvents == 1) {
      // No need of tracking the separation between tokens if these are removed after each destroyer event.
      return TokenEventGraph::SeparationTrackingMethod::None;
    }
    for (const auto& rule : rules) {
      if (rule.eventSelectionFunction != EventSelectionFunction::All) {
        return TokenEventGraph::SeparationTrackingMethod::DestroyerChoices;
      }
    }
    return TokenEventGraph::SeparationTrackingMethod::None;
  }
};

HypergraphSubstitutionSystem::HypergraphSubstitutionSystem(
    const std::vector<Rule>& rules,
    const std::vector<AtomsVector>& initialTokens,
    uint64_t maxDestroyerEvents,
    const HypergraphMatcher::OrderingSpec& orderingSpec,
    const HypergraphMatcher::EventDeduplication& eventDeduplication,
    unsigned int randomSeed)
    : implementation_(std::make_shared<Implementation>(
          rules, initialTokens, maxDestroyerEvents, orderingSpec, eventDeduplication, randomSeed)) {}

int64_t HypergraphSubstitutionSystem::replaceOnce(const std::function<bool()>& shouldAbort) {
  return implementation_->replaceOnce(shouldAbort, true);
}

int64_t HypergraphSubstitutionSystem::replace(const StepSpecification& stepSpec,
                                              const std::function<bool()>& shouldAbort,
                                              double const timeConstraint) {
  return implementation_->replace(stepSpec, shouldAbort, timeConstraint);
}

std::vector<AtomsVector> HypergraphSubstitutionSystem::tokens() const { return implementation_->tokens(); }

Generation HypergraphSubstitutionSystem::maxCompleteGeneration(const std::function<bool()>& shouldAbort) {
  return implementation_->maxCompleteGeneration(shouldAbort);
}

HypergraphSubstitutionSystem::TerminationReason HypergraphSubstitutionSystem::terminationReason() const {
  return implementation_->terminationReason();
}

const std::vector<Event>& HypergraphSubstitutionSystem::events() const { return implementation_->events(); }
}  // namespace SetReplace
