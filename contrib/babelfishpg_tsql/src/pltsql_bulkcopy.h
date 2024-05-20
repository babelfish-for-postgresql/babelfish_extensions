#include "access/heapam.h"

typedef struct BulkCopyStateData *BulkCopyState;

/*
 * Stores one or many CopyMultiInsertBuffers and details about the size and
 * number of tuples which are stored in them.  This allows multiple buffers to
 * exist at once when COPYing into a partitioned table.
 */
typedef struct CopyMultiInsertInfo
{
	List	   *multiInsertBuffers; /* List of tracked CopyMultiInsertBuffers */
	int			bufferedTuples; /* number of tuples buffered over all buffers */
	BulkCopyState cstate;		/* Bulk Copy state for this
								 * CopyMultiInsertInfo */
	EState	   *estate;			/* Executor state used for BULK COPY */
	CommandId	mycid;			/* Command Id used for BULK COPY */
	int			ti_options;		/* table insert options */
} CopyMultiInsertInfo;

/*
 * This struct contains all the state variables used throughout a BULK COPY
 * operation.
 */
typedef struct BulkCopyStateData
{
	Relation	rel;			/* relation to insert into */
	List	   *attnumlist;		/* integer list of attnums to insert */

	EState	   *estate;
	CommandId	mycid;
	BulkInsertState bistate;
	CopyMultiInsertInfo multiInsertInfo;
	ResultRelInfo *resultRelInfo;
	ResultRelInfo *target_resultRelInfo;

	/* these are just for error messages, see BulkCopyErrorCallback */
	const char *cur_relname;	/* table name for error messages */
	uint64		cur_rowno;		/* row number for error messages */

	/*
	 * Working state
	 */
	MemoryContext copycontext;	/* per-copy execution context */

	AttrNumber	num_defaults;
	int		   *defmap;			/* array of default att numbers */
	ExprState **defexprs;		/* array of default att expressions */
	List	   *range_table;
	int			seq_index;		/* index for an identity column */
	Oid			seqid;			/* oid of the sequence for an identity column */
	int			rv_index;		/* index for a rowversion datatype column */

	/*
	 * Keep track of Datums, which are placed into slots, but not yet flushed
	 * with table_multi_insert, to be able to free them after flush happens.
	 * Incoming Values and ValueAllocFlags are appended to these 2 lists.
	 * Lists are trimmed after the flush in CleanupBufferedValuesAfterFlush.
	 * Max size of these lists is: 
	 *     (MAX_BUFFERED_TUPLES + [last incoming batch size]) * colCount
	 */
	List	   *bufferedValues;			/* List of Values (as Datums) that need to be
								 * cleaned up after the executor flush */
	List	   *bufferedValueAllocFlags;			/* List of flags, set to true when
								 * corresponding Datum in Values list was allocated on heap
								 * with palloc */

} BulkCopyStateData;

/* ----------------------
 *  Bulk Copy Statement
 * ----------------------
 */
typedef struct BulkCopyStmt
{
	RangeVar   *relation;		/* the relation to copy */
	List	   *attlist;		/* List of column names (as Strings), or NIL
								 * for all columns */

	int			cur_batch_num;	/* Inserts can be batched implicitly depending
								 * on protocol side, we should hold a counter
								 * for the current batch */
	uint64		rows_processed; /* Number of rows processed helps in tracking
								 * the progress */

	int			ncol;			/* Holds the number of columns */
	int			nrow;			/* Holds the number of rows for the current
								 * batch */
	Datum	   *Values;			/* List of Values (as Datums) that need to be
								 * inserted for the current batch */
	bool	   *Nulls;			/* List of flags, set to true when corresponding
								 * Datum in Values list is NULL */
	bool	   *ValueAllocFlags;			/* List of flags, set to true when
								 * corresponding Datum in Values list was allocated on heap
								 * with palloc */
	BulkCopyState cstate;		/* Contains all the state variables used
								 * throughout a BULK COPY */
} BulkCopyStmt;

extern void BulkCopy(BulkCopyStmt *stmt, uint64 *processed);
extern void EndBulkCopy(BulkCopyState cstate, int colCount);
