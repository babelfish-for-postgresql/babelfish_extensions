#ifndef FORJSON_H
#define FORJSON_H

/* Enum declaration to support FOR JSON clause */
typedef enum
{
	TSQL_FORJSON_AUTO,
	TSQL_FORJSON_PATH,
} TSQLFORJSONMode;

typedef enum
{
	TSQL_JSON_DIRECTIVE_INCLUDE_NULL_VALUES,
	TSQL_JSON_DIRECTIVE_WITHOUT_ARRAY_WRAPPER
} TSQLJSONDirective;

#endif							/* FORJSON_H */