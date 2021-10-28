/*-------------------------------------------------------------------------
 *
 * tdsprinttup.c
 *	  Routines to print out tuples to the destination (both frontend
 *	  clients and standalone backends are supported here).
 *
 *
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * IDENTIFICATION
 *	  contrib/babelfishpg_tds/src/backend/tds/tdsprinttup.c
 *
 *-------------------------------------------------------------------------
 */

static void TdsPrinttupStartup(DestReceiver *self, int operation,
				 TupleDesc typeinfo);
static void TdsShutdown(DestReceiver *self);
static void TdsDestroy(DestReceiver *self);

/* ----------------------------------------------------------------
 *		tdsprinttup support
 * ----------------------------------------------------------------
 */

/* ----------------
 *	Maintain and use carefully
 *
 *	Private state for a printtup destination object
 *
 * NOTE: finfo is the lookup info for either typoutput or typsend, whichever
 * we are using for this column.
 * ----------------
 */
typedef struct
{								/* Per-attribute information */
	Oid			typoutput;		/* Oid for the type's text output fn */
	Oid			typsend;		/* Oid for the type's binary output fn */
	bool		typisvarlena;	/* is it varlena (ie possibly toastable)? */
	int16		format;			/* format code for this column */
	FmgrInfo	finfo;			/* Precomputed call info for output fn */
} PrinttupAttrInfo;

typedef struct
{
	DestReceiver pub;			/* publicly-known function pointers */
	Portal		portal;			/* the Portal we are printing from */
	bool		sendDescrip;	/* send RowDescription at startup? */
	TupleDesc	attrinfo;		/* The attr info we are set up for */
	int			nattrs;
	PrinttupAttrInfo *myinfo;	/* Cached info about each attr */
	StringInfoData buf;			/* output buffer (*not* in tmpcontext) */
	MemoryContext tmpcontext;	/* Memory context for per-row workspace */
} DR_printtup;


static void
TdsPrinttupStartup(DestReceiver *self, int operation, TupleDesc typeinfo)
{
	DR_printtup *myState = (DR_printtup *) self;
	Portal		portal = myState->portal;

	/*
	 * Create I/O buffer to be used for all messages.  This cannot be inside
	 * tmpcontext, since we want to re-use it across rows.
	 */
	initStringInfo(&myState->buf);

	/*
	 * Create a temporary memory context that we can reset once per row to
	 * recover palloc'd memory.  This avoids any problems with leaks inside
	 * datatype output routines, and should be faster than retail pfree's
	 * anyway.
	 */
	myState->tmpcontext = AllocSetContextCreate(CurrentMemoryContext,
												"printtup",
												ALLOCSET_DEFAULT_SIZES);

	TdsSendRowDescription(typeinfo,
							FetchPortalTargetList(portal),
							portal->formats);
	return;
}

/* ----------------
 *		printtup_shutdown
 * ----------------
 */
static void
TdsShutdown(DestReceiver *self)
{
	DR_printtup *myState = (DR_printtup *) self;

	TdsPrintTupShutdown();

	if (myState->myinfo)
		pfree(myState->myinfo);
	myState->myinfo = NULL;

	myState->attrinfo = NULL;

	if (myState->buf.data)
		pfree(myState->buf.data);
	myState->buf.data = NULL;

	if (myState->tmpcontext)
		MemoryContextDelete(myState->tmpcontext);
	myState->tmpcontext = NULL;
}

static void
TdsDestroy(DestReceiver *self)
{
	pfree(self);
}
