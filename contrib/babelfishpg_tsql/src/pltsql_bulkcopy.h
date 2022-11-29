/*
 * This struct contains all the state variables used throughout a BULK COPY
 * operation.
 */
typedef struct BulkCopyStateData
{
	Relation	rel;			/* relation to insert into */
	List	   *attnumlist;		/* integer list of attnums to insert */


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
	int 		seq_index; 		/* index for an identity column */
	Oid			seqid; 			/* oid of the sequence for an identity column */
	int			rv_index;		/* index for a rowversion datatype column */

} BulkCopyStateData;
typedef struct BulkCopyStateData *BulkCopyState;

/* ----------------------
 *  Bulk Copy Statement
 * ----------------------
 */
typedef struct BulkCopyStmt
{
	RangeVar   *relation;		/* the relation to copy */
	List	   *attlist;		/* List of column names (as Strings), or NIL
								 * for all columns */

	int 		cur_batch_num;  /* Inserts can be batched implicitly depending on protocol side,
								 * we should hold a counter for the current batch */
	uint64 		rows_processed; /* Number of rows processed helps in tracking the progress */

	int 		ncol;			/* Holds the number of columns */
	int 		nrow;			/* Holds the number of rows for the current batch */
	Datum	   *Values;			/* List of Values (as Datums) that need to be inserted
								 * for the current batch */
	bool 	   *Nulls;			/* List of Nulls (as Datums) that need to be inserted
								 * for the current batch */
	BulkCopyState cstate;   /* Contains all the state variables used throughout a BULK COPY */
} BulkCopyStmt;

extern void BulkCopy(BulkCopyStmt *stmt, uint64 *processed);
extern void EndBulkCopy(BulkCopyState cstate);