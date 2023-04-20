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
* Tuple infomask has HEAP_XMAX_IS_MULTI set so grab the updater xid from multixact.
* Return True if tuple is visible. Otherwise False.
*/
static bool
_updater_multi_xid_failed_unexpectedly(HeapTuple htup, Snapshot mvcc_snapshot)
{
    /*
    * It is possible we dont reach here for Table Variables.
    * But keep the check to be as close as PG as possible
    */
    HeapTupleHeader tuple = htup->t_data;
    TransactionId xmax = HeapTupleGetUpdateXid(tuple);
    Assert(TransactionIdIsValid(xmax));
    Assert(tuple->t_infomask & HEAP_XMAX_IS_MULTI);

    if (TransactionIdIsCurrentTransactionId(xmax))
        return (mvcc_snapshot && HeapTupleHeaderGetCmax(tuple) >= mvcc_snapshot->curcid);

    /* Table Variable: This should be any other transaction */
    Assert(!TransactionIdIsInProgress(xmax));

    return find_failed_transaction(xmax);

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
 *    1.1.3. XMAX is lock-only (SELECT-FOR-SHARE, SELECT-FOR-UPDATE)
 *    1.1.4. XMAX is set but (tuple->cid >= snapshotcid) to guard against the Halloween problem
 *  1.2. XMIN is current transaction
 *    1.2.1. INSERTed before current command (tuple->cid < snapshotcid) to guard the Halloween problem
 *    1.2.2. XMAX is NOT set (not yet DELETED/UPDATED)
 *    1.2.3. XMAX is set but lock-only (eg: SELECT-FOR-SHARE, SELECT-FOR-UPDATE)
 *    1.2.4. XMAX is set but (tuple->cid >= snapshotcid) to guard against the Halloween problem
 *    1.2.5. XMAX is set but by a previous subtransaction that failed unexpectedly
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

            if (tuple->t_infomask & HEAP_XMAX_INVALID
                || HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))  /* Case 1.2.2 or 1.2.3 in comment section */
                return true;

            if (tuple->t_infomask & HEAP_XMAX_IS_MULTI)
                return _updater_multi_xid_failed_unexpectedly(htup, snapshot);
            else if (TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmax(tuple))) /* Case 1.2.4 and 2.2.2 */
                return (HeapTupleHeaderGetCmax(tuple) >= snapshot->curcid);
            else if (find_failed_transaction(HeapTupleHeaderGetRawXmax(tuple)))             /* Case 1.2.5 */
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

    if ((tuple->t_infomask & HEAP_XMAX_INVALID) || HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask)) /* Cases 1.1.1 and 1.1.3 in comment section */
        return true;

    if (tuple->t_infomask & HEAP_XMAX_IS_MULTI)
    {
        /* already checked above */
        Assert(!HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask));
        return _updater_multi_xid_failed_unexpectedly(htup, snapshot);
    }

    /* The HEAP_XMAX_COMMITTED hint bit is not yet set */
    if (!(tuple->t_infomask & HEAP_XMAX_COMMITTED))
    {
        if (TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmax(tuple)))
            return (HeapTupleHeaderGetCmax(tuple) >= snapshot->curcid); /* Cases 1.2.4 and 2.4.1 in comment section */

        /* Case 1.1.2 xmax must have aborted unexpectedly or crashed */
        if (find_failed_transaction(HeapTupleHeaderGetRawXmax(tuple)))
        {
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
            return true;
        } else if (TransactionIdDidCommit(HeapTupleHeaderGetRawXmax(tuple)))
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_COMMITTED, HeapTupleHeaderGetRawXmax(tuple));
    }

    /* xmax transaction committed or clean rollback. Case 2.3 in comment section */
    return false;
}


