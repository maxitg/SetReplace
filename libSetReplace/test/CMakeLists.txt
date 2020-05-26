set(_link_libraries SetReplace ${GTEST_LIBRARIES})

add_executable(Set_test Set_test.cpp)
target_link_libraries(Set_test ${_link_libraries})

gtest_discover_tests(Set_test)
