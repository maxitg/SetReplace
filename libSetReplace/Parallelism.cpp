#include "Parallelism.hpp"

#include <algorithm>
#include <mutex>
#include <stdexcept>
#include <thread>

namespace SetReplace::Parallelism {
namespace {
struct ParallelismBase {
  explicit ParallelismBase(unsigned numHardwareThreads) : numHardwareThreads_(numHardwareThreads), threadsInUse_(0) {}

  const unsigned numHardwareThreads_;
  unsigned threadsInUse_;
  std::mutex reservationMutex_;
};

template <Type>
class Parallelism;

template <>
class Parallelism<Type::CPU> : ParallelismBase {
 public:
  Parallelism() : ParallelismBase(std::thread::hardware_concurrency()) {}

  [[nodiscard]] bool isAvailable() const { return numHardwareThreads_ >= 2; }

  [[nodiscard]] int64_t numThreadsAvailable() const { return isAvailable() ? numHardwareThreads_ - threadsInUse_ : 0; }

  [[nodiscard]] int64_t reserveThreads(const int64_t& requestedNumThreads) {
    std::lock_guard lock(reservationMutex_);
    const auto numThreadsToReserve = std::min(requestedNumThreads, numThreadsAvailable());
    threadsInUse_ += numThreadsToReserve;
    return numThreadsToReserve;
  }

  void returnThreads(const int64_t& numThreadsToReturn) {
    std::lock_guard lock(reservationMutex_);
    threadsInUse_ -= numThreadsToReturn;
  }
};

Parallelism<Type::CPU> cpuParallelism;
}  // namespace

bool isAvailable(const Type& type) {
  if (type == Type::CPU) return cpuParallelism.isAvailable();
  throw std::runtime_error("Invalid Parallelism::Type");
}

int64_t reserveThreads(const Type& type, const int64_t& requestedNumThreads) {
  if (type == Type::CPU) return cpuParallelism.reserveThreads(requestedNumThreads);
  throw std::runtime_error("Invalid Parallelism::Type");
}

void returnThreads(const Type& type, const int64_t& numThreadsToReturn) {
  if (type == Type::CPU) return cpuParallelism.returnThreads(numThreadsToReturn);
  throw std::runtime_error("Invalid Parallelism::Type");
}
}  // namespace SetReplace::Parallelism
