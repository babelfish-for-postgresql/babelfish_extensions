/*-------------------------------------------------------------------------
 *
 * pltsql_bulkcopy.c		- Bulk Copy for PL/tsql
 *
 * Portions Copyright (c) 2022, AWS
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  contrib/babelfishpg_tsql/src/pltsql_bulkcopy.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include <ctype.h>
#include <unistd.h>
#include <sys/stat.h>

#include "access/tableam.h"
#include "access/xact.h"
#include "catalog/dependency.h"
#include "catalog/namespace.h"
#include "commands/sequence.h"
#include "commands/copy.h"
#include "executor/executor.h"
#include "executor/nodeModifyTable.h"
#include "executor/tuptable.h"
#include "optimizer/optimizer.h"
#include "miscadmin.h"
#include "parser/parse_relation.h"
#include "pltsql_bulkcopy.h"
#include "rewrite/rewriteHandler.h"
#include "utils/builtins.h"
#include "utils/lsyscache.h"
#include "utils/rel.h"
#include "utils/rls.h"
#include "pltsql.h"

/*
 * No more than this many tuples per CopyMultiInsertBuffer
 *
 * Caution: Don't make this too big, as we could end up with this many
 * CopyMultiInsertBuffer items stored in CopyMultiInsertInfo's
 * multiInsertBuffers list.
 */
#define MAX_BUFFERED_TUPLES		1000

/* Trim the list of buffers back down to this number after flushing */
#define MAX_PARTITION_BUFFERS	32

/* Stores multi-insert data related to a single relation. */
typedef struct CopyMultiInsertBuffer
{
	TupleTableSlot *slots[MAX_BUFFERED_TUPLES]; /* Array to store tuples */
	ResultRelInfo *resultRelInfo;	/* ResultRelInfo for 'relid' */
	BulkInsertState bistate;	/* BulkInsertState for this rel */
	int			nused;			/* number of 'slots' containing tuples */
	uint64		linenos[MAX_BUFFERED_TUPLES];	/* Line # of tuple in bulk copy
												 * stream */
} CopyMultiInsertBuffer;

static BulkCopyState
BeginBulkCopy(Relation rel,
			  List *attnamelist);

static uint64
ExecuteBulkCopy(BulkCopyState cstate, int rowCount, int colCount,
				Datum *Values, bool *Nulls);

static List *
BulkCopyGetAttnums(TupleDesc tupDesc, Relation rel, List *attnamelist);

void BulkCopyErrorCallback(void *arg);

/*
 *	 BulkCopy - executes the Insert Bulk into a table
 *
 * Do not allow Bulk Copy if user doesn't have proper permission to access
 * the table or the specifically requested columns.
 */
void
BulkCopy(BulkCopyStmt *stmt, uint64 *processed)
{
	Relation	rel;
	TupleDesc	tupDesc;
	List	   *attnums;

	Assert (stmt && stmt->relation);

	/* Open and lock the relation, using the appropriate lock type. */
	rel = table_openrv(stmt->relation, RowExclusiveLock);

	tupDesc = RelationGetDescr(rel);

	/* Generate or convert list of columns to process. */
	attnums = BulkCopyGetAttnums(tupDesc, rel, stmt->attlist);

	/* Execute Bulk Copy within try-catch block. */
	PG_TRY();
	{
		if (!stmt->cstate)
			stmt->cstate = BeginBulkCopy(rel, attnums);
		
		*processed = ExecuteBulkCopy(stmt->cstate, stmt->nrow, stmt->ncol, stmt->Values, stmt->Nulls);
		stmt->rows_processed += *processed;
	}
	PG_CATCH();
	{
		/* For exact row which caused error, we have BulkCopyErrorCallback. */
		elog(WARNING, "Error while executing Bulk Copy. Error occured while processing at "
			"implicit Batch number: %d, Rows inserted in total: %ld", stmt->cur_batch_num, stmt->rows_processed);
		if (rel != NULL)
			table_close(rel, NoLock);
		PG_RE_THROW();
	}
	PG_END_TRY();

	elog(DEBUG2, "Bulk Copy Progress: Successfully inserted implicit number of batches: %d, "
		"number of rows inserted in total: %ld, "
		"number of rows inserted in current batch: %ld",
		stmt->cur_batch_num, stmt->rows_processed, *processed);

	if (rel != NULL)
		table_close(rel, NoLock);
}


