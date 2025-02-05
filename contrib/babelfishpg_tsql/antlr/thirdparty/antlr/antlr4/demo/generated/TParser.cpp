/* parser/listener/visitor header section */

// Generated from /home/mrxmohit/workplace/babelfish_extensions/contrib/babelfishpg_tsql/antlr/thirdparty/antlr/antlr4/demo/TParser.g4 by ANTLR 4.13.2

/* parser precinclude section */

#include "TParserListener.h"
#include "TParserVisitor.h"

#include "TParser.h"


/* parser postinclude section */
#ifndef _WIN32
#pragma GCC diagnostic ignored "-Wunused-parameter"
#endif


using namespace antlrcpp;
using namespace antlrcpptest;

using namespace antlr4;

namespace {

struct TParserStaticData final {
  TParserStaticData(std::vector<std::string> ruleNames,
                        std::vector<std::string> literalNames,
                        std::vector<std::string> symbolicNames)
      : ruleNames(std::move(ruleNames)), literalNames(std::move(literalNames)),
        symbolicNames(std::move(symbolicNames)),
        vocabulary(this->literalNames, this->symbolicNames) {}

  TParserStaticData(const TParserStaticData&) = delete;
  TParserStaticData(TParserStaticData&&) = delete;
  TParserStaticData& operator=(const TParserStaticData&) = delete;
  TParserStaticData& operator=(TParserStaticData&&) = delete;

