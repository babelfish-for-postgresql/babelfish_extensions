#include "postgres.h"

#include "table_variable_mvcc.h"
#include "access/heapam.h"
#include "access/htup_details.h"
#include "access/multixact.h"
#include "access/subtrans.h"
#include "access/tableam.h"
#include "access/transam.h"
#include "access/xact.h"
#include "access/xlog.h"
#include "storage/bufmgr.h"
#include "storage/procarray.h"
#include "utils/builtins.h"
#include "utils/combocid.h"
#include "utils/memutils.h"
#include "utils/snapmgr.h"

#include "pltsql.h"

/*
* MVCC is different for Table Variables because Table Variables
* are not supposed to be sensitive to ROLLBACK. All DML operations
* are visible regardless of transaction performing the DML
* COMMITs or ABORTs. DML operation is not visible if and only if the
* the transaction performing the DML hit an error (ie: unexpected rollback)
* This map keeps track of failed transaction ids
*/
static HTAB *table_variable_failed_xid_map = NULL;

void
init_failed_transactions_map(void)
{
	HASHCTL ctl;

	if (table_variable_failed_xid_map)
		return;

	ctl.keysize = sizeof(TransactionId);
	ctl.entrysize = sizeof(TransactionId);
	ctl.hcxt = CacheMemoryContext;

	table_variable_failed_xid_map =
		hash_create("Failed Transactions Map",
					32,
					&ctl,
					HASH_ELEM | HASH_CONTEXT | HASH_BLOBS);
}

void
destroy_failed_transactions_map(void)
{
	if (!table_variable_failed_xid_map)
		return;

	hash_destroy(table_variable_failed_xid_map);
	table_variable_failed_xid_map = NULL;
}

void
add_failed_transaction(TransactionId xid)
{
	bool found = false;

	if (!table_variable_failed_xid_map)
		return;

	hash_search(table_variable_failed_xid_map, (void *) &xid, HASH_ENTER, &found);
}

bool
find_failed_transaction(TransactionId xid)
{
	bool found = false;

	Assert(table_variable_failed_xid_map);
	hash_search(table_variable_failed_xid_map, (void *) &xid, HASH_FIND, &found);
	return found;
}

static bool
TVHeapTupleSatisfiesAny(HeapTuple htup, Snapshot snapshot, Buffer buffer)
{
    return true;
}


/*
 * TVHeapTupleSatisfiesMVCC
 *
 * Table Variables are not sensitive to rollbacks and are meant for use on current session only.
 * This is equivalent to HeapTupleSatisfiesMVCC for regular tables.
 * However, it ignores XidInMVCCSnapshot() because it only cares whether the xid is committed or unexpectedly rolled back.
 * It still uses snapshot because it needs the command id in cases when xid is the current transaction.
 *
 * 1. A row is VISIBLE when:
 *  1.1. XMIN is NOT-IN-PROGRESS anymore (xmin already COMMITTED/ROllBACK)
 *    1.1.1. XMAX is NOT set (not yet DELETED/UPDATED)
 *    1.1.2. XMAX failed unexpectedly
 *    1.1.3. XMAX is set but (tuple->cid >= snapshotcid) to guard against the Halloween problem
 *  1.2. XMIN is current transaction
 *    1.2.1. INSERTed before current command (tuple->cid < snapshotcid) to guard the Halloween problem
 *    1.2.2. XMAX is NOT set (not yet DELETED/UPDATED)
 *    1.2.3. XMAX is set but (tuple->cid >= snapshotcid) to guard against the Halloween problem
 *    1.2.4. XMAX is set but by a previous subtransaction that failed unexpectedly
 *
 * 2. A row is INVISIBLE when:
 *  2.1. XMIN is NOT-IN-PROGRESS anymore
 *    2.1.1. XMIN Failed unexpectedly
 *    2.1.2. XMIN INVALID flag is set by previous scan operations
 *    2.1.3. updated/deleted by previous command in the same transaction
 *  2.2. XMIN is current transaction
 *    2.2.1. Inserted by current command. eg: INSERT INTO t SELECT * FROM t (tuple->cid >= snapshotcid)
 *    2.2.2. updated/deleted by previous command in the same transaction (tuple->cid < snapshotcid)
 *    2.2.3. INSERTed by a previous subtransaction that failed unexpectedly
 *  2.3. XMAX committed or clean Rollback
 *  2.4. XMAX is current transaction
 *    2.4.1. updated/deleted by a previous command (tuple->cid < snapshotcid)
 */