/*
 * BulkCopyGetAttnums - build an integer list of attnums to be copied
 *
 * The input attnamelist is either the user-specified column list,
 * or NIL if there was none (in which case we want all the non-dropped
 * columns).
 *
 * We don't include generated columns in the generated full list and we don't
 * allow them to be specified explicitly.
 *
 * rel can be NULL ... it's only used for error reports.
 */
static List *
BulkCopyGetAttnums(TupleDesc tupDesc, Relation rel, List *attnamelist)
{
	List	   *attnums = NIL;

	if (attnamelist == NIL)
	{
		/* Generate default column list. */
		int			attr_count = tupDesc->natts;
		int			i;

		for (i = 0; i < attr_count; i++)
		{
			if (TupleDescAttr(tupDesc, i)->attisdropped)
				continue;
			if (TupleDescAttr(tupDesc, i)->attgenerated)
				continue;
			attnums = lappend_int(attnums, i + 1);
		}
	}
	else
	{
		/* Validate the user-supplied list and extract attnums. */
		ListCell   *l;

		foreach(l, attnamelist)
		{
			char	   *name = (char *)lfirst(l);
			int			attnum;
			int			i;

			/* Lookup column name. */
			attnum = InvalidAttrNumber;
			for (i = 0; i < tupDesc->natts; i++)
			{
				Form_pg_attribute att = TupleDescAttr(tupDesc, i);

				if (att->attisdropped)
					continue;
				if (namestrcmp(&(att->attname), name) == 0)
				{
					if (att->attgenerated)
						ereport(ERROR,
								(errcode(ERRCODE_INVALID_COLUMN_REFERENCE),
								 errmsg("column \"%s\" is a Computed column",
										name),
								 errdetail("Computed columns cannot be used in BULK COPY.")));
					else if (is_tsql_rowversion_or_timestamp_datatype_hook && is_tsql_rowversion_or_timestamp_datatype_hook(att->atttypid))
						ereport(ERROR,
								(errcode(ERRCODE_INVALID_COLUMN_REFERENCE),
									errmsg("column \"%s\" is a ROWVERSION/TIMESTAMP column",
										name),
									errdetail("ROWVERSION/TIMESTAMP columns cannot be used in BULK COPY.")));
					
					attnum = att->attnum;
					break;
				}
			}
			if (attnum == InvalidAttrNumber)
			{
				if (rel != NULL)
					ereport(ERROR,
							(errcode(ERRCODE_UNDEFINED_COLUMN),
							 errmsg("column \"%s\" of relation \"%s\" does not exist",
									name, RelationGetRelationName(rel))));
				else
					ereport(ERROR,
							(errcode(ERRCODE_UNDEFINED_COLUMN),
							 errmsg("column \"%s\" does not exist",
									name)));
			}
			/* Check for duplicates. */
			if (list_member_int(attnums, attnum))
				ereport(ERROR,
						(errcode(ERRCODE_DUPLICATE_COLUMN),
						 errmsg("column \"%s\" specified more than once",
								name)));
			attnums = lappend_int(attnums, attnum);
		}
	}

	return attnums;
}

/*
 * BulkCopyErrorCallback - error context callback for Bulk Copy
 *
 * The argument for the error context must be BulkCopyState.
 */
void
BulkCopyErrorCallback(void *arg)
{
	BulkCopyState cstate = (BulkCopyState) arg;
	errcontext("Bulk Copy for %s, row: %ld  (doesn't take implicit batching into consideration)",
				cstate->cur_relname,  cstate->cur_rowno);
}

/*
 * Allocate memory and initialize a new CopyMultiInsertBuffer for this
 * ResultRelInfo.
 */
static CopyMultiInsertBuffer *
CopyMultiInsertBufferInit(ResultRelInfo *rri)
{
	CopyMultiInsertBuffer *buffer;

	buffer = (CopyMultiInsertBuffer *) palloc(sizeof(CopyMultiInsertBuffer));
	memset(buffer->slots, 0, sizeof(TupleTableSlot *) * MAX_BUFFERED_TUPLES);
	buffer->resultRelInfo = rri;
	buffer->bistate = GetBulkInsertState();
	buffer->nused = 0;

	return buffer;
}

