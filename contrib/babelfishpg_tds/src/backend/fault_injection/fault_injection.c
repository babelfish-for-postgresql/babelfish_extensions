/*-------------------------------------------------------------------------
 *
 * fault_injection.c
 *	  Fault Injection Framework
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  contrib/babelfishpg_tds/src/backend/fault_injection/fault_injection.c
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "fmgr.h"
#include "lib/stringinfo.h"
#include "miscadmin.h"
#include "utils/builtins.h"
#include "utils/hsearch.h"
#include "utils/memutils.h"

#include "src/include/faultinjection.h"
#include "src/include/tds_int.h"

extern Datum inject_fault(PG_FUNCTION_ARGS);
extern Datum inject_fault_status(PG_FUNCTION_ARGS);
extern Datum trigger_test_fault(PG_FUNCTION_ARGS);
extern Datum inject_fault_status_all(PG_FUNCTION_ARGS);

PG_FUNCTION_INFO_V1(inject_fault);
PG_FUNCTION_INFO_V1(inject_fault_status);
PG_FUNCTION_INFO_V1(trigger_test_fault);
PG_FUNCTION_INFO_V1(inject_fault_status_all);

bool		trigger_fault_injection = true;
static HTAB *faultInjectorHash = NULL;

int			tamperByte = INVALID_TAMPER_BYTE;

/*
 * FaultInjectionHashInit - initialize the hash
 */
static void
FaultInjectionHashInit()
{
	HASHCTL		hash_ctl;
	MemoryContext oldContext;

	oldContext = MemoryContextSwitchTo(TopMemoryContext);
	/* Local cache */
	MemSet(&hash_ctl, 0, sizeof(hash_ctl));
	hash_ctl.keysize = FAULT_NAME_MAX_LENGTH;
	hash_ctl.entrysize = sizeof(FaultInjectorEntry_s);
	faultInjectorHash = hash_create("Fault Injection Cache",
									16,
									&hash_ctl,
									HASH_ELEM | HASH_STRINGS);
	MemoryContextSwitchTo(oldContext);
}

/*
 * FaultInjectionInitialize - initializa the fault injection hash with enrties
 */
static void
FaultInjectionInitialize()
{
	int			i = 0;
	bool		foundPtr;

	if (faultInjectorHash == NULL)
		FaultInjectionHashInit();

	do
	{
		const FaultInjectorEntry_s *entry = &Faults[i];
		FaultInjectorEntry_s *new_entry;

		if (entry->type == InvalidType)
			break;
		new_entry = (FaultInjectorEntry_s *) hash_search(
														 faultInjectorHash,
														 (void *) entry->faultName, //key
														 HASH_ENTER,
														 &foundPtr);
		/* should not try to insert same entry multiple times */
		Assert(foundPtr == false);

		if (new_entry == NULL)
		{
			ereport(ERROR,
					(errmsg("FaultInjectionLookupHashEntry() could not insert fault injection hash entry:'%s' ",
							entry->faultName)));
		}

		new_entry->type = entry->type;
		new_entry->num_occurrences = 0;
		new_entry->fault_callback = entry->fault_callback;

		i++;
	} while (true);
}

/*
 * FaultInjectionLookupHashEntry - look for the entry
 */
static FaultInjectorEntry_s *
FaultInjectionLookupHashEntry(const char *faultName)
{
	FaultInjectorEntry_s *entry;

	if (faultInjectorHash == NULL)
		FaultInjectionInitialize();

	entry = (FaultInjectorEntry_s *) hash_search(
												 faultInjectorHash,
												 (void *) faultName, //key
												 HASH_FIND,
												 NULL);

	if (entry == NULL)
	{
		ereport(ERROR,
				(errmsg("FaultInjectionLookupHashEntry() could not find fault injection hash entry:'%s' ",
						faultName)));
	}

	return entry;
}

