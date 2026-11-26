set(_link_libraries SetReplace ${GTEST_LIBRARIES})

add_executable(Parallelism_test Parallelism_tests.cpp)
add_executable(HypergraphSubstitutionSystem_test HypergraphSubstitutionSystem_test.cpp)
add_executable(TokenEventGraph_test TokenEventGraph_test.cpp)
add_executable(profile_tests profile_tests.cpp)

target_link_libraries(Parallelism_test ${_link_libraries})
target_link_libraries(HypergraphSubstitutionSystem_test ${_link_libraries})
target_link_libraries(TokenEventGraph_test ${_link_libraries})
target_link_libraries(profile_tests ${_link_libraries})

gtest_discover_tests(Parallelism_test)
gtest_discover_tests(HypergraphSubstitutionSystem_test)
gtest_discover_tests(TokenEventGraph_test)
gtest_discover_tests(profile_tests TEST_PREFIX "Profile.")
