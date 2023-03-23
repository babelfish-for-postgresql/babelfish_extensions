#include <string.h>

#include "postgres.h"

#include "common/hashfn.h"
#include "miscadmin.h"
#include "nodes/bitmapset.h"
#include "pgstat.h"
#include "storage/proc.h"
#include "utils/elog.h"
#include "utils/hsearch.h"
#include "utils/palloc.h"		/* Needed for pstrdup() */

#include "src/include/tds_int.h"
#include "src/include/tds_response.h"
#include "src/include/err_handler.h"
#include "src/include/tds_instr.h"

static bool is_user_defined_error(int pg_error_code);

bool		tds_disable_error_log_hook = false;
static HTAB *error_map_hash = NULL;

extern bool GetTdsEstateErrorData(int *number, int *severity, int *state);

error_map_details error_list[] = {
#include "src/include/error_mapping.h"
	{"00000", NULL, 0, 0, NULL}
};

/*
 * Returns list of sql error code for which Babel does have support for.
 */
void *
get_mapped_error_list()
{
	return error_list;
}

/*
 * Returns list of sql error code for which Babel does have support for.
 */
int *
get_mapped_tsql_error_code_list()
{
	int			i;
	int		   *list;			/* Temp list to store list of mapped sql error
								 * codes and its length. */
	Bitmapset  *tmp = NULL;		/* To store the unique sql error codes. */
	int			tmp_len = 0;	/* To store number of unique sql error codes. */
	int			prev_idx = -1;	/* To retrieve all members of set. */
	int			len = sizeof(error_list) / sizeof(error_list[0]);

	for (i = 0; i < len - 1; i++)
	{
		if (!bms_is_member(error_list[i].tsql_error_code, tmp))
		{
			/* If given sql error code is not already present in set. */
			tmp = bms_add_member(tmp, error_list[i].tsql_error_code);
			tmp_len += 1;
		}
	}

	list = palloc0((tmp_len + 1) * sizeof(int));
	list[0] = tmp_len;
	i = 1;
	while ((prev_idx = bms_next_member(tmp, prev_idx)) >= 0)
	{
		list[i] = prev_idx;
		i += 1;
	}

	bms_free(tmp);
	return list;
}

/*
 * load_err_code_mapping() - loads error code mapping details in HASH table.
 */
void
load_error_mapping()
{
	HASHCTL		hashCtl;
	int			i,
				len = sizeof(error_list) / sizeof(error_list[0]);

	/* For now, we don't allow user to update the mapping. */
	if (error_map_hash != NULL)
		return;

	MemSet(&hashCtl, 0, sizeof(hashCtl));
	hashCtl.keysize = sizeof(error_map_key);
	hashCtl.entrysize = sizeof(error_map);
	hashCtl.hcxt = TdsMemoryContext;
	error_map_hash = hash_create("Error code mapping cache",
								 len,
								 &hashCtl,
								 HASH_ELEM | HASH_CONTEXT | HASH_BLOBS);

	for (i = 0; i < len - 1; i++)
	{
		error_map_info map_info;
		error_map_key key_info;
		bool		found;

		key_info.sqlerrcode = MAKE_SQLSTATE(error_list[i].sql_state[0],
											error_list[i].sql_state[1],
											error_list[i].sql_state[2],
											error_list[i].sql_state[3],
											error_list[i].sql_state[4]);
		key_info.message_hash = (uint32) hash_any((unsigned char *) error_list[i].error_message, strlen(error_list[i].error_message));
		map_info = (error_map_info) hash_search(error_map_hash,
												&key_info,
												HASH_ENTER,
												&found);
		if (found)
		{
			error_map_node *head = map_info->head;
			error_map_node *tmp = (error_map_node *) palloc0(sizeof(error_map_node));

			tmp->error_msg_keywords = error_list[i].error_msg_keywords;
			tmp->tsql_error_code = error_list[i].tsql_error_code;
			tmp->tsql_error_severity = error_list[i].tsql_error_severity;
			tmp->next = head;
			map_info->head = tmp;
		}
		else
		{
			error_map_node *tmp = (error_map_node *) palloc0(sizeof(error_map_node));

			tmp->error_msg_keywords = error_list[i].error_msg_keywords;
			tmp->tsql_error_code = error_list[i].tsql_error_code;
			tmp->tsql_error_severity = error_list[i].tsql_error_severity;
			tmp->next = NULL;
			map_info->head = tmp;
		}
	}
}

bool
get_tsql_error_details(ErrorData *edata,
					   int *tsql_error_code,
					   int *tsql_error_severity,
					   int *tsql_error_state,
					   char *error_context)
{
	error_map_info map_info;
	error_map_key key_info;
	bool		found;

	/* Skip mapping if this is a user-defined error */
	if (is_user_defined_error(edata->sqlerrcode))
	{
		if (GetTdsEstateErrorData(tsql_error_code, tsql_error_severity, tsql_error_state))
			return true;

		/* Failed to find reliable user-defined error data, use default values */
		*tsql_error_code = 50000;
		*tsql_error_severity = 16;
		*tsql_error_state = 1;

		return true;
	}

	/*
	 * This condition is useful when error is thrown before initialising the
	 * hash table. In that case, load hash table immediately.
	 */
	if (error_map_hash == NULL)
	{
		MemoryContext oldContext = MemoryContextSwitchTo(TdsMemoryContext);

		load_error_mapping();
		MemoryContextSwitchTo(oldContext);
	}

	key_info.message_hash = (uint32) hash_any((unsigned char *) edata->message_id, (edata->message_id != NULL) ? strlen(edata->message_id) : 0);
	key_info.sqlerrcode = edata->sqlerrcode;

	map_info = (error_map_info) hash_search(error_map_hash,
											&key_info,
											HASH_FIND,
											&found);

	/* For all system generated errors, error state is default to be 1 */
	*tsql_error_state = 1;

	/* TODO: Ideally we should have mapping for every error. */
	if (!found)
	{
		*tsql_error_code = ERRCODE_PLTSQL_ERROR_NOT_MAPPED;
		*tsql_error_severity = 16;

		TDSInstrumentation(INSTR_TDS_UNMAPPED_ERROR);

		elog(LOG, "Unmapped error found. Code: %d, Message: %s, File: %s, Line: %d, Context: %s",
			 edata->sqlerrcode, edata->message, edata->filename, edata->lineno, error_context);

		return false;
	}
	else
	{
		bool		flag = false;
		error_map_node *tmp = map_info->head;

		while (tmp)
		{
			if (!tmp->error_msg_keywords)
				elog(FATAL, "Error message keyword is NULL (internal error)");

			if (strlen(tmp->error_msg_keywords) == 0)
			{
				flag = true;
				*tsql_error_code = tmp->tsql_error_code;
				*tsql_error_severity = tmp->tsql_error_severity;
			}
			else
			{
				/*
				 * All key words should be matched to qualify it as a correct
				 * tsql error details.
				 */
				char	   *key_word;
				char	   *tmp_keywords = pstrdup(tmp->error_msg_keywords);

				flag = true;

				/*
				 * According to document of strtok(), passed string is modify
				 * by being broken into smaller strings (tokens). Certian
				 * platforms does not allow to modify the string literal.
				 * Attempting to do so will result in segmentation fault. So,
				 * here we are storing string literal into temp string and
				 * then passing it into strtok().
				 */
				key_word = strtok(tmp_keywords, "#");
				while (key_word != NULL)
				{
					if (!strcasestr(edata->message, key_word))
					{
						flag = false;
						break;
					}
					key_word = strtok(NULL, "#");
				}
				if (flag)
				{
					*tsql_error_code = tmp->tsql_error_code;
					*tsql_error_severity = tmp->tsql_error_severity;
					pfree(tmp_keywords);
					return true;
				}
				pfree(tmp_keywords);
			}
			tmp = tmp->next;
		}

		/*
		 * If appropriate tsql error code could not be found then use PG error
		 * code as a default.
		 */
		if (!flag)
		{
			TDSInstrumentation(INSTR_TDS_UNMAPPED_ERROR);

			elog(LOG, "Unmapped error found. Code: %d, Message: %s, File: %s, Line: %d, Context: %s",
				 edata->sqlerrcode, edata->message, edata->filename, edata->lineno, error_context);

			*tsql_error_code = ERRCODE_PLTSQL_ERROR_NOT_MAPPED;
			*tsql_error_severity = 16;
			return false;
		}
	}
	return true;
}

void
emit_tds_log(ErrorData *edata)
{
	int			tsql_error_code,
				tsql_error_sev,
				tsql_error_state,
				error_lineno;

	/*
	 * We've already sent the error token to the TDS client.  We don't have to
	 * send the error to a psql client.  So, turn it off.
	 */
	edata->output_to_client = false;

	/* If disabled, return from here */
	if (tds_disable_error_log_hook)
		return;

	/* disable further entry to this function to avoid recursion */
	tds_disable_error_log_hook = true;

	if (edata->elevel < ERROR)
	{
		elog(DEBUG5, "suppressing informational client message < ERROR");

		/* reset the flag */
		tds_disable_error_log_hook = false;
		return;
	}

	/*
	 * It is possible that we fail while processing the error (for example,
	 * because of encoding conversion failure). Therefore, we place a PG_TRY
	 * block so that we can log the internal error and
	 * tds_disable_error_log_hook can be set to false so that further errors
	 * can be sent to client.
	 */

	PG_TRY();
	{
		if (MyProc != NULL)
		{
			error_lineno = 1;
			get_tsql_error_details(edata, &tsql_error_code, &tsql_error_sev, &tsql_error_state, "TDS");
			if (pltsql_plugin_handler_ptr && pltsql_plugin_handler_ptr->pltsql_current_lineno && *(pltsql_plugin_handler_ptr->pltsql_current_lineno) > 0)
				error_lineno = *(pltsql_plugin_handler_ptr->pltsql_current_lineno);
		}
		else
		{
			/* We are not in position to load the error mapping hash table. */
			error_lineno = 0;
			tsql_error_code = ERRCODE_PLTSQL_ERROR_NOT_MAPPED;
			tsql_error_sev = 16;
			tsql_error_state = 1;
		}

		TdsSendError(tsql_error_code, tsql_error_state, tsql_error_sev,
					 edata->message, error_lineno);

		/*
		 * If we've not reached the main query loop yet, flush the error
		 * message immediately.
		 */
		if (!IsNormalProcessingMode())
		{
			/*
			 * As of now, we can only reach here if we get any error during
			 * prelogin and login phase.
			 */
			TdsSendDone(TDS_TOKEN_DONE, TDS_DONE_ERROR, 0, 0);
			TdsFlush();
		}
	}
	PG_CATCH();
	{
		/* Log the internal error message */
		ErrorData  *next_edata;

		next_edata = CopyErrorData();
		elog(LOG, "internal error occurred: %s", next_edata->message);
		FreeErrorData(next_edata);
	}
	PG_END_TRY();

	/* reset the flag */
	tds_disable_error_log_hook = false;
}


void
reset_error_mapping_cache()
{
	error_map_hash = NULL;
}

/*
 * Define whether this is a user-defined error
 */
static bool
is_user_defined_error(int pg_error_code)
{
	if (pg_error_code == ERRCODE_PLTSQL_RAISERROR ||
		pg_error_code == ERRCODE_PLTSQL_THROW)
		return true;

	return false;
}