/*
 * Make a new buffer for this ResultRelInfo.
 * Code is copied from src/backend/commands/copyfrom.c
 */
static inline void
CopyMultiInsertInfoSetupBuffer(CopyMultiInsertInfo *miinfo,
							   ResultRelInfo *rri)
{
	CopyMultiInsertBuffer *buffer;

	buffer = CopyMultiInsertBufferInit(rri);

	/* Setup back-link so we can easily find this buffer again. */
	rri->ri_CopyMultiInsertBuffer = buffer;
	/* Record that we're tracking this buffer. */
	miinfo->multiInsertBuffers = lappend(miinfo->multiInsertBuffers, buffer);
}

/*
 * Initialize an already allocated CopyMultiInsertInfo.
 *
 * If rri is a non-partitioned table then a CopyMultiInsertBuffer is set up
 * for that table.
 */
static void
CopyMultiInsertInfoInit(CopyMultiInsertInfo *miinfo, ResultRelInfo *rri,
						BulkCopyState cstate, EState *estate, CommandId mycid,
						int ti_options)
{
	miinfo->multiInsertBuffers = NIL;
	miinfo->bufferedTuples = 0;
	miinfo->cstate = cstate;
	miinfo->estate = estate;
	miinfo->mycid = mycid;
	miinfo->ti_options = ti_options;

	/*
	 * Only setup the buffer when not dealing with a partitioned table.
	 * Buffers for partitioned tables will just be setup when we need to send
	 * tuples their way for the first time.
	 */
	if (rri->ri_RelationDesc->rd_rel->relkind != RELKIND_PARTITIONED_TABLE)
		CopyMultiInsertInfoSetupBuffer(miinfo, rri);
}

/*
 * Returns true if the buffers are full.
 * Code is copied from src/backend/commands/copyfrom.c
 */
static inline bool
CopyMultiInsertInfoIsFull(CopyMultiInsertInfo *miinfo)
{
	if (miinfo->bufferedTuples >= MAX_BUFFERED_TUPLES)
		return true;
	return false;
}

/*
 * Returns true if we have no buffered tuples.
 * Code is copied from src/backend/commands/copyfrom.c
 */
static inline bool
CopyMultiInsertInfoIsEmpty(CopyMultiInsertInfo *miinfo)
{
	return miinfo->bufferedTuples == 0;
}

/*
 * Write the tuples stored in 'buffer' out to the table.
 */
static inline void
CopyMultiInsertBufferFlush(CopyMultiInsertInfo *miinfo,
						   CopyMultiInsertBuffer *buffer)
{
	MemoryContext oldcontext;
	int			i;
	uint64		save_cur_lineno;
	BulkCopyState cstate = miinfo->cstate;
	EState	   *estate = miinfo->estate;
	CommandId	mycid = miinfo->mycid;
	int			ti_options = miinfo->ti_options;
	int			nused = buffer->nused;
	ResultRelInfo *resultRelInfo = buffer->resultRelInfo;
	TupleTableSlot **slots = buffer->slots;

	/*
	 * Print error context information correctly, if one of the operations
	 * below fails.
	 */
	save_cur_lineno = cstate->cur_rowno;

	/*
	 * table_multi_insert may leak memory, so switch to short-lived memory
	 * context before calling it.
	 */
	oldcontext = MemoryContextSwitchTo(GetPerTupleMemoryContext(estate));
	table_multi_insert(resultRelInfo->ri_RelationDesc,
					   slots,
					   nused,
					   mycid,
					   ti_options,
					   buffer->bistate);
	MemoryContextSwitchTo(oldcontext);

	for (i = 0; i < nused; i++)
	{
		/*
		 * If there are any indexes, update them for all the inserted tuples.
		 */
		if (resultRelInfo->ri_NumIndices > 0)
		{
			List	   *recheckIndexes;

			cstate->cur_rowno = buffer->linenos[i];
			recheckIndexes =
				ExecInsertIndexTuples(resultRelInfo,
									  buffer->slots[i], estate, false, false,
									  NULL, NIL);
			list_free(recheckIndexes);
		}

		ExecClearTuple(slots[i]);
	}

	/* Mark that all slots are free. */
	buffer->nused = 0;

	/* reset cur_rowno */
	cstate->cur_rowno = save_cur_lineno;
}

