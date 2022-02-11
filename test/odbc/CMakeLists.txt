cmake_minimum_required(VERSION 3.17)
project(odbc)

# GoogleTest requires at least C++11
set(CMAKE_CXX_STANDARD 17)

# Retrieve GoogleTests
include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/refs/tags/release-1.11.0.zip
)

# For Windows: Prevent overriding the parent project's compiler/linker settings
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

find_package(ODBC REQUIRED)

enable_testing()

add_executable(

  main
  constants.cpp
  database_objects.cpp
  odbc_handler.cpp
  query_generator.cpp
  test_connection.cpp
  test_data_types.cpp
  test_diagnostics.cpp
  test_direct_executed_statements.cpp
  test_transactions.cpp
  test_resultset.cpp
  test_metadata.cpp
  test_prepared_statements.cpp
  test_sqlgetinfo.cpp
  main.cpp
)

target_link_libraries(
  main
  gtest_main
  odbc
)

include(GoogleTest)
gtest_add_tests(TARGET main)