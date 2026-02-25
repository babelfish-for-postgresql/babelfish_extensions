#ifndef TSQL_FOR_H
#define TSQL_FOR_H

#include "lib/stringinfo.h"
#include "nodes/pg_list.h"

/* Private struct for the result of tsql_for_clause production */
typedef struct TSQL_ForClause
{
	int			mode;
	char	   *elementName;
	List	   *commonDirectives;
	int			location;		/* token location of FOR, or -1 if unknown */
} TSQL_ForClause;

/* Enum declarations to support FOR XML clause */
typedef enum
{
	TSQL_FORXML_RAW,
	TSQL_FORXML_AUTO,
	TSQL_FORXML_PATH,
	TSQL_FORXML_EXPLICIT
}			TSQLFORXMLMode;

typedef enum
{
	TSQL_XML_DIRECTIVE_BINARY_BASE64,
	TSQL_XML_DIRECTIVE_TYPE,
	TSQL_XML_DIRECTIVE_ELEMENTS,
    TSQL_XML_DIRECTIVE_ELEMENTS_XSINIL,
    TSQL_XML_DIRECTIVE_ELEMENTS_ABSENT
}			TSQLXMLDirective;

/* Enum declarations to support FOR JSON clause */
typedef enum
{
	TSQL_FORJSON_AUTO,
	TSQL_FORJSON_PATH,
}			TSQLFORJSONMode;

typedef enum
{
	TSQL_JSON_DIRECTIVE_INCLUDE_NULL_VALUES,
	TSQL_JSON_DIRECTIVE_WITHOUT_ARRAY_WRAPPER
}			TSQLJSONDirective;

/* XML namespace constants */
#define XML_XMLNS_XSI "xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\""
#define XML_XSI_NIL "xsi:nil=\"true\""

extern void tsql_for_datetime_format(StringInfo format_output, const char *outputstr);
extern void tsql_for_datetimeoffset_format(StringInfo format_output, const char *outputstr);

#endif							/* TSQL_FOR_H */
