#ifndef TSQL_TYPECODE_H
#define TSQL_TYPECODE_H

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

#define TOTAL_TYPECODE_COUNT 24

typedef struct type_info
{
    Oid oid; /* oid is only retrievable during runtime, so we have to init to 0 */
    bool nsp_is_sys;
    const char *pg_typname;
    const char *tsql_typname;
    uint8_t family_prio;
    uint8_t prio;
    uint8_t svhdr_size;
} type_info_t;

typedef struct ht_oid2typecode_entry {
    Oid key;
    uint8_t persist_id;
} ht_oid2typecode_entry_t;

extern Oid get_type_oid(int type_code);

extern Oid tsql_bpchar_oid;
extern Oid tsql_nchar_oid;
extern Oid tsql_varchar_oid;
extern Oid tsql_nvarchar_oid;
extern Oid tsql_ntext_oid;
extern Oid tsql_image_oid;
extern Oid tsql_binary_oid;
extern Oid tsql_varbinary_oid;

extern Oid lookup_tsql_datatype_oid(const char *typename);
extern bool is_tsql_bpchar_datatype(Oid oid);
extern bool is_tsql_nchar_datatype(Oid oid);
extern bool is_tsql_varchar_datatype(Oid oid);
extern bool is_tsql_nvarchar_datatype(Oid oid);
extern bool is_tsql_text_datatype(Oid oid);
extern bool is_tsql_ntext_datatype(Oid oid);
extern bool is_tsql_image_datatype(Oid oid);
extern bool is_tsql_binary_datatype(Oid oid);
extern bool is_tsql_varbinary_datatype(Oid oid);

#endif