/*
 * TVHeapTupleSatisfiesDirty
 *		True iff heap tuple is valid including effects of open transactions.
 *
 * See SNAPSHOT_DIRTY's definition for the intended behaviour.
 *
 * This is essentially like HeapTupleSatisfiesSelf as far as effects of
 * the current transaction and committed/aborted xacts are concerned.
 * However, we also include the effects of other xacts still in progress.
 *
 * A special hack is that the passed-in snapshot struct is used as an
 * output argument to return the xids of concurrent xacts that affected the
 * tuple.  snapshot->xmin is set to the tuple's xmin if that is another
 * transaction that's still in progress; or to InvalidTransactionId if the
 * tuple's xmin is committed good, committed dead, or my own xact.
 * Similarly for snapshot->xmax and the tuple's xmax.  If the tuple was
 * inserted speculatively, meaning that the inserter might still back down
 * on the insertion without aborting the whole transaction, the associated
 * token is also returned in snapshot->speculativeToken.
 *
 * SnapshotDirty does not have any xmin, xmax, command ids set.
 * 1. A row is VISIBLE for SnapshotDirty when:
 *  1.1. XMIN is COMMITTED or expected ROLLBACK
 *    1.1.1. XMAX is INVALID
 *    1.1.2. XMAX failed unexpectedly
 *    1.1.3. XMAX is lock-only (SELECT-FOR-SHARE, SELECT-FOR-UPDATE)
 *  1.2. XMIN or XMAX is in-progress - special case for SnapshotDirty
 *
 * 2. A row is INVISIBLE when:
 *  2.0. XMIN INVALID hint bit is set by previous scan operations
 *  2.1. XMIN Failed unexpectedly
 *  2.3. XMAX committed or clean Rollback
 *  2.4. XMAX is current transaction
 */
static bool
TVHeapTupleSatisfiesDirty(HeapTuple htup, Snapshot snapshot, Buffer buffer)
{
    HeapTupleHeader tuple = htup->t_data;

    Assert(ItemPointerIsValid(&htup->t_self));
    Assert(htup->t_tableOid != InvalidOid);

    snapshot->xmin = snapshot->xmax = InvalidTransactionId;
    snapshot->speculativeToken = 0;

    if (!HeapTupleHeaderXminCommitted(tuple))
    {
        if (HeapTupleHeaderXminInvalid(tuple))                  /* This is Case 2.0 in the comment */
            return false;

        if (TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmin(tuple)))
        {
            if (tuple->t_infomask & HEAP_XMAX_INVALID)          /* Case 1.1.1 */
                return true;

            if (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))    /* Case 1.1.3 */
                return true;

            if (tuple->t_infomask & HEAP_XMAX_IS_MULTI)
                return _updater_multi_xid_failed_unexpectedly(htup, NULL);

            if (!TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmax(tuple)))
            {
                /* deleting subtransaction must have aborted */
                if (find_failed_transaction (HeapTupleHeaderGetRawXmax(tuple)))
                {
                    HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
                    return true;    /* Case 1.1.2 */
                }
            }

            return false;           /* Case 2.1 */
        }
        else if (TransactionIdIsInProgress(HeapTupleHeaderGetRawXmin(tuple)))
        {
            /*
            * Return the speculative token to caller.  Caller can worry about
            * xmax, since it requires a conclusively locked row version, and
            * a concurrent update to this tuple is a conflict of its
            * purposes.
            */
            if (HeapTupleHeaderIsSpeculative(tuple))
            {
                snapshot->speculativeToken =
                    HeapTupleHeaderGetSpeculativeToken(tuple);

                Assert(snapshot->speculativeToken != 0);
            }

            snapshot->xmin = HeapTupleHeaderGetRawXmin(tuple);
            /* XXX shouldn't we fall through to look at xmax? */
            return true;		/* in insertion by other. Case 1.3 */
        }
        else if (TransactionIdDidCommit(HeapTupleHeaderGetRawXmin(tuple)))
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMIN_COMMITTED, HeapTupleHeaderGetRawXmin(tuple));
        else if (find_failed_transaction(HeapTupleHeaderGetRawXmin(tuple)))
        {
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMIN_INVALID, InvalidTransactionId);
            return false;   /* Case 2.1 */
        }

        /* xmin "considered" committed */
    }

    /* by here, the inserting transaction is considered committed */

    if (tuple->t_infomask & HEAP_XMAX_INVALID)	/* Case 1.1.1 */
        return true;

    if (tuple->t_infomask & HEAP_XMAX_COMMITTED)
        return (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask));   /* Case 1.1.3 */

    if (tuple->t_infomask & HEAP_XMAX_IS_MULTI)
        return _updater_multi_xid_failed_unexpectedly(htup, NULL);

    if (TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmax(tuple)))
        return (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask));  /* Case 1.1.2 */

    if (TransactionIdIsInProgress(HeapTupleHeaderGetRawXmax(tuple)))
    {
        if (!HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))
            snapshot->xmax = HeapTupleHeaderGetRawXmax(tuple);
        return true;    /* Case 1.1.2 */
    }

    if (find_failed_transaction(HeapTupleHeaderGetRawXmax(tuple)))
    {
        HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
        return true;    /* Case 1.1.3 */
    }
    else if (TransactionIdDidCommit(HeapTupleHeaderGetRawXmax(tuple)))
        HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_COMMITTED, HeapTupleHeaderGetRawXmax(tuple));

    /* xmax transaction considered committed */

    if (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))
    {
        HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
        return true;     /* Case 1.1.3 */
    }

    return false;				/* Case 2.3. updated by other */
}

