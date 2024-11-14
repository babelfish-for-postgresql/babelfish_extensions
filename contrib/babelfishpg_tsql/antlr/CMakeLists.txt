# minimum required CMAKE version
CMAKE_MINIMUM_REQUIRED(VERSION 3.7 FATAL_ERROR)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake-dir)

# compiler must be 17+ to support ANTLR-4.13
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC -O2 -ggdb -w -Wno-deprecated")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC -O2 -ggdb -w -Wno-deprecated")

message(STATUS "CMAKE_C_FLAGS=${CMAKE_C_FLAGS}")

# add antrl4cpp artifacts to project environment
#include_directories($ENV{ANTLR4_RUNTIME_INCLUDE_DIR})
SET (MYDIR /usr/local/include/antlr4-runtime/)
include_directories(${MYDIR})

# set variable pointing to the antlr tool that supports C++
# this is not required if the jar file can be found under PATH environment
set(ANTLR_EXECUTABLE ${PROJECT_SOURCE_DIR}/thirdparty/antlr/antlr-4.13.2-complete.jar)
# add macros to generate ANTLR Cpp code from grammar
find_package(ANTLR REQUIRED)

antlr_target(SampleGrammarLexer TSqlLexer.g4 LEXER)
antlr_target(SampleGrammarParser TSqlParser.g4 PARSER LISTENER VISITOR
			 DEPENDS_ANTLR SampleGrammarLexer
			 COMPILE_FLAGS -lib ${ANTLR_SampleGrammarLexer_OUTPUT_DIR})

# include generated files in project environment
include_directories(${ANTLR_SampleGrammarLexer_OUTPUT_DIR})
include_directories(${ANTLR_SampleGrammarParser_OUTPUT_DIR})

add_library(antlr_tsql STATIC ${ANTLR_SampleGrammarLexer_CXX_OUTPUTS} ${ANTLR_SampleGrammarParser_CXX_OUTPUTS})
