#include "Parallelism.hpp"

#include <algorithm>
#include <memory>
#include <mutex>
#include <stdexcept>
#include <thread>

namespace SetReplace::Parallelism {
namespace {
struct ParallelismBase {
  explicit ParallelismBase(int numHardwareThreads) noexcept
      : numHardwareThreads_(numHardwareThreads), threadsInUse_(0) {}

  int numHardwareThreads_;
  int threadsInUse_;
  std::mutex reservationMutex_;
};

template <HardwareType>
class Parallelism;

template <>
class Parallelism<HardwareType::StdCpu> : private ParallelismBase {
 public:
  Parallelism() noexcept : ParallelismBase(static_cast<int>(std::thread::hardware_concurrency())) {}

  [[nodiscard]] bool isAvailable() const { return numHardwareThreads_ >= 2; }

  [[nodiscard]] int numThreadsAvailable() const { return isAvailable() ? numHardwareThreads_ - threadsInUse_ : 0; }

  [[nodiscard]] int acquireThreads(const int& requestedNumThreads) {
    std::lock_guard lock(reservationMutex_);
    auto numThreadsToReserve = std::min(requestedNumThreads, numThreadsAvailable());
    if (numThreadsToReserve <= 1) numThreadsToReserve = 0;
    threadsInUse_ += numThreadsToReserve;
    return numThreadsToReserve;
  }

  void releaseThreads(const int& numThreadsToReturn) {
    std::lock_guard lock(reservationMutex_);
    threadsInUse_ -= numThreadsToReturn;
  }

  void overrideNumHardwareThreads(const int& numThreads) { numHardwareThreads_ = numThreads; }
};

Parallelism<HardwareType::StdCpu> cpuParallelism;

/** @brief Reserves at most requestedNumThreads of the given hardware type and returns the number of threads
 * successfully reserved.
 */
int acquireThreads(const HardwareType& type, const int& requestedNumThreads) {
  if (requestedNumThreads <= 1) return 0;
  if (type == HardwareType::StdCpu) return cpuParallelism.acquireThreads(requestedNumThreads);
  throw std::runtime_error("Invalid Parallelism::HardwareType");
}

/** @brief Releases ownership of numThreadsToReturn of the given hardware type.
 */
void releaseThreads(const HardwareType& type, const int& numThreadsToReturn) {
  if (type == HardwareType::StdCpu) return cpuParallelism.releaseThreads(numThreadsToReturn);
  throw std::runtime_error("Invalid Parallelism::HardwareType");
}
}  // namespace

class ThreadAcquisitionToken::Implementation {
 public:
  Implementation(const HardwareType& type, const int& requestedNumThreads)
      : hardwareType_(type), threads_(acquireThreads(hardwareType_, requestedNumThreads)) {}

  [[nodiscard]] constexpr const int& numThreads() const noexcept { return threads_; }

  ~Implementation() { releaseThreads(hardwareType_, threads_); }

 private:
  const HardwareType hardwareType_;
  const int threads_;
};

ThreadAcquisitionToken::ThreadAcquisitionToken(const HardwareType& type, const int& requestedNumThreads)
    : implementation_(std::make_shared<Implementation>(type, requestedNumThreads)) {}

int ThreadAcquisitionToken::numThreads() const noexcept { return implementation_->numThreads(); }

bool isAvailable(const HardwareType& type) {
  if (type == HardwareType::StdCpu) return cpuParallelism.isAvailable();
  throw std::runtime_error("Invalid Parallelism::HardwareType");
}

namespace Testing {
void overrideNumHardwareThreads(const HardwareType& type, const int& numThreads) {
  if (type == HardwareType::StdCpu) {
    cpuParallelism.overrideNumHardwareThreads(numThreads);
  } else {
    throw std::runtime_error("Invalid Parallelism::HardwareType");
  }
}
}  // namespace Testing
}  // namespace SetReplace::Parallelism