/*
 * TVHeapTupleSatisfiesSelf
 *		True iff heap tuple is valid "for itself".
 *
 * See SNAPSHOT_MVCC's definition for the intended behaviour.
 *
 * Note:
 *		Assumes heap tuple is valid.
 *
 * The satisfaction of "itself" requires the following:
 *
 * ((Xmin == my-transaction &&				the row was updated by the current transaction, and
 *		(Xmax is null						it was not deleted
 *		 [|| Xmax != my-transaction)])			[or it was deleted by another transaction]
 * ||
 *
 * (Xmin is committed &&					the row was modified by a committed transaction, and
 *		(Xmax is null ||					the row has not been deleted, or
 *			(Xmax != my-transaction &&			the row was deleted by another transaction
 *			 Xmax is not committed)))			that has not been committed
 *
 * 1. A row is VISIBLE for SnapshotSelf when:
 *  1.1. XMIN is COMMITTED or expected ROLLBACK or Current Transaction
 *    1.1.1. XMAX is INVALID
 *    1.1.2. XMAX failed unexpectedly
 *    1.1.3. XMAX is lock-only (SELECT-FOR-SHARE, SELECT-FOR-UPDATE)
 *    1.1.4. XMAX is in-progress
 *
 * 2. A row is INVISIBLE when:
 *  2.0. XMIN INVALID hint bit is set by previous scan operations
 *  2.1. XMIN Failed unexpectedly
 *  2.3. XMAX committed or clean Rollback
 *  2.4. XMIN is in-progress
 */