/*
 * Drop used slots and free member for this buffer.
 *
 * The buffer must be flushed before cleanup.
 * Code is copied from src/backend/commands/copyfrom.c
 */
static inline void
CopyMultiInsertBufferCleanup(CopyMultiInsertInfo *miinfo,
							 CopyMultiInsertBuffer *buffer)
{
	int			i;

	/* Ensure buffer was flushed. */
	Assert(buffer->nused == 0);

	/* Remove back-link to ourself. */
	buffer->resultRelInfo->ri_CopyMultiInsertBuffer = NULL;

	FreeBulkInsertState(buffer->bistate);

	/* Since we only create slots on demand, just drop the non-null ones. */
	for (i = 0; i < MAX_BUFFERED_TUPLES && buffer->slots[i] != NULL; i++)
		ExecDropSingleTupleTableSlot(buffer->slots[i]);

	table_finish_bulk_insert(buffer->resultRelInfo->ri_RelationDesc,
							 miinfo->ti_options);

	pfree(buffer);
}

/*
 * Write out all stored tuples in all buffers out to the tables.
 *
 * Once flushed we also trim the tracked buffers list down to size by removing
 * the buffers created earliest first.
 *
 * Callers should pass 'curr_rri' as the ResultRelInfo that's currently being
 * used.  When cleaning up old buffers we'll never remove the one for
 * 'curr_rri'.
 * Code is copied from src/backend/commands/copyfrom.c
 */
static inline void
CopyMultiInsertInfoFlush(CopyMultiInsertInfo *miinfo, ResultRelInfo *curr_rri)
{
	ListCell   *lc;

	foreach(lc, miinfo->multiInsertBuffers)
	{
		CopyMultiInsertBuffer *buffer = (CopyMultiInsertBuffer *) lfirst(lc);

		CopyMultiInsertBufferFlush(miinfo, buffer);
	}

	miinfo->bufferedTuples = 0;

	/*
	 * Trim the list of tracked buffers down if it exceeds the limit.  Here we
	 * remove buffers starting with the ones we created first.  It seems less
	 * likely that these older ones will be needed than the ones that were
	 * just created.
	 */
	while (list_length(miinfo->multiInsertBuffers) > MAX_PARTITION_BUFFERS)
	{
		CopyMultiInsertBuffer *buffer;

		buffer = (CopyMultiInsertBuffer *) linitial(miinfo->multiInsertBuffers);

		/*
		 * We never want to remove the buffer that's currently being used, so
		 * if we happen to find that then move it to the end of the list.
		 */
		if (buffer->resultRelInfo == curr_rri)
		{
			miinfo->multiInsertBuffers = list_delete_first(miinfo->multiInsertBuffers);
			miinfo->multiInsertBuffers = lappend(miinfo->multiInsertBuffers, buffer);
			buffer = (CopyMultiInsertBuffer *) linitial(miinfo->multiInsertBuffers);
		}

		CopyMultiInsertBufferCleanup(miinfo, buffer);
		miinfo->multiInsertBuffers = list_delete_first(miinfo->multiInsertBuffers);
	}
}

/*
 * Cleanup allocated buffers and free memory.
 */
static inline void
CopyMultiInsertInfoCleanup(CopyMultiInsertInfo *miinfo)
{
	ListCell   *lc;

	foreach(lc, miinfo->multiInsertBuffers)
		CopyMultiInsertBufferCleanup(miinfo, lfirst(lc));

	list_free(miinfo->multiInsertBuffers);
}

/*
 * Get the next TupleTableSlot that the next tuple should be stored in.
 *
 * Callers must ensure that the buffer is not full.
 *
 * Note: 'miinfo' is unused but has been included for consistency with the
 * other functions in this area.
 * Code is copied from src/backend/commands/copyfrom.c
 */
