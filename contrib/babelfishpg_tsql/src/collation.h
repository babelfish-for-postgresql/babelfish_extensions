#ifndef TSQL_COLLATION_H
#define TSQL_COLLATION_H

#include "postgres.h"

#include "mb/pg_wchar.h"
#include "nodes/nodeFuncs.h"
#include "nodes/pathnodes.h"
#include "fmgr.h"

/* Set default encoding to UTF8 */
#define COLL_DEFAULT_ENCODING PG_UTF8

typedef struct coll_info
{
	Oid			oid;			/* oid is only retrievable during runtime, so
								 * we have to init to 0 */
	const char *collname;
	int32_t		lcid;			/* lcid */
	int32_t		ver;			/* Ver */
	int32_t		style;			/* Style */
	int32_t		sortid;			/* Sort id */
	int32_t		collateflags;	/* Collate flags, changes based on case,
								 * accent, kana, width, bin */
	int32_t		code_page;		/* Code Page */
	pg_enc		enc;			/* encoding */
} coll_info_t;

typedef struct like_ilike_info
{
	Oid			like_oid;		/* oid for like operators */
	char	   *like_op_name;	/* the operator name for LIKE */
	char	   *ilike_op_name;	/* the operator name for corresponding LIKE */
	char	   *op_left_schema; /* the schema of left operand */
	char	   *op_left_name;	/* the name of left operand */
	char	   *op_right_schema;	/* the schema of right operand */
	char	   *op_right_name;	/* the name of right operand */
	bool		is_not_match;	/* if this is a NOT LIKE operator */
	Oid			ilike_oid;		/* oid for corresponding ilike operators */
	Oid			ilike_opfuncid; /* oid for corresponding ILIKE func */
} like_ilike_info_t;

typedef struct remove_accent_map_pair
{
	uint32 		original_char;
	uint32 		normalized_char;
} remove_accent_map_pair;

/* match definition in babelfishpg_common:collation.h */
typedef struct collation_callbacks
{
	/* Function pointers set up by the plugin */
	char	   *(*EncodingConversion) (const char *s, int len, int src_encoding, int dest_encoding, int *encodedByteLen);

	Oid			(*get_database_or_server_collation_oid_internal) (bool missingOk);

	coll_info_t (*lookup_collation_table_callback) (Oid oid);

	like_ilike_info_t (*lookup_like_ilike_table) (Oid opno);

	Datum		(*collation_list_internal) (PG_FUNCTION_ARGS);

	Datum		(*is_collated_ci_as_internal) (PG_FUNCTION_ARGS);

	Datum		(*is_collated_ai_internal) (PG_FUNCTION_ARGS);

	int			(*collationproperty_helper) (const char *collationaname, const char *property);

	bytea	   *(*tdscollationproperty_helper) (const char *collationaname, const char *property);

	bool		(*is_database_or_server_collation_CI) (void);

	bool		(*is_valid_server_collation_name) (const char *collationname);

	int			(*find_locale) (const char *locale);

	Oid			(*get_oid_from_collidx_internal) (int collidx);

	int			(*find_cs_as_collation_internal) (int collidx);

	int			(*find_collation_internal) (const char *collation_name);

	bool		(*has_ilike_node) (Node *expr);

	const char *(*translate_bbf_collation_to_tsql_collation) (const char *collname);

	const char *(*translate_tsql_collation_to_bbf_collation) (const char *collname);

	void		(*set_db_collation) (Oid db_coll);

} collation_callbacks;

extern collation_callbacks *collation_callbacks_ptr;

/* Wrappers to call any callback functions from collation_callbacks_ptr. */
extern Oid	tsql_get_database_or_server_collation_oid_internal(bool missingOk);
extern Datum tsql_collation_list_internal(PG_FUNCTION_ARGS);
extern Datum tsql_is_collated_ci_as_internal(PG_FUNCTION_ARGS);
extern Datum tsql_is_collated_ai_internal(PG_FUNCTION_ARGS);
extern int	tsql_collationproperty_helper(const char *collationaname, const char *property);
extern bytea *tsql_tdscollationproperty_helper(const char *collationaname, const char *property);
extern bool tsql_is_database_or_server_collation_CI(void);
extern bool tsql_is_valid_server_collation_name(const char *collationname);
extern int	tsql_find_locale(const char *locale);
extern Oid	tsql_get_oid_from_collidx(int collidx);
coll_info_t tsql_lookup_collation_table_internal(Oid oid);
like_ilike_info_t tsql_lookup_like_ilike_table_internal(Oid opno);
int			tsql_find_cs_as_collation_internal(int collidx);
int			tsql_find_collation_internal(const char *collation_name);
extern const char *tsql_translate_bbf_collation_to_tsql_collation(const char *collname);
extern const char *tsql_translate_tsql_collation_to_bbf_collation(const char *collname);
extern bool pltsql_strpos_non_determinstic(text *t1, text *t2, Oid collid, int *r);
extern bool pltsql_replace_non_determinstic(text *t1, text *t2, text *t3, Oid collid, text **result);

/* Utility functions */
extern bool has_ilike_node_and_ci_as_coll(Node *expr);

extern Node *pltsql_planner_node_transformer(PlannerInfo *root,
											 Node *expr,
											 int kind);
extern Node *pltsql_predicate_transformer(Node *expr);

void set_db_collation_internal(const char *db_name);
bool supported_collation_for_db_and_like(int32_t code_page);
char* get_collation_name_for_db(const char* dbname);

/* Expression kind codes for preprocess_expression */
#define EXPRKIND_QUAL				0
#define EXPRKIND_TARGET				1

#endif