static bool
TVHeapTupleSatisfiesSelf(HeapTuple htup, Snapshot snapshot, Buffer buffer)
{
    HeapTupleHeader tuple = htup->t_data;

    Assert(ItemPointerIsValid(&htup->t_self));
    Assert(htup->t_tableOid != InvalidOid);

    if (!HeapTupleHeaderXminCommitted(tuple))
    {
        if (HeapTupleHeaderXminInvalid(tuple))      /* Case 2.0 in comment section */
            return false;

        if (TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmin(tuple)))
        {
            if (tuple->t_infomask & HEAP_XMAX_INVALID ||
                HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))          /* Case 1.1.1 and 1.1.3 */
                return true;

            if (tuple->t_infomask & HEAP_XMAX_IS_MULTI)
                return _updater_multi_xid_failed_unexpectedly(htup, NULL);

            if (!TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmax(tuple)) &&
                find_failed_transaction(HeapTupleHeaderGetRawXmax(tuple)))
            {
                HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
                return true;                                    /* Case 1.1.2 */
            }

            return false;   /* Case 2.3 in comment section */
        }
        else if (TransactionIdIsInProgress(HeapTupleHeaderGetRawXmin(tuple)))
            return false;   /* Case 2.4 in comment section */
        else if (TransactionIdDidCommit(HeapTupleHeaderGetRawXmin(tuple)))
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
        return (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask));   /* Case 1.1.3 */

    if (tuple->t_infomask & HEAP_XMAX_IS_MULTI)
        return _updater_multi_xid_failed_unexpectedly(htup, NULL);

    if (TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmax(tuple))) /* Case 2.4 and 1.1.3 */
        return (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask));

    if (TransactionIdIsInProgress(HeapTupleHeaderGetRawXmax(tuple)))           /* Case 1.1.4 */
        return true;

    if (find_failed_transaction(HeapTupleHeaderGetRawXmax(tuple))
        || HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))                        /* Case 1.1.2 and 1.1.3 */
    {
        HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
        return true;
    }
    else if (TransactionIdDidCommit(HeapTupleHeaderGetRawXmax(tuple)))
        HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_COMMITTED, HeapTupleHeaderGetRawXmax(tuple));

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
    switch (snapshot->snapshot_type)
    {
        case SNAPSHOT_MVCC:
            return TVHeapTupleSatisfiesMVCC(tup, snapshot, buffer);
            break;
        case SNAPSHOT_ANY:
            return TVHeapTupleSatisfiesAny(tup, snapshot, buffer);
            break;
        case SNAPSHOT_SELF:
            return TVHeapTupleSatisfiesSelf(tup, snapshot, buffer);
            break;
       case SNAPSHOT_DIRTY:
           return TVHeapTupleSatisfiesDirty(tup, snapshot, buffer);
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
TM_Result
TVHeapTupleSatisfiesUpdate(HeapTuple htup, CommandId curcid,
                         Buffer buffer)
{
    HeapTupleHeader tuple = htup->t_data;

    Assert(ItemPointerIsValid(&htup->t_self));
    Assert(htup->t_tableOid != InvalidOid);

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

            if (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))
            {
                TransactionId xmax;

                xmax = HeapTupleHeaderGetRawXmax(tuple);

                /*
                 * Careful here: even though this tuple was created by our own
                 * transaction, it might be locked by other transactions, if
                 * the original version was key-share locked when we updated
                 * it.
                 */

                if (tuple->t_infomask & HEAP_XMAX_IS_MULTI)
                {
                    if (MultiXactIdIsRunning(xmax, true))
                        return TM_BeingModified;
                    else
                        return TM_Ok;
                }

                /*
                 * If the locker is gone, then there is nothing of interest
                 * left in this Xmax; otherwise, report the tuple as
                 * locked/updated.
                 */
                if (!TransactionIdIsInProgress(xmax))
                    return TM_Ok;
                return TM_BeingModified;
            }

            if (tuple->t_infomask & HEAP_XMAX_IS_MULTI)
            {
                TransactionId xmax;

                xmax = HeapTupleGetUpdateXid(tuple);

                /* not LOCKED_ONLY, so it has to have an xmax */
                Assert(TransactionIdIsValid(xmax));

                /* deleting subtransaction must have aborted */
                if (!TransactionIdIsCurrentTransactionId(xmax))
                {
                    if (MultiXactIdIsRunning(HeapTupleHeaderGetRawXmax(tuple),
                                             false))
                        return TM_BeingModified;
                    if (find_failed_transaction(xmax))
                        return TM_Ok;
                }
                else
                {
                    if (HeapTupleHeaderGetCmax(tuple) >= curcid)
                        return TM_SelfModified; /* updated after scan started */
                    else
                        return TM_Invisible;    /* updated before scan started */
                }
            }

            if (!TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmax(tuple)))
            {
                /* deleting subtransaction must have aborted */
                if (find_failed_transaction(HeapTupleHeaderGetRawXmax(tuple)))
                {
                    HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
                    return TM_Ok;
                }
            }

            if (HeapTupleHeaderGetCmax(tuple) >= curcid)
                return TM_SelfModified; /* updated after scan started */
            else
                return TM_Invisible;    /* updated before scan started */
        }
        else if (TransactionIdIsInProgress(HeapTupleHeaderGetRawXmin(tuple)))
            return TM_Invisible;
        else if (TransactionIdDidCommit(HeapTupleHeaderGetRawXmin(tuple)))
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMIN_COMMITTED, HeapTupleHeaderGetRawXmin(tuple));
        else if (find_failed_transaction(HeapTupleHeaderGetRawXmin(tuple)))
        {
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMIN_INVALID, InvalidTransactionId);
            return TM_Invisible;
        }
    }

    /* by here, the inserting transaction is considered committed */

    if (tuple->t_infomask & HEAP_XMAX_INVALID)  /* xid invalid or aborted */
        return TM_Ok;

    if (tuple->t_infomask & HEAP_XMAX_COMMITTED)
    {
        if (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))
            return TM_Ok;
        if (!ItemPointerEquals(&htup->t_self, &tuple->t_ctid))
            return TM_Updated;  /* updated by other */
        else
            return TM_Deleted;  /* deleted by other */
    }

    if (tuple->t_infomask & HEAP_XMAX_IS_MULTI)
    {
        TransactionId xmax;

        if (HEAP_LOCKED_UPGRADED(tuple->t_infomask))
            return TM_Ok;

        if (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))
        {
            if (MultiXactIdIsRunning(HeapTupleHeaderGetRawXmax(tuple), true))
                return TM_BeingModified;

            HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
            return TM_Ok;
        }

        xmax = HeapTupleGetUpdateXid(tuple);
        if (!TransactionIdIsValid(xmax))
        {
            if (MultiXactIdIsRunning(HeapTupleHeaderGetRawXmax(tuple), false))
                return TM_BeingModified;
        }

        /* not LOCKED_ONLY, so it has to have an xmax */
        Assert(TransactionIdIsValid(xmax));

        if (TransactionIdIsCurrentTransactionId(xmax))
        {
            if (HeapTupleHeaderGetCmax(tuple) >= curcid)
                return TM_SelfModified; /* updated after scan started */
            else
                return TM_Invisible;    /* updated before scan started */
        }

        if (MultiXactIdIsRunning(HeapTupleHeaderGetRawXmax(tuple), false))
            return TM_BeingModified;

        if (TransactionIdDidCommit(xmax))
        {
            if (!ItemPointerEquals(&htup->t_self, &tuple->t_ctid))
                return TM_Updated;
            else
                return TM_Deleted;
        }

         /*
         * By here, the update in the Xmax is either aborted or crashed, but
         * what about the other members?
         */

        if (!MultiXactIdIsRunning(HeapTupleHeaderGetRawXmax(tuple), false))
        {
            /*
             * There's no member, even just a locker, alive anymore, so we can
             * mark the Xmax as invalid.
             */
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
            return TM_Ok;
        }
        else
        {
            /* There are lockers running */
            return TM_BeingModified;
        }
    }

    if (TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmax(tuple)))
    {
        if (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))
            return TM_BeingModified;
        if (HeapTupleHeaderGetCmax(tuple) >= curcid)
            return TM_SelfModified; /* updated after scan started */
        else
            return TM_Invisible;    /* updated before scan started */
    }

    if (TransactionIdIsInProgress(HeapTupleHeaderGetRawXmax(tuple)))
        return TM_BeingModified;

    if (!TransactionIdDidCommit(HeapTupleHeaderGetRawXmax(tuple)))
    {
        /* it must have aborted unexpectedly or crashed */
        if (find_failed_transaction(HeapTupleHeaderGetRawXmax(tuple)))
        {
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
            return TM_Ok;
        }
    }
    else
        HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_COMMITTED, HeapTupleHeaderGetRawXmax(tuple));

    /* xmax transaction committed */

    if (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))
    {
        HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
        return TM_Ok;
    }

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
        else if (find_failed_transaction(HeapTupleHeaderGetRawXmin(tuple)))
        {
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMIN_INVALID, InvalidTransactionId);
            return HEAPTUPLE_DEAD;
        }

        /*
        * At this point the xmin is known committed, but we might not have
        * been able to set the hint bit yet; so we can no longer Assert that
        * it's set.
        */
    }

    /*
    * Okay, the inserter committed, so it was good at some point.  Now what
    * about the deleting transaction?
    */
    if (tuple->t_infomask & HEAP_XMAX_INVALID || HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))
        return HEAPTUPLE_LIVE;

    if (tuple->t_infomask & HEAP_XMAX_IS_MULTI)
    {
        TransactionId xmax = HeapTupleGetUpdateXid(tuple);

        /* already checked above */
        Assert(!HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask));

        /* not LOCKED_ONLY, so it has to have an xmax */
        Assert(TransactionIdIsValid(xmax));

        if (find_failed_transaction(xmax))
            return HEAPTUPLE_LIVE;

        return HEAPTUPLE_DEAD;
    }

    if (!(tuple->t_infomask & HEAP_XMAX_COMMITTED))
    {
        if (find_failed_transaction(HeapTupleHeaderGetRawXmax(tuple)))
        {
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMIN_INVALID, InvalidTransactionId);
            return HEAPTUPLE_LIVE;
        }
    }

    /* Deleter is considered committed */
    return HEAPTUPLE_DEAD;
}