  std::vector<antlr4::dfa::DFA> decisionToDFA;
  antlr4::atn::PredictionContextCache sharedContextCache;
  const std::vector<std::string> ruleNames;
  const std::vector<std::string> literalNames;
  const std::vector<std::string> symbolicNames;
  const antlr4::dfa::Vocabulary vocabulary;
  antlr4::atn::SerializedATNView serializedATN;
  std::unique_ptr<antlr4::atn::ATN> atn;
};

::antlr4::internal::OnceFlag tparserParserOnceFlag;
#if ANTLR4_USE_THREAD_LOCAL_CACHE
static thread_local
#endif
std::unique_ptr<TParserStaticData> tparserParserStaticData = nullptr;

void tparserParserInitialize() {
#if ANTLR4_USE_THREAD_LOCAL_CACHE
  if (tparserParserStaticData != nullptr) {
    return;
  }
#else
  assert(tparserParserStaticData == nullptr);
#endif
  auto staticData = std::make_unique<TParserStaticData>(
    std::vector<std::string>{
      "main", "divide", "and_", "conquer", "unused", "unused2", "stat", 
      "expr", "flowControl", "id", "array", "idarray", "any"
    },
    std::vector<std::string>{
      "", "", "'return'", "'continue'", "", "", "", "'<'", "'>'", "'='", 
      "'and'", "':'", "';'", "'+'", "'-'", "'*'", "'('", "')'", "'{'", "'}'", 
      "'\\u003F'", "','", "", "", "", "", "", "", "'.'", "'..'", "'$'", 
      "'&'"
    },
    std::vector<std::string>{
      "", "DUMMY", "Return", "Continue", "INT", "Digit", "ID", "LessThan", 
      "GreaterThan", "Equal", "And", "Colon", "Semicolon", "Plus", "Minus", 
      "Star", "OpenPar", "ClosePar", "OpenCurly", "CloseCurly", "QuestionMark", 
      "Comma", "String", "Foo", "Bar", "Any", "Comment", "WS", "Dot", "DotDot", 
      "Dollar", "Ampersand"
    }
  );
  static const int32_t serializedATNSegment[] = {
  	4,1,31,152,2,0,7,0,2,1,7,1,2,2,7,2,2,3,7,3,2,4,7,4,2,5,7,5,2,6,7,6,2,
  	7,7,7,2,8,7,8,2,9,7,9,2,10,7,10,2,11,7,11,2,12,7,12,1,0,4,0,28,8,0,11,
  	0,12,0,29,1,0,1,0,1,1,1,1,1,1,1,1,3,1,38,8,1,1,1,1,1,1,2,1,2,1,3,4,3,
  	45,8,3,11,3,12,3,46,1,3,1,3,1,3,1,3,1,3,1,3,5,3,55,8,3,10,3,12,3,58,9,
  	3,1,3,3,3,61,8,3,1,3,3,3,64,8,3,1,4,1,4,1,5,1,5,1,5,4,5,71,8,5,11,5,12,
  	5,72,1,5,3,5,76,8,5,1,5,1,5,1,6,1,6,1,6,1,6,1,6,1,6,1,6,1,6,3,6,88,8,
  	6,1,7,1,7,1,7,1,7,1,7,1,7,1,7,1,7,1,7,3,7,99,8,7,1,7,1,7,1,7,1,7,1,7,
  	1,7,1,7,1,7,1,7,1,7,1,7,1,7,1,7,1,7,1,7,5,7,116,8,7,10,7,12,7,119,9,7,
  	1,8,1,8,1,8,3,8,124,8,8,1,9,1,9,1,10,1,10,1,10,1,10,5,10,132,8,10,10,
  	10,12,10,135,9,10,1,10,1,10,1,11,1,11,1,11,1,11,5,11,143,8,11,10,11,12,
  	11,146,9,11,1,11,1,11,1,12,1,12,1,12,1,60,1,14,13,0,2,4,6,8,10,12,14,
  	16,18,20,22,24,0,2,1,0,11,13,1,0,12,12,159,0,27,1,0,0,0,2,33,1,0,0,0,
  	4,41,1,0,0,0,6,63,1,0,0,0,8,65,1,0,0,0,10,70,1,0,0,0,12,87,1,0,0,0,14,
  	98,1,0,0,0,16,123,1,0,0,0,18,125,1,0,0,0,20,127,1,0,0,0,22,138,1,0,0,
  	0,24,149,1,0,0,0,26,28,3,12,6,0,27,26,1,0,0,0,28,29,1,0,0,0,29,27,1,0,
  	0,0,29,30,1,0,0,0,30,31,1,0,0,0,31,32,5,0,0,1,32,1,1,0,0,0,33,37,5,6,
  	0,0,34,35,3,4,2,0,35,36,5,8,0,0,36,38,1,0,0,0,37,34,1,0,0,0,37,38,1,0,
  	0,0,38,39,1,0,0,0,39,40,4,1,0,0,40,3,1,0,0,0,41,42,5,10,0,0,42,5,1,0,
  	0,0,43,45,3,2,1,0,44,43,1,0,0,0,45,46,1,0,0,0,46,44,1,0,0,0,46,47,1,0,
  	0,0,47,64,1,0,0,0,48,49,4,3,1,0,49,50,3,4,2,0,50,51,6,3,-1,0,51,64,1,
  	0,0,0,52,60,5,6,0,0,53,55,5,7,0,0,54,53,1,0,0,0,55,58,1,0,0,0,56,54,1,
  	0,0,0,56,57,1,0,0,0,57,59,1,0,0,0,58,56,1,0,0,0,59,61,3,2,1,0,60,61,1,
  	0,0,0,60,56,1,0,0,0,61,62,1,0,0,0,62,64,6,3,-1,0,63,44,1,0,0,0,63,48,
  	1,0,0,0,63,52,1,0,0,0,64,7,1,0,0,0,65,66,3,12,6,0,66,9,1,0,0,0,67,68,
  	3,8,4,0,68,69,9,0,0,0,69,71,1,0,0,0,70,67,1,0,0,0,71,72,1,0,0,0,72,70,
  	1,0,0,0,72,73,1,0,0,0,73,75,1,0,0,0,74,76,7,0,0,0,75,74,1,0,0,0,75,76,
  	1,0,0,0,76,77,1,0,0,0,77,78,8,1,0,0,78,11,1,0,0,0,79,80,3,14,7,0,80,81,
  	5,9,0,0,81,82,3,14,7,0,82,83,5,12,0,0,83,88,1,0,0,0,84,85,3,14,7,0,85,
  	86,5,12,0,0,86,88,1,0,0,0,87,79,1,0,0,0,87,84,1,0,0,0,88,13,1,0,0,0,89,
  	90,6,7,-1,0,90,91,5,16,0,0,91,92,3,14,7,0,92,93,5,17,0,0,93,99,1,0,0,
  	0,94,99,3,18,9,0,95,99,3,16,8,0,96,99,5,4,0,0,97,99,5,22,0,0,98,89,1,
  	0,0,0,98,94,1,0,0,0,98,95,1,0,0,0,98,96,1,0,0,0,98,97,1,0,0,0,99,117,
  	1,0,0,0,100,101,10,9,0,0,101,102,5,15,0,0,102,116,3,14,7,10,103,104,10,
  	8,0,0,104,105,5,13,0,0,105,116,3,14,7,9,106,107,10,6,0,0,107,108,5,20,
  	0,0,108,109,3,14,7,0,109,110,5,11,0,0,110,111,3,14,7,6,111,116,1,0,0,
  	0,112,113,10,5,0,0,113,114,5,9,0,0,114,116,3,14,7,5,115,100,1,0,0,0,115,
  	103,1,0,0,0,115,106,1,0,0,0,115,112,1,0,0,0,116,119,1,0,0,0,117,115,1,
  	0,0,0,117,118,1,0,0,0,118,15,1,0,0,0,119,117,1,0,0,0,120,121,5,2,0,0,
  	121,124,3,14,7,0,122,124,5,3,0,0,123,120,1,0,0,0,123,122,1,0,0,0,124,
  	17,1,0,0,0,125,126,5,6,0,0,126,19,1,0,0,0,127,128,5,18,0,0,128,133,5,
  	4,0,0,129,130,5,21,0,0,130,132,5,4,0,0,131,129,1,0,0,0,132,135,1,0,0,
  	0,133,131,1,0,0,0,133,134,1,0,0,0,134,136,1,0,0,0,135,133,1,0,0,0,136,
  	137,5,19,0,0,137,21,1,0,0,0,138,139,5,18,0,0,139,144,3,18,9,0,140,141,
  	5,21,0,0,141,143,3,18,9,0,142,140,1,0,0,0,143,146,1,0,0,0,144,142,1,0,
  	0,0,144,145,1,0,0,0,145,147,1,0,0,0,146,144,1,0,0,0,147,148,5,19,0,0,
  	148,23,1,0,0,0,149,150,9,0,0,0,150,25,1,0,0,0,15,29,37,46,56,60,63,72,
  	75,87,98,115,117,123,133,144
  };
  staticData->serializedATN = antlr4::atn::SerializedATNView(serializedATNSegment, sizeof(serializedATNSegment) / sizeof(serializedATNSegment[0]));

  antlr4::atn::ATNDeserializer deserializer;
  staticData->atn = deserializer.deserialize(staticData->serializedATN);

  const size_t count = staticData->atn->getNumberOfDecisions();
  staticData->decisionToDFA.reserve(count);
  for (size_t i = 0; i < count; i++) { 
    staticData->decisionToDFA.emplace_back(staticData->atn->getDecisionState(i), i);
  }
  tparserParserStaticData = std::move(staticData);
}

}

TParser::TParser(TokenStream *input) : TParser(input, antlr4::atn::ParserATNSimulatorOptions()) {}

TParser::TParser(TokenStream *input, const antlr4::atn::ParserATNSimulatorOptions &options) : Parser(input) {
  TParser::initialize();
  _interpreter = new atn::ParserATNSimulator(this, *tparserParserStaticData->atn, tparserParserStaticData->decisionToDFA, tparserParserStaticData->sharedContextCache, options);
}

TParser::~TParser() {
  delete _interpreter;
}

const atn::ATN& TParser::getATN() const {
  return *tparserParserStaticData->atn;
}

std::string TParser::getGrammarFileName() const {
  return "TParser.g4";
}

const std::vector<std::string>& TParser::getRuleNames() const {
  return tparserParserStaticData->ruleNames;
}

const dfa::Vocabulary& TParser::getVocabulary() const {
  return tparserParserStaticData->vocabulary;
}

antlr4::atn::SerializedATNView TParser::getSerializedATN() const {
  return tparserParserStaticData->serializedATN;
}

/* parser definitions section */

//----------------- MainContext ------------------------------------------------------------------

TParser::MainContext::MainContext(ParserRuleContext *parent, size_t invokingState)
  : ParserRuleContext(parent, invokingState) {
}

tree::TerminalNode* TParser::MainContext::EOF() {
  return getToken(TParser::EOF, 0);
}

