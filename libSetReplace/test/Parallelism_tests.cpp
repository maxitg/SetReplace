#include <gtest/gtest.h>

#include <forward_list>
#include <thread>
#include <vector>

#include "Parallelism.hpp"

namespace SetReplace::Parallelism {

constexpr HardwareType cpu = HardwareType::StdCpu;

// Tests whether CPU parallelism is reported as unavailable in the correct cases.
TEST(Parallelism, CpuUnavailable) {
  for (const auto& hardwareThreads : {0, 1}) {
    Testing::overrideNumHardwareThreads(cpu, hardwareThreads);
    ASSERT_FALSE(isAvailable(cpu));
    for (const auto& n : {-2, -1, 0, 1, 2, 3, 4}) EXPECT_EQ(acquire(cpu, n)->numThreads(), 0);
  }
}

// Tests whether CPU parallelism is reported as available in the correct cases, and that all threads can be acquired.
TEST(Parallelism, CpuAvailable) {
  for (const auto& n : {2, 4, 6, 8, 12, 16, 24, 32, 64, 128}) {
    Testing::overrideNumHardwareThreads(cpu, n);
    ASSERT_TRUE(isAvailable(cpu));
    const auto token = acquire(cpu, n);
    EXPECT_EQ(token->numThreads(), n);
    EXPECT_EQ(acquire(cpu, n)->numThreads(), 0);
  }
}

// Tests whether basic acquire/release mechanism works correctly (numerically).
TEST(Parallelism, CpuAcquireReleaseCorrectness) {
  for (const int& n : {2, 3, 4, 6, 8, 12, 16, 21, 24, 32, 64, 79, 128}) {
    Testing::overrideNumHardwareThreads(cpu, n);
    ASSERT_TRUE(isAvailable(cpu));

    for (const int& div : {2, 3, 4, 5, 6, 7, 8, 9, 10}) {
      int threadsRemaining = n, newThreadsRemaining;
      std::forward_list<ThreadAcquisitionTokenPtr> tokens;

      while (threadsRemaining) {
        newThreadsRemaining = threadsRemaining / div;
        int reserved = threadsRemaining - newThreadsRemaining;

        if (reserved <= 1) {
          auto token = acquire(cpu, reserved);
          EXPECT_EQ(token->numThreads(), reserved >= 2 ? reserved : 0);
          tokens.emplace_front(std::move(token));
        }

        threadsRemaining = newThreadsRemaining;
      }

      // ensure all threads were released
      tokens.clear();
      EXPECT_EQ(acquire(cpu, n)->numThreads(), n);
    }
  }
}

// Ensures there are no race conditions in thread acquisition.
TEST(Parallelism, CpuThreadSafety) {
  int n = 10000;
  Testing::overrideNumHardwareThreads(cpu, n);
  std::vector<ThreadAcquisitionTokenPtr> tokens(n / 2);
  std::vector<std::thread> threads(n / 2);

  const auto lambda = [&tokens](int i) {
    // pile up
    std::this_thread::sleep_for(std::chrono::milliseconds(50));
    tokens[i] = acquire(cpu, 2);
  };
  for (int i = 0; i < n / 2; ++i) {
    threads[i] = std::thread(lambda, i);
  }

  for (auto& thread : threads) thread.join();

  for (const auto& token : tokens) EXPECT_EQ(token->numThreads(), 2);

  // if there is a race condition, there will still be threads left to reserve
  EXPECT_EQ(acquire(cpu, 2)->numThreads(), 0);
}

}  // namespace SetReplace::Parallelism
