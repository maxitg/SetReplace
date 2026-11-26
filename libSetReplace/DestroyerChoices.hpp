#ifndef LIBSETREPLACE_DESTROYERCHOICES_HPP_
#define LIBSETREPLACE_DESTROYERCHOICES_HPP_

#include <cstddef>
#include <cstdint>
#include <functional>
#include <limits>
#include <vector>

#include "IDTypes.hpp"

namespace SetReplace {
namespace detail {
// Persistent maps from token IDs to their chosen destroyer events. Internal to TokenEventGraph.
// Each root owns a version of a compressed binary radix tree. Unchanged subtrees are shared, so updates allocate
// only the path to a changed leaf; union and conflict checks skip identical subtrees. Branch bits decrease strictly
// along a path, bounding recursion by the number of bits in a token ID, independent of insertion order.
// With sequential token IDs, a chain takes O(log T) time and new nodes per event, instead of copying O(T) ancestors.
// Unions and conflict checks can still visit O(T) nodes when the histories do not share subtrees.
class DestroyerChoices {
 public:
  using Root = size_t;
  static constexpr Root empty = 0;
  static constexpr Root incompatible = std::numeric_limits<Root>::max();

  // No references into this arena survive an allocation: vector growth can relocate all nodes. Roots remain valid.
  DestroyerChoices() : nodes_(1) {}

  bool contains(Root root, const TokenID token) const {
    const auto key = static_cast<uint64_t>(token);
    while (root != empty) {
      const auto& node = nodes_[root];
      if (node.bit == 0) return node.prefix == key;
      if (!hasPrefix(key, node)) return false;
      root = (key & node.bit) ? node.right : node.left;
    }
    return false;
  }

  // Set, rather than insert: preserve TokenEventGraph's input-order behavior even for non-spacelike events.
  Root set(const Root root, const TokenID token, const EventID event) {
    const auto key = static_cast<uint64_t>(token);
    if (root == empty) return leaf(key, event);
    const auto node = nodes_[root];
    if (node.bit == 0 && node.prefix == key) {
      return node.event == event ? root : leaf(key, event);
    }
    if (node.bit == 0 || !hasPrefix(key, node)) return join(root, leaf(key, event));
    const auto left = (key & node.bit) ? node.left : set(node.left, token, event);
    const auto right = (key & node.bit) ? set(node.right, token, event) : node.right;
    return rebuild(root, node, left, right);
  }

  // Return the union, or incompatible if the maps disagree on a common token. Neither input version is modified.
  Root unite(const Root first, const Root second) {
    if (first == empty) return second;
    if (second == empty || first == second) return first;
    const auto a = nodes_[first];
    const auto b = nodes_[second];
    if (a.bit == b.bit && a.prefix == b.prefix) {
      if (a.bit == 0) return a.event == b.event ? first : incompatible;
      const auto left = unite(a.left, b.left);
      if (left == incompatible) return incompatible;
      const auto right = unite(a.right, b.right);
      if (right == incompatible) return incompatible;
      if (left == b.left && right == b.right) return second;
      return rebuild(first, a, left, right);
    }
    if (a.bit < b.bit) return unite(second, first);
    if (a.bit != 0 && hasPrefix(b.prefix, a)) {
      const auto left = (b.prefix & a.bit) ? a.left : unite(a.left, second);
      if (left == incompatible) return incompatible;
      const auto right = (b.prefix & a.bit) ? unite(a.right, second) : a.right;
      if (right == incompatible) return incompatible;
      return rebuild(first, a, left, right);
    }
    return join(first, second);
  }

  bool compatible(const Root first, const Root second) const {
    if (first == empty || second == empty || first == second) return true;
    const auto& a = nodes_[first];
    const auto& b = nodes_[second];
    if (a.bit == b.bit && a.prefix == b.prefix) {
      if (a.bit == 0) return a.event == b.event;
      return compatible(a.left, b.left) && compatible(a.right, b.right);
    }
    if (a.bit < b.bit) return compatible(second, first);
    if (a.bit != 0 && hasPrefix(b.prefix, a)) {
      return compatible((b.prefix & a.bit) ? a.right : a.left, second);
    }
    return true;  // disjoint key ranges
  }

 private:
  struct Node {
    uint64_t prefix = 0;  // a leaf's key, or the common bits above a branch's bit
    uint64_t bit = 0;     // zero for leaves, otherwise the highest bit distinguishing the children
    Root left = empty;
    Root right = empty;
    EventID event = 0;  // only used by leaves
  };

  static uint64_t prefixAt(const uint64_t key, const uint64_t bit) { return key & ~(bit | (bit - 1)); }

  static bool hasPrefix(const uint64_t key, const Node& node) { return prefixAt(key, node.bit) == node.prefix; }

  Root leaf(const uint64_t key, const EventID event) {
    nodes_.push_back({key, 0, empty, empty, event});
    return nodes_.size() - 1;
  }

  Root rebuild(const Root root, const Node& node, const Root left, const Root right) {
    if (left == node.left && right == node.right) return root;
    nodes_.push_back({node.prefix, node.bit, left, right, 0});
    return nodes_.size() - 1;
  }

  // Join disjoint trees at their highest differing key bit. The existing nodes are reused as children.
  Root join(const Root first, const Root second) {
    const auto firstPrefix = nodes_[first].prefix;
    auto differingBits = firstPrefix ^ nodes_[second].prefix;
    differingBits |= differingBits >> 1;
    differingBits |= differingBits >> 2;
    differingBits |= differingBits >> 4;
    differingBits |= differingBits >> 8;
    differingBits |= differingBits >> 16;
    differingBits |= differingBits >> 32;
    const auto bit = differingBits - (differingBits >> 1);
    const auto left = (firstPrefix & bit) ? second : first;
    const auto right = (firstPrefix & bit) ? first : second;
    nodes_.push_back({prefixAt(firstPrefix, bit), bit, left, right, 0});
    return nodes_.size() - 1;
  }

  std::vector<Node> nodes_;
};
}  // namespace detail
}  // namespace SetReplace

#endif  // LIBSETREPLACE_DESTROYERCHOICES_HPP_