std::vector<TParser::StatContext *> TParser::MainContext::stat() {
  return getRuleContexts<TParser::StatContext>();
}

TParser::StatContext* TParser::MainContext::stat(size_t i) {
  return getRuleContext<TParser::StatContext>(i);
}


size_t TParser::MainContext::getRuleIndex() const {
  return TParser::RuleMain;
}

void TParser::MainContext::enterRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->enterMain(this);
}

void TParser::MainContext::exitRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->exitMain(this);
}


std::any TParser::MainContext::accept(tree::ParseTreeVisitor *visitor) {
  if (auto parserVisitor = dynamic_cast<TParserVisitor*>(visitor))
    return parserVisitor->visitMain(this);
  else
    return visitor->visitChildren(this);
}

TParser::MainContext* TParser::main() {
  MainContext *_localctx = _tracker.createInstance<MainContext>(_ctx, getState());
  enterRule(_localctx, 0, TParser::RuleMain);
  size_t _la = 0;

#if __cplusplus > 201703L
  auto onExit = finally([=, this] {
#else
  auto onExit = finally([=] {
#endif
    exitRule();
  });
  try {
    enterOuterAlt(_localctx, 1);
    setState(27); 
    _errHandler->sync(this);
    _la = _input->LA(1);
    do {
      setState(26);
      stat();
      setState(29); 
      _errHandler->sync(this);
      _la = _input->LA(1);
    } while ((((_la & ~ 0x3fULL) == 0) &&
      ((1ULL << _la) & 4259932) != 0));
    setState(31);
    match(TParser::EOF);
   
  }
  catch (RecognitionException &e) {
    _errHandler->reportError(this, e);
    _localctx->exception = std::current_exception();
    _errHandler->recover(this, _localctx->exception);
  }

  return _localctx;
}

//----------------- DivideContext ------------------------------------------------------------------

TParser::DivideContext::DivideContext(ParserRuleContext *parent, size_t invokingState)
  : ParserRuleContext(parent, invokingState) {
}

tree::TerminalNode* TParser::DivideContext::ID() {
  return getToken(TParser::ID, 0);
}

TParser::And_Context* TParser::DivideContext::and_() {
  return getRuleContext<TParser::And_Context>(0);
}

tree::TerminalNode* TParser::DivideContext::GreaterThan() {
  return getToken(TParser::GreaterThan, 0);
}


size_t TParser::DivideContext::getRuleIndex() const {
  return TParser::RuleDivide;
}

void TParser::DivideContext::enterRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->enterDivide(this);
}

void TParser::DivideContext::exitRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->exitDivide(this);
}


std::any TParser::DivideContext::accept(tree::ParseTreeVisitor *visitor) {
  if (auto parserVisitor = dynamic_cast<TParserVisitor*>(visitor))
    return parserVisitor->visitDivide(this);
  else
    return visitor->visitChildren(this);
}

TParser::DivideContext* TParser::divide() {
  DivideContext *_localctx = _tracker.createInstance<DivideContext>(_ctx, getState());
  enterRule(_localctx, 2, TParser::RuleDivide);

#if __cplusplus > 201703L
  auto onExit = finally([=, this] {
#else
  auto onExit = finally([=] {
#endif
    exitRule();
  });
  try {
    enterOuterAlt(_localctx, 1);
    setState(33);
    match(TParser::ID);
    setState(37);
    _errHandler->sync(this);

    switch (getInterpreter<atn::ParserATNSimulator>()->adaptivePredict(_input, 1, _ctx)) {
    case 1: {
      setState(34);
      and_();
      setState(35);
      match(TParser::GreaterThan);
      break;
    }

    default:
      break;
    }
    setState(39);

    if (!(doesItBlend())) throw FailedPredicateException(this, "doesItBlend()");
   
  }
  catch (RecognitionException &e) {
    _errHandler->reportError(this, e);
    _localctx->exception = std::current_exception();
    _errHandler->recover(this, _localctx->exception);
  }

  return _localctx;
}

//----------------- And_Context ------------------------------------------------------------------

TParser::And_Context::And_Context(ParserRuleContext *parent, size_t invokingState)
  : ParserRuleContext(parent, invokingState) {
}

tree::TerminalNode* TParser::And_Context::And() {
  return getToken(TParser::And, 0);
}


size_t TParser::And_Context::getRuleIndex() const {
  return TParser::RuleAnd_;
}

void TParser::And_Context::enterRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->enterAnd_(this);
}

void TParser::And_Context::exitRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->exitAnd_(this);
}


std::any TParser::And_Context::accept(tree::ParseTreeVisitor *visitor) {
  if (auto parserVisitor = dynamic_cast<TParserVisitor*>(visitor))
    return parserVisitor->visitAnd_(this);
  else
    return visitor->visitChildren(this);
}

TParser::And_Context* TParser::and_() {
  And_Context *_localctx = _tracker.createInstance<And_Context>(_ctx, getState());
  enterRule(_localctx, 4, TParser::RuleAnd_);
   doInit(); 

#if __cplusplus > 201703L
  auto onExit = finally([=, this] {
#else
  auto onExit = finally([=] {
#endif
    exitRule();
  });
  try {
    enterOuterAlt(_localctx, 1);
    setState(41);
    match(TParser::And);
   _ctx->stop = _input->LT(-1);
     doAfter(); 
  }
  catch (RecognitionException &e) {
    _errHandler->reportError(this, e);
    _localctx->exception = std::current_exception();
    _errHandler->recover(this, _localctx->exception);
  }

  return _localctx;
}

//----------------- ConquerContext ------------------------------------------------------------------

TParser::ConquerContext::ConquerContext(ParserRuleContext *parent, size_t invokingState)
  : ParserRuleContext(parent, invokingState) {
}

std::vector<TParser::DivideContext *> TParser::ConquerContext::divide() {
  return getRuleContexts<TParser::DivideContext>();
}

TParser::DivideContext* TParser::ConquerContext::divide(size_t i) {
  return getRuleContext<TParser::DivideContext>(i);
}

TParser::And_Context* TParser::ConquerContext::and_() {
  return getRuleContext<TParser::And_Context>(0);
}

tree::TerminalNode* TParser::ConquerContext::ID() {
  return getToken(TParser::ID, 0);
}

std::vector<tree::TerminalNode *> TParser::ConquerContext::LessThan() {
  return getTokens(TParser::LessThan);
}

tree::TerminalNode* TParser::ConquerContext::LessThan(size_t i) {
  return getToken(TParser::LessThan, i);
}


size_t TParser::ConquerContext::getRuleIndex() const {
  return TParser::RuleConquer;
}

void TParser::ConquerContext::enterRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->enterConquer(this);
}

void TParser::ConquerContext::exitRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->exitConquer(this);
}


