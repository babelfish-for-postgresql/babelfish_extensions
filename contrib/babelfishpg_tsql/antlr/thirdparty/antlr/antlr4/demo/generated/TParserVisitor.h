
// Generated from /home/mrxmohit/workplace/babelfish_extensions/contrib/babelfishpg_tsql/antlr/thirdparty/antlr/antlr4/demo/TParser.g4 by ANTLR 4.13.2

#pragma once


#include "antlr4-runtime.h"
#include "TParser.h"


namespace antlrcpptest {

/**
 * This class defines an abstract visitor for a parse tree
 * produced by TParser.
 */
class  TParserVisitor : public antlr4::tree::AbstractParseTreeVisitor {
public:

  /**
   * Visit parse trees produced by TParser.
   */
    virtual std::any visitMain(TParser::MainContext *context) = 0;

    virtual std::any visitDivide(TParser::DivideContext *context) = 0;

    virtual std::any visitAnd_(TParser::And_Context *context) = 0;

    virtual std::any visitConquer(TParser::ConquerContext *context) = 0;

    virtual std::any visitUnused(TParser::UnusedContext *context) = 0;

    virtual std::any visitUnused2(TParser::Unused2Context *context) = 0;

    virtual std::any visitStat(TParser::StatContext *context) = 0;

    virtual std::any visitExpr(TParser::ExprContext *context) = 0;

    virtual std::any visitReturn(TParser::ReturnContext *context) = 0;

    virtual std::any visitContinue(TParser::ContinueContext *context) = 0;

    virtual std::any visitId(TParser::IdContext *context) = 0;

    virtual std::any visitArray(TParser::ArrayContext *context) = 0;

    virtual std::any visitIdarray(TParser::IdarrayContext *context) = 0;

    virtual std::any visitAny(TParser::AnyContext *context) = 0;


};

}  // namespace antlrcpptest
