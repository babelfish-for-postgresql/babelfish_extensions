
/*-------------------------------------------------------------------------
 *
 * tds.c
 *	  TDS Listener extension entrypoint
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  contrib/babelfishpg_tds/src/backend/tds/tds.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"
#include "funcapi.h"
#include "varatt.h"

#include "access/printtup.h"
#include "access/xact.h"
#include "src/include/tds_int.h"
#include "src/include/tds_secure.h"
#include "src/include/tds_instr.h"
#include "commands/defrem.h"
#include "fmgr.h"
#include "pgstat.h"
#include "libpq/libpq.h"
#include "libpq/libpq-be.h"
#include "miscadmin.h"
#include "parser/parse_expr.h"
#include "postmaster/postmaster.h"
#include "storage/procarray.h"
#include "storage/ipc.h"
#include "storage/lwlock.h"
#include "storage/shmem.h"
#include "storage/sinvaladt.h"
#include "utils/builtins.h"
#include "utils/guc.h"
#include "utils/elog.h"
#include "utils/pidfile.h"
#include "utils/lsyscache.h"

#include "src/include/err_handler.h"


/* ----------
 * Total number of backends including auxiliary
 *
 * We reserve a slot for each possible BackendId, plus one for each
 * possible auxiliary process type.  (This scheme assumes there is not
 * more than one of any auxiliary process type at a time.) MaxBackends
 * includes autovacuum workers and background workers as well.
 * ----------
 */
#define NumBackendStatSlots (MaxBackends + NUM_AUXILIARY_PROCS)

#define LIBDATALEN 32
#define LANGDATALEN 128
#define HOSTDATALEN 128
#define XACT_SNAPSHOT 5
#define CONTEXTINFOLEN 128

PG_MODULE_MAGIC;

/* Shmem state */
typedef struct TdsStatus
{
	/*
	 * To avoid locking overhead, we use the following protocol: a backend
	 * increments st_changecount before modifying its entry, and again after
	 * finishing a modification.  A would-be reader should note the value of
	 * st_changecount, copy the entry into private memory, then check
	 * st_changecount again.  If the value hasn't changed, and if it's even,
	 * the copy is valid; otherwise start over.  This makes updates cheap
	 * while reads are potentially expensive, but that's the tradeoff we want.
	 *
	 * The above protocol needs memory barriers to ensure that the apparent
	 * order of execution is as it desires.  Otherwise, for example, the CPU
	 * might rearrange the code so that st_changecount is incremented twice
	 * before the modification on a machine with weak memory ordering.  Hence,
	 * use the macros defined below for manipulating st_changecount, rather
	 * than touching it directly.
	 */
	int			st_changecount;

	/* The entry is valid iff st_procpid > 0, unused if st_procpid == 0 */
	int			st_procpid;

	/* Add more TDS info */
	uint32_t	client_version;

	bool		quoted_identifier;
	bool		arithabort;
	bool		ansi_null_dflt_on;
	bool		ansi_defaults;
	bool		ansi_warnings;
	bool		ansi_padding;
	bool		ansi_nulls;
	bool		concat_null_yields_null;
	int			textsize;
	int			datefirst;
	int			lock_timeout;
	int			transaction_isolation;

	char	   *st_library_name;	/* Library */
	char	   *st_host_name;	/* Hostname */
	char	   *st_language;	/* Language */
	char	   *st_context_info;	/* CONTEXT_INFO */

	uint32_t	client_pid;

	uint64		rowcount;
	int			error;
	int			trancount;

	uint32_t	protocol_version;
	uint32_t	packet_size;
	int			encrypt_option;

	int16		database_id;
} TdsStatus;

typedef struct LocalTdsStatus
{
	/*
	 * Local version of the tds status entry.
	 */
	TdsStatus	tdsStatus;

	/*
	 * The xid of the current transaction if available, InvalidTransactionId
	 * if not.
	 */
	TransactionId backend_xid;

	/*
	 * The xmin of the current session if available, InvalidTransactionId if
	 * not.
	 */
	TransactionId backend_xmin;

	/*
	 * Number of cached subtransactions in the current session.
	 */
	int	backend_subxact_count;

	/*
	 * The number of subtransactions in the current session which exceeded the
	 * cached subtransaction limit.
	 */
	bool backend_subxact_overflowed;
} LocalTdsStatus;

static TdsStatus *TdsStatusArray = NULL;
static TdsStatus *MyTdsStatusEntry;
static LocalTdsStatus *localTdsStatusTable = NULL;

