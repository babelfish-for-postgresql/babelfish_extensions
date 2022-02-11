#ifndef TSQLIFACE_H
#define TSQLIFACE_H

// header file for common structures shared between CPP files.
// do not include this in C file.

#include <string>

#include "../antlr/antlr4cpp_generated_src/TSqlParser/TSqlParserBaseVisitor.h"

/* unsupported feature handler interface */
class TsqlUnsupportedFeatureHandler : public TSqlParserBaseVisitor
{
public:
		static std::unique_ptr<TsqlUnsupportedFeatureHandler> create();

		virtual bool hasUnsupportedFeature() const = 0;
		virtual void setPublishInstr(bool) = 0;
		virtual void setThrowError(bool) = 0;

		//void walk(antlr4::tree::ParseTree *tree);
};

/* auxiliary data structure for convenience */
struct FormattedMessage
{
	const char *fmt;
	std::vector<const void *> args;
};

/*
 * Error handling in cpp code. This exception will be caught in antlr_parser_cpp() and converted to ereport().
 *
 * please note that direclty calling ereport(ERROR) in cpp code may cause a leakage because it interrupts program-counter so
 * cpp object's destructor may not be called ever. With PGErrorWrapperException, the error is caught the bottom stack of cpp code
 * and it will be translated to C structure. then all cpp objects are destoryed and ereport will be called.
 *
 * lineno is additionally needed due to TDS protocol
 */
class PGErrorWrapperException
{
public:
	PGErrorWrapperException(int lv, int code, const char *msg, int lineno, int pos)
		: elevel(lv), ecode(code), emsg(msg), elineno(lineno), epos(pos)
	{}

	PGErrorWrapperException(int lv, int code, FormattedMessage&& fmt, int lineno, int pos)
		: elevel(lv), ecode(code), emsg(fmt.fmt), elineno(lineno), epos(pos)
	{
		eargs = std::move(fmt.args);
	}

	PGErrorWrapperException(int lv, int code, const char *msg, std::pair<int,int> line_and_pos) // sugar
		: elevel(lv), ecode(code), emsg(msg), elineno(line_and_pos.first), epos(line_and_pos.second)
	{}

	PGErrorWrapperException(int lv, int code, FormattedMessage&& fmt, std::pair<int,int> line_and_pos) // sugar
		: elevel(lv), ecode(code), emsg(fmt.fmt), elineno(line_and_pos.first), epos(line_and_pos.second)
	{
		eargs = std::move(fmt.args);
	}

	int get_errcode() const { return ecode; }
	int get_errorline() const { return elineno; }
	int get_errpos() const { return epos; }
	const char *get_errmsg() const { return emsg; }
	const std::vector<const void *> &get_errargs() const { return eargs; }

protected:
	int elevel;
	int ecode;
	const char *emsg;
	int elineno; /* error line. not converted to PG error. instead, directly set via global variable which will be read by TDS */
	int epos;
	std::vector<const void *> eargs;
};

FormattedMessage
format_errmsg(const char *fmt, const char *arg0);

FormattedMessage
format_errmsg(const char *fmt, int64_t arg0);

template <typename... Types>
FormattedMessage
format_errmsg(const char *fmt, const char *arg1, Types... args);

template <typename... Types>
FormattedMessage
format_errmsg(const char *fmt, int64_t arg1, Types... args);

#endif // TSQLIFACE_H
