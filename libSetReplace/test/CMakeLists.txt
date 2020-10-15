set(_link_libraries SetReplace ${GTEST_LIBRARIES})

add_executable(Parallelism_test Parallelism_tests.cpp)
add_executable(Set_test Set_test.cpp)
add_executable(profile_tests profile_tests.cpp)

target_link_libraries(Parallelism_test ${_link_libraries})
target_link_libraries(Set_test ${_link_libraries})
target_link_libraries(profile_tests ${_link_libraries})

gtest_discover_tests(Parallelism_test Set_test profile_tests)