static inline TupleTableSlot *
CopyMultiInsertInfoNextFreeSlot(CopyMultiInsertInfo *miinfo,
								ResultRelInfo *rri)
{
	CopyMultiInsertBuffer *buffer = rri->ri_CopyMultiInsertBuffer;
	int			nused = buffer->nused;

	Assert(buffer != NULL);
	Assert(nused < MAX_BUFFERED_TUPLES);

	if (buffer->slots[nused] == NULL)
		buffer->slots[nused] = table_slot_create(rri->ri_RelationDesc, NULL);
	return buffer->slots[nused];
}

/*
 * Record the previously reserved TupleTableSlot that was reserved by
 * CopyMultiInsertInfoNextFreeSlot as being consumed.
 * Code is copied from src/backend/commands/copyfrom.c
 */
static inline void
CopyMultiInsertInfoStore(CopyMultiInsertInfo *miinfo, ResultRelInfo *rri,
						 TupleTableSlot *slot, uint64 lineno)
{
	CopyMultiInsertBuffer *buffer = rri->ri_CopyMultiInsertBuffer;

	Assert(buffer != NULL);
	Assert(slot == buffer->slots[buffer->nused]);

	/* Store the line number so we can properly report any errors later */
	buffer->linenos[buffer->nused] = lineno;

	/* Record this slot as being used */
	buffer->nused++;

	/* Update how many tuples are stored and their size */
	miinfo->bufferedTuples++;
}

/*
 * ExecuteBulkCopy - Carry out the insertion for the rows provided.
 */