uint32_t	MyTdsClientVersion = 0;
uint32_t	MyTdsClientPid = -1;
char	   *MyTdsLibraryName = NULL;
char	   *MyTdsHostName = NULL;
char	   *MyTdsContextInfo = NULL;
uint32_t	MyTdsProtocolVersion = TDS_DEFAULT_VERSION;
uint32_t	MyTdsPacketSize = 0;
int			MyTdsEncryptOption = TDS_ENCRYPT_OFF;
static char *TdsLibraryNameBuffer = NULL;
static char *TdsHostNameBuffer = NULL;
static char *TdsLanguageBuffer = NULL;
static char *TdsContextInfoBuffer = NULL;

static int	localNumBackends = 0;
static bool isLocalStatusTableValid = false;

TdsInstrPlugin **tds_instr_plugin_ptr = NULL;

extern void _PG_init(void);
extern void _PG_fini(void);

/* Hook for plugins */
static struct PLtsql_protocol_plugin pltsql_plugin_handler;
PLtsql_protocol_plugin *pltsql_plugin_handler_ptr = &pltsql_plugin_handler;

static Oid	tvp_lookup(const char *relname, Oid relnamespace);
static relname_lookup_hook_type prev_relname_lookup_hook = NULL;

/* Shmem hook */
static shmem_startup_hook_type next_shmem_startup_hook = NULL;
static shmem_request_hook_type prev_shmem_request_hook = NULL;

static Size tds_memsize(void);
static void tds_shmem_request(void);

/* Shmem init interfaces */
static void tds_status_shmem_startup(void);
static void tds_stats_shmem_shutdown(int code, Datum arg);

static void tdsstat_read_current_status(void);
static LocalTdsStatus *tdsstat_fetch_stat_local_tdsentry(int beid);

/*
 * Module initialization function
 */
void
_PG_init(void)
{
	/* Be sure we do initialization only once */
	static bool inited = false;

	if (inited)
		return;

	/* Must be loaded with shared_preload_libaries */
	if (!process_shared_preload_libraries_in_progress)
		ereport(ERROR, (errcode(ERRCODE_OBJECT_NOT_IN_PREREQUISITE_STATE),
						errmsg("babelfishpg_tds must be loaded via shared_preload_libraries")));

	TdsDefineGucs();

	tds_instr_plugin_ptr = (TdsInstrPlugin **) find_rendezvous_variable("TdsInstrPlugin");

	pe_init();

	prev_relname_lookup_hook = relname_lookup_hook;
	relname_lookup_hook = tvp_lookup;

	/* Shmem hooks */
	next_shmem_startup_hook = shmem_startup_hook;
	shmem_startup_hook = tds_status_shmem_startup;

	prev_shmem_request_hook = shmem_request_hook;
	shmem_request_hook = tds_shmem_request;

	/* Install our object_access_hook into the chain */
	next_object_access_hook = object_access_hook;
	object_access_hook = babelfish_object_access;

	/* Install our process utility hook into the chain */
	next_ProcessUtility = ProcessUtility_hook;
	ProcessUtility_hook = tdsutils_ProcessUtility;

	inited = true;
}

/*
 * Module unload function
 */
void
_PG_fini(void)
{
	pe_fin();
	relname_lookup_hook = prev_relname_lookup_hook;
	object_access_hook = next_object_access_hook;
	ProcessUtility_hook = next_ProcessUtility;
	shmem_request_hook = prev_shmem_request_hook;
}

static Size
TdsStatusArraySize()
{
	return mul_size(sizeof(TdsStatus), NumBackendStatSlots);
}

static Size
TdsLibraryNameBufferSize()
{
	return mul_size(LIBDATALEN, NumBackendStatSlots);
}

static Size
TdsHostNameBufferSize()
{
	return mul_size(HOSTDATALEN, NumBackendStatSlots);
}

static Size
TdsLanguageBufferSize()
{
	return mul_size(LANGDATALEN, NumBackendStatSlots);
}

static Size
TdsContextInfoBufferSize()
{
	return mul_size(CONTEXTINFOLEN, NumBackendStatSlots);
}

static Size
tds_memsize()
{
	Size		size;

	size = TdsStatusArraySize();
	size = add_size(size, TdsLibraryNameBufferSize());
	size = add_size(size, TdsHostNameBufferSize());
	size = add_size(size, TdsLanguageBufferSize());
	size = add_size(size, TdsContextInfoBufferSize());
	return size;
}

static void
tds_shmem_request()
{
	if (prev_shmem_request_hook)
		prev_shmem_request_hook();

	/*
	 * Request additional shared resources.  (These are no-ops if we're not in
	 * the postmaster process.)  We'll allocate or attach to the shared
	 * resources in tds_status_shmem_startup().
	 */
	RequestAddinShmemSpace(tds_memsize());
}

