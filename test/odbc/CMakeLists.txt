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

file(GLOB SRC CONFIGURE_DEPENDS src/*.cpp)
file(GLOB MSSQL_TEST_SOURCES CONFIGURE_DEPENDS mssqlodbc/*.cpp)
file(GLOB PSQL_UTIL_SOURCES CONFIGURE_DEPENDS psqlodbc/*.cpp)
file(GLOB PSQL_TEST_SOURCES CONFIGURE_DEPENDS psqlodbc/test/*.cpp)

add_executable(
  main
  ${SRC}
  ${MSSQL_TEST_SOURCES}
  ${PSQL_UTIL_SOURCES}
  ${PSQL_TEST_SOURCES}
)

target_link_libraries(
  main
  gtest_main
  odbc
)

include(GoogleTest)
gtest_add_tests(TARGET main)