/* lexer header section */

// Generated from /home/mrxmohit/workplace/babelfish_extensions/contrib/babelfishpg_tsql/antlr/thirdparty/antlr/antlr4/demo/TLexer.g4 by ANTLR 4.13.2

#pragma once

/* lexer precinclude section */

#include "antlr4-runtime.h"


/* lexer postinclude section */
#ifndef _WIN32
#pragma GCC diagnostic ignored "-Wunused-parameter"
#endif


namespace antlrcpptest {

/* lexer context section */

class  TLexer : public antlr4::Lexer {
public:
  enum {
    DUMMY = 1, Return = 2, Continue = 3, INT = 4, Digit = 5, ID = 6, LessThan = 7, 
    GreaterThan = 8, Equal = 9, And = 10, Colon = 11, Semicolon = 12, Plus = 13, 
    Minus = 14, Star = 15, OpenPar = 16, ClosePar = 17, OpenCurly = 18, 
    CloseCurly = 19, QuestionMark = 20, Comma = 21, String = 22, Foo = 23, 
    Bar = 24, Any = 25, Comment = 26, WS = 27, Dot = 28, DotDot = 29, Dollar = 30, 
    Ampersand = 31
  };

  enum {
    CommentsChannel = 2, DirectiveChannel = 3
  };

  enum {
    Mode1 = 1, Mode2 = 2
  };

  explicit TLexer(antlr4::CharStream *input);

  ~TLexer() override;

  /* public lexer declarations section */
  bool canTestFoo() { return true; }
  bool isItFoo() { return true; }
  bool isItBar() { return true; }

  void myFooLexerAction() { /* do something*/ };
  void myBarLexerAction() { /* do something*/ };


  std::string getGrammarFileName() const override;

  const std::vector<std::string>& getRuleNames() const override;

  const std::vector<std::string>& getChannelNames() const override;

  const std::vector<std::string>& getModeNames() const override;

  const antlr4::dfa::Vocabulary& getVocabulary() const override;

  antlr4::atn::SerializedATNView getSerializedATN() const override;

  const antlr4::atn::ATN& getATN() const override;

  void action(antlr4::RuleContext *context, size_t ruleIndex, size_t actionIndex) override;

  bool sempred(antlr4::RuleContext *_localctx, size_t ruleIndex, size_t predicateIndex) override;

  // By default the static state used to implement the lexer is lazily initialized during the first
  // call to the constructor. You can call this function if you wish to initialize the static state
  // ahead of time.
  static void initialize();

private:
  /* private lexer declarations/members section */

  // Individual action functions triggered by action() above.
  void FooAction(antlr4::RuleContext *context, size_t actionIndex);
  void BarAction(antlr4::RuleContext *context, size_t actionIndex);

  // Individual semantic predicate functions triggered by sempred() above.
  bool FooSempred(antlr4::RuleContext *_localctx, size_t predicateIndex);
  bool BarSempred(antlr4::RuleContext *_localctx, size_t predicateIndex);

};

}  // namespace antlrcpptest
