#ifndef LIBSETREPLACE_PARALLELISM_HPP_
#define LIBSETREPLACE_PARALLELISM_HPP_

#include <cstdint>
#include <memory>

namespace SetReplace::Parallelism {
/** @brief The type of hardware that can be parallelized.
 */
enum class HardwareType {
  /** @brief The main CPU (accessible through <thread> standard header).
   */
  STDCPU
};

class ThreadAcquisitionToken {
 public:
  ThreadAcquisitionToken(const HardwareType& type, const int64_t& requestedNumThreads);

  [[nodiscard]] int64_t numThreads() const noexcept;

 private:
  class Implementation;
  std::shared_ptr<Implementation> implementation_;
};

inline std::shared_ptr<ThreadAcquisitionToken> acquire(const HardwareType& type, const int64_t& requestedNumThreads) {
  return std::make_shared<ThreadAcquisitionToken>(type, requestedNumThreads);
}

/** @brief Returns whether the hardware type can be parallelized.
 */
bool isAvailable(const HardwareType& type);
}  // namespace SetReplace::Parallelism

#endif  // LIBSETREPLACE_PARALLELISM_HPP_