/*
 * tds_status_shmem_startup hook: allocate or attach to shared memory,
 * the TDS status array and string buffers
 */
static void
tds_status_shmem_startup(void)
{
	bool		found;
	char	   *buffer;

	/*
	 * Create or attach to the shared memory state
	 */
	LWLockAcquire(AddinShmemInitLock, LW_EXCLUSIVE);

	TdsStatusArray = (TdsStatus *) ShmemInitStruct("TDS Status Array",
												   TdsStatusArraySize(),
												   &found);
	if (!found)
	{
		/*
		 * We're the first - initialize.
		 */
		MemSet(TdsStatusArray, 0, TdsStatusArraySize());
	}

	Assert(TdsStatusArray != NULL);

	/* Create or attach to the shared TDS library name buffer */
	TdsLibraryNameBuffer = (char *)
		ShmemInitStruct("TDS library name buffer", TdsLibraryNameBufferSize(), &found);

	if (!found)
	{
		int			i;

		MemSet(TdsLibraryNameBuffer, 0, TdsLibraryNameBufferSize());

		/* Initialize st_library_name pointers. */
		buffer = TdsLibraryNameBuffer;
		for (i = 0; i < MaxBackends; i++)
		{
			TdsStatusArray[i].st_library_name = buffer;
			buffer += LIBDATALEN;
		}
	}

	/* Create or attach to the shared TDS host name buffer */
	TdsHostNameBuffer = (char *)
		ShmemInitStruct("TDS host name buffer", TdsHostNameBufferSize(), &found);

	if (!found)
	{
		int			i;

		MemSet(TdsHostNameBuffer, 0, TdsHostNameBufferSize());

		/* Initialize st_host_name pointers. */
		buffer = TdsHostNameBuffer;
		for (i = 0; i < MaxBackends; i++)
		{
			TdsStatusArray[i].st_host_name = buffer;
			buffer += HOSTDATALEN;
		}
	}

	/* Create or attach to the shared TDS language buffer */
	TdsLanguageBuffer = (char *)
		ShmemInitStruct("TDS language buffer", TdsLanguageBufferSize(), &found);

	if (!found)
	{
		int			i;

		MemSet(TdsLanguageBuffer, 0, TdsLanguageBufferSize());

		/* Initialize st_language pointers. */
		buffer = TdsLanguageBuffer;
		for (i = 0; i < MaxBackends; i++)
		{
			TdsStatusArray[i].st_language = buffer;
			buffer += LANGDATALEN;
		}
	}

	/* Create or attach to the shared TDS context info buffer */
	TdsContextInfoBuffer = (char *)
		ShmemInitStruct("TDS context info buffer", TdsContextInfoBufferSize(), &found);

	if (!found)
	{
		int			i;

		MemSet(TdsContextInfoBuffer, 0, TdsContextInfoBufferSize());

		/* Initialize st_context_info pointers. */
		buffer = TdsContextInfoBuffer;
		for (i = 0; i < MaxBackends; i++)
		{
			TdsStatusArray[i].st_context_info = buffer;
			buffer += CONTEXTINFOLEN;
		}
	}

	LWLockRelease(AddinShmemInitLock);

	/*
	 * If we're in the postmaster (or a standalone backend...), set up a shmem
	 * exit hook to persist the dirty outlines
	 */
	if (!IsUnderPostmaster)
		on_shmem_exit(tds_stats_shmem_shutdown, (Datum) 0);

	if (next_shmem_startup_hook)
		next_shmem_startup_hook();

	return;
}

/*
 * tds_status_shmem_shutdown hook: if we want to persist any data
 * across database restarts, write additional logic here. No-op
 * for now.
 */
static void
tds_stats_shmem_shutdown(int code, Datum arg)
{
	/* Don't try to save the outlines during a crash. */
	if (code)
		return;

	/* Safety check ... shouldn't get here unless shmem is set up. */
	if (TdsStatusArray == NULL)
		return;

	return;
}

/* ----------
 * tdsstat_initialize() -
 *
 *	Initialize tdsstats state, and set up our on-proc-exit hook.
 * ----------
 */
void
tdsstat_initialize(void)
{
	/* Initialize MyTdsStatusEntry */
	Assert(MyProcNumber >= 0 && MyProcNumber < MaxBackends);
	MyTdsStatusEntry = &TdsStatusArray[MyProcNumber];

	/* Set up a process-exit hook to clean up */
	on_shmem_exit(tds_stats_shmem_shutdown, 0);
}

