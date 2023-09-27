#ifndef TSQL_TYPECODE_H
#define TSQL_TYPECODE_H

#include "postgres.h"

#include "fmgr.h"

/* Persistent Type Code for SQL Variant Type */
/* WARNING: EXISTING VALUES MUST NOT BE CHANGED */

#define SQLVARIANT_T        0
#define DATETIMEOFFSET_T    1
#define DATETIME2_T         2
#define DATETIME_T          3
#define SMALLDATETIME_T     4
#define DATE_T              5
#define TIME_T              6
#define FLOAT_T             7
#define REAL_T              8
#define NUMERIC_T           9
#define MONEY_T            10
#define SMALLMONEY_T       11
#define BIGINT_T           12
#define INT_T              13
#define SMALLINT_T         14
#define TINYINT_T          15
#define BIT_T              16
#define NVARCHAR_T         17
#define NCHAR_T            18
#define VARCHAR_T          19
#define CHAR_T             20
#define VARBINARY_T        21
#define BINARY_T           22
#define UNIQUEIDENTIFIER_T 23

#define IS_STRING_TYPE(t)                       \
    ( ((t) == NVARCHAR_T) || ((t) == NCHAR_T)   \
      || ((t) == VARCHAR_T) || ((t) == CHAR_T))

#define IS_MONEY_TYPE(t) (((t) == MONEY_T) || ((t) == SMALLMONEY_T))
#define IS_BINARY_TYPE(t) (((t) == VARBINARY_T) || ((t) == BINARY_T))

/* MACRO from fixed decimal */
#ifndef FIXEDDECIMAL_MULTIPLIER
#define FIXEDDECIMAL_MULTIPLIER 10000LL
#endif

#define TOTAL_TYPECODE_COUNT 33

struct Node;

typedef struct type_info
{
	Oid			oid;			/* oid is only retrievable during runtime, so
								 * we have to init to 0 */
	bool		nsp_is_sys;
	const char *pg_typname;
	const char *tsql_typname;
	uint8_t		family_prio;
	uint8_t		prio;
	uint8_t		svhdr_size;
} type_info_t;

typedef struct ht_oid2typecode_entry
{
	Oid			key;
	uint8_t		persist_id;
} ht_oid2typecode_entry_t;

extern Oid	get_type_oid(int type_code);

extern Oid	tsql_bpchar_oid;
extern Oid	tsql_nchar_oid;
extern Oid	tsql_varchar_oid;
extern Oid	tsql_nvarchar_oid;
extern Oid	tsql_ntext_oid;
extern Oid	tsql_image_oid;
extern Oid	tsql_binary_oid;
extern Oid	tsql_varbinary_oid;
extern Oid	tsql_rowversion_oid;
extern Oid	tsql_timestamp_oid;
extern Oid	tsql_datetime2_oid;
extern Oid	tsql_smalldatetime_oid;
extern Oid	tsql_datetimeoffset_oid;
extern Oid	tsql_decimal_oid;

extern Oid	lookup_tsql_datatype_oid(const char *typename);
extern bool is_tsql_bpchar_datatype(Oid oid);
extern bool is_tsql_nchar_datatype(Oid oid);
extern bool is_tsql_varchar_datatype(Oid oid);
extern bool is_tsql_nvarchar_datatype(Oid oid);
extern bool is_tsql_text_datatype(Oid oid);
extern bool is_tsql_ntext_datatype(Oid oid);
extern bool is_tsql_image_datatype(Oid oid);
extern bool is_tsql_binary_datatype(Oid oid);
extern bool is_tsql_sys_binary_datatype(Oid oid);
extern bool is_tsql_varbinary_datatype(Oid oid);
extern bool is_tsql_sys_varbinary_datatype(Oid oid);
extern bool is_tsql_rowversion_datatype(Oid oid);
extern bool is_tsql_timestamp_datatype(Oid oid);
extern bool is_tsql_rowversion_or_timestamp_datatype(Oid oid);
extern bool is_tsql_datetime2_datatype(Oid oid);
extern bool is_tsql_smalldatetime_datatype(Oid oid);
extern bool is_tsql_datetimeoffset_datatype(Oid oid);
extern bool is_tsql_decimal_datatype(Oid oid);

extern void handle_type_and_collation(struct Node *node, Oid typid, Oid collationid);
extern bool check_target_type_is_sys_varchar(Oid funcid);
extern type_info_t get_tsql_type_info(uint8_t type_code);
extern Datum translate_pg_type_to_tsql(PG_FUNCTION_ARGS);

/*
 * TransMemoryContext Memory context is created to load hash table to
 * store 1. "OID to Persist Type Code Mapping" and 2. "OID to Persist
 * like to ilike Mapping" and 3. "OID to Persist Collation ID Mapping".
 */
extern MemoryContext TransMemoryContext;

#endif
