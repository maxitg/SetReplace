#ifndef LIBSETREPLACE_PARALLELISM_HPP_
#define LIBSETREPLACE_PARALLELISM_HPP_

#include <cstdint>

namespace SetReplace::Parallelism {
enum class Type { CPU };

bool isAvailable(const Type& type);

int64_t reserveThreads(const Type& type, const int64_t& requestedNumThreads);

void returnThreads(const Type& type, const int64_t& numThreadsToReturn);
}  // namespace SetReplace::Parallelism

#endif  // LIBSETREPLACE_PARALLELISM_HPP_