static uint64
ExecuteBulkCopy(BulkCopyState cstate, int rowCount, int colCount,
				Datum *Values, bool *Nulls)
{
	int cur_index = 0;
	int cur_row_in_batch = 0;
	
	ExprContext *econtext;
	MemoryContext oldcontext = CurrentMemoryContext;

	ErrorContextCallback errcallback;
	int64		processed = 0;
	int		   *defmap = cstate->defmap;
	ExprState **defexprs = cstate->defexprs;

	Assert(cstate->rel);
	Assert(list_length(cstate->range_table) == 1);

	/*
	 * The target must be a plain, foreign, or partitioned relation, or have
	 * an INSTEAD OF INSERT row trigger.
	 */
	if (cstate->rel->rd_rel->relkind != RELKIND_RELATION &&
		cstate->rel->rd_rel->relkind != RELKIND_FOREIGN_TABLE &&
		cstate->rel->rd_rel->relkind != RELKIND_PARTITIONED_TABLE &&
		!(cstate->rel->trigdesc &&
		  cstate->rel->trigdesc->trig_insert_instead_row))
	{
		if (cstate->rel->rd_rel->relkind == RELKIND_VIEW)
			ereport(ERROR,
					(errcode(ERRCODE_WRONG_OBJECT_TYPE),
					 errmsg("cannot bulk copy to view \"%s\"",
							RelationGetRelationName(cstate->rel))));
		else if (cstate->rel->rd_rel->relkind == RELKIND_MATVIEW)
			ereport(ERROR,
					(errcode(ERRCODE_WRONG_OBJECT_TYPE),
					 errmsg("cannot bulk copy to materialized view \"%s\"",
							RelationGetRelationName(cstate->rel))));
		else if (cstate->rel->rd_rel->relkind == RELKIND_SEQUENCE)
			ereport(ERROR,
					(errcode(ERRCODE_WRONG_OBJECT_TYPE),
					 errmsg("cannot bulk copy to sequence \"%s\"",
							RelationGetRelationName(cstate->rel))));
		else
			ereport(ERROR,
					(errcode(ERRCODE_WRONG_OBJECT_TYPE),
					 errmsg("cannot bulk copy to non-table relation \"%s\"",
							RelationGetRelationName(cstate->rel))));
	}

	ExecOpenIndices(cstate->resultRelInfo, false);

	econtext = GetPerTupleExprContext(cstate->estate);

	/* Set up callback to identify error line number. */
	errcallback.callback = BulkCopyErrorCallback;
	errcallback.arg = (void *) cstate;
	errcallback.previous = error_context_stack;
	error_context_stack = &errcallback;

	for (;;)
	{
		TupleTableSlot *myslot;

		CHECK_FOR_INTERRUPTS();

		/*
		 * Reset the per-tuple exprcontext. We do this after every tuple, to
		 * clean-up after expression evaluations etc.
		 */
		ResetPerTupleExprContext(cstate->estate);

		Assert(cstate->resultRelInfo == cstate->target_resultRelInfo);

		myslot = CopyMultiInsertInfoNextFreeSlot(&cstate->multiInsertInfo, cstate->resultRelInfo);

		/*
		 * Switch to per-tuple context before building the TupleTableSlot, which does
		 * evaluate default expressions etc. and requires per-tuple context.
		 */
		MemoryContextSwitchTo(GetPerTupleMemoryContext(cstate->estate));

		ExecClearTuple(myslot);

		/*
		 * Directly store the Values/Nulls array in the slot.
		 * Since Values/Nulls are flattened arrays, we extract only the next row's
		 * values and store it in the slot.
		 */
		if (cur_index < rowCount * colCount)
		{
			/* Initialize all values for row to NULL. */
			MemSet(myslot->tts_values, 0, myslot->tts_tupleDescriptor->natts * sizeof(Datum));
			MemSet(myslot->tts_isnull, false, myslot->tts_tupleDescriptor->natts * sizeof(bool));

			/* colCount could be less than natts if user wants to insert only in a subset of columns. */
			for (int i = 0, j = 0; i < myslot->tts_tupleDescriptor->natts && j <= colCount; i++)
			{
				if (!list_member_int(cstate->attnumlist, i + 1))
				{
					/*
					 * If there is an identity column then we should insert the value for seuqence.
					 * This is to be done only when we do not receive any data for this column,
					 * otherwise we insert the data we receive.
					 */
					if (cstate->seq_index == i)
					{
						myslot->tts_values[i] = Int64GetDatum(nextval_internal(cstate->seqid, true));
					}
					else
						myslot->tts_isnull[i] = true;
				}
				else
				{
					/* j will never be >= colCount since that is handled by protocol. */
					if (Nulls[cur_row_in_batch * colCount + j])
						myslot->tts_isnull[i] = Nulls[cur_row_in_batch * colCount + j];
					else
					{
						myslot->tts_values[i] = Values[cur_row_in_batch * colCount + j];
					}
					j++;
					/*
					 * We increment cur_index only for the columns we received data for.
					 * We need not check for overflow (cur_index < rowCount * colCount)
					 * for each loop since that is handled by the protocol.
					 */
					cur_index++;
				}
			}
			cur_row_in_batch++;
			cstate->cur_rowno++;

			/*
			 * Now compute and insert any defaults available for the columns not
			 * provided by the input data.  Anything not processed here or above will
			 * remain NULL.
			 */
			for (int i = 0; i < cstate->num_defaults; i++)
			{
				/*
				 * The caller must supply econtext and have switched into the
				 * per-tuple memory context in it.
				 */
				Assert(econtext != NULL);
				Assert(CurrentMemoryContext == econtext->ecxt_per_tuple_memory);

				if (myslot->tts_isnull[defmap[i]] && (!insert_bulk_keep_nulls || cstate->rv_index == defmap[i]))
					myslot->tts_values[defmap[i]] = ExecEvalExpr(defexprs[i], econtext,
													&myslot->tts_isnull[defmap[i]]);
			}
		}
		else
			break;

		ExecStoreVirtualTuple(myslot);

		/*
		 * Constraints and where clause might reference the tableoid column,
		 * so (re-)initialize tts_tableOid before evaluating them.
		 */
		myslot->tts_tableOid = RelationGetRelid(cstate->target_resultRelInfo->ri_RelationDesc);

		MemoryContextSwitchTo(oldcontext);

		/* Compute stored generated columns */
		if (cstate->resultRelInfo->ri_RelationDesc->rd_att->constr &&
			cstate->resultRelInfo->ri_RelationDesc->rd_att->constr->has_generated_stored)
			ExecComputeStoredGenerated(cstate->resultRelInfo, cstate->estate, myslot,
										CMD_INSERT);

		/*
		 * If the target is a plain table, check the constraints of
		 * the tuple.
		 */
		if (cstate->resultRelInfo->ri_RelationDesc->rd_att->constr)
			ExecConstraints(cstate->resultRelInfo, myslot, cstate->estate);

		/*
		 * The slot previously might point into the per-tuple
		 * context. For batching it needs to be longer lived.
		 */
		ExecMaterializeSlot(myslot);	

		/*
		 * Store the slot in the multi-insert buffer.
		 * Add this tuple to the tuple buffer.
		 */
		CopyMultiInsertInfoStore(&cstate->multiInsertInfo,
									cstate->resultRelInfo, myslot,
									cstate->cur_rowno);

		/* Update the number of rows processed. */
		processed++;

		/*
		 * If enough inserts have queued up, then flush all
		 * buffers out to the table.
		 */
		if (CopyMultiInsertInfoIsFull(&cstate->multiInsertInfo))
			CopyMultiInsertInfoFlush(&cstate->multiInsertInfo, cstate->resultRelInfo);
	}

	/* Done, clean up. */
	error_context_stack = errcallback.previous;

	MemoryContextSwitchTo(oldcontext);

	return processed;
}