std::any TParser::ConquerContext::accept(tree::ParseTreeVisitor *visitor) {
  if (auto parserVisitor = dynamic_cast<TParserVisitor*>(visitor))
    return parserVisitor->visitConquer(this);
  else
    return visitor->visitChildren(this);
}

TParser::ConquerContext* TParser::conquer() {
  ConquerContext *_localctx = _tracker.createInstance<ConquerContext>(_ctx, getState());
  enterRule(_localctx, 6, TParser::RuleConquer);
  size_t _la = 0;

#if __cplusplus > 201703L
  auto onExit = finally([=, this] {
#else
  auto onExit = finally([=] {
#endif
    exitRule();
  });
  try {
    setState(63);
    _errHandler->sync(this);
    switch (getInterpreter<atn::ParserATNSimulator>()->adaptivePredict(_input, 5, _ctx)) {
    case 1: {
      enterOuterAlt(_localctx, 1);
      setState(44); 
      _errHandler->sync(this);
      _la = _input->LA(1);
      do {
        setState(43);
        divide();
        setState(46); 
        _errHandler->sync(this);
        _la = _input->LA(1);
      } while (_la == TParser::ID);
      break;
    }

    case 2: {
      enterOuterAlt(_localctx, 2);
      setState(48);

      if (!(doesItBlend())) throw FailedPredicateException(this, "doesItBlend()");
      setState(49);
      and_();
       myAction(); 
      break;
    }

    case 3: {
      enterOuterAlt(_localctx, 3);
      setState(52);
      antlrcpp::downCast<ConquerContext *>(_localctx)->idToken = match(TParser::ID);
      setState(60);
      _errHandler->sync(this);

      switch (getInterpreter<atn::ParserATNSimulator>()->adaptivePredict(_input, 4, _ctx)) {
      case 1 + 1: {
        setState(56);
        _errHandler->sync(this);
        _la = _input->LA(1);
        while (_la == TParser::LessThan) {
          setState(53);
          match(TParser::LessThan);
          setState(58);
          _errHandler->sync(this);
          _la = _input->LA(1);
        }
        setState(59);
        divide();
        break;
      }

      default:
        break;
      }
       (antlrcpp::downCast<ConquerContext *>(_localctx)->idToken != nullptr ? antlrcpp::downCast<ConquerContext *>(_localctx)->idToken->getText() : ""); 
      break;
    }

    default:
      break;
    }
   
  }
  catch (RecognitionException &e) {
    _errHandler->reportError(this, e);
    _localctx->exception = std::current_exception();
    _errHandler->recover(this, _localctx->exception);
  }

  return _localctx;
}

//----------------- UnusedContext ------------------------------------------------------------------

TParser::UnusedContext::UnusedContext(ParserRuleContext *parent, size_t invokingState)
  : ParserRuleContext(parent, invokingState) {
}

TParser::UnusedContext::UnusedContext(ParserRuleContext *parent, size_t invokingState, double input)
  : ParserRuleContext(parent, invokingState) {
  this->input = input;
}

TParser::StatContext* TParser::UnusedContext::stat() {
  return getRuleContext<TParser::StatContext>(0);
}


size_t TParser::UnusedContext::getRuleIndex() const {
  return TParser::RuleUnused;
}

void TParser::UnusedContext::enterRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->enterUnused(this);
}

void TParser::UnusedContext::exitRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->exitUnused(this);
}


std::any TParser::UnusedContext::accept(tree::ParseTreeVisitor *visitor) {
  if (auto parserVisitor = dynamic_cast<TParserVisitor*>(visitor))
    return parserVisitor->visitUnused(this);
  else
    return visitor->visitChildren(this);
}

TParser::UnusedContext* TParser::unused(double input) {
  UnusedContext *_localctx = _tracker.createInstance<UnusedContext>(_ctx, getState(), input);
  enterRule(_localctx, 8, TParser::RuleUnused);
   doInit(); 

#if __cplusplus > 201703L
  auto onExit = finally([=, this] {
#else
  auto onExit = finally([=] {
#endif

    cleanUp();

    exitRule();
  });
  try {
    enterOuterAlt(_localctx, 1);
    setState(65);
    stat();
   _ctx->stop = _input->LT(-1);
     doAfter(); 
  }
  catch (...) {

      // Replaces the standard exception handling.

  }
  return _localctx;
}

//----------------- Unused2Context ------------------------------------------------------------------

TParser::Unused2Context::Unused2Context(ParserRuleContext *parent, size_t invokingState)
  : ParserRuleContext(parent, invokingState) {
}

std::vector<tree::TerminalNode *> TParser::Unused2Context::Semicolon() {
  return getTokens(TParser::Semicolon);
}

tree::TerminalNode* TParser::Unused2Context::Semicolon(size_t i) {
  return getToken(TParser::Semicolon, i);
}

std::vector<TParser::UnusedContext *> TParser::Unused2Context::unused() {
  return getRuleContexts<TParser::UnusedContext>();
}

TParser::UnusedContext* TParser::Unused2Context::unused(size_t i) {
  return getRuleContext<TParser::UnusedContext>(i);
}

tree::TerminalNode* TParser::Unused2Context::Colon() {
  return getToken(TParser::Colon, 0);
}

tree::TerminalNode* TParser::Unused2Context::Plus() {
  return getToken(TParser::Plus, 0);
}


size_t TParser::Unused2Context::getRuleIndex() const {
  return TParser::RuleUnused2;
}

void TParser::Unused2Context::enterRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->enterUnused2(this);
}

void TParser::Unused2Context::exitRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->exitUnused2(this);
}


std::any TParser::Unused2Context::accept(tree::ParseTreeVisitor *visitor) {
  if (auto parserVisitor = dynamic_cast<TParserVisitor*>(visitor))
    return parserVisitor->visitUnused2(this);
  else
    return visitor->visitChildren(this);
}

