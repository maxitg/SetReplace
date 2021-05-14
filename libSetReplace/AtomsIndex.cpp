#include "AtomsIndex.hpp"

#include <algorithm>
#include <memory>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

namespace SetReplace {
class AtomsIndex::Implementation {
 private:
  const GetAtomsVectorFunc getAtomsVector_;
  std::unordered_map<Atom, std::unordered_set<TokenID>> index_;

 public:
  explicit Implementation(GetAtomsVectorFunc getAtomsVector) : getAtomsVector_(std::move(getAtomsVector)) {}

  void removeTokens(const std::vector<TokenID>& tokenIDs) {
    const std::unordered_set<TokenID> tokensToDelete(tokenIDs.begin(), tokenIDs.end());

    std::unordered_set<Atom> involvedAtoms;
    for (const auto& token : tokenIDs) {
      const auto& atomsVector = getAtomsVector_(token);
      involvedAtoms.insert(atomsVector.begin(), atomsVector.end());
    }

    for (const auto& atom : involvedAtoms) {
      auto& atomTokenSet = index_[atom];
      auto atomTokenIterator = atomTokenSet.begin();
      const auto atomTokenSetEnd = atomTokenSet.cend();
      while (atomTokenIterator != atomTokenSetEnd) {
        if (tokensToDelete.count(*atomTokenIterator)) {
          atomTokenIterator = atomTokenSet.erase(atomTokenIterator);
        } else {
          ++atomTokenIterator;
        }
      }
      if (atomTokenSet.empty()) {
        index_.erase(atom);
      }
    }
  }

  void addTokens(const std::vector<TokenID>& tokenIDs) {
    for (const auto& tokenID : tokenIDs) {
      for (const auto& atom : getAtomsVector_(tokenID)) {
        index_[atom].insert(tokenID);
      }
    }
  }

  std::unordered_set<TokenID> tokensContainingAtom(const Atom atom) const {
    const auto resultIterator = index_.find(atom);
    return resultIterator != index_.end() ? resultIterator->second : std::unordered_set<TokenID>();
  }
};

AtomsIndex::AtomsIndex(const GetAtomsVectorFunc& getAtomsVector)
    : implementation_(std::make_shared<Implementation>(getAtomsVector)) {}

void AtomsIndex::removeTokens(const std::vector<TokenID>& tokenIDs) { implementation_->removeTokens(tokenIDs); }

void AtomsIndex::addTokens(const std::vector<TokenID>& tokenIDs) { implementation_->addTokens(tokenIDs); }

std::unordered_set<TokenID> AtomsIndex::tokensContainingAtom(const Atom atom) const {
  return implementation_->tokensContainingAtom(atom);
}
}  // namespace SetReplace