/*
 * BeginBulkCopy - Setup required before we actually execute the BULk COPY.
 *
 * 'rel': Used as a template for the tuples
 * 'attnums': Integer list of attnums.
 *
 * Returns a BulkCopyState, to be passed to ExecuteBulkCopy and related functions.
 */
static BulkCopyState
BeginBulkCopy(Relation rel,
			  List *attnums)
{
	BulkCopyState cstate;
	TupleDesc	tupDesc;
	AttrNumber	num_phys_attrs,
				num_defaults;
	int			attnum;
	int			ti_options = 0; /* start with default options for insert */
	int		   *defmap;
	ExprState **defexprs;
	MemoryContext oldcontext;
	ParseNamespaceItem *nsitem;
	RangeTblEntry *rte;
	ParseState *pstate = make_parsestate(NULL);
	ListCell   *cur;

	nsitem = addRangeTableEntryForRelation(pstate, rel, RowExclusiveLock,
											NULL, false, false);
	rte = nsitem->p_rte;
	rte->requiredPerms = ACL_INSERT;

	foreach(cur, attnums)
	{
		int			attno = lfirst_int(cur) - FirstLowInvalidHeapAttributeNumber;
		rte->insertedCols = bms_add_member(rte->insertedCols, attno);
	}

	/* Check access permissions. */
	ExecCheckRTPerms(pstate->p_rtable, true);

	/* Permission check for row security policies. */
	if (check_enable_rls(rte->relid, InvalidOid, false) == RLS_ENABLED)
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				errmsg("Bulk Copy not supported with row-level security"),
				errhint("Use INSERT statements instead.")));

	/* Check read-only transaction and parallel mode. */
	if (XactReadOnly && !rel->rd_islocaltemp)
		PreventCommandIfReadOnly("BULK LOAD");

	/* Allocate workspace and zero all fields */
	cstate = (BulkCopyStateData *) palloc0(sizeof(BulkCopyStateData));
	cstate->attnumlist = attnums;

	/*
	 * We allocate everything used by a cstate in a new memory context. This
	 * avoids memory leaks.
	 */
	cstate->copycontext = AllocSetContextCreate(CurrentMemoryContext,
												"BULK COPY",
												ALLOCSET_DEFAULT_SIZES);

	oldcontext = MemoryContextSwitchTo(cstate->copycontext);

	/* Initialize state variables */
	cstate->rel = rel;
	cstate->cur_relname = RelationGetRelationName(cstate->rel);
	cstate->cur_rowno = 0;
	cstate->seq_index = -1;
	cstate->rv_index = -1;

	/* Assign range table. */
	cstate->range_table = pstate->p_rtable;

	tupDesc = RelationGetDescr(cstate->rel);
	num_phys_attrs = tupDesc->natts;
	num_defaults = 0;

	/*
	 * Pick up the required catalog information for each attribute in the
	 * relation, including the info about defaults and constraints.
	 */
	defmap = (int *) palloc(num_phys_attrs * sizeof(int));
	defexprs = (ExprState **) palloc(num_phys_attrs * sizeof(ExprState *));

	for (attnum = 1; attnum <= num_phys_attrs; attnum++)
	{
		Form_pg_attribute att = TupleDescAttr(tupDesc, attnum - 1);

		/* We don't need info for dropped attributes */
		if (att->attisdropped)
			continue;

		/* Save the index for the identity column */
		if (att->attidentity)
		{
			cstate->seq_index = attnum - 1;
			cstate->seqid = getIdentitySequence(RelationGetRelid(cstate->rel), attnum, false);
		}
		/* Get default info if needed */
		else if (!att->attgenerated && att->atthasdef)
		{
			Expr	   *defexpr = (Expr *) build_column_default(cstate->rel,
																attnum);
			
			/* Save the index for the rowversion datatype */
			if (is_tsql_rowversion_or_timestamp_datatype_hook && is_tsql_rowversion_or_timestamp_datatype_hook(att->atttypid))
				cstate->rv_index = attnum - 1;

			/* Use default value if one exists */
			if (defexpr != NULL)
			{
				/* Run the expression through planner */
				defexpr = expression_planner(defexpr);

				/* Initialize executable expression in copycontext */
				defexprs[num_defaults] = ExecInitExpr(defexpr, NULL);
				defmap[num_defaults] = attnum - 1;
				num_defaults++;
			}
		}
	}

	/* We keep those variables in cstate. */
	cstate->defmap = defmap;
	cstate->defexprs = defexprs;
	cstate->num_defaults = num_defaults;


	cstate->estate = CreateExecutorState(); /* for ExecConstraints() */
	cstate->bistate = NULL;
	cstate->mycid = GetCurrentCommandId(true);

	cstate->multiInsertInfo.multiInsertBuffers = NIL;
	cstate->multiInsertInfo.bufferedTuples = 0;
	cstate->multiInsertInfo.cstate = NIL;
	cstate->multiInsertInfo.estate = NIL;
	cstate->multiInsertInfo.mycid = 0;
	cstate->multiInsertInfo.ti_options = 0;

	Assert(cstate->rel);
	Assert(list_length(cstate->range_table) == 1);

	/*
	 * If the target file is new-in-transaction, we assume that checking FSM
	 * for free space is a waste of time.  This could possibly be wrong, but
	 * it's unlikely.
	 */
	if (RELKIND_HAS_STORAGE(cstate->rel->rd_rel->relkind) &&
		(cstate->rel->rd_createSubid != InvalidSubTransactionId ||
		 cstate->rel->rd_firstRelfilenodeSubid != InvalidSubTransactionId))
		ti_options |= TABLE_INSERT_SKIP_FSM;

	/*
	* We need a ResultRelInfo so we can use the regular executor's
	* index-entry-making machinery.  (There used to be a huge amount of code
	* here that basically duplicated execUtils.c ...).
	*/
	ExecInitRangeTable(cstate->estate, cstate->range_table);
	cstate->resultRelInfo = cstate->target_resultRelInfo = makeNode(ResultRelInfo);
	ExecInitResultRelation(cstate->estate, cstate->resultRelInfo, 1);

	/* Verify the named relation is a valid target for INSERT. */
	CheckValidResultRel(cstate->resultRelInfo, CMD_INSERT);

	CopyMultiInsertInfoInit(&cstate->multiInsertInfo, cstate->resultRelInfo, cstate,
							cstate->estate, cstate->mycid, ti_options);

	MemoryContextSwitchTo(oldcontext);

	return cstate;
}

/*
 * EndBulkCopy - Clean up storage and release resources for BULK COPY.
 */
void
EndBulkCopy(BulkCopyState cstate)
{
	if (cstate)
	{
		/* Flush any remaining bufferes out to the table. */
		if (!CopyMultiInsertInfoIsEmpty(&cstate->multiInsertInfo))
			CopyMultiInsertInfoFlush(&cstate->multiInsertInfo, NULL);
			
		if (cstate->bistate != NULL)
			FreeBulkInsertState(cstate->bistate);

		ExecResetTupleTable(cstate->estate->es_tupleTable, false);

		/* Tear down the multi-insert buffer data. */
		CopyMultiInsertInfoCleanup(&cstate->multiInsertInfo);

		/* Close the result relations, */
		ExecCloseResultRelations(cstate->estate);
		ExecCloseRangeTableRelations(cstate->estate);

		FreeExecutorState(cstate->estate);

		MemoryContextDelete(cstate->copycontext);
		pfree(cstate);
	}
}
