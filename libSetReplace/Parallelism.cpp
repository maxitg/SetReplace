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

template <HardwareType>
class Parallelism;

template <>
class Parallelism<HardwareType::STDCPU> : ParallelismBase {
 public:
  Parallelism() : ParallelismBase(std::thread::hardware_concurrency()) {}

  [[nodiscard]] bool isAvailable() const { return numHardwareThreads_ >= 2; }

  [[nodiscard]] int64_t numThreadsAvailable() const { return isAvailable() ? numHardwareThreads_ - threadsInUse_ : 0; }

  [[nodiscard]] int64_t acquireThreads(const int64_t& requestedNumThreads) {
    std::lock_guard lock(reservationMutex_);
    const auto numThreadsToReserve = std::min(requestedNumThreads, numThreadsAvailable());
    threadsInUse_ += numThreadsToReserve;
    return numThreadsToReserve;
  }

  void releaseThreads(const int64_t& numThreadsToReturn) {
    std::lock_guard lock(reservationMutex_);
    threadsInUse_ -= numThreadsToReturn;
  }
};

Parallelism<HardwareType::STDCPU> cpuParallelism;

/** @brief Reserves at most requestedNumThreads of the given hardware type and returns the number of threads
 * successfully reserved.
 */
int64_t acquireThreads(const HardwareType& type, const int64_t& requestedNumThreads) {
  if (requestedNumThreads <= 0) return 0;
  if (type == HardwareType::STDCPU) return cpuParallelism.acquireThreads(requestedNumThreads);
  throw std::runtime_error("Invalid Parallelism::Type");
}

/** @brief Releases ownership of numThreadsToReturn of the given hardware type.
 */
void releaseThreads(const HardwareType& type, const int64_t& numThreadsToReturn) {
  if (numThreadsToReturn <= 0) return;
  if (type == HardwareType::STDCPU) return cpuParallelism.releaseThreads(numThreadsToReturn);
  throw std::runtime_error("Invalid Parallelism::Type");
}
}  // namespace

class ThreadAcquisitionToken::Implementation {
 public:
  Implementation(const HardwareType& type, const int64_t& requestedNumThreads)
      : hardwareType_(type), threads_(acquireThreads(hardwareType_, requestedNumThreads)) {}

  [[nodiscard]] constexpr const int64_t& numThreads() const noexcept { return threads_; }

  ~Implementation() { releaseThreads(hardwareType_, threads_); }

 private:
  const HardwareType hardwareType_;
  const int64_t threads_;
};

ThreadAcquisitionToken::ThreadAcquisitionToken(const HardwareType& type, const int64_t& requestedNumThreads)
    : implementation_(std::make_shared<Implementation>(type, requestedNumThreads)) {}

int64_t ThreadAcquisitionToken::numThreads() const noexcept { return implementation_->numThreads(); }

bool isAvailable(const HardwareType& type) {
  if (type == HardwareType::STDCPU) return cpuParallelism.isAvailable();
  throw std::runtime_error("Invalid Parallelism::Type");
}
}  // namespace SetReplace::Parallelism
