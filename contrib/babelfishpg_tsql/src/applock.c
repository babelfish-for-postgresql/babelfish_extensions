/*-------------------------------------------------------------------------
 *
 * applock.c
 *   Application Lock Functionality for Babelfish
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "access/xact.h"
#include "executor/spi.h"
#include "fmgr.h"
#include "miscadmin.h"
#include "parser/parser.h"
#include "pltsql.h"
#include "storage/lmgr.h"
#include "utils/builtins.h"
#include "utils/guc.h"
#include "utils/timeout.h"
#include "datatypes.h"


PG_FUNCTION_INFO_V1(sp_getapplock_function);
PG_FUNCTION_INFO_V1(sp_releaseapplock_function);
PG_FUNCTION_INFO_V1(APPLOCK_MODE);
PG_FUNCTION_INFO_V1(APPLOCK_TEST);

/* 
 * Applock local and global hashmaps. The local one keeps track of applock 
 * that the current session owns. The global one resolves hash conflict if
 * two different lock resource name are hashed to the same integer key.
 * Both uses the same cache entry structure for convenience.
 */
static HTAB * appLockCacheLocal = NULL;
static HTAB * appLockCacheGlobal = NULL;

/* Max length of applock resource name string (including the ending '\0') */
#define APPLOCK_MAX_RESOURCE_LENGTH 256
/* 
 * Max number of retries to search for usable key when hash collision happens.
 * The chance of multiple strings being hashed to the same key is roughly
 * (1/2^63)*(#_of_strings-1). So a small APPLOCK_MAX_TRY_SEARCH_KEY should be
 * enough. Also, because we have to scan all the possible candidate keys when 
 * looking for a usable key (see ApplockGetUsableKey()), a small 
 * APPLOCK_MAX_TRY_SEARCH_KEY is preferred too.
 */
#define APPLOCK_MAX_TRY_SEARCH_KEY 5

typedef struct applockcacheent
{
    int64       key;			/* (hashed) key integer of the lock */
    char        resource[APPLOCK_MAX_RESOURCE_LENGTH];	/* Resource name string of the lock */
    uint32_t    refcount;		/* Currently how many times this lock is being held. 
	                               Note the count may be different locally/globally.*/
    slist_head  mode_head;		/* lock mode list, keeping track of all lock modes 
	                               currently being held with this lock resource .
	                               Only used in local cache. */ 
    bool        is_session;		/* If it's session lock or transaction lock */
} AppLockCacheEnt;

/* Linked-list struct for keeping track of the lockmodes one owns */
typedef struct
{
	slist_node	sn;
	short		mode;
} AppLockModeNode;

/*
 * Applock modes
 * 
 * Table of compatibility ('Yes' indicates compatible):
 *
 * mode                  IS    S    U    IX    X
 * Intent shared (IS)    Yes   Yes  Yes  Yes   No
 * Shared (S)            Yes   Yes  Yes  No    No
 * Update (U)            Yes   Yes  No   No    No
 * Intent exclusive (IX) Yes   No   No   Yes   No
 * Exclusive (X)         No    No   No   No    No
 *
 * Note that APPLOCKMODE_SHAREDINTENTEXCLUSIVE and
 * APPLOCKMODE_UPDATEINTENTEXCLUSIVE are special lockmodes that
 * are NOT acquirable by sp_getapplock but can be returned by
 * APPLOCK_MODE(). See comments for APPLOCK_MODE().
 */
typedef enum {
	APPLOCKMODE_NOLOCK,
	APPLOCKMODE_INTENTEXCLUSIVE,
	APPLOCKMODE_INTENTSHARED,
	APPLOCKMODE_SHARED,
	APPLOCKMODE_UPDATE,
	APPLOCKMODE_EXCLUSIVE,
	APPLOCKMODE_SHAREDINTENTEXCLUSIVE,
	APPLOCKMODE_UPDATEINTENTEXCLUSIVE
} Applock_All_Lockmode;

/*
 * Strings for Applock modes. The order MUST match the mode enum in
 * Applock_All_Lockmode.
 */
static const char *AppLockModeStrings[] =
{
	"NoLock",
	"IntentExclusive",
	"IntentShared",
	"Shared",
	"Update",
	"Exclusive",
	"SharedIntentExclusive",
	"UpdateIntentExclusive"
};

static void ApplockPrintMessage(const char *fmt, ...) {
	char msg[128];
	va_list args;

	va_start(args, fmt);
	vsprintf(msg, fmt, args);

	ereport(WARNING, errmsg_internal("%s", msg));
	if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->send_info)
		((*pltsql_protocol_plugin_ptr)->send_info) (0, 1, 0, msg, 0);

	va_end (args);
}

/* Helper macro to validate and get a string argument */
#define ApplockGetStringArg(argnum, OUT)		\
    do {					\
		if (fcinfo->args[argnum].isnull)  {  \
			ApplockPrintMessage("parameter cannot be null"); \
			return -999;  \
		}  \
		OUT = text_to_cstring(DatumGetVarCharPP(PG_GETARG_DATUM(argnum)));  \
    } while (0);

#define SET_LOCKTAG_APPLOCK(locktag,id1,id2,id3,id4) \
	((locktag).locktag_field1 = (id1), \
	 (locktag).locktag_field2 = (id2), \
	 (locktag).locktag_field3 = (id3), \
	 (locktag).locktag_field4 = (id4), \
	 (locktag).locktag_type = LOCKTAG_ADVISORY, \
	 (locktag).locktag_lockmethodid = APPLOCK_LOCKMETHOD)

/* 
 * PG advisory lock uses 0 and 1 for field4 (see comments for SET_LOCKTAG_INT64). 
 * We use 2 to avoid conflict with it.
 */
#define ApplockSetLocktag(tag, key64) \
	SET_LOCKTAG_APPLOCK(tag, \
						 MyDatabaseId, \
						 (uint32) ((key64) >> 32), \
						 (uint32) (key64), \
						 2)

#define AppLockCacheInsert(ID, ENTRY)  \
    do { \
        bool found; \
        (ENTRY) = (AppLockCacheEnt*) hash_search(appLockCacheLocal, \
                                                    (void *) &(ID), \
                                                    HASH_ENTER, &found); \
	if (!found) {  \
		(ENTRY)->refcount = 0;  \
		strcpy((ENTRY)->resource, "");  \
		slist_init(&(ENTRY)->mode_head);  \
	}  \
} while(0) 

#define AppLockCacheLookup(ID, ENTRY) \
    do { \
        (ENTRY) = (AppLockCacheEnt *) hash_search(appLockCacheLocal, \
                                                    (void *) &(ID), \
                                                    HASH_FIND, NULL); \
} while(0)

#define AppLockCacheDelete(ID) \
    do { \
        AppLockCacheEnt *hentry; \
        hentry = (AppLockCacheEnt *) hash_search(appLockCacheLocal, \
                                                    (void *) &(ID), \
                                                    HASH_REMOVE, NULL); \
        if (hentry == NULL) \
		    ApplockPrintMessage("failed to delete app lock entry for key %ld", ID); \
} while(0)

#define ApplockSetLockTimeout(val) \
	do {  \
		if (timeout != -99) {  \
			char timeout_str[16];  \
			sprintf(timeout_str, "%d", val);  \
			SetConfigOption("lock_timeout", timeout_str,  \
							PGC_USERSET, PGC_S_OVERRIDE);  \
		}  \
} while (0);

#define ApplockCheckParallelMode(suppress_warning)		\
    do {					\
	if (IsInParallelMode()) {		\
		if (!suppress_warning)  \
			ApplockPrintMessage("cannot use advisory locks during a parallel operation"); \
		return -999;  \
	}      \
    } while (0);

#define ApplockCheckLockmode(IN, OUT, suppress_warning)				\
    do {							\
	if (pg_strcasecmp(IN, "IntentShared") == 0)		\
		(OUT) = APPLOCKMODE_INTENTSHARED;			\
	else if (pg_strcasecmp(IN, "Shared") == 0)		\
		(OUT) = APPLOCKMODE_SHARED;				\
	else if (pg_strcasecmp(IN, "Update") == 0)		\
		(OUT) = APPLOCKMODE_UPDATE;				\
	else if (pg_strcasecmp(IN, "IntentExclusive") == 0)	\
		(OUT) = APPLOCKMODE_INTENTEXCLUSIVE;		\
	else if (pg_strcasecmp(IN, "Exclusive") == 0)		\
		(OUT) = APPLOCKMODE_EXCLUSIVE;			\
	else {						\
		if (!suppress_warning) \
			ApplockPrintMessage("Option \'%s\' not recognized for \'@LockMode\' parameter", IN); \
		return -999;  \
	}      \
    } while (0)

#define ApplockCheckLockowner(IN, OUT, suppress_warning)		\
    do {						\
	if (pg_strcasecmp(IN, "Session") == 0)	\
		(OUT) = true;			\
	else if (pg_strcasecmp(IN, "Transaction") == 0)	\
		(OUT) = false;			\
	else {					\
		if (!suppress_warning)  \
            ApplockPrintMessage("Option \'%s\' not recognized for \'@LockOwner\' parameter", IN);	\
		return -999;  \
	}      \
    } while (0)

/* 
 * We accept any input of dbprincipal until we decide otherwise.
 * Also a placeholder to escape unused variable error for dbprincipal.
 */
#define ApplockCheckDbPrincipal(IN)	\
    do {				\
	if (pg_strcasecmp((IN), "dbo"))	\
	    ;				\
    } while (0);

static void ApplockRemoveCache(bool release_session);

/* 
 * Simple consistent hashing function to convert a string to an int.
 * We'll avoid return non-negative values because that will be used for errors.
 * The chance of 2 strings colliding with the same key is about 1/2^63.
 * See https://cp-algorithms.com/string/string-hashing.html
 */
static int64
applock_simple_hash(char *str)
{
	const int p = 31;
	const int64 m = INT64_MAX;
	uint64 hash_value = 0;
	int64 p_pow = 1;
	char c;

	c = *str;
	while (c) {
		hash_value = (hash_value + (c - 'a' + 1) * p_pow) % m;
		p_pow = (p_pow * p) % m;
		c = *++str;
	}
    return hash_value;
}

/* 
 * Get PG Lock mode for corresponding Applock mode. 
 * See AppLockConflicts[] defined in backend/storage/lmgr/lock.c.
 */
static short getPGLockMode(short applockmode)
{
	short mode = 0;
	
	if (applockmode == APPLOCKMODE_EXCLUSIVE)
		mode = ExclusiveLock;
	else if (applockmode == APPLOCKMODE_SHARED)
		mode = ShareLock;
	else if (applockmode == APPLOCKMODE_UPDATE)
		mode = ShareUpdateExclusiveLock;
	else if (applockmode == APPLOCKMODE_INTENTSHARED)
		mode = RowShareLock;
	else if (applockmode == APPLOCKMODE_INTENTEXCLUSIVE)
		mode = RowExclusiveLock;
	else
		ApplockPrintMessage("wrong application lock mode %d", applockmode);

	return mode;
}

/* Initialize both local and global hashmaps */
static void initApplockCache()
{
	HASHCTL         ctl;

	/* Local cache */
	MemSet(&ctl, 0, sizeof(ctl));
	ctl.keysize = sizeof(int64);
	ctl.entrysize = sizeof(AppLockCacheEnt);
	appLockCacheLocal = hash_create("Applock Cache", 16, 
				&ctl, HASH_ELEM | HASH_BLOBS);

	/* Global cache */
	LWLockAcquire(AddinShmemInitLock, LW_EXCLUSIVE);
	MemSet(&ctl, 0, sizeof(ctl));
	ctl.keysize = sizeof(int64);
	ctl.entrysize = sizeof(AppLockCacheEnt);
	appLockCacheGlobal = (HTAB*)ShmemInitHash("Applock",
										/*table size*/ 32,
										/*max table size*/ 32,
										&ctl,
										HASH_ELEM);
	LWLockRelease(AddinShmemInitLock);

	/* 
	 * Init this function handler to be called when PG implicitly
	 * release locks at the end of transaction/session. 
	 */
	applock_release_func_handler = (void*) ApplockRemoveCache;
}

/* Search a key corresponding to a resource name in local hashmap. */
static int64 AppLockSearchKeyLocal(char *resource)
{
	AppLockCacheEnt *entry;
	int64 key;
	int try_search = 0;

	key = applock_simple_hash(resource);
	while (try_search++ < APPLOCK_MAX_TRY_SEARCH_KEY) {
		entry = (AppLockCacheEnt*) hash_search(appLockCacheLocal,
                                                    (void *) &key,
                                                    HASH_FIND, NULL);
		if (entry && strcmp(entry->resource, resource) == 0)
			return key;
		/* be mindful of overflow */
		key = (key % INT64_MAX) + 1;
	}

	return -1;
}

/* Search a key corresponding to a resource name in global hashmap. */
static int64 AppLockSearchKeyGlobal(char *resource)
{
	AppLockCacheEnt *entry;
	int64 key;
	int try_search = 0;

	LWLockAcquire(TsqlApplockSyncLock, LW_SHARED);

	key = applock_simple_hash(resource);
	while (try_search++ < APPLOCK_MAX_TRY_SEARCH_KEY) {
		entry = (AppLockCacheEnt*) hash_search(appLockCacheGlobal,
                                                    (void *) &key,
                                                    HASH_FIND, NULL);
		if (entry && strcmp(entry->resource, resource) == 0) {
			LWLockRelease(TsqlApplockSyncLock);
			return key;
		}
		/* be mindful of overflow */
		key = (key % INT64_MAX) + 1;
	}

	LWLockRelease(TsqlApplockSyncLock);
	return -1;
}

/* 
 * Un-reference an entry in the appLockCacheGlobal. 
 * Delete it if its refcount is reduced to 0.
 */
static void ApplockUnrefGlobalCache(int64 key)
{
	AppLockCacheEnt *entry;

	LWLockAcquire(TsqlApplockSyncLock, LW_EXCLUSIVE);
    entry = (AppLockCacheEnt *) hash_search(appLockCacheGlobal,
                                                (void *) &key,
                                                HASH_FIND, NULL);
	if (entry && --entry->refcount == 0) {
		hash_search(appLockCacheGlobal,
											(void *) &key,
											HASH_REMOVE, NULL);
		strcpy(entry->resource, "");
	}
	LWLockRelease(TsqlApplockSyncLock);
}

/* 
 * Get a usable key from the resource string that doesn't collide 
 * with existing ones. 
 * Return a usable key (non-negative integer) if found, or -1 if couldn't.
 */
static int64 ApplockGetUsableKey(char *resource)
{
	int64			key, usable_key;
    bool			found;
	AppLockCacheEnt *entry;
	int				try_search = 0;

	/* Firstly, try search in the global cache to see if it's available already*/
	if ((key = AppLockSearchKeyGlobal(resource)) != -1) {
		LWLockAcquire(TsqlApplockSyncLock, LW_EXCLUSIVE);
		entry = (AppLockCacheEnt*) hash_search(appLockCacheGlobal,
													(void *) &key,
													HASH_ENTER, &found);
		/* Someone might've just deleted it. So check it before modify.*/
		if (found) {
			++entry->refcount;
			LWLockRelease(TsqlApplockSyncLock);
			return key;
		}
		LWLockRelease(TsqlApplockSyncLock);
	}

	/* Otherwise, try generating a new key for this resource */

	/* convert resource string to key integer */
	key = applock_simple_hash(resource);
	usable_key = -1;

	LWLockAcquire(TsqlApplockSyncLock, LW_EXCLUSIVE);

	/* 
	 * Some different resource name may have been hashed to the same key. 
	 * In that case, we keep incrementing key until we find a usable one. 
	 *
	 * NB: it's not very meaningful to try too many times because if it
	 * turns out that a couple of random keys have somehow all been used,
	 * we probably have a bug somewhere so it's better to error out.
	 * Also, we have to search all the possible candidate keys for the resource
	 * to make sure someone else did not just insert the same resource with 
	 * some key unknown to the caller.
	 */
	while (try_search++ < APPLOCK_MAX_TRY_SEARCH_KEY) {
		entry = (AppLockCacheEnt*) hash_search(appLockCacheGlobal,
                                                    (void *) &key,
                                                    HASH_FIND, NULL);
		/* Someone might've just inserted an entry for this resource. */
		if (entry && strcmp(entry->resource, resource) == 0) {
			entry->refcount++;
			LWLockRelease(TsqlApplockSyncLock);
			return key;
		}
		/* Key usable, record it if not done so. */
		if (!entry && usable_key == -1)
			usable_key = key;

		/* Keep searching, be mindful of overflow */
		key = (key % INT64_MAX) + 1;
	}

	if (usable_key != -1) {
		entry = (AppLockCacheEnt*) hash_search(appLockCacheGlobal,
													(void *) &usable_key,
													HASH_ENTER, &found);
		/* It must be non-existing at this point. */
		Assert(!found);

		entry->key = usable_key;
		entry->refcount = 1;
		strcpy(entry->resource, resource);
	}

	LWLockRelease(TsqlApplockSyncLock);
	return usable_key;
}

/*
 * Common function for sp_getapplock_function() and APPLOCK_TEST().
 *
 * Returns:
 * 0: lock acquired successfully.
 * -999: lock request attempt failed.
 * 1: lock acquired successfully but after waiting.
 * -1: timed out.
 * -2: lock request canceled.
 * -3: lock request was chosen as a deadlock victim.
 */
static int _sp_getapplock_internal (char *resource, char *lockmode, 
		                            char *lockowner, int32_t timeout, 
								    char *dbprincipal, bool suppress_warning)
{
	int32_t		cur_timeout;
	int64       key;
	LOCKTAG     tag;
	short		mode;
	bool		is_session;
	bool		lock_timeout_occurred = false;
	bool		no_wait = false;
	AppLockCacheEnt	*entry;
	volatile TimestampTz	start_time;
	AppLockModeNode *node;

	/* a few sanity checks */
	ApplockCheckParallelMode(suppress_warning);
	ApplockCheckLockmode(lockmode, mode, suppress_warning);
	ApplockCheckLockowner(lockowner, is_session, suppress_warning);
	ApplockCheckDbPrincipal(dbprincipal);

	if (pg_strcasecmp(lockowner, "Transaction") == 0 && !IsTransactionBlockActive())
	{
		if (!suppress_warning)
			ApplockPrintMessage("You attempted to acquire a transactional application lock without an active transaction.");
		return -999;
	}
	if ((key = ApplockGetUsableKey(resource)) < 0)
	{
		if (!suppress_warning)
			ApplockPrintMessage("could not find usable key for lock resource %s.",resource);
		return -999;
	}

	ApplockSetLocktag(tag, key);

	/* 
	 * Setting timeout if timeout is not the meaningless default value (-99).
	 * Note some special cases in timeout: in TSQL -1 means wait forever
	 * and 0 means do not wait at all. But in PG, 0 means wait forever and
	 * -1 is meaningless. To make PG not wait at all, we need to pass
	 * no_wait=true to LockAcquire().
	 */
	if (timeout == 0)
		no_wait = true;
	timeout = (timeout == -1 ? 0 : timeout);
	cur_timeout = atoi(GetConfigOption("lock_timeout", false, false));
	ApplockSetLockTimeout(timeout);
	
	start_time = GetCurrentTimestamp();
	/* finally, attempt to acquire the lock.*/
	PG_TRY();
	{
		/* If lock is unavailable, throw an error to let the catch block deal with it */
		if (LockAcquire(&tag, getPGLockMode(mode), is_session, no_wait) == LOCKACQUIRE_NOT_AVAIL)
			ereport(ERROR,
					(errcode(ERRCODE_LOCK_NOT_AVAILABLE),
					errmsg("Applock resource \'%s\' unavailable", resource)));
	}
	PG_CATCH();
	{
		/* 
		 * Exceptions during lock acquiring. This could be timeout, deadlock
		 * or other failures. Note that we have to return something here
		 * instead of throwing the errors out because otherwise the caller 
		 * won't be able to get the return code as defined in TSQL standard. 
		 * Therefore, we unfortunately can't print PG's nice deadlock report.
		 */

		/* Un-referencing the global cache entry associated with this key. */
		ApplockUnrefGlobalCache(key);

		/*
		 * Did timeout occur?
		 *
		 * NB: ERRCODE_LOCK_NOT_AVAILABLE is not just for timeout, so we
		 * have to check the elapse time to really make sure.
		 * Also, although get_timeout_indicator(LOCK_TIMEOUT, if_reset) can
		 * check the same but when timeout happens, ProcessInterrupts() always 
		 * reset the indicator, thus we have to use another way.
		 */
		lock_timeout_occurred = timeout >= 0 && 
									get_timeout_finish_time(LOCK_TIMEOUT) 
										- start_time > (int64)timeout * 1e3 && 
									geterrcode() == ERRCODE_LOCK_NOT_AVAILABLE;

		/* reset timeout back */
		ApplockSetLockTimeout(cur_timeout);

		if (lock_timeout_occurred)
		{
			if (!suppress_warning)
				ApplockPrintMessage("Applock request for \'%s\' timed out", resource);
			return -1;
		}
		/* Not timed out, but it's still due to lock unavailable. */
		else if (geterrcode() == ERRCODE_LOCK_NOT_AVAILABLE)
		{
			if (!suppress_warning)
				ApplockPrintMessage("Applock resource \'%s\' unavailable", resource);
			return -999;
		}
		/* Did deadlock occur? */
		else if (geterrcode() == ERRCODE_T_R_DEADLOCK_DETECTED)
		{
			if (!suppress_warning)
				ApplockPrintMessage("Deadlock detected in applock request for \'%s\' ", resource);
			return -3;
		}
		/* 
		 * Regard all other exceptions as lock request being canceled (e.g.
		 * the calling query was interrupted and terminated.)
		 */
		else
		{
			if (!suppress_warning)
			    ApplockPrintMessage("Applock request for \'%s\' is canceled", resource);
			return -2;
		}
	}
	PG_END_TRY();

	ApplockSetLockTimeout(cur_timeout);
	
	/* lock aquired, we can insert or update the local cache entry now. */
	AppLockCacheInsert(key, entry);
	strcpy(entry->resource, resource);
	entry->refcount++;
	node = malloc(sizeof(AppLockModeNode));
	node->mode = mode;
	slist_push_head(&entry->mode_head, &node->sn);
	entry->is_session = is_session;

	return 0;
}

/*
 * Common function for sp_releaseapplock_function() and APPLOCK_TEST().
 *
 * Returns:
 * 0: lock released successfully.
 * -999: lock release attempt failed.
 */
static int _sp_releaseapplock_internal(char *resource, char *lockowner,
                                      char *dbprincipal, bool suppress_warning)
{
	int64           key;
	LOCKTAG         tag;
	short		mode;
	bool		is_session;
	AppLockCacheEnt	*entry;
	AppLockModeNode *node;

	/* a few sanity checks */
	ApplockCheckParallelMode(suppress_warning);
	ApplockCheckLockowner(lockowner, is_session, suppress_warning);
	ApplockCheckDbPrincipal(dbprincipal);

	/* Search in the global cache for the key. */
	if ((key = AppLockSearchKeyGlobal(resource)) == -1) {
		if (!suppress_warning)
			ApplockPrintMessage("No lock resource \'%s\' acquired before.", resource);
		LWLockRelease(TsqlApplockSyncLock);
		return -999;
	}

	/* verify the key in the local cache, and if the lock owner matches */
	AppLockCacheLookup(key, entry);
	if (entry == NULL) {
		if (!suppress_warning)
			ApplockPrintMessage("No lock resource \'%s\' acquired before.", resource);
		return -999;
	}
	if (is_session != entry->is_session) {
		if (!suppress_warning)
			ApplockPrintMessage("Wrong LockOwner for lock resource \'%s\', it is a %s lock.", 
							resource, entry->is_session ? "Session" : "Transaction");
		return -999;
	}

	/* Set tag according to key. */
	ApplockSetLocktag(tag, key);

	/* get the same lock mode as recorded */
	mode = ((AppLockModeNode*)entry->mode_head.head.next)->mode;

	if (!LockRelease(&tag, getPGLockMode(mode), is_session))
		return -999;

	/* Un-referencing the local cache entry and delete it if needed. */
	node = (AppLockModeNode*)slist_pop_head_node((slist_head*)&entry->mode_head);
	free(node);
	if (--entry->refcount == 0)
		AppLockCacheDelete(key);

	/* Un-referencing the global cache entry associated with this key. */
	ApplockUnrefGlobalCache(key);

	return 0;
}

/*
 * Get application lock function, to be called by procedure sp_getapplock
 */
Datum
sp_getapplock_function(PG_FUNCTION_ARGS)
{
	char 		*resource, *lockmode, *lockowner, *dbprincipal;
	int32_t		timeout;
	int			ret;

	/* Init applock hash table if we haven't done so. */
	if (!appLockCacheLocal)
		initApplockCache();

	ApplockGetStringArg(0, resource);
	ApplockGetStringArg(1, lockmode);
	ApplockGetStringArg(2, lockowner);
	timeout = DatumGetInt32(PG_GETARG_DATUM(3));
	ApplockGetStringArg(4, dbprincipal);

	ret = _sp_getapplock_internal(resource, lockmode, lockowner, timeout, dbprincipal, false);

	PG_RETURN_INT32(ret);
}

/*
 * Release application lock function, to be called by procedure sp_releaseapplock
 */
Datum
sp_releaseapplock_function(PG_FUNCTION_ARGS)
{
	char 		*resource, *lockowner, *dbprincipal;
	int			ret;

	/* Init applock hash table if we haven't done so. */
	if (!appLockCacheLocal)
		initApplockCache();

	ApplockGetStringArg(0, resource);
	ApplockGetStringArg(1, lockowner);
	ApplockGetStringArg(2, dbprincipal);

	ret = _sp_releaseapplock_internal(resource, lockowner, dbprincipal, false);

	PG_RETURN_INT32(ret);
}

/*
 * Get lockmode of the applock the caller holds and return the mode in string.
 *
 * NB: when there are more than one lock modes, the mode to return is the 'highest' 
 * lockmode among them. The main order is: from lowest (most relaxed) to 
 * highest (most strict): IntentShared < Shared < Update < Exclusive. 
 * A special case is IntentExclusive which if is held, there could be 3 
 * different return modes depending on what's the other mode being held:
 *   1. IntentExclusive + IntentExclusive = IntentExclusive
 *   2. IntentExclusive + IntentShared = SharedIntentExclusive
 *   3. IntentExclusive + Update = UpdateIntentExclusive
 */
Datum
APPLOCK_MODE(PG_FUNCTION_ARGS)
{
	char				*resource;
	short				high_mode, ret_mode;
	AppLockCacheEnt		*entry;
	int64				key;
	slist_iter			iter;
	bool				has_intent_exc;

	/* Init applock hash table if not yet done. */
	if (!appLockCacheLocal)
		initApplockCache();

	ApplockGetStringArg(1, resource);

	/* If we don't own the lock, just return NoLock */
	if ((key = AppLockSearchKeyLocal(resource)) < 0)
		PG_RETURN_VARCHAR_P(tsql_varchar_input(AppLockModeStrings[APPLOCKMODE_NOLOCK], 
												strlen(AppLockModeStrings[APPLOCKMODE_NOLOCK]), 
												-1));

	/* 
	 * Loop all the lock modes I've owned this resource with, and find the 
	 * correct string to return.
	 */
	AppLockCacheLookup(key, entry);
	high_mode = APPLOCKMODE_NOLOCK;
	has_intent_exc = false;
	slist_foreach(iter, &entry->mode_head) {
		AppLockModeNode *node = slist_container(AppLockModeNode, sn, iter.cur);
		if (node->mode == APPLOCKMODE_INTENTEXCLUSIVE)
			has_intent_exc = true;
		if (node->mode > high_mode)
			high_mode = node->mode;
	}
	if (has_intent_exc && high_mode == APPLOCKMODE_INTENTSHARED)
		ret_mode = APPLOCKMODE_SHAREDINTENTEXCLUSIVE;
	else if (has_intent_exc && high_mode == APPLOCKMODE_UPDATE)
		ret_mode = APPLOCKMODE_UPDATEINTENTEXCLUSIVE;
	else
		ret_mode = high_mode;

	PG_RETURN_VARCHAR_P(tsql_varchar_input(AppLockModeStrings[ret_mode], 
												strlen(AppLockModeStrings[ret_mode]), 
												-1));
}

/*
 * Test if an applock can be acquired. We took a simple approach where we 
 * try aqcuiring the lock and releasing it immediately.
 * The alternative is to remember all lockmodes and who owns them in the global 
 * hashmap, which entails too much of invasiveness and additional shared 
 * memory management.
 *
 * Returns:
 * 1 - the lock is grantable.
 * 0 - the lock is not grantable.
 */
Datum
APPLOCK_TEST(PG_FUNCTION_ARGS)
{
	char 		*resource, *lockmode, *lockowner, *dbprincipal;

	/* Init applock hash table if not yet done. */
	if (!appLockCacheLocal)
		initApplockCache();

	ApplockGetStringArg(0, dbprincipal);
	ApplockGetStringArg(1, resource);
	ApplockGetStringArg(2, lockmode);
	ApplockGetStringArg(3, lockowner);

	if (pg_strcasecmp(lockowner, "Transaction") == 0 && !IsTransactionBlockActive())
		ereport(ERROR,
				(errcode(ERRCODE_LOCK_NOT_AVAILABLE),
				errmsg("The statement or function must be executed in the context of a user transaction.")));

	/* 
	 * Pass the arguments and a time out of 0 (no wait) to the internal 
	 * getapplock function. Suppress the warning messages as they would be
	 * normal during testing a lock. If anything happened besides having 
	 * acquired the lock successfully, just return 0.
	 */
	if (_sp_getapplock_internal(resource, lockmode, lockowner, 0, dbprincipal, true) != 0)
		PG_RETURN_INT32(0);

	/* 
	 * PANIC: we've acquired the lock but can't release it for some reason.
	 * Unlike previous case, we need to print messages clearly indicating 
	 * such, so user is aware of the dangling lock, and error out to prevent
	 * any inconsistent state.
	 */
	if (_sp_releaseapplock_internal(resource, lockowner, dbprincipal, false) != 0)
		ereport(PANIC,
				(errcode(ERRCODE_INTERNAL_ERROR),
				errmsg("Lock acuiqred during APPLOCK_TEST for resource \'%s\'"
							"but couldn't release it.", 
						resource)));

	/* Lock can be acquired now. */
	PG_RETURN_INT32(1);
}

/* 
 * Function to be called by a hook in the backend.
 * Remove all hash entries for application locks of either transaction-only 
 * or transaction+session too.
 *
 * @release_session: if we remove session locks as well as transaction locks.
 */
static void
ApplockRemoveCache(bool release_session)
{
	HASH_SEQ_STATUS hash_seq;
	AppLockCacheEnt *entry;

	/* 
	 * If we are not using TSQL dialect or applock cache is not initialized,
	 * don't bother.
	 */
	if (sql_dialect != SQL_DIALECT_TSQL || !appLockCacheLocal)
		return;

	hash_seq_init(&hash_seq, appLockCacheLocal);
  
	while ((entry = hash_seq_search(&hash_seq)) != NULL)
	{
		int i;
		if (!release_session && entry->is_session)
			continue;

		/* unreferencing my entries in global hashmap */
		for (i = 0; i < entry->refcount; i++) 
			ApplockUnrefGlobalCache(entry->key);

		/* free allocated space, and the entry itself. */
		hash_search(appLockCacheLocal, (void *) &entry->key, HASH_REMOVE, NULL);
	}

	/* Release all applocks too. */
	LockReleaseAll(APPLOCK_LOCKMETHOD, release_session);
}
