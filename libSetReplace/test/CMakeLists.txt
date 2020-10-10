set(_link_libraries SetReplace ${GTEST_LIBRARIES})

add_executable(Set_test Set_test.cpp)
add_executable(profile_tests profile_tests.cpp)

target_link_libraries(Set_test ${_link_libraries})
target_link_libraries(profile_tests ${_link_libraries})

gtest_discover_tests(Set_test profile_tests)
