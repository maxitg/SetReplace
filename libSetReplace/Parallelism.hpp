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

/** @brief RAII thread acquisition manager.
 * @details On construction, the given number of threads of the given hardware type will be reserved for use. On
 * destruction, the threads will be released. This class is thread-safe.
 */
class ThreadAcquisitionToken {
 public:
  ThreadAcquisitionToken(const HardwareType& type, const int64_t& requestedNumThreads);

  /** @brief Returns the number of threads successfully reserved.
   */
  [[nodiscard]] int64_t numThreads() const noexcept;

 private:
  class Implementation;
  std::shared_ptr<Implementation> implementation_;
};

/** @brief Returns a RAII token for reserving the given number of threads for the given hardware type.
 */
inline std::shared_ptr<ThreadAcquisitionToken> acquire(const HardwareType& type, const int64_t& requestedNumThreads) {
  return std::make_shared<ThreadAcquisitionToken>(type, requestedNumThreads);
}

/** @brief Returns whether the hardware type can be parallelized.
 */
bool isAvailable(const HardwareType& type);
}  // namespace SetReplace::Parallelism

#endif  // LIBSETREPLACE_PARALLELISM_HPP_