TParser::Unused2Context* TParser::unused2() {
  Unused2Context *_localctx = _tracker.createInstance<Unused2Context>(_ctx, getState());
  enterRule(_localctx, 10, TParser::RuleUnused2);
  size_t _la = 0;

#if __cplusplus > 201703L
  auto onExit = finally([=, this] {
#else
  auto onExit = finally([=] {
#endif
    exitRule();
  });
  try {
    size_t alt;
    enterOuterAlt(_localctx, 1);
    setState(70); 
    _errHandler->sync(this);
    alt = 1;
    do {
      switch (alt) {
        case 1: {
              setState(67);
              unused(1);
              setState(68);
              matchWildcard();
              break;
            }

      default:
        throw NoViableAltException(this);
      }
      setState(72); 
      _errHandler->sync(this);
      alt = getInterpreter<atn::ParserATNSimulator>()->adaptivePredict(_input, 6, _ctx);
    } while (alt != 2 && alt != atn::ATN::INVALID_ALT_NUMBER);
    setState(75);
    _errHandler->sync(this);

    switch (getInterpreter<atn::ParserATNSimulator>()->adaptivePredict(_input, 7, _ctx)) {
    case 1: {
      setState(74);
      _la = _input->LA(1);
      if (!((((_la & ~ 0x3fULL) == 0) &&
        ((1ULL << _la) & 14336) != 0))) {
      _errHandler->recoverInline(this);
      }
      else {
        _errHandler->reportMatch(this);
        consume();
      }
      break;
    }

    default:
      break;
    }
    setState(77);
    _la = _input->LA(1);
    if (_la == 0 || _la == Token::EOF || (_la == TParser::Semicolon)) {
    _errHandler->recoverInline(this);
    }
    else {
      _errHandler->reportMatch(this);
      consume();
    }
   
  }
  catch (RecognitionException &e) {
    _errHandler->reportError(this, e);
    _localctx->exception = std::current_exception();
    _errHandler->recover(this, _localctx->exception);
  }

  return _localctx;
}

//----------------- StatContext ------------------------------------------------------------------

TParser::StatContext::StatContext(ParserRuleContext *parent, size_t invokingState)
  : ParserRuleContext(parent, invokingState) {
}

std::vector<TParser::ExprContext *> TParser::StatContext::expr() {
  return getRuleContexts<TParser::ExprContext>();
}

TParser::ExprContext* TParser::StatContext::expr(size_t i) {
  return getRuleContext<TParser::ExprContext>(i);
}

tree::TerminalNode* TParser::StatContext::Equal() {
  return getToken(TParser::Equal, 0);
}

tree::TerminalNode* TParser::StatContext::Semicolon() {
  return getToken(TParser::Semicolon, 0);
}


size_t TParser::StatContext::getRuleIndex() const {
  return TParser::RuleStat;
}

void TParser::StatContext::enterRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->enterStat(this);
}

void TParser::StatContext::exitRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->exitStat(this);
}


std::any TParser::StatContext::accept(tree::ParseTreeVisitor *visitor) {
  if (auto parserVisitor = dynamic_cast<TParserVisitor*>(visitor))
    return parserVisitor->visitStat(this);
  else
    return visitor->visitChildren(this);
}

TParser::StatContext* TParser::stat() {
  StatContext *_localctx = _tracker.createInstance<StatContext>(_ctx, getState());
  enterRule(_localctx, 12, TParser::RuleStat);

#if __cplusplus > 201703L
  auto onExit = finally([=, this] {
#else
  auto onExit = finally([=] {
#endif
    exitRule();
  });
  try {
    setState(87);
    _errHandler->sync(this);
    switch (getInterpreter<atn::ParserATNSimulator>()->adaptivePredict(_input, 8, _ctx)) {
    case 1: {
      enterOuterAlt(_localctx, 1);
      setState(79);
      expr(0);
      setState(80);
      match(TParser::Equal);
      setState(81);
      expr(0);
      setState(82);
      match(TParser::Semicolon);
      break;
    }

    case 2: {
      enterOuterAlt(_localctx, 2);
      setState(84);
      expr(0);
      setState(85);
      match(TParser::Semicolon);
      break;
    }

    default:
      break;
    }
   
  }
  catch (RecognitionException &e) {
    _errHandler->reportError(this, e);
    _localctx->exception = std::current_exception();
    _errHandler->recover(this, _localctx->exception);
  }

  return _localctx;
}

//----------------- ExprContext ------------------------------------------------------------------

TParser::ExprContext::ExprContext(ParserRuleContext *parent, size_t invokingState)
  : ParserRuleContext(parent, invokingState) {
}

tree::TerminalNode* TParser::ExprContext::OpenPar() {
  return getToken(TParser::OpenPar, 0);
}

std::vector<TParser::ExprContext *> TParser::ExprContext::expr() {
  return getRuleContexts<TParser::ExprContext>();
}

TParser::ExprContext* TParser::ExprContext::expr(size_t i) {
  return getRuleContext<TParser::ExprContext>(i);
}

tree::TerminalNode* TParser::ExprContext::ClosePar() {
  return getToken(TParser::ClosePar, 0);
}

TParser::IdContext* TParser::ExprContext::id() {
  return getRuleContext<TParser::IdContext>(0);
}

TParser::FlowControlContext* TParser::ExprContext::flowControl() {
  return getRuleContext<TParser::FlowControlContext>(0);
}

tree::TerminalNode* TParser::ExprContext::INT() {
  return getToken(TParser::INT, 0);
}

tree::TerminalNode* TParser::ExprContext::String() {
  return getToken(TParser::String, 0);
}

tree::TerminalNode* TParser::ExprContext::Star() {
  return getToken(TParser::Star, 0);
}

tree::TerminalNode* TParser::ExprContext::Plus() {
  return getToken(TParser::Plus, 0);
}

tree::TerminalNode* TParser::ExprContext::QuestionMark() {
  return getToken(TParser::QuestionMark, 0);
}

tree::TerminalNode* TParser::ExprContext::Colon() {
  return getToken(TParser::Colon, 0);
}

tree::TerminalNode* TParser::ExprContext::Equal() {
  return getToken(TParser::Equal, 0);
}


size_t TParser::ExprContext::getRuleIndex() const {
  return TParser::RuleExpr;
}

void TParser::ExprContext::enterRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->enterExpr(this);
}

void TParser::ExprContext::exitRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->exitExpr(this);
}


std::any TParser::ExprContext::accept(tree::ParseTreeVisitor *visitor) {
  if (auto parserVisitor = dynamic_cast<TParserVisitor*>(visitor))
    return parserVisitor->visitExpr(this);
  else
    return visitor->visitChildren(this);
}


TParser::ExprContext* TParser::expr() {
   return expr(0);
}

TParser::ExprContext* TParser::expr(int precedence) {
  ParserRuleContext *parentContext = _ctx;
  size_t parentState = getState();
  TParser::ExprContext *_localctx = _tracker.createInstance<ExprContext>(_ctx, parentState);
  TParser::ExprContext *previousContext = _localctx;
  (void)previousContext; // Silence compiler, in case the context is not used by generated code.
  size_t startState = 14;
  enterRecursionRule(_localctx, 14, TParser::RuleExpr, precedence);

    

#if __cplusplus > 201703L
  auto onExit = finally([=, this] {
#else
  auto onExit = finally([=] {
#endif
    unrollRecursionContexts(parentContext);
  });
  try {
    size_t alt;
    enterOuterAlt(_localctx, 1);
    setState(98);
    _errHandler->sync(this);
    switch (_input->LA(1)) {
      case TParser::OpenPar: {
        setState(90);
        match(TParser::OpenPar);
        setState(91);
        expr(0);
        setState(92);
        match(TParser::ClosePar);
        break;
      }

      case TParser::ID: {
        setState(94);
        antlrcpp::downCast<ExprContext *>(_localctx)->identifier = id();
        break;
      }

      case TParser::Return:
      case TParser::Continue: {
        setState(95);
        flowControl();
        break;
      }

      case TParser::INT: {
        setState(96);
        match(TParser::INT);
        break;
      }

      case TParser::String: {
        setState(97);
        match(TParser::String);
        break;
      }

    default:
      throw NoViableAltException(this);
    }
    _ctx->stop = _input->LT(-1);
    setState(117);
    _errHandler->sync(this);
    alt = getInterpreter<atn::ParserATNSimulator>()->adaptivePredict(_input, 11, _ctx);
    while (alt != 2 && alt != atn::ATN::INVALID_ALT_NUMBER) {
      if (alt == 1) {
        if (!_parseListeners.empty())
          triggerExitRuleEvent();
        previousContext = _localctx;
        setState(115);
        _errHandler->sync(this);
        switch (getInterpreter<atn::ParserATNSimulator>()->adaptivePredict(_input, 10, _ctx)) {
        case 1: {
          _localctx = _tracker.createInstance<ExprContext>(parentContext, parentState);
          pushNewRecursionContext(_localctx, startState, RuleExpr);
          setState(100);

          if (!(precpred(_ctx, 9))) throw FailedPredicateException(this, "precpred(_ctx, 9)");
          setState(101);
          match(TParser::Star);
          setState(102);
          expr(10);
          break;
        }

        case 2: {
          _localctx = _tracker.createInstance<ExprContext>(parentContext, parentState);
          pushNewRecursionContext(_localctx, startState, RuleExpr);
          setState(103);

          if (!(precpred(_ctx, 8))) throw FailedPredicateException(this, "precpred(_ctx, 8)");
          setState(104);
          match(TParser::Plus);
          setState(105);
          expr(9);
          break;
        }

        case 3: {
          _localctx = _tracker.createInstance<ExprContext>(parentContext, parentState);
          pushNewRecursionContext(_localctx, startState, RuleExpr);
          setState(106);

          if (!(precpred(_ctx, 6))) throw FailedPredicateException(this, "precpred(_ctx, 6)");
          setState(107);
          match(TParser::QuestionMark);
          setState(108);
          expr(0);
          setState(109);
          match(TParser::Colon);
          setState(110);
          expr(6);
          break;
        }

        case 4: {
          _localctx = _tracker.createInstance<ExprContext>(parentContext, parentState);
          pushNewRecursionContext(_localctx, startState, RuleExpr);
          setState(112);

          if (!(precpred(_ctx, 5))) throw FailedPredicateException(this, "precpred(_ctx, 5)");
          setState(113);
          match(TParser::Equal);
          setState(114);
          expr(5);
          break;
        }

        default:
          break;
        } 
      }
      setState(119);
      _errHandler->sync(this);
      alt = getInterpreter<atn::ParserATNSimulator>()->adaptivePredict(_input, 11, _ctx);
    }
  }
  catch (RecognitionException &e) {
    _errHandler->reportError(this, e);
    _localctx->exception = std::current_exception();
    _errHandler->recover(this, _localctx->exception);
  }
  return _localctx;
}

//----------------- FlowControlContext ------------------------------------------------------------------

TParser::FlowControlContext::FlowControlContext(ParserRuleContext *parent, size_t invokingState)
  : ParserRuleContext(parent, invokingState) {
}


size_t TParser::FlowControlContext::getRuleIndex() const {
  return TParser::RuleFlowControl;
}

void TParser::FlowControlContext::copyFrom(FlowControlContext *ctx) {
  ParserRuleContext::copyFrom(ctx);
}

//----------------- ReturnContext ------------------------------------------------------------------

tree::TerminalNode* TParser::ReturnContext::Return() {
  return getToken(TParser::Return, 0);
}

TParser::ExprContext* TParser::ReturnContext::expr() {
  return getRuleContext<TParser::ExprContext>(0);
}

TParser::ReturnContext::ReturnContext(FlowControlContext *ctx) { copyFrom(ctx); }

void TParser::ReturnContext::enterRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->enterReturn(this);
}
void TParser::ReturnContext::exitRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->exitReturn(this);
}

std::any TParser::ReturnContext::accept(tree::ParseTreeVisitor *visitor) {
  if (auto parserVisitor = dynamic_cast<TParserVisitor*>(visitor))
    return parserVisitor->visitReturn(this);
  else
    return visitor->visitChildren(this);
}
//----------------- ContinueContext ------------------------------------------------------------------

tree::TerminalNode* TParser::ContinueContext::Continue() {
  return getToken(TParser::Continue, 0);
}