static bool
TVHeapTupleSatisfiesMVCC(HeapTuple htup, Snapshot snapshot, Buffer buffer)
{
    HeapTupleHeader tuple = htup->t_data;

    Assert(ItemPointerIsValid(&htup->t_self));
    Assert(htup->t_tableOid != InvalidOid);

    /* The HEAP_XMIN_COMMITTED hint bit is not yet set */
    if (!HeapTupleHeaderXminCommitted(tuple))
    {
        if (HeapTupleHeaderXminInvalid(tuple))      /* Case 2.1.2 in comment section */
            return false;

        else if (TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmin(tuple)))
        {
            if (HeapTupleHeaderGetCmin(tuple) >= snapshot->curcid)  /* Inserted after scan started. Case 2.2.1 in comment section */
                return false;

            /* There should not be any locking in table variable at this point */
            Assert(!HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask));
            Assert((tuple->t_infomask & HEAP_XMAX_IS_MULTI) == 0);

            if (tuple->t_infomask & HEAP_XMAX_INVALID)
                return true;

            /* xmax is current txn or some subtxn of current txn that committed */
            if (TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmax(tuple))) /* Case 1.2.3 and 2.2.2 */
                return (HeapTupleHeaderGetCmax(tuple) >= snapshot->curcid);

            if (find_failed_transaction(HeapTupleHeaderGetRawXmax(tuple)))             /* Case 1.2.5 */
            {
                /* deleting subtransaction must have aborted unexpectedly */
                HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
                return true;
            }
        }
        else if (TransactionIdDidCommit(HeapTupleHeaderGetRawXmin(tuple)))
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMIN_COMMITTED, HeapTupleHeaderGetRawXmin(tuple));
        else if (find_failed_transaction(HeapTupleHeaderGetRawXmin(tuple))) /* This is case 2.2.3 in comment section */
        {
            /* xmin is aborted unexpectedly */
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMIN_INVALID, InvalidTransactionId);
            return false;
        }
    }

    /* by here, the inserting transaction is "considered" committed */

    /* There should not be any locking in table variable at this point */
    Assert(!HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask));
    Assert((tuple->t_infomask & HEAP_XMAX_IS_MULTI) == 0);

    if ((tuple->t_infomask & HEAP_XMAX_INVALID)) /* Case 1.1.1 comment section */
        return true;

    /* The HEAP_XMAX_COMMITTED hint bit is not yet set */
    if (!(tuple->t_infomask & HEAP_XMAX_COMMITTED))
    {
        if (TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmax(tuple)))
            return (HeapTupleHeaderGetCmax(tuple) >= snapshot->curcid); /* Cases 1.2.4 and 2.4.1 in comment section */

        if (TransactionIdDidCommit(HeapTupleHeaderGetRawXmax(tuple)))
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_COMMITTED, HeapTupleHeaderGetRawXmax(tuple));
        else if (find_failed_transaction(HeapTupleHeaderGetRawXmax(tuple))) /* Case 1.1.2 xmax must have aborted unexpectedly or crashed */
        {
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
            return true;
        }
    }

    /* xmax transaction committed or clean rollback. Case 2.3 in comment section */
    return false;
}


/*
 * TVHeapTupleSatisfiesDirtyOrSelf
 *
 * In general, HeapTupleSatisfiesSelf and HeapTupleSatisfiesDirty are the same
 * as far as effects of the current transaction and committed/aborted xacts are concerned.
 * The difference is that HeapTupleSatisfiesSelf also includes the effects of other xacts still in progress.
 * This is not the case for Table Variables because tables are per-session.
 * Hence for table variables, SNAPSHOT_SELF and SNAPSHOT_DIRTY are the same
 *
 * 1. A row is VISIBLE when:
 *  1.1. XMIN is COMMITTED or expected ROLLBACK or Current Transaction
 *    1.1.1. XMAX is INVALID
 *    1.1.2. XMAX failed unexpectedly
 *    1.1.3. XMAX is in-progress
 *
 * 2. A row is INVISIBLE when:
 *  2.0. XMIN INVALID hint bit is set by previous scan operations
 *  2.1. XMIN Failed unexpectedly
 *  2.3. XMAX committed or clean Rollback
 */
static bool
TVHeapTupleSatisfiesDirtyOrSelf(HeapTuple htup, Snapshot snapshot, Buffer buffer)
{
    HeapTupleHeader tuple = htup->t_data;

    Assert(ItemPointerIsValid(&htup->t_self));
    Assert(htup->t_tableOid != InvalidOid);

    if (snapshot->snapshot_type == SNAPSHOT_DIRTY)
    {
        snapshot->xmin = snapshot->xmax = InvalidTransactionId;
        snapshot->speculativeToken = 0;
    }

    if (!HeapTupleHeaderXminCommitted(tuple))
    {
        if (HeapTupleHeaderXminInvalid(tuple))      /* Case 2.0 in comment section */
            return false;

        if (TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmin(tuple)))
        {
            if (tuple->t_infomask & HEAP_XMAX_INVALID)
                return true;                                    /* Case 1.1.1 */

            Assert(!HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask));
            Assert(!(tuple->t_infomask & HEAP_XMAX_IS_MULTI));

            if (find_failed_transaction(HeapTupleHeaderGetRawXmax(tuple)))
            {
                HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
                return true;                                    /* Case 1.1.2 */
            }

            return false;   /* Case 2.3 in comment section */
        }

        /* Table Variables are per-session so if xmin is active it would be true above */
        Assert(!TransactionIdIsInProgress(HeapTupleHeaderGetRawXmin(tuple)));

        if (TransactionIdDidCommit(HeapTupleHeaderGetRawXmin(tuple)))
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMIN_COMMITTED, HeapTupleHeaderGetRawXmin(tuple));
        else if (find_failed_transaction(HeapTupleHeaderGetRawXmin(tuple)))
        {
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMIN_INVALID, InvalidTransactionId);
            return false;   /* Case 2.1 in comment section */
        }
    }

    /* by here, the inserting transaction is considered committed */

    if (tuple->t_infomask & HEAP_XMAX_INVALID)                  /* Case 1.1.1 */
        return true;

    if (tuple->t_infomask & HEAP_XMAX_COMMITTED)
        return false;   /* Case 1.1.3 */

    Assert(!(HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask)));
    Assert(!(tuple->t_infomask & HEAP_XMAX_IS_MULTI));

    if (TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmax(tuple)))     /* Case 2.4 and 1.1.3 */
        return false;

    /* Table Variables are per-session so if xmax is active it would be true above */
    Assert(!TransactionIdIsInProgress(HeapTupleHeaderGetRawXmax(tuple)));

    if (TransactionIdDidCommit(HeapTupleHeaderGetRawXmax(tuple)))
        HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_COMMITTED, HeapTupleHeaderGetRawXmax(tuple));
    else if (find_failed_transaction(HeapTupleHeaderGetRawXmax(tuple)))
    {
        HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
        return true;        /* Case 1.1.3 */
    }

    /* xmax transaction considered committed */
    return false;   /* Case 2.3 */
}

static bool
TVHeapTupleSatisfiesToast(HeapTuple htup, Snapshot snapshot, Buffer buffer)
{
	HeapTupleHeader tuple = htup->t_data;

	Assert(ItemPointerIsValid(&htup->t_self));
	Assert(htup->t_tableOid != InvalidOid);

	if (!HeapTupleHeaderXminCommitted(tuple))
	{
		if (HeapTupleHeaderXminInvalid(tuple))
			return false;

		/*
		 * An invalid Xmin can be left behind by a speculative insertion that
		 * is canceled by super-deleting the tuple.  This also applies to
		 * TOAST tuples created during speculative insertion.
		 */
		else if (!TransactionIdIsValid(HeapTupleHeaderGetXmin(tuple)))
			return false;
	}

	/* otherwise assume the tuple is valid for TOAST. */
	return true;
}

static bool
TVHeapTupleSatisfiesNonVacuumable(HeapTuple htup, Snapshot snapshot, Buffer buffer)
{
	TransactionId dead_after = InvalidTransactionId;
	HTSV_Result res;

	res = TVHeapTupleSatisfiesVacuumHorizon(htup, buffer, &dead_after);

	if (res == HEAPTUPLE_RECENTLY_DEAD)
	{
		Assert(TransactionIdIsValid(dead_after));

		if (GlobalVisTestIsRemovableXid(snapshot->vistest, dead_after))
			res = HEAPTUPLE_DEAD;
	}
	else
		Assert(!TransactionIdIsValid(dead_after));

	return res != HEAPTUPLE_DEAD;
}

/*
 * HeapTupleSatisfiesVisibility
 *		True iff heap tuple satisfies a time qual.
 *
 * Notes:
 *	Assumes heap tuple is valid, and buffer at least share locked.
 *
 *	Hint bits in the HeapTuple's t_infomask may be updated as a side effect;
 *	if so, the indicated buffer is marked dirty.
 */
bool
TVHeapTupleSatisfiesVisibility(HeapTuple tup, Snapshot snapshot, Buffer buffer)
{
    if (!IS_TDS_CLIENT())
        ereport(ERROR, (errmsg("Table Variables on non-TDS clients are unsupported")));

    switch (snapshot->snapshot_type)
    {
        case SNAPSHOT_MVCC:
            return TVHeapTupleSatisfiesMVCC(tup, snapshot, buffer);
            break;
        case SNAPSHOT_ANY:
            return TVHeapTupleSatisfiesAny(tup, snapshot, buffer);
            break;
        case SNAPSHOT_SELF:
        case SNAPSHOT_DIRTY:
            return TVHeapTupleSatisfiesDirtyOrSelf(tup, snapshot, buffer);
            break;
        case SNAPSHOT_TOAST:
             return TVHeapTupleSatisfiesToast(tup, snapshot, buffer);
             break;
        case SNAPSHOT_NON_VACUUMABLE:
             return TVHeapTupleSatisfiesNonVacuumable(tup, snapshot, buffer);
             break;

        case SNAPSHOT_HISTORIC_MVCC:
        default:
            ereport(ERROR, (errmsg("Unsupported snapshot type %d for Table Variables", snapshot->snapshot_type)));
            break;
    }

    return false;				/* keep compiler quiet */

}


/*
 * TVHeapTupleSatisfiesUpdate
 *
 * Counterpart of HeapTupleSatisfiesUpdate.
 * The only difference is this function is not rollback sensitive.
 */
TM_Result TVHeapTupleSatisfiesUpdate(HeapTuple htup, CommandId curcid, Buffer buffer)
{
    HeapTupleHeader tuple = htup->t_data;

    Assert(ItemPointerIsValid(&htup->t_self));
    Assert(htup->t_tableOid != InvalidOid);

    if (!IS_TDS_CLIENT())
        ereport(ERROR, (errmsg("Table Variables on non-TDS clients are unsupported")));

    if (!HeapTupleHeaderXminCommitted(tuple))
    {
        if (HeapTupleHeaderXminInvalid(tuple))
            return TM_Invisible;

        else if (TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmin(tuple)))
        {
            if (HeapTupleHeaderGetCmin(tuple) >= curcid)
                return TM_Invisible;    /* inserted after scan started */

            if (tuple->t_infomask & HEAP_XMAX_INVALID)  /* xid invalid */
                return TM_Ok;

            /* These should not be supported for Table Variables at this point */
            Assert(!(HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask)));
            Assert(!(tuple->t_infomask & HEAP_XMAX_IS_MULTI));

            /* deleting subtransaction must have aborted */
            if (find_failed_transaction(HeapTupleHeaderGetRawXmax(tuple)))
            {
                HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
                return TM_Ok;
            }

            if (HeapTupleHeaderGetCmax(tuple) >= curcid)
                return TM_SelfModified; /* updated after scan started */
            else
                return TM_Invisible;    /* updated before scan started */
        }

        /* Table Variables are per-session so if xmin is active it would be true above */
        Assert(!TransactionIdIsInProgress(HeapTupleHeaderGetRawXmin(tuple)));

        if (TransactionIdDidCommit(HeapTupleHeaderGetRawXmin(tuple)))
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMIN_COMMITTED, HeapTupleHeaderGetRawXmin(tuple));
        else if (find_failed_transaction(HeapTupleHeaderGetRawXmin(tuple)))
        {
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMIN_INVALID, InvalidTransactionId);
            return TM_Invisible;
        }
    }

    /* by here, the inserting transaction is "considered" committed */
    if (tuple->t_infomask & HEAP_XMAX_INVALID)
        return TM_Ok;

    Assert(!(tuple->t_infomask & HEAP_XMAX_IS_MULTI));
    Assert(!(HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask)));

    if (tuple->t_infomask & HEAP_XMAX_COMMITTED)
    {
        if (!ItemPointerEquals(&htup->t_self, &tuple->t_ctid))
            return TM_Updated;  /* updated by other */
        else
            return TM_Deleted;  /* deleted by other */
    }

    if (TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmax(tuple)))
    {
        if (HeapTupleHeaderGetCmax(tuple) >= curcid)
            return TM_SelfModified; /* updated after scan started */
        else
            return TM_Invisible;    /* updated before scan started */
    }

    /* Table Variables are per-session so if xmax is active it would be true above */
    Assert(!TransactionIdIsInProgress(HeapTupleHeaderGetRawXmax(tuple)));

    if (TransactionIdDidCommit(HeapTupleHeaderGetRawXmax(tuple)))
        HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_COMMITTED, HeapTupleHeaderGetRawXmax(tuple));
    else if (find_failed_transaction(HeapTupleHeaderGetRawXmax(tuple)))
    {
        HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
        return TM_Ok;
    }

    /* xmax transaction committed */
    if (!ItemPointerEquals(&htup->t_self, &tuple->t_ctid))
        return TM_Updated;      /* updated by other */
    else
        return TM_Deleted;      /* deleted by other */
}


/*
 * HeapTupleSatisfiesVacuum
 *
 *  Determine the status of tuples for VACUUM purposes.  Here, what
 *  we mainly want to know is if a tuple is potentially visible to *any*
 *  running transaction.  If so, it can't be removed yet by VACUUM.
 *
 * OldestXmin is a cutoff XID (obtained from
 * GetOldestNonRemovableTransactionId()).  Tuples deleted by XIDs >=
 * OldestXmin are deemed "recently dead"; they might still be visible to some
 * open transaction, so we can't remove them, even if we see that the deleting
 * transaction has committed.
 */
HTSV_Result
TVHeapTupleSatisfiesVacuum(HeapTuple htup, TransactionId OldestXmin,
                         Buffer buffer)
{
    TransactionId dead_after = InvalidTransactionId;
    HTSV_Result res;

    res = TVHeapTupleSatisfiesVacuumHorizon(htup, buffer, &dead_after);

    if (res == HEAPTUPLE_RECENTLY_DEAD)
    {
        Assert(TransactionIdIsValid(dead_after));

        if (TransactionIdPrecedes(dead_after, OldestXmin))
            res = HEAPTUPLE_DEAD;
    }
    else
        Assert(!TransactionIdIsValid(dead_after));

    return res;
}


/*
 * Work horse for TVHeapTupleSatisfiesVacuum and similar routines.
 *
 * In contrast to HeapTupleSatisfiesVacuum this routine, when encountering a
 * tuple that could still be visible to some backend, stores the xid that
 * needs to be compared with the horizon in *dead_after, and returns
 * HEAPTUPLE_RECENTLY_DEAD. The caller then can perform the comparison with
 * the horizon.  This is e.g. useful when comparing with different horizons.
 *
 * Note: HEAPTUPLE_DEAD can still be returned here, e.g. if the inserting
 * transaction aborted.
 */
HTSV_Result
TVHeapTupleSatisfiesVacuumHorizon(HeapTuple htup, Buffer buffer, TransactionId *dead_after)
{
    HeapTupleHeader tuple = htup->t_data;

    Assert(ItemPointerIsValid(&htup->t_self));
    Assert(htup->t_tableOid != InvalidOid);
    Assert(dead_after != NULL);

    *dead_after = InvalidTransactionId;

    if (!IS_TDS_CLIENT())
        ereport(ERROR, (errmsg("Table Variables on non-TDS clients are unsupported")));

    /*
    * Has inserting transaction committed?
    *
    * If the inserting transaction aborted, then the tuple was never visible
    * to any other transaction, so we can delete it immediately.
    */
    if (!HeapTupleHeaderXminCommitted(tuple))
    {
        if (HeapTupleHeaderXminInvalid(tuple))
            return HEAPTUPLE_DEAD;

        else if (TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmin(tuple)))
        {
            TransactionId xmax;
            if (tuple->t_infomask & HEAP_XMAX_INVALID)	/* xid invalid */
                return HEAPTUPLE_LIVE;

            xmax = HeapTupleHeaderGetUpdateXid(tuple);
            if (TransactionIdIsCurrentTransactionId(xmax)) {
                *dead_after = HeapTupleHeaderGetRawXmax(tuple);
                return HEAPTUPLE_RECENTLY_DEAD;
            }
            else if (find_failed_transaction(xmax))
                return HEAPTUPLE_LIVE;

        }
        else if (TransactionIdDidCommit(HeapTupleHeaderGetRawXmin(tuple)))
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMIN_COMMITTED, HeapTupleHeaderGetRawXmin(tuple));
        else if (find_failed_transaction(HeapTupleHeaderGetRawXmin(tuple)))
        {
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMIN_INVALID, InvalidTransactionId);
            return HEAPTUPLE_DEAD;
        }

    }

    /*
    * Okay, the inserter committed or had a clean rollback, so it was good at some point.
    * Now what about the deleting transaction?
    */
    if (tuple->t_infomask & HEAP_XMAX_INVALID)
        return HEAPTUPLE_LIVE;

    Assert(!HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask));
    Assert(!(tuple->t_infomask & HEAP_XMAX_IS_MULTI));

    if (!(tuple->t_infomask & HEAP_XMAX_COMMITTED))
    {
        if (TransactionIdDidCommit(HeapTupleHeaderGetRawXmax(tuple)))
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_COMMITTED, HeapTupleHeaderGetRawXmax(tuple));
        else if (find_failed_transaction(HeapTupleHeaderGetRawXmax(tuple)))
        {
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
            return HEAPTUPLE_LIVE;
        }
    }

    /*
    * Deleter is not in-progress anymore, allow caller to check if it was recent enough that
    * some open transactions could still see the tuple.
    */
    *dead_after = HeapTupleHeaderGetRawXmax(tuple);
    return HEAPTUPLE_RECENTLY_DEAD;
}
