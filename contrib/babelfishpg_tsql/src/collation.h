#ifndef TSQL_COLLATION_H
#define TSQL_COLLATION_H

#include "mb/pg_wchar.h"
#include "nodes/nodeFuncs.h"
#include "nodes/pathnodes.h"

/* Set default encoding to UTF8 */
#define COLL_DEFAULT_ENCODING PG_UTF8

typedef struct coll_info
{
    Oid oid; /* oid is only retrievable during runtime, so we have to init to 0 */
    const char * collname;
    int32_t lcid; /* lcid */
    int32_t ver; /* Ver */
    int32_t style; /* Style */
    int32_t sortid; /* Sort id */
    int32_t collateflags; /* Collate flags, changes based on case, accent, kana, width, bin */
    int32_t code_page; /* Code Page */
} coll_info_t;

#define MAX_ICU_LOCALE_LEN sizeof("es_TRADITIONAL")

typedef struct locale_info
{
    int32_t lcid; /* locale identifier */
    int32_t code_page; /* default code page or 0 if Unicode-only */
    char icu_locale [MAX_ICU_LOCALE_LEN + 1]; /* See https://www.localeplanet.com/icu/ */
} locale_info_t;

typedef struct coll_translate
{
    const char * from_collname;
    const char * to_collname;
    int32_t code_page;  
} coll_translate_t;

typedef struct ht_oid2collid_entry {
    Oid key;
    uint8_t persist_id;
} ht_oid2collid_entry_t;

typedef struct ht_like2ilike_entry{
    Oid key;
    uint8_t persist_id;
} ht_like2ilike_entry_t;


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
} like_ilike_info_t;

/* return -1 if coll1 < coll2, 0 if coll1 = coll2, 1 if coll1 > coll2 */
extern int8_t cmp_collation(uint16_t coll1, uint16_t coll2);
bool collation_is_accent_insensitive(int collidx);

extern coll_info_t lookup_collation_table(Oid collid);
extern like_ilike_info_t lookup_like_ilike_table(Oid opno);
extern int get_server_collation_collidx(void);
extern int find_any_collation(const char *collation_name);
extern bool is_server_collation_CI_AS(void);
extern int find_cs_as_collation(int collidx);
extern Oid get_server_collation_oid_internal(void);
extern int find_locale(const char *given_locale);
extern bool is_valid_server_collation_name(const char *collname);

extern Oid BABELFISH_CLUSTER_COLLATION_OID(void);

extern Node* pltsql_like_ilike_transformer (PlannerInfo *root,
                                            Node *expr,
                                            int kind);

extern bool collation_is_CI_AS(Oid colloid);

typedef struct Tsql_collation_callbacks
{
	/* Function pointers set up by the plugin */
	Oid (*get_tsql_collation_oid_f)(int persist_coll_id);
	int (*get_persist_collation_id_f)(Oid coll_oid);
	int (*get_server_collation_collidx_f)(void);
	int8_t (*cmp_collation_f)(uint16_t coll1, uint16_t coll2);

} Tsql_collation_callbacks;

Tsql_collation_callbacks *get_collation_callbacks(void);

/* Expression kind codes for preprocess_expression */
#define EXPRKIND_QUAL				0
#define EXPRKIND_TARGET				1

#endif