static void
FaultInjectionEnableTest(FaultInjectorEntry_s *entry)
{
	List	   *list = FaultInjectionTypes[entry->type].injected_entries;
	ListCell   *lc;
	MemoryContext oldContext;


	foreach(lc, list)
	{
		if (entry == (FaultInjectorEntry_s *) lfirst(lc))
			return;
	}

	oldContext = MemoryContextSwitchTo(TopMemoryContext);
	list = lappend(list, entry);
	MemoryContextSwitchTo(oldContext);

	FaultInjectionTypes[entry->type].injected_entries = list;
}

static inline void
FaultInjectionDisableTest(FaultInjectorEntry_s *entry)
{
	ListCell   *lc;
	List	   *list = FaultInjectionTypes[entry->type].injected_entries;

	if (list_length(list) == 1)
	{
		list_free(list);
		list = NIL;
	}
	else
	{
		foreach(lc, list)
		{
			if (entry == (FaultInjectorEntry_s *) lfirst(lc))
				list = list_delete_cell(list, lc);
		}
	}

	tamperByte = INVALID_TAMPER_BYTE;
	FaultInjectionTypes[entry->type].injected_entries = list;
}

static char *
FetchFaultStatus(char *faultName)
{
	StringInfo	buf = makeStringInfo();
	FaultInjectorEntry_s *entry;

	entry = FaultInjectionLookupHashEntry(faultName);

	if (entry->num_occurrences == 0)
		appendStringInfo(buf, "disabled, Type: %s",
						 FaultInjectionTypes[entry->type].faultTypeName);
	else
		appendStringInfo(buf, "enabled, Type: %s, pending occurrences: %d",
						 FaultInjectionTypes[entry->type].faultTypeName,
						 entry->num_occurrences);

	return buf->data;
}

static char *
InjectFault(const char *faultName, int num_occurrences, int tamper_byte)
{
	StringInfo	buf = makeStringInfo();
	FaultInjectorEntry_s *entry;

	entry = FaultInjectionLookupHashEntry(faultName);
	if (entry->num_occurrences == 0 && num_occurrences > 0)
		FaultInjectionEnableTest(entry);
	else if (entry->num_occurrences > 0 && num_occurrences == 0)
		FaultInjectionDisableTest(entry);

	entry->num_occurrences = num_occurrences;
	tamperByte = tamper_byte;

	if (entry->num_occurrences == 0)
		appendStringInfo(buf, "disabled");
	else if (tamperByte != INVALID_TAMPER_BYTE)
		appendStringInfo(buf, "enabled, pending occurrences: %d, tamper byte value: %d",
						 entry->num_occurrences, tamperByte);
	else
		appendStringInfo(buf, "enabled, pending occurrences: %d", entry->num_occurrences);

	return buf->data;
}

void
TriggerFault(FaultInjectorType_e type, void *arg)
{
	List	   *list = FaultInjectionTypes[type].injected_entries;
	List	   *tmp_list = NIL;
	ListCell   *lc;

	/* if triggering is disabled, return */
	if (!trigger_fault_injection || list_length(list) == 0)
		return;

	TDS_DEBUG(TDS_DEBUG1, "Triggering fault type: %s", FaultInjectionTypes[type].faultTypeName);

	/* Fast Path when entry is just 1 */
	if (list_length(list) == 1)
	{
		FaultInjectorEntry_s *entry;

		lc = list_head(list);
		entry = (FaultInjectorEntry_s *) lfirst(lc);

		/* otherwise it should have been removed */
		Assert(entry->num_occurrences > 0);

		PG_TRY();
		{
			TDS_DEBUG(TDS_DEBUG2, "Triggering fault: %s", entry->faultName);
			(*(entry->fault_callback)) (arg, &(entry->num_occurrences));
		}
		PG_CATCH();
		{
			if (entry->num_occurrences == 0)
				FaultInjectionDisableTest(entry);

			PG_RE_THROW();
		}
		PG_END_TRY();

		if (entry->num_occurrences == 0)
			FaultInjectionDisableTest(entry);

		return;
	}

	/*
	 * If there is more than one entry, we've to be careful while removing
	 * entries from the list while traversing the same.
	 */
	foreach(lc, list)
	{
		FaultInjectorEntry_s *entry = (FaultInjectorEntry_s *) lfirst(lc);

		/* otherwise it should have been removed */
		Assert(entry->num_occurrences > 0);

		PG_TRY();
		{
			TDS_DEBUG(TDS_DEBUG2, "Triggering fault: %s", entry->faultName);
			(*(entry->fault_callback)) (arg, &(entry->num_occurrences));
		}
		PG_CATCH();
		{
			if (entry->num_occurrences == 0)
				tmp_list = lappend(tmp_list, entry);

			foreach(lc, tmp_list)
			{
				FaultInjectorEntry_s *entry = (FaultInjectorEntry_s *) lfirst(lc);

				FaultInjectionDisableTest(entry);
			}

			list_free(tmp_list);

			PG_RE_THROW();
		}
		PG_END_TRY();

		if (entry->num_occurrences == 0)
			tmp_list = lappend(tmp_list, entry);
	}

	foreach(lc, tmp_list)
	{
		FaultInjectorEntry_s *entry = (FaultInjectorEntry_s *) lfirst(lc);

		FaultInjectionDisableTest(entry);
	}

	list_free(tmp_list);
}

/*
 * InjectFaultAll - inject all the faults if enable = true, disable otherwise
 *
 * It enables the faults with occurences as 1
 */
static char *
InjectFaultAll(bool enable)
{
	int			i = 0;
	StringInfo	response = makeStringInfo();

	do
	{
		char	   *ret;
		const FaultInjectorEntry_s *entry = &Faults[i];

		if (entry->type == InvalidType)
			break;
		ret = InjectFault(entry->faultName, (enable) ? 1 : 0, INVALID_TAMPER_BYTE);

		if (!ret)
			elog(ERROR, "failed to inject fault");

		pfree(ret);

		i++;
	} while (true);

	appendStringInfo(response, "success");

	return response->data;
}

Datum
inject_fault(PG_FUNCTION_ARGS)
{
	char	   *faultName = TextDatumGetCString(PG_GETARG_DATUM(0));
	int			num_occurrences = PG_GETARG_INT32(1);
	char	   *response;
	int			nargs = PG_NARGS();
	int			tamper_byte = INVALID_TAMPER_BYTE;

	if (nargs > 2)
		tamper_byte = PG_GETARG_INT32(2);

	if (num_occurrences < 0)
		elog(ERROR, "number of occurrences cannot be negative");

	/* check if we need to enable/disable all the tests */
	if (strcmp(faultName, "all") == 0 && num_occurrences > 0)
		response = InjectFaultAll(true);
	else if (strcmp(faultName, "all") == 0 && num_occurrences == 0)
		response = InjectFaultAll(false);
	else
		response = InjectFault(faultName, num_occurrences, tamper_byte);
	if (!response)
		elog(ERROR, "failed to inject fault");

	PG_RETURN_TEXT_P(cstring_to_text(response));
}

Datum
inject_fault_status(PG_FUNCTION_ARGS)
{
	char	   *faultName = TextDatumGetCString(PG_GETARG_DATUM(0));
	char	   *response;

	response = FetchFaultStatus(faultName);
	if (!response)
		elog(ERROR, "failed to fetch injected fault status");

	PG_RETURN_TEXT_P(cstring_to_text(response));
}

Datum
inject_fault_status_all(PG_FUNCTION_ARGS)
{
	/* TODO */
	PG_RETURN_VOID();
}

Datum
trigger_test_fault(PG_FUNCTION_ARGS)
{
	StringInfo	buf = makeStringInfo();

	TriggerFault(TestType, (void *) buf);
	if (!buf)
		elog(ERROR, "failed to trigger fault");

	PG_RETURN_TEXT_P(cstring_to_text(buf->data));
}