void
tdsstat_bestart(void)
{
	volatile TdsStatus *vtdsentry = MyTdsStatusEntry;
	TdsStatus	ltdsentry;

	int			len;
	char	   *library_name = NULL;
	char	   *host_name = NULL;
	const char *language = NULL;

	/*
	 * To minimize the time spent modifying the TdsStatus entry, and avoid
	 * risk of errors inside the critical section, we first copy the
	 * shared-memory struct to a local variable, then modify the data in the
	 * local variable, then copy the local variable back to shared memory.
	 * Only the last step has to be inside the critical section.
	 *
	 * Most of the data we copy from shared memory is just going to be
	 * overwritten, but the struct's not so large that it's worth the
	 * maintenance hassle to copy only the needful fields.
	 */
	memcpy(&ltdsentry,
		   unvolatize(TdsStatus *, vtdsentry),
		   sizeof(TdsStatus));

	ltdsentry.st_procpid = MyProcPid;
	ltdsentry.client_version = MyTdsClientVersion;
	ltdsentry.client_pid = MyTdsClientPid;
	ltdsentry.protocol_version = MyTdsProtocolVersion;
	ltdsentry.packet_size = MyTdsPacketSize;

	/* Set the boot GUC values */
	ltdsentry.quoted_identifier = (pltsql_plugin_handler_ptr && pltsql_plugin_handler_ptr->quoted_identifier) ? pltsql_plugin_handler_ptr->quoted_identifier : true;

	ltdsentry.arithabort = (pltsql_plugin_handler_ptr && pltsql_plugin_handler_ptr->arithabort) ? pltsql_plugin_handler_ptr->arithabort : true;

	ltdsentry.ansi_null_dflt_on = (pltsql_plugin_handler_ptr && pltsql_plugin_handler_ptr->ansi_null_dflt_on) ? pltsql_plugin_handler_ptr->ansi_null_dflt_on : true;

	ltdsentry.ansi_defaults = (pltsql_plugin_handler_ptr && pltsql_plugin_handler_ptr->ansi_defaults) ? pltsql_plugin_handler_ptr->ansi_defaults : true;

	ltdsentry.ansi_warnings = (pltsql_plugin_handler_ptr && pltsql_plugin_handler_ptr->ansi_warnings) ? pltsql_plugin_handler_ptr->ansi_warnings : true;

	ltdsentry.ansi_padding = (pltsql_plugin_handler_ptr && pltsql_plugin_handler_ptr->ansi_padding) ? pltsql_plugin_handler_ptr->ansi_padding : true;

	ltdsentry.ansi_nulls = (pltsql_plugin_handler_ptr && pltsql_plugin_handler_ptr->ansi_nulls) ? pltsql_plugin_handler_ptr->ansi_nulls : true;

	ltdsentry.concat_null_yields_null = (pltsql_plugin_handler_ptr && pltsql_plugin_handler_ptr->concat_null_yields_null) ? pltsql_plugin_handler_ptr->concat_null_yields_null : true;

	ltdsentry.textsize = (pltsql_plugin_handler_ptr && pltsql_plugin_handler_ptr->textsize) ? pltsql_plugin_handler_ptr->textsize : 0;

	ltdsentry.datefirst = (pltsql_plugin_handler_ptr && pltsql_plugin_handler_ptr->datefirst) ? pltsql_plugin_handler_ptr->datefirst : 7;

	ltdsentry.lock_timeout = (pltsql_plugin_handler_ptr && pltsql_plugin_handler_ptr->lock_timeout) ? pltsql_plugin_handler_ptr->lock_timeout : -1;

	ltdsentry.transaction_isolation = DefaultXactIsoLevel;

	language = (pltsql_plugin_handler_ptr && pltsql_plugin_handler_ptr->language) ? pltsql_plugin_handler_ptr->language : NULL;

	if (language != NULL)
	{
		len = pg_mbcliplen(language, strlen(language), LANGDATALEN - 1);
		memcpy((char *) ltdsentry.st_language, language, len);
		ltdsentry.st_language[len] = '\0';
	}

	library_name = MyTdsLibraryName;

	if (library_name != NULL)
	{
		len = pg_mbcliplen(library_name, strlen(library_name), LIBDATALEN - 1);
		memcpy((char *) ltdsentry.st_library_name, library_name, len);
		ltdsentry.st_library_name[len] = '\0';
	}

	host_name = MyTdsHostName;

	if (host_name != NULL)
	{
		len = pg_mbcliplen(host_name, strlen(host_name), HOSTDATALEN - 1);
		memcpy((char *) ltdsentry.st_host_name, host_name, len);
		ltdsentry.st_host_name[len] = '\0';
	}

	memset(ltdsentry.st_context_info, 0, CONTEXTINFOLEN);

	ltdsentry.encrypt_option = MyTdsEncryptOption;
	ltdsentry.database_id = 0;

	/*
	 * We're ready to enter the critical section that fills the shared-memory
	 * status entry.  We follow the protocol of bumping st_changecount before
	 * and after; and make sure it's even afterwards.  We use a volatile
	 * pointer here to ensure the compiler doesn't try to get cute.
	 */
	PGSTAT_BEGIN_WRITE_ACTIVITY(vtdsentry);

	/* make sure we'll memcpy the same st_changecount back */
	ltdsentry.st_changecount = vtdsentry->st_changecount;

	memcpy(unvolatize(TdsStatus *, vtdsentry),
		   &ltdsentry,
		   sizeof(TdsStatus));

	PGSTAT_END_WRITE_ACTIVITY(vtdsentry);
}

static LocalTdsStatus *
tdsstat_fetch_stat_local_tdsentry(int beid)
{
	LocalTdsStatus *localentry;

	tdsstat_read_current_status();

	if (beid < 1 || beid > localNumBackends)
		return NULL;

	localentry = &localTdsStatusTable[beid - 1];

	if (localentry->tdsStatus.st_procpid <= 0)
		return NULL;

	return localentry;
}

/* ----------
 * tdsstat_fetch_stat_numbackends() -
 *
 *	Support function for the SQL-callable pgstat* functions. Returns
 *	the number of sessions known in the localTdsStatusTable, i.e.
 *	the maximum 1-based index to pass to tdsstat_fetch_stat_local_tdsentry().
 * ----------
 */
int
tdsstat_fetch_stat_numbackends(void)
{
	tdsstat_read_current_status();
	return localNumBackends;
}

/* ----------
 * tdsstat_read_current_status() -
 *
 *	Copy the current contents of the TdsStatus array to local memory,
 *	if not already done in this transaction.
 * ----------
 */
static void
tdsstat_read_current_status(void)
{
	volatile TdsStatus *tdsentry;
	LocalTdsStatus *localtable;
	LocalTdsStatus *localentry;
	ProcNumber		i;

	if (isLocalStatusTableValid)
		return;					/* already done */

	/*
	 * Allocate storage for local copy of state data.
	 */
	localtable = (LocalTdsStatus *)
		palloc0(sizeof(LocalTdsStatus) * NumBackendStatSlots);

	localNumBackends = 0;

	tdsentry = TdsStatusArray;
	localentry = localtable;

	for (i = 1; i <= NumBackendStatSlots; i++)
	{
		/*
		 * Follow the protocol of retrying if st_changecount changes while we
		 * copy the entry, or if it's odd.  (The check for odd is needed to
		 * cover the case where we are able to completely copy the entry while
		 * the source backend is between increment steps.) We use a volatile
		 * pointer here to ensure the compiler doesn't try to get cute.
		 */
		for (;;)
		{
			int			before_changecount;
			int			after_changecount;

			pgstat_begin_read_activity(tdsentry, before_changecount);

			localentry->tdsStatus.st_procpid = tdsentry->st_procpid;

			/* Skip all the data-copying work if entry is not in use */
			if (localentry->tdsStatus.st_procpid > 0)
			{
				memcpy(&localentry->tdsStatus, unvolatize(TdsStatus *, tdsentry), sizeof(TdsStatus));

				if (tdsentry->client_version)
					localentry->tdsStatus.client_version = tdsentry->client_version;

				if (tdsentry->st_library_name)
					localentry->tdsStatus.st_library_name = tdsentry->st_library_name;

				if (tdsentry->st_host_name)
					localentry->tdsStatus.st_host_name = tdsentry->st_host_name;

				if (tdsentry->st_language)
					localentry->tdsStatus.st_language = tdsentry->st_language;

				if (tdsentry->st_context_info)
					localentry->tdsStatus.st_context_info = tdsentry->st_context_info;

				if (tdsentry->quoted_identifier)
					localentry->tdsStatus.quoted_identifier = tdsentry->quoted_identifier;

				if (tdsentry->arithabort)
					localentry->tdsStatus.arithabort = tdsentry->arithabort;

				if (tdsentry->ansi_null_dflt_on)
					localentry->tdsStatus.ansi_null_dflt_on = tdsentry->ansi_null_dflt_on;

				if (tdsentry->ansi_defaults)
					localentry->tdsStatus.ansi_defaults = tdsentry->ansi_defaults;

				if (tdsentry->ansi_warnings)
					localentry->tdsStatus.ansi_warnings = tdsentry->ansi_warnings;

				if (tdsentry->ansi_padding)
					localentry->tdsStatus.ansi_padding = tdsentry->ansi_padding;

				if (tdsentry->ansi_nulls)
					localentry->tdsStatus.ansi_nulls = tdsentry->ansi_nulls;

				if (tdsentry->concat_null_yields_null)
					localentry->tdsStatus.concat_null_yields_null = tdsentry->concat_null_yields_null;

				if (tdsentry->textsize)
					localentry->tdsStatus.textsize = tdsentry->textsize;

				if (tdsentry->datefirst)
					localentry->tdsStatus.datefirst = tdsentry->datefirst;

				if (tdsentry->lock_timeout)
					localentry->tdsStatus.lock_timeout = tdsentry->lock_timeout;

				if (tdsentry->transaction_isolation)
					localentry->tdsStatus.transaction_isolation = tdsentry->transaction_isolation;

				if (tdsentry->client_pid)
					localentry->tdsStatus.client_pid = tdsentry->client_pid;

				if (tdsentry->rowcount)
					localentry->tdsStatus.rowcount = tdsentry->rowcount;

				if (tdsentry->error)
					localentry->tdsStatus.error = tdsentry->error;

				if (tdsentry->trancount)
					localentry->tdsStatus.trancount = tdsentry->trancount;

				if (tdsentry->protocol_version)
					localentry->tdsStatus.protocol_version = tdsentry->protocol_version;

				if (tdsentry->packet_size)
					localentry->tdsStatus.packet_size = tdsentry->packet_size;

				if (tdsentry->encrypt_option)
					localentry->tdsStatus.encrypt_option = tdsentry->encrypt_option;

				if (tdsentry->database_id)
					localentry->tdsStatus.database_id = tdsentry->database_id;
			}

			pgstat_end_read_activity(tdsentry, after_changecount);

			if (pgstat_read_activity_complete(before_changecount, after_changecount))
				break;

			/* Make sure we can break out of loop if stuck... */
			CHECK_FOR_INTERRUPTS();
		}

		tdsentry++;

		/* Only valid entries get included into the local array */
		if (localentry->tdsStatus.st_procpid > 0)
		{
			ProcNumberGetTransactionIds(i, 
									   &localentry->backend_xid, 
									   &localentry->backend_xmin, 
									   &localentry->backend_subxact_count, 
									   &localentry->backend_subxact_overflowed);

			localentry++;
			localNumBackends++;
		}
	}

	localTdsStatusTable = localtable;
	isLocalStatusTableValid = true;
}

/*
 * get_tds_database_backend_count: Returns true if there are
 * any active connections to the database for which the
 * db_id is provided.
 * If ignore_current_connection is set to true then we need
 * to ignore the current connection, i.e. return true only
 * if there are more than 1 active connections on the db_id.
 */
bool
get_tds_database_backend_count(int16 db_id, bool ignore_current_connection)
{
	TdsStatus  *tdsentry;
	LocalTdsStatus *local_tdsentry;
	int number_of_connections = 0;

	/* Read the latest activity from the shared mem. */
	tdsstat_read_current_status();

	for (int i = 0; i < localNumBackends; i++)
	{
		local_tdsentry = &localTdsStatusTable[i];

		if (!local_tdsentry)
			return false;

		tdsentry = &local_tdsentry->tdsStatus;

		/*
		 * Return true if we find the first backend connected to
		 * this database. Also sanity check that the pid is valid.
		 * 
		 * If ignore_current_connection is set to true then we need to skip
		 * at least one connection using that database,
		 * i.e. increment count to 1 and return true
		 * only when we find another connection using same database.
		 */
		if (tdsentry->st_procpid > 0 &&
			tdsentry->client_pid != 0 && tdsentry->database_id == db_id)
		{
			if (ignore_current_connection && number_of_connections == 0)
				number_of_connections++;
			else
				return true;
		}
	}
	return false;
}

bool
tds_stat_get_activity(Datum *values, bool *nulls, int len, int pid, int curr_backend)
{
	LocalTdsStatus *local_tdsentry;
	TdsStatus  *tdsentry;
	int			tsql_isolation_level;

	MemSet(values, 0, len);
	MemSet(nulls, false, len);

	/* Get the next one in the list */
	local_tdsentry = tdsstat_fetch_stat_local_tdsentry(curr_backend);
	if (!local_tdsentry)
		return false;

	tdsentry = &local_tdsentry->tdsStatus;

	/* If looking for specific PID, ignore all the others */
	if (pid != -1 && tdsentry->st_procpid != pid)
		return false;

	values[0] = Int32GetDatum(tdsentry->st_procpid);

	/* TDS Client Version must be valid */
	if (tdsentry->client_version != 0)
		values[1] = Int32GetDatum(tdsentry->client_version);

	/* Library name must be valid */
	if (tdsentry->st_library_name)
		values[2] = CStringGetTextDatum(tdsentry->st_library_name);
	else
		nulls[2] = true;

	/* Language must be valid */
	if (tdsentry->st_language)
		values[3] = CStringGetTextDatum(tdsentry->st_language);
	else
		nulls[3] = true;

	values[4] = BoolGetDatum(tdsentry->quoted_identifier);
	values[5] = BoolGetDatum(tdsentry->arithabort);
	values[6] = BoolGetDatum(tdsentry->ansi_null_dflt_on);
	values[7] = BoolGetDatum(tdsentry->ansi_defaults);
	values[8] = BoolGetDatum(tdsentry->ansi_warnings);
	values[9] = BoolGetDatum(tdsentry->ansi_padding);
	values[10] = BoolGetDatum(tdsentry->ansi_nulls);
	values[11] = BoolGetDatum(tdsentry->concat_null_yields_null);
	values[12] = Int32GetDatum(tdsentry->textsize);
	values[13] = Int32GetDatum(tdsentry->datefirst);
	values[14] = Int32GetDatum(tdsentry->lock_timeout);

	/*
	 * In postgres, transaction isolation level mapping is as follows:
	 * XACT_READ_UNCOMMITTED	0 XACT_READ_COMMITTED		1
	 * XACT_REPEATABLE_READ		2 XACT_SERIALIZABLE		3
	 *
	 * In T-SQL, transaction isolation level mapping is as follows:
	 * XACT_READ_UNCOMMITTED	1 XACT_READ_COMMITTED		2
	 * XACT_REPEATABLE_READ		3 XACT_SERIALIZABLE		4 XACT_SNAPSHOT		5
	 *
	 * So adding 1 while storing value in tuples with one exception. We are
	 * treating T-SQL SNAPSHOT isolation as REPEATABLE_READ in Babelfish so
	 * handling this case separately. We don't support T-SQL REPEATABLE_READ
	 * isolation level in Babelfish yet so this logic holds for now. Once we
	 * support REPEATABLE_READ isolation level in Babelfish, we need to figure
	 * out if XACT_REPEATABLE_READ PG isolation level represents T-SQL
	 * SNAPSHOT or REPEATABLE_READ.
	 */
	if (tdsentry->transaction_isolation == XACT_REPEATABLE_READ)
		tsql_isolation_level = XACT_SNAPSHOT;
	else
		tsql_isolation_level = tdsentry->transaction_isolation + 1;

	values[15] = Int16GetDatum(tsql_isolation_level);

	/* Client PID must be valid */
	if (tdsentry->client_pid != 0)
		values[16] = Int32GetDatum(tdsentry->client_pid);
	else
		nulls[16] = true;

	values[17] = Int64GetDatum(tdsentry->rowcount);
	values[18] = Int32GetDatum(tdsentry->error);
	values[19] = Int32GetDatum(tdsentry->trancount);

	/*
	 * ValidateLoginRequest() already checks if protocol version is valid or
	 * not
	 */
	values[20] = Int32GetDatum(tdsentry->protocol_version);

	/* ValidateLoginRequest() already checks if packet size is valid or not */
	values[21] = Int32GetDatum(tdsentry->packet_size);

	values[22] = CStringGetTextDatum(tdsentry->encrypt_option == 1 ? "TRUE" : "FALSE");
	values[23] = Int16GetDatum(tdsentry->database_id);

	/* Host name must be valid */
	if (len > 24)
	{
		if (tdsentry->st_host_name)
			values[24] = CStringGetTextDatum(tdsentry->st_host_name);
		else
			nulls[24] = true;
	}

	if (len > 25)
	{
		if (tdsentry->st_context_info)
			values[25] = PointerGetDatum(cstring_to_text_with_len(tdsentry->st_context_info, CONTEXTINFOLEN));
		else
			nulls[25] = true;
	}

	return true;
}

void
TdsSetGucStatVariable(const char *guc, bool boolVal, const char *strVal, int intVal)
{
	volatile TdsStatus *vtdsentry = MyTdsStatusEntry;
	int			len;

	PGSTAT_BEGIN_WRITE_ACTIVITY(vtdsentry);

	if (strcmp(guc, "babelfishpg_tsql.language") == 0)
	{
		len = pg_mbcliplen(strVal, strlen(strVal), LANGDATALEN - 1);
		memcpy((char *) vtdsentry->st_language, strVal, len);
		vtdsentry->st_language[len] = '\0';
	}
	else if (strcmp(guc, "babelfishpg_tsql.quoted_identifier") == 0)
		vtdsentry->quoted_identifier = boolVal;
	else if (strcmp(guc, "babelfishpg_tsql.arithabort") == 0)
		vtdsentry->arithabort = boolVal;
	else if (strcmp(guc, "babelfishpg_tsql.ansi_null_dflt_on") == 0)
		vtdsentry->ansi_null_dflt_on = boolVal;
	else if (strcmp(guc, "babelfishpg_tsql.ansi_defaults") == 0)
		vtdsentry->ansi_defaults = boolVal;
	else if (strcmp(guc, "babelfishpg_tsql.ansi_warnings") == 0)
		vtdsentry->ansi_warnings = boolVal;
	else if (strcmp(guc, "babelfishpg_tsql.ansi_padding") == 0)
		vtdsentry->ansi_padding = boolVal;
	else if (strcmp(guc, "babelfishpg_tsql.ansi_nulls") == 0)
		vtdsentry->ansi_nulls = boolVal;
	else if (strcmp(guc, "babelfishpg_tsql.concat_null_yields_null") == 0)
		vtdsentry->concat_null_yields_null = boolVal;
	else if (strcmp(guc, "babelfishpg_tsql.textsize") == 0)
		vtdsentry->textsize = intVal;
	else if (strcmp(guc, "babelfishpg_tsql.datefirst") == 0)
		vtdsentry->datefirst = intVal;
	else if (strcmp(guc, "lock_timeout") == 0)
		vtdsentry->lock_timeout = intVal;
	else if (strcmp(guc, "default_transaction_isolation") == 0)
		vtdsentry->transaction_isolation = intVal;

	PGSTAT_END_WRITE_ACTIVITY(vtdsentry);
}

void
TdsSetAtAtStatVariable(TdsAtAtVarType at_at_var, int intVal, uint64 bigintVal)
{
	volatile TdsStatus *vtdsentry = MyTdsStatusEntry;

	PGSTAT_BEGIN_WRITE_ACTIVITY(vtdsentry);

  switch (at_at_var)
  {
    case RCOUNT_TYPE:
      vtdsentry->rowcount = bigintVal;
      break;
    case ERR_TYPE:
      vtdsentry->error = intVal;
      break;
    case TRANCOUNT_TYPE:
      vtdsentry->trancount = intVal;
      break;
    default:
      break;
  }

	PGSTAT_END_WRITE_ACTIVITY(vtdsentry);
}

void
TdsSetDatabaseStatVariable(int16 db_id)
{
	volatile TdsStatus *vtdsentry = MyTdsStatusEntry;

	PGSTAT_BEGIN_WRITE_ACTIVITY(vtdsentry);

	vtdsentry->database_id = db_id;

	PGSTAT_END_WRITE_ACTIVITY(vtdsentry);
}

/*
 * For table-valued parameter that's not handled by pltsql, we set up a hook so
 * that we can look up a TVP's underlying table.
 */
static Oid
tvp_lookup(const char *relname, Oid relnamespace)
{
	Oid			relid;
	ListCell   *lc;

	if (prev_relname_lookup_hook)
		relid = (*prev_relname_lookup_hook) (relname, relnamespace);
	else
		relid = get_relname_relid(relname, relnamespace);

	/*
	 * If we find a TVP whose name matches relname, return its underlying
	 * table's relid. Otherwise, just return relname's relid.
	 */
	foreach(lc, tvp_lookup_list)
	{
		TvpLookupItem *item = (TvpLookupItem *) lfirst(lc);

		if (strcmp(relname, item->name) == 0)
		{
			if (OidIsValid(item->tableRelid))
				return item->tableRelid;
			else
				return get_relname_relid(item->tableName, relnamespace);
		}
	}

	return relid;
}

void
invalidate_stat_table(void)
{
	isLocalStatusTableValid = false;
}

char *
get_tds_host_name(void)
{
	return MyTdsHostName;
}

uint32_t
get_tds_client_pid(void)
{
	return MyTdsClientPid;
}

Datum
get_tds_context_info(void)
{
	if (MyTdsContextInfo)
		PG_RETURN_TEXT_P(cstring_to_text_with_len(MyTdsContextInfo, CONTEXTINFOLEN));
	else
		PG_RETURN_VOID();
}

void
set_tds_context_info(bytea *context_info)
{
	int32		len;
	char	   *data;

	volatile TdsStatus *vtdsentry = MyTdsStatusEntry;

	PGSTAT_BEGIN_WRITE_ACTIVITY(vtdsentry);

	len = VARSIZE(context_info) - VARHDRSZ;
	data = VARDATA(context_info);
	memset(vtdsentry->st_context_info, 0, CONTEXTINFOLEN);
	memcpy(vtdsentry->st_context_info, data, len);

	PGSTAT_END_WRITE_ACTIVITY(vtdsentry);

	if (!MyTdsContextInfo)
		MyTdsContextInfo = vtdsentry->st_context_info;
}
