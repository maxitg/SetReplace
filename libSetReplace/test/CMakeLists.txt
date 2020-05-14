set(_link_libraries SetReplace ${GTEST_LIBRARIES})

add_executable(SetTest SetTest.cpp)
target_link_libraries(SetTest ${_link_libraries})

gtest_discover_tests(SetTest)
