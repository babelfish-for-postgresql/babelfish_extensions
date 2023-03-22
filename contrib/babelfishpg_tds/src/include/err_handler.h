#include "utils/elog.h"

typedef struct error_map_details
{
	char		sql_state[5];
	const char *error_message;
	int			tsql_error_code;
	int			tsql_error_severity;
	char	   *error_msg_keywords;
} error_map_details;

/* Function in err_handler.c */
extern void emit_tds_log(ErrorData *edata);
extern void load_error_mapping(void);
extern bool get_tsql_error_details(ErrorData *edata,
								   int *tsql_error_code,
								   int *tsql_error_severity,
								   int *tsql_error_state,
								   char *error_context);
extern void reset_error_mapping_cache(void);
extern void *get_mapped_error_list(void);
extern int *get_mapped_tsql_error_code_list(void);

/*
 * Structure to store key information for error mapping.
 * Hash of error message along with sqlerrorcode is key here.
 */
typedef struct error_map_key
{
	uint32		message_hash;	/* Hash of error message */
	int			sqlerrcode;		/* encoded ERRSTATE of error code */
} error_map_key;

/*
 * This linked list will be used during second level of lookup.
 * i.e., when given PG error code and error message_id (untranslated error message) is not enough
 * to uniquely identify the correct tsql error details.
 */
typedef struct error_map_node
{
	char	   *error_msg_keywords; /* Unique keywords from error message to
									 * identify the correct tsql error. */
	int			tsql_error_code;	/* TSQL error code */
	int			tsql_error_severity;	/* TSQL error severity */
	struct error_map_node *next;
} error_map_node;

/*
 * Structure to store list of tsql error details for given key.
 */
typedef struct error_map
{
	error_map_key key;
	error_map_node *head;
} error_map;

typedef error_map *error_map_info;
