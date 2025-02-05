
// Generated from /home/mrxmohit/workplace/babelfish_extensions/contrib/babelfishpg_tsql/antlr/thirdparty/antlr/antlr4/demo/TParser.g4 by ANTLR 4.13.2

#pragma once


#include "antlr4-runtime.h"
#include "TParserVisitor.h"


namespace antlrcpptest {

/**
 * This class provides an empty implementation of TParserVisitor, which can be
 * extended to create a visitor which only needs to handle a subset of the available methods.
 */
class  TParserBaseVisitor : public TParserVisitor {
public:

  virtual std::any visitMain(TParser::MainContext *ctx) override {
    return visitChildren(ctx);
  }

  virtual std::any visitDivide(TParser::DivideContext *ctx) override {
    return visitChildren(ctx);
  }

  virtual std::any visitAnd_(TParser::And_Context *ctx) override {
    return visitChildren(ctx);
  }

  virtual std::any visitConquer(TParser::ConquerContext *ctx) override {
    return visitChildren(ctx);
  }

  virtual std::any visitUnused(TParser::UnusedContext *ctx) override {
    return visitChildren(ctx);
  }

  virtual std::any visitUnused2(TParser::Unused2Context *ctx) override {
    return visitChildren(ctx);
  }

  virtual std::any visitStat(TParser::StatContext *ctx) override {
    return visitChildren(ctx);
  }

  virtual std::any visitExpr(TParser::ExprContext *ctx) override {
    return visitChildren(ctx);
  }

  virtual std::any visitReturn(TParser::ReturnContext *ctx) override {
    return visitChildren(ctx);
  }

  virtual std::any visitContinue(TParser::ContinueContext *ctx) override {
    return visitChildren(ctx);
  }

  virtual std::any visitId(TParser::IdContext *ctx) override {
    return visitChildren(ctx);
  }

  virtual std::any visitArray(TParser::ArrayContext *ctx) override {
    return visitChildren(ctx);
  }

  virtual std::any visitIdarray(TParser::IdarrayContext *ctx) override {
    return visitChildren(ctx);
  }

  virtual std::any visitAny(TParser::AnyContext *ctx) override {
    return visitChildren(ctx);
  }


};

}  // namespace antlrcpptest