TParser::ContinueContext::ContinueContext(FlowControlContext *ctx) { copyFrom(ctx); }

void TParser::ContinueContext::enterRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->enterContinue(this);
}
void TParser::ContinueContext::exitRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->exitContinue(this);
}

std::any TParser::ContinueContext::accept(tree::ParseTreeVisitor *visitor) {
  if (auto parserVisitor = dynamic_cast<TParserVisitor*>(visitor))
    return parserVisitor->visitContinue(this);
  else
    return visitor->visitChildren(this);
}
TParser::FlowControlContext* TParser::flowControl() {
  FlowControlContext *_localctx = _tracker.createInstance<FlowControlContext>(_ctx, getState());
  enterRule(_localctx, 16, TParser::RuleFlowControl);

#if __cplusplus > 201703L
  auto onExit = finally([=, this] {
#else
  auto onExit = finally([=] {
#endif
    exitRule();
  });
  try {
    setState(123);
    _errHandler->sync(this);
    switch (_input->LA(1)) {
      case TParser::Return: {
        _localctx = _tracker.createInstance<TParser::ReturnContext>(_localctx);
        enterOuterAlt(_localctx, 1);
        setState(120);
        match(TParser::Return);
        setState(121);
        expr(0);
        break;
      }

      case TParser::Continue: {
        _localctx = _tracker.createInstance<TParser::ContinueContext>(_localctx);
        enterOuterAlt(_localctx, 2);
        setState(122);
        match(TParser::Continue);
        break;
      }

    default:
      throw NoViableAltException(this);
    }
   
  }
  catch (RecognitionException &e) {
    _errHandler->reportError(this, e);
    _localctx->exception = std::current_exception();
    _errHandler->recover(this, _localctx->exception);
  }

  return _localctx;
}

//----------------- IdContext ------------------------------------------------------------------

TParser::IdContext::IdContext(ParserRuleContext *parent, size_t invokingState)
  : ParserRuleContext(parent, invokingState) {
}

tree::TerminalNode* TParser::IdContext::ID() {
  return getToken(TParser::ID, 0);
}


size_t TParser::IdContext::getRuleIndex() const {
  return TParser::RuleId;
}

void TParser::IdContext::enterRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->enterId(this);
}

void TParser::IdContext::exitRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->exitId(this);
}


std::any TParser::IdContext::accept(tree::ParseTreeVisitor *visitor) {
  if (auto parserVisitor = dynamic_cast<TParserVisitor*>(visitor))
    return parserVisitor->visitId(this);
  else
    return visitor->visitChildren(this);
}

TParser::IdContext* TParser::id() {
  IdContext *_localctx = _tracker.createInstance<IdContext>(_ctx, getState());
  enterRule(_localctx, 18, TParser::RuleId);

#if __cplusplus > 201703L
  auto onExit = finally([=, this] {
#else
  auto onExit = finally([=] {
#endif
    exitRule();
  });
  try {
    enterOuterAlt(_localctx, 1);
    setState(125);
    match(TParser::ID);
   
  }
  catch (RecognitionException &e) {
    _errHandler->reportError(this, e);
    _localctx->exception = std::current_exception();
    _errHandler->recover(this, _localctx->exception);
  }

  return _localctx;
}

//----------------- ArrayContext ------------------------------------------------------------------

TParser::ArrayContext::ArrayContext(ParserRuleContext *parent, size_t invokingState)
  : ParserRuleContext(parent, invokingState) {
}

tree::TerminalNode* TParser::ArrayContext::OpenCurly() {
  return getToken(TParser::OpenCurly, 0);
}

tree::TerminalNode* TParser::ArrayContext::CloseCurly() {
  return getToken(TParser::CloseCurly, 0);
}

std::vector<tree::TerminalNode *> TParser::ArrayContext::INT() {
  return getTokens(TParser::INT);
}

tree::TerminalNode* TParser::ArrayContext::INT(size_t i) {
  return getToken(TParser::INT, i);
}

std::vector<tree::TerminalNode *> TParser::ArrayContext::Comma() {
  return getTokens(TParser::Comma);
}

tree::TerminalNode* TParser::ArrayContext::Comma(size_t i) {
  return getToken(TParser::Comma, i);
}


size_t TParser::ArrayContext::getRuleIndex() const {
  return TParser::RuleArray;
}

void TParser::ArrayContext::enterRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->enterArray(this);
}

void TParser::ArrayContext::exitRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->exitArray(this);
}


std::any TParser::ArrayContext::accept(tree::ParseTreeVisitor *visitor) {
  if (auto parserVisitor = dynamic_cast<TParserVisitor*>(visitor))
    return parserVisitor->visitArray(this);
  else
    return visitor->visitChildren(this);
}

TParser::ArrayContext* TParser::array() {
  ArrayContext *_localctx = _tracker.createInstance<ArrayContext>(_ctx, getState());
  enterRule(_localctx, 20, TParser::RuleArray);
  size_t _la = 0;

#if __cplusplus > 201703L
  auto onExit = finally([=, this] {
#else
  auto onExit = finally([=] {
#endif
    exitRule();
  });
  try {
    enterOuterAlt(_localctx, 1);
    setState(127);
    match(TParser::OpenCurly);
    setState(128);
    antlrcpp::downCast<ArrayContext *>(_localctx)->intToken = match(TParser::INT);
    antlrcpp::downCast<ArrayContext *>(_localctx)->el.push_back(antlrcpp::downCast<ArrayContext *>(_localctx)->intToken);
    setState(133);
    _errHandler->sync(this);
    _la = _input->LA(1);
    while (_la == TParser::Comma) {
      setState(129);
      match(TParser::Comma);
      setState(130);
      antlrcpp::downCast<ArrayContext *>(_localctx)->intToken = match(TParser::INT);
      antlrcpp::downCast<ArrayContext *>(_localctx)->el.push_back(antlrcpp::downCast<ArrayContext *>(_localctx)->intToken);
      setState(135);
      _errHandler->sync(this);
      _la = _input->LA(1);
    }
    setState(136);
    match(TParser::CloseCurly);
   
  }
  catch (RecognitionException &e) {
    _errHandler->reportError(this, e);
    _localctx->exception = std::current_exception();
    _errHandler->recover(this, _localctx->exception);
  }

  return _localctx;
}

//----------------- IdarrayContext ------------------------------------------------------------------

TParser::IdarrayContext::IdarrayContext(ParserRuleContext *parent, size_t invokingState)
  : ParserRuleContext(parent, invokingState) {
}

tree::TerminalNode* TParser::IdarrayContext::OpenCurly() {
  return getToken(TParser::OpenCurly, 0);
}

tree::TerminalNode* TParser::IdarrayContext::CloseCurly() {
  return getToken(TParser::CloseCurly, 0);
}

std::vector<TParser::IdContext *> TParser::IdarrayContext::id() {
  return getRuleContexts<TParser::IdContext>();
}

TParser::IdContext* TParser::IdarrayContext::id(size_t i) {
  return getRuleContext<TParser::IdContext>(i);
}

std::vector<tree::TerminalNode *> TParser::IdarrayContext::Comma() {
  return getTokens(TParser::Comma);
}

tree::TerminalNode* TParser::IdarrayContext::Comma(size_t i) {
  return getToken(TParser::Comma, i);
}


size_t TParser::IdarrayContext::getRuleIndex() const {
  return TParser::RuleIdarray;
}

void TParser::IdarrayContext::enterRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->enterIdarray(this);
}

void TParser::IdarrayContext::exitRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->exitIdarray(this);
}


