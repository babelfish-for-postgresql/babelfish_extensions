#include "postgres.h"
#include "utils/builtins.h"
#include "funcapi.h"
#include "pltsql.h"
#if 0
PG_MODULE_MAGIC;

void _PG_init(void);

void
_PG_init(void)
{
  /*
   * Do initialization here
   */
}
#endif

PG_FUNCTION_INFO_V1(antlr_parser);

Datum
antlr_parser(PG_FUNCTION_ARGS)
{
  extern ANTLR_result antlr_parser_cpp(const char *sourceText);
  char *sourceText = text_to_cstring(PG_GETARG_TEXT_PP(0));
 
  ANTLR_result result = antlr_parser_cpp(sourceText);

  PG_RETURN_TEXT_P(cstring_to_text((result.success ? "success" : result.errfmt)));
}
