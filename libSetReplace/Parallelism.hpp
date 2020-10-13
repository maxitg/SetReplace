#ifndef LIBSETREPLACE_PARALLELISM_HPP_
#define LIBSETREPLACE_PARALLELISM_HPP_

#include <cstdint>

namespace SetReplace::Parallelism {
/** @brief The type of hardware that can be parallelized.
 */
enum class HardwareType {
  /** @brief The main CPU (accessible through <thread> standard header).
   */
  STDCPU
};

/** @brief Returns whether the hardware type can be parallelized.
 */
bool isAvailable(const HardwareType& type);

/** @brief Reserves at most requestedNumThreads of the given hardware type and returns the number of threads
 * successfully reserved.
 */
int64_t acquireThreads(const HardwareType& type, const int64_t& requestedNumThreads);

/** @brief Releases ownership of numThreadsToReturn of the given hardware type.
 */
void releaseThreads(const HardwareType& type, const int64_t& numThreadsToReturn);
}  // namespace SetReplace::Parallelism

#endif  // LIBSETREPLACE_PARALLELISM_HPP_