std::any TParser::IdarrayContext::accept(tree::ParseTreeVisitor *visitor) {
  if (auto parserVisitor = dynamic_cast<TParserVisitor*>(visitor))
    return parserVisitor->visitIdarray(this);
  else
    return visitor->visitChildren(this);
}

TParser::IdarrayContext* TParser::idarray() {
  IdarrayContext *_localctx = _tracker.createInstance<IdarrayContext>(_ctx, getState());
  enterRule(_localctx, 22, TParser::RuleIdarray);
  size_t _la = 0;

#if __cplusplus > 201703L
  auto onExit = finally([=, this] {
#else
  auto onExit = finally([=] {
#endif
    exitRule();
  });
  try {
    enterOuterAlt(_localctx, 1);
    setState(138);
    match(TParser::OpenCurly);
    setState(139);
    antlrcpp::downCast<IdarrayContext *>(_localctx)->idContext = id();
    antlrcpp::downCast<IdarrayContext *>(_localctx)->element.push_back(antlrcpp::downCast<IdarrayContext *>(_localctx)->idContext);
    setState(144);
    _errHandler->sync(this);
    _la = _input->LA(1);
    while (_la == TParser::Comma) {
      setState(140);
      match(TParser::Comma);
      setState(141);
      antlrcpp::downCast<IdarrayContext *>(_localctx)->idContext = id();
      antlrcpp::downCast<IdarrayContext *>(_localctx)->element.push_back(antlrcpp::downCast<IdarrayContext *>(_localctx)->idContext);
      setState(146);
      _errHandler->sync(this);
      _la = _input->LA(1);
    }
    setState(147);
    match(TParser::CloseCurly);
   
  }
  catch (RecognitionException &e) {
    _errHandler->reportError(this, e);
    _localctx->exception = std::current_exception();
    _errHandler->recover(this, _localctx->exception);
  }

  return _localctx;
}

//----------------- AnyContext ------------------------------------------------------------------

TParser::AnyContext::AnyContext(ParserRuleContext *parent, size_t invokingState)
  : ParserRuleContext(parent, invokingState) {
}


size_t TParser::AnyContext::getRuleIndex() const {
  return TParser::RuleAny;
}

void TParser::AnyContext::enterRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->enterAny(this);
}

void TParser::AnyContext::exitRule(tree::ParseTreeListener *listener) {
  auto parserListener = dynamic_cast<TParserListener *>(listener);
  if (parserListener != nullptr)
    parserListener->exitAny(this);
}


std::any TParser::AnyContext::accept(tree::ParseTreeVisitor *visitor) {
  if (auto parserVisitor = dynamic_cast<TParserVisitor*>(visitor))
    return parserVisitor->visitAny(this);
  else
    return visitor->visitChildren(this);
}

TParser::AnyContext* TParser::any() {
  AnyContext *_localctx = _tracker.createInstance<AnyContext>(_ctx, getState());
  enterRule(_localctx, 24, TParser::RuleAny);

#if __cplusplus > 201703L
  auto onExit = finally([=, this] {
#else
  auto onExit = finally([=] {
#endif
    exitRule();
  });
  try {
    enterOuterAlt(_localctx, 1);
    setState(149);
    antlrcpp::downCast<AnyContext *>(_localctx)->t = matchWildcard();
   
  }
  catch (RecognitionException &e) {
    _errHandler->reportError(this, e);
    _localctx->exception = std::current_exception();
    _errHandler->recover(this, _localctx->exception);
  }

  return _localctx;
}

bool TParser::sempred(RuleContext *context, size_t ruleIndex, size_t predicateIndex) {
  switch (ruleIndex) {
    case 1: return divideSempred(antlrcpp::downCast<DivideContext *>(context), predicateIndex);
    case 3: return conquerSempred(antlrcpp::downCast<ConquerContext *>(context), predicateIndex);
    case 7: return exprSempred(antlrcpp::downCast<ExprContext *>(context), predicateIndex);

  default:
    break;
  }
  return true;
}

bool TParser::divideSempred(DivideContext *_localctx, size_t predicateIndex) {
  switch (predicateIndex) {
    case 0: return doesItBlend();

  default:
    break;
  }
  return true;
}

bool TParser::conquerSempred(ConquerContext *_localctx, size_t predicateIndex) {
  switch (predicateIndex) {
    case 1: return doesItBlend();

  default:
    break;
  }
  return true;
}

bool TParser::exprSempred(ExprContext *_localctx, size_t predicateIndex) {
  switch (predicateIndex) {
    case 2: return precpred(_ctx, 9);
    case 3: return precpred(_ctx, 8);
    case 4: return precpred(_ctx, 6);
    case 5: return precpred(_ctx, 5);

  default:
    break;
  }
  return true;
}

void TParser::initialize() {
#if ANTLR4_USE_THREAD_LOCAL_CACHE
  tparserParserInitialize();
#else
  ::antlr4::internal::call_once(tparserParserOnceFlag, tparserParserInitialize);
#endif
}
