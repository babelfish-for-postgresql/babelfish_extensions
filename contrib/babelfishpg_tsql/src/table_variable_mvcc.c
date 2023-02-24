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
 * TVHeapTupleSatisfiesMVCC
 *
 * Table Variables are not  sensitive to rollbacks and are meant for use on current session only.
 * This ignores XidInMVCCSnapshot() because it only cares whether the xid is committed or unexpectedly rolled back.
 * However it uses snapshot still because it needs the command id in cases when xid is the current transaction.
 */
static bool
TVHeapTupleSatisfiesMVCC(HeapTuple htup, Snapshot snapshot, Buffer buffer)
{
    HeapTupleHeader tuple = htup->t_data;

    Assert(ItemPointerIsValid(&htup->t_self));
    Assert(htup->t_tableOid != InvalidOid);

    if (!HeapTupleHeaderXminCommitted(tuple))
    {
        if (HeapTupleHeaderXminInvalid(tuple))
            return false;

        else if (TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmin(tuple)))
        {
            if (HeapTupleHeaderGetCmin(tuple) >= snapshot->curcid)
                return false;	/* inserted after scan started */

            if (tuple->t_infomask & HEAP_XMAX_INVALID)	/* xid invalid */
                return true;

            if (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))	/* not deleter */
                return true;

            if (tuple->t_infomask & HEAP_XMAX_IS_MULTI)
            {
                TransactionId xmax;

                xmax = HeapTupleGetUpdateXid(tuple);

                /* not LOCKED_ONLY, so it has to have an xmax */
                Assert(TransactionIdIsValid(xmax));

                /* updating subtransaction must have aborted */
                if (!TransactionIdIsCurrentTransactionId(xmax))
                    return true;
                else if (HeapTupleHeaderGetCmax(tuple) >= snapshot->curcid)
                    return true;	/* updated after scan started */
                else
                    return false;	/* updated before scan started */
            }

            if (!TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmax(tuple)))
            {
                /* deleting subtransaction must have aborted unexpectedly */
                if (find_failed_transaction(HeapTupleHeaderGetRawXmax(tuple)))
                {
                    HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
                    return true;
                }
            }

            if (HeapTupleHeaderGetCmax(tuple) >= snapshot->curcid)
                return true;	/* deleted after scan started */
            else
                return false;	/* deleted before scan started */
        }
        else if (TransactionIdDidCommit(HeapTupleHeaderGetRawXmin(tuple)))
        {
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMIN_COMMITTED, HeapTupleHeaderGetRawXmin(tuple));
        }
        else
        {
            /* xmin is aborted or crashed */
            if (find_failed_transaction(HeapTupleHeaderGetRawXmin(tuple)))
            {
                HeapTupleSetHintBits(tuple, buffer, HEAP_XMIN_INVALID, InvalidTransactionId);
                return false;
            }
        }
    }

    /* by here, the inserting transaction has committed */

    if (tuple->t_infomask & HEAP_XMAX_INVALID)	/* xid invalid or aborted */
        return true;

    if (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))
        return true;

    if (tuple->t_infomask & HEAP_XMAX_IS_MULTI)
    {
        TransactionId xmax;

        /* already checked above */
        Assert(!HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask));

        xmax = HeapTupleGetUpdateXid(tuple);

        /* not LOCKED_ONLY, so it has to have an xmax */
        Assert(TransactionIdIsValid(xmax));

        if (TransactionIdIsCurrentTransactionId(xmax))
        {
            if (HeapTupleHeaderGetCmax(tuple) >= snapshot->curcid)
                return true;	/* deleted after scan started */
            else
                return false;	/* deleted before scan started */
        }

        if (TransactionIdDidCommit(xmax) || !find_failed_transaction(xmax))
            return false;		/* updating transaction committed */

        /* it must have aborted unexpectedly or crashed */
        return true;
    }

    if (!(tuple->t_infomask & HEAP_XMAX_COMMITTED))
    {
        if (TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmax(tuple)))
        {
            if (HeapTupleHeaderGetCmax(tuple) >= snapshot->curcid)
                return true;	/* deleted after scan started */
            else
                return false;	/* deleted before scan started */
        }

        if (!TransactionIdDidCommit(HeapTupleHeaderGetRawXmax(tuple)) )
        {
            /* xmax must have aborted unexpectedly or crashed */
            if (find_failed_transaction(HeapTupleHeaderGetRawXmax(tuple)))
            {
                HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
                return true;
            }
        }

        /* xmax transaction committed */
        HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_COMMITTED, HeapTupleHeaderGetRawXmax(tuple));
    }

    /* xmax transaction committed */
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
        if (HeapTupleHeaderXminInvalid(tuple))
            return false;

        if (TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmin(tuple)))
        {
            if (tuple->t_infomask & HEAP_XMAX_INVALID)	/* xid invalid */
                return true;

            if (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))	/* not deleter */
                return true;

            if (tuple->t_infomask & HEAP_XMAX_IS_MULTI)
            {
                TransactionId xmax;

                xmax = HeapTupleGetUpdateXid(tuple);

                /* not LOCKED_ONLY, so it has to have an xmax */
                Assert(TransactionIdIsValid(xmax));

                /* updating subtransaction must have aborted */
                if (!TransactionIdIsCurrentTransactionId(xmax))
                {
                    if (find_failed_transaction(xmax))
                        return true;
                }
                else
                    return false;
            }

            if (!TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmax(tuple)))
            {
                /* deleting subtransaction must have aborted */
                if (find_failed_transaction (HeapTupleHeaderGetRawXmax(tuple)))
                {
                    HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
                    return true;
                }
            }

            return false;
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
            return true;		/* in insertion by other */
        }
        else if (TransactionIdDidCommit(HeapTupleHeaderGetRawXmin(tuple)))
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMIN_COMMITTED, HeapTupleHeaderGetRawXmin(tuple));
        else if (find_failed_transaction(HeapTupleHeaderGetRawXmin(tuple)))
        {
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMIN_INVALID, InvalidTransactionId);
            return false;
        }
    }

    /* by here, the inserting transaction is considered committed */

    if (tuple->t_infomask & HEAP_XMAX_INVALID)	/* xid invalid or aborted */
        return true;

    if (tuple->t_infomask & HEAP_XMAX_COMMITTED)
    {
        if (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))
            return true;
        return false;			/* updated by other */
    }

    if (tuple->t_infomask & HEAP_XMAX_IS_MULTI)
    {
        TransactionId xmax;

        if (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))
            return true;

        xmax = HeapTupleGetUpdateXid(tuple);

        /* not LOCKED_ONLY, so it has to have an xmax */
        Assert(TransactionIdIsValid(xmax));

        if (TransactionIdIsCurrentTransactionId(xmax))
            return false;
        if (TransactionIdIsInProgress(xmax))
        {
            snapshot->xmax = xmax;
            return true;
        }
        if (TransactionIdDidCommit(xmax))
            return false;
        /* it must have aborted or crashed */
        return true;
    }

    if (TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmax(tuple)))
    {
        if (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))
            return true;
        return false;
    }

    if (TransactionIdIsInProgress(HeapTupleHeaderGetRawXmax(tuple)))
    {
        if (!HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))
            snapshot->xmax = HeapTupleHeaderGetRawXmax(tuple);
        return true;
    }

    if (find_failed_transaction(HeapTupleHeaderGetRawXmax(tuple)))
    {
        /* it must have aborted unexpectedly or crashed */
        HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
        return true;
    }

    /* xmax transaction considered committed */

    if (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))
    {
        HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
        return true;
    }

    HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_COMMITTED, HeapTupleHeaderGetRawXmax(tuple));
    return false;				/* updated by other */
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
 */
static bool
TVHeapTupleSatisfiesSelf(HeapTuple htup, Snapshot snapshot, Buffer buffer)
{
    HeapTupleHeader tuple = htup->t_data;

    Assert(ItemPointerIsValid(&htup->t_self));
    Assert(htup->t_tableOid != InvalidOid);

    if (!HeapTupleHeaderXminCommitted(tuple))
    {
        if (HeapTupleHeaderXminInvalid(tuple))
            return false;

        if (TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmin(tuple)))
        {
            if (tuple->t_infomask & HEAP_XMAX_INVALID)	/* xid invalid */
                return true;

            if (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))	/* not deleter */
                return true;

            if (tuple->t_infomask & HEAP_XMAX_IS_MULTI)
            {
                TransactionId xmax;

                xmax = HeapTupleGetUpdateXid(tuple);

                /* not LOCKED_ONLY, so it has to have an xmax */
                Assert(TransactionIdIsValid(xmax));

                /* updating subtransaction must have aborted */
                if (!TransactionIdIsCurrentTransactionId(xmax) && find_failed_transaction(xmax))
                    return true;
                return false;
            }

            if (!TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmax(tuple)) &&
                find_failed_transaction(HeapTupleHeaderGetRawXmax(tuple)))
            {
                HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
                return true;
            }

            return false;
        }
        else if (TransactionIdIsInProgress(HeapTupleHeaderGetRawXmin(tuple)))
            return false;
        else if (TransactionIdDidCommit(HeapTupleHeaderGetRawXmin(tuple)))
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMIN_COMMITTED, HeapTupleHeaderGetRawXmin(tuple));
        else if (find_failed_transaction(HeapTupleHeaderGetRawXmin(tuple)))
        {
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMIN_INVALID, InvalidTransactionId);
            return false;
        }
    }

    /* by here, the inserting transaction is considered committed */

    if (tuple->t_infomask & HEAP_XMAX_INVALID)	/* xid invalid or aborted */
        return true;

    if (tuple->t_infomask & HEAP_XMAX_COMMITTED)
    {
        if (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))
            return true;
        return false;			/* updated by other */
    }

    if (tuple->t_infomask & HEAP_XMAX_IS_MULTI)
    {
        TransactionId xmax;

        if (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))
            return true;

        xmax = HeapTupleGetUpdateXid(tuple);

        /* not LOCKED_ONLY, so it has to have an xmax */
        Assert(TransactionIdIsValid(xmax));

        if (TransactionIdIsCurrentTransactionId(xmax))
            return false;
        if (TransactionIdIsInProgress(xmax))
            return true;
        if (TransactionIdDidCommit(xmax))
            return false;
        /* it must have aborted or crashed */
        return true;
    }

    if (TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmax(tuple)))
    {
        if (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))
            return true;
        return false;
    }

    if (TransactionIdIsInProgress(HeapTupleHeaderGetRawXmax(tuple)))
        return true;

    if (find_failed_transaction(HeapTupleHeaderGetRawXmax(tuple)))
    {
        /* it must have aborted or crashed */
        HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
        return true;
    }

    /* xmax transaction considered committed */

    if (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))
    {
        HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
        return true;
    }

    HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_COMMITTED, HeapTupleHeaderGetRawXmax(tuple));
    return false;
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
        //     return HeapTupleSatisfiesHistoricMVCC(tup, snapshot, buffer);
        //     break;


            ereport(WARNING, (errmsg("[TableVariableAM] Unsupported snapshot type %d", snapshot->snapshot_type)));
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
        {
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMIN_COMMITTED, HeapTupleHeaderGetRawXmin(tuple));
        }

        else
        {
            /* it must have aborted or crashed */
            if (find_failed_transaction(HeapTupleHeaderGetRawXmin(tuple)))
            {
                HeapTupleSetHintBits(tuple, buffer, HEAP_XMIN_INVALID, InvalidTransactionId);
                return TM_Invisible;
            }
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

    /* xmax transaction committed */

    if (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))
    {
        HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
        return TM_Ok;
    }

    HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_COMMITTED, HeapTupleHeaderGetRawXmax(tuple));
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
        else if (TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetRawXmin(tuple)))
        {
            if (tuple->t_infomask & HEAP_XMAX_INVALID)	/* xid invalid */
                return HEAPTUPLE_INSERT_IN_PROGRESS;
            /* only locked? run infomask-only check first, for performance */
            if (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask) ||
                HeapTupleHeaderIsOnlyLocked(tuple))
                return HEAPTUPLE_INSERT_IN_PROGRESS;
            /* inserted and then deleted by same xact */
            if (TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetUpdateXid(tuple)))
                return HEAPTUPLE_DELETE_IN_PROGRESS;
            /* deleting subtransaction must have aborted */
            return HEAPTUPLE_INSERT_IN_PROGRESS;
        }
        else if (TransactionIdIsInProgress(HeapTupleHeaderGetRawXmin(tuple)))
        {
            /*
                * It'd be possible to discern between INSERT/DELETE in progress
                * here by looking at xmax - but that doesn't seem beneficial for
                * the majority of callers and even detrimental for some. We'd
                * rather have callers look at/wait for xmin than xmax. It's
                * always correct to return INSERT_IN_PROGRESS because that's
                * what's happening from the view of other backends.
                */
            return HEAPTUPLE_INSERT_IN_PROGRESS;
        }
        else if (TransactionIdDidCommit(HeapTupleHeaderGetRawXmin(tuple)))
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMIN_COMMITTED, HeapTupleHeaderGetRawXmin(tuple));
        else
        {
            /*
            * Not in Progress, Not Committed, so either Aborted or crashed
            */
            if (find_failed_transaction(HeapTupleHeaderGetRawXmin(tuple)))
            {
                HeapTupleSetHintBits(tuple, buffer, HEAP_XMIN_INVALID, InvalidTransactionId);
                return HEAPTUPLE_DEAD;
            }
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
    if (tuple->t_infomask & HEAP_XMAX_INVALID)
        return HEAPTUPLE_LIVE;

    if (HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask))
    {
        /*
        * "Deleting" xact really only locked it, so the tuple is live in any
        * case.  However, we should make sure that either XMAX_COMMITTED or
        * XMAX_INVALID gets set once the xact is gone, to reduce the costs of
        * examining the tuple for future xacts.
        */
        if (!(tuple->t_infomask & HEAP_XMAX_COMMITTED))
        {
            if (tuple->t_infomask & HEAP_XMAX_IS_MULTI)
            {
                /*
                * If it's a pre-pg_upgrade tuple, the multixact cannot
                * possibly be running; otherwise have to check.
                */
                if (!HEAP_LOCKED_UPGRADED(tuple->t_infomask) &&
                    MultiXactIdIsRunning(HeapTupleHeaderGetRawXmax(tuple),
                                            true))
                    return HEAPTUPLE_LIVE;
                HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
            }
            else
            {
                if (TransactionIdIsInProgress(HeapTupleHeaderGetRawXmax(tuple)))
                    return HEAPTUPLE_LIVE;
                HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
            }
        }

        /*
        * We don't really care whether xmax did commit, abort or crash. We
        * know that xmax did lock the tuple, but it did not and will never
        * actually update it.
        */

        return HEAPTUPLE_LIVE;
    }

    if (tuple->t_infomask & HEAP_XMAX_IS_MULTI)
    {
        TransactionId xmax = HeapTupleGetUpdateXid(tuple);

        /* already checked above */
        Assert(!HEAP_XMAX_IS_LOCKED_ONLY(tuple->t_infomask));

        /* not LOCKED_ONLY, so it has to have an xmax */
        Assert(TransactionIdIsValid(xmax));

        if (TransactionIdIsInProgress(xmax))
            return HEAPTUPLE_DELETE_IN_PROGRESS;
        else if (TransactionIdDidCommit(xmax))
        {
            /*
                * The multixact might still be running due to lockers.  Need to
                * allow for pruning if below the xid horizon regardless --
                * otherwise we could end up with a tuple where the updater has to
                * be removed due to the horizon, but is not pruned away.  It's
                * not a problem to prune that tuple, because any remaining
                * lockers will also be present in newer tuple versions.
                */
            *dead_after = xmax;
            return HEAPTUPLE_RECENTLY_DEAD;
        }
        else if (!MultiXactIdIsRunning(HeapTupleHeaderGetRawXmax(tuple), false))
        {
            /*
            * Not in Progress, Not Committed, so either Aborted or crashed.
            * Mark the Xmax as invalid.
            */
            if (!find_failed_transaction(HeapTupleHeaderGetRawXmax(tuple))) {
                HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
                *dead_after = xmax;
                return HEAPTUPLE_RECENTLY_DEAD;
            }
        }

        return HEAPTUPLE_LIVE;
    }

    if (!(tuple->t_infomask & HEAP_XMAX_COMMITTED))
    {
        if (TransactionIdIsInProgress(HeapTupleHeaderGetRawXmax(tuple)))
            return HEAPTUPLE_DELETE_IN_PROGRESS;
        else if (TransactionIdDidCommit(HeapTupleHeaderGetRawXmax(tuple)))
            HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_COMMITTED, HeapTupleHeaderGetRawXmax(tuple));
        else
        {
            /*
            * Not in Progress, Not Committed, so either Aborted or crashed
            */
            if (find_failed_transaction(HeapTupleHeaderGetRawXmax(tuple)))
            {
                HeapTupleSetHintBits(tuple, buffer, HEAP_XMAX_INVALID, InvalidTransactionId);
                return HEAPTUPLE_LIVE;
            }
        }

        /*
        * At this point the xmax is known committed, but we might not have
        * been able to set the hint bit yet; so we can no longer Assert that
        * it's set.
        */
    }

    /*
    * Deleter committed, allow caller to check if it was recent enough that
    * some open transactions could still see the tuple.
    */
    *dead_after = HeapTupleHeaderGetRawXmax(tuple);
    return HEAPTUPLE_RECENTLY_DEAD;
}
