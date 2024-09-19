#include <algorithm>
#include <functional>
#include <iostream>
#include <strstream>
#include <string>
#include <unordered_map>

#pragma GCC diagnostic ignored "-Wattributes"

#include "antlr4-runtime.h" // antlr4-cpp-runtime
#include "tree/ParseTreeWalker.h" // antlr4-cpp-runtime
#include "tree/ParseTreeProperty.h" // antlr4-cpp-runtime


#include "../antlr/antlr4cpp_generated_src/TSqlLexer/TSqlLexer.h"
#include "../antlr/antlr4cpp_generated_src/TSqlParser/TSqlParser.h"
#include "../antlr/antlr4cpp_generated_src/TSqlParser/TSqlParserBaseListener.h"

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wregister"

extern "C" {
#if 0
#include "tsqlNodes.h"
#else
#include "pltsql.h"
#include "pltsql-2.h"
#include "pl_explain.h"
#include "session.h"
#include "multidb.h"

#include "guc.h"

#endif

#ifdef LOG // maybe already defined in elog.h, which is conflicted with grammar token LOG
#undef LOG
#endif
}

#pragma GCC diagnostic pop

using namespace std;
using namespace antlr4;
using namespace tree;

extern "C"
{
	bool antlr_warmup_query_tsql(const char *sourceText);
}

bool
antlr_warmup_query_tsql(const char *sourceText)
{
	ANTLRInputStream sourceStream((string)sourceText);

	TSqlLexer lexer(&sourceStream);
	CommonTokenStream tokens(&lexer);

	TSqlParser parser(&tokens);

    parser.getInterpreter<atn::ParserATNSimulator>()->setPredictionMode(atn::PredictionMode::SLL);

    parser.removeErrorListeners();
	try
	{
		auto t_start = std::chrono::high_resolution_clock::now();
       	parser.tsql_file();
		auto t_end = std::chrono::high_resolution_clock::now();
		double elapsed_time_ms = std::chrono::duration<double, std::milli>(t_end-t_start).count();
		elog(WARNING, "ANTLR warm up Time for query: %s | %f ms", sourceText, 
			elapsed_time_ms);
    }
	catch (std::exception &e) /* not to cause a crash just in case */
	{
		return false;
	}
	catch (...) /* not to cause a crash just in case. consume all exception before C-layer */
	{
		return false;
	}
    return true;
}

