#include "postgres.h"

#include "catalog/pg_collation.h"
#include "mb/pg_wchar.h"
#include "nodes/nodeFuncs.h"
#include "nodes/pathnodes.h"


extern char *pltsql_default_locale;
extern char *pltsql_server_collation_name;

/* Set default encoding to UTF8 */
#define COLL_DEFAULT_ENCODING PG_UTF8

/* Expression kind codes for preprocess_expression */
#define EXPRKIND_QUAL				0
#define EXPRKIND_TARGET				1

typedef struct coll_translate
{
	const char * from_collname;
	const char * to_collname;
	int32_t code_page;  
} coll_translate_t;

typedef struct coll_info
{
	Oid oid; /* oid is only retrievable during runtime, so we have to init to 0 */
	const char *collname;
	int32_t lcid; /* lcid */
	int32_t ver; /* Ver */
	int32_t style; /* Style */
	int32_t sortid; /* Sort id */
	int32_t collateflags; /* Collate flags, changes based on case, accent, kana, width, bin */
	int32_t code_page; /* Code Page */
	pg_enc	enc; /* encoding */
} coll_info;

#define MAX_ICU_LOCALE_LEN sizeof("es_TRADITIONAL")

typedef struct locale_info
{
	int32_t lcid; /* locale identifier */
	int32_t code_page; /* default code page or 0 if Unicode-only */
	pg_enc	enc; /* encoding corresponding to lcid */
	char icu_locale [MAX_ICU_LOCALE_LEN + 1]; /* See https://www.localeplanet.com/icu/ */
} locale_info;

typedef struct ht_oid2collid_entry {
	Oid key;
	uint8_t persist_id;
} ht_oid2collid_entry;

typedef struct like_ilike_info
{
    Oid like_oid; /* oid for like operators */
    char * like_op_name; /* the operator name for LIKE */
    char * ilike_op_name; /* the operator name for corresponding LIKE */
    char * op_left_schema; /* the schema of left operand */
    char * op_left_name; /* the name of left operand */
    char * op_right_schema; /* the schema of right operand */
    char * op_right_name; /* the name of right operand */
    bool is_not_match; /* if this is a NOT LIKE operator*/
    Oid ilike_oid; /* oid for corresponding ilike operators */
    Oid ilike_opfuncid; /* oid for corresponding ILIKE func */
} like_ilike_info;

typedef struct ht_like2ilike_entry{
    Oid key;
    uint8_t persist_id;
} ht_like2ilike_entry_t;

typedef struct collation_callbacks
{
	/* Function pointers set up by the plugin */
	char* (*EncodingConversion)(const char *s, int len, int src_encoding, int dest_encoding, int *encodedByteLen);

	Oid (*get_server_collation_oid_internal)(bool missingOk);

	coll_info (*lookup_collation_table_callback) (Oid oid);

	like_ilike_info (*lookup_like_ilike_table)(Oid opno);

	Datum (*collation_list_internal)(PG_FUNCTION_ARGS);

	Datum (*is_collated_ci_as_internal)(PG_FUNCTION_ARGS);

	int (*collationproperty_helper)(const char *collationaname, const char *property);

	bytea* (*tdscollationproperty_helper)(const char *collationaname, const char *property);

	bool (*is_server_collation_CI_AS)(void);

	bool (*is_valid_server_collation_name)(const char *collationname);

	int (*find_locale)(const char *locale);

	Oid (*get_oid_from_collidx_internal)(int collidx);

	int (*find_cs_as_collation_internal)(int collidx);

	int (*find_collation_internal)(const char *collation_name);

	bool (*has_ilike_node)(Node *expr);

} collation_callbacks;

extern int find_cs_as_collation(int collidx);
extern int find_any_collation(const char *collation_name, bool check_for_server_collation_name_guc);
extern Oid get_server_collation_oid_internal(bool missingOk);
extern coll_info lookup_collation_table(Oid collid);
extern int8_t cmp_collation(uint16_t coll1, uint16_t coll2);
extern bool collation_is_CI_AS(Oid colloid);
extern bool is_valid_server_collation_name(const char *collname);
extern Oid get_tsql_collation_oid(int persist_coll_id);
extern int get_persist_collation_id(Oid coll_oid);
extern int find_locale(const char *given_locale);
extern int get_server_collation_collidx(void);
extern Datum collation_list_internal(PG_FUNCTION_ARGS);
extern Datum is_collated_ci_as_internal(PG_FUNCTION_ARGS);
extern int collationproperty_helper(const char *collationaname, const char *property);
extern bytea* tdscollationproperty_helper(const char *collationname, const char *property);
extern bool is_server_collation_CI_AS(void);
extern int translate_collation(const char *collation_name, bool check_for_server_collation_name_guc);
extern int init_collid_trans_tab_internal(void);
extern int init_like_ilike_table_internal(void);
extern like_ilike_info lookup_like_ilike_table(Oid opno);
extern int find_collation(const char *collation_name);
Oid get_oid_from_collidx(int collidx);
extern bool has_ilike_node(Node *expr);

extern collation_callbacks *get_collation_callbacks(void);

/* Hooks defined in collation.c */
extern Oid BABELFISH_CLUSTER_COLLATION_OID(void);

extern const char *
BabelfishTranslateCollation(const char *collname, Oid collnamespace, int32 encoding);

extern void
BabelfishPreCreateCollation_hook(
	char collprovider,
	bool collisdeterministic,
	int32 collencoding,
	const char **collcollate,
	const char **collctype,
	const char *collversion);

extern TranslateCollation_hook_type prev_TranslateCollation_hook;
extern PreCreateCollation_hook_type prev_PreCreateCollation_hook;