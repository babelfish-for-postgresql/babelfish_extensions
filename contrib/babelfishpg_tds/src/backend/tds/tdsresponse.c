/*-------------------------------------------------------------------------
 *
 * tdsresponse.c
 *	  TDS Listener functions for sending a TDS response
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  contrib/babelfishpg_tds/src/backend/tds/tdsresponse.c
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"
#include "varatt.h"

#include "access/htup_details.h"	/* for GETSTRUCT() to extract tuple data */
#include "access/printtup.h"	/* for SetRemoteDestReceiverParams() */
#include "access/xact.h"		/* for IsTransactionOrTransactionBlock() */
#include "access/genam.h"
#include "access/heapam.h"
#include "catalog/indexing.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_type.h"
#include "miscadmin.h"
#include "nodes/makefuncs.h"
#include "nodes/pathnodes.h"
#include "parser/parse_coerce.h"
#include "parser/parse_type.h"
#include "parser/parsetree.h"
#include "utils/fmgroids.h"
#include "utils/lsyscache.h"
#include "utils/syscache.h"
#include "utils/memdebug.h"
#include "utils/numeric.h"
#include "utils/portal.h"
#include "utils/rel.h"
#include "utils/syscache.h"

#include "src/include/tds_instr.h"
#include "src/include/tds_int.h"
#include "src/include/tds_protocol.h"
#include "src/include/tds_response.h"
#include "src/include/tds_timestamp.h"
#include "src/include/guc.h"

#define SP_FLAGS_WITHRECOMP			0x01
#define SP_FLAGS_NOMETADATA			0x02
#define	SP_FLAGS_REUSEMETADATA		0x04

/* ColInfo token flags */
#define COLUMN_STATUS_EXPRESSION		0x04
#define COLUMN_STATUS_KEY				0x08
#define COLUMN_STATUS_HIDDEN			0x10
#define COLUMN_STATUS_DIFFERENT_NAME	0x20

/* two possible values of rowstat column */
#define SP_CURSOR_FETCH_SUCCEEDED		0x0001
#define SP_CURSOR_FETCH_MISSING			0x0002

/* Numeirc operator OID from pg_proc.dat */
#define NUMERIC_ADD_OID 1724
#define NUMERIC_SUB_OID 1725
#define NUMERIC_MUL_OID 1726
#define NUMERIC_DIV_OID 1727
#define NUMERIC_MOD_OID 1728
#define NUMERIC_MOD_OID2 1729
#define NUMERIC_UPLUS_OID 1915
#define NUMERIC_UMINUS_OID 1771

#define Max(x, y)				((x) > (y) ? (x) : (y))
#define Min(x, y)				((x) < (y) ? (x) : (y))
#define ROWVERSION_SIZE 8
#define VARBINARY_MAX_SCALE 8000

/*
 * Local structures and functions copied from printtup.c
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

typedef struct TdsExecutionStateData
{
	int			current_stack;
	int			error_stack_offset;
	int			cur_error_number;
	int			cur_error_severity;
	int			cur_error_state;
} TdsExecutionStateData;

typedef TdsExecutionStateData *TdsExecutionState;

/* Local variables */
static bool TdsHavePendingDone = false;
static bool TdsPendingDoneNocount;
static uint8_t TdsPendingDoneToken;
static uint16_t TdsPendingDoneStatus;
static uint16_t TdsPendingDoneCurCmd;
static uint64_t TdsPendingDoneRowCnt;
static TdsExecutionState tds_estate = NULL;

/*
 * This denotes whether we've sent an error token and the next done token
 * should have the error flag marked.
 */
static bool markErrorFlag = false;

static TdsColumnMetaData *colMetaData = NULL;
static List *relMetaDataInfoList = NULL;

static Oid sys_vector_oid = InvalidOid;
static Oid sys_sparsevec_oid = InvalidOid;
static Oid sys_halfvec_oid = InvalidOid;
static Oid decimal_oid = InvalidOid;

static void FillTabNameWithNumParts(StringInfo buf, uint8 numParts, TdsRelationMetaDataInfo relMetaDataInfo);
static void FillTabNameWithoutNumParts(StringInfo buf, uint8 numParts, TdsRelationMetaDataInfo relMetaDataInfo);
static void SetTdsEstateErrorData(void);
static void ResetTdsEstateErrorData(void);
static void SetAttributesForColmetada(TdsColumnMetaData *col);
static int32 resolve_numeric_typmod_from_exp(Plan *plan, Node *expr);
static int32 resolve_numeric_typmod_outer_var(Plan *plan, AttrNumber attno);
static bool is_this_a_vector_datatype(Oid oid);

static inline void
SendPendingDone(bool more)
{
	/*
	 * If this is the last token, there better be at least one pending done
	 * token to send.  We also call this function after sending the prelogin
	 * response although we don't have any done token to send.  So just do
	 * this check once protocol code is initialized.
	 */
	Assert(!TdsRequestCtrl || more || TdsHavePendingDone);

	/*
	 * If this is the last token, then the done token should be either DONE or
	 * DONEPROC.
	 */
	Assert(!TdsRequestCtrl || more ||
		   (TdsPendingDoneToken == TDS_TOKEN_DONEPROC ||
			TdsPendingDoneToken == TDS_TOKEN_DONE));

	if (TdsHavePendingDone)
	{
		uint32_t	tdsVersion = GetClientTDSVersion();

		TdsHavePendingDone = false;

		/* In NOCOUNT=ON mode we need to suppress the DONE_COUNT */
		if (TdsPendingDoneNocount)
			TdsPendingDoneStatus &= ~TDS_DONE_COUNT;

		/* If done token follows error token then suppress DONE_COUNT */
		if (TdsPendingDoneStatus & TDS_DONE_ERROR)
			TdsPendingDoneStatus &= ~TDS_DONE_COUNT;

		if (more)
		{
			/* Suppress non-SELECT DONEINPROC while NOCOUNT=ON */
			if (TdsPendingDoneNocount &&
				TdsPendingDoneToken == TDS_TOKEN_DONEINPROC &&
				TdsPendingDoneCurCmd != TDS_CMD_SELECT)
			{
				return;
			}

			TdsPendingDoneStatus |= TDS_DONE_MORE;
		}

		/* extra handling if this follows an error token */
		if (tds_estate && (TdsPendingDoneStatus & TDS_DONE_ERROR))
		{
			/* TODO: If we've saved the error command type, send the same. */

			/*
			 * If we're sending a done token that follows an error token, then
			 * we must clear the error stack offset.  Because, after that
			 * we'll be back to normal execution.
			 */
			tds_estate->error_stack_offset = 0;

			/*
			 * If a statement throws an error, the row count should be always
			 * 0.
			 */
			Assert(TdsPendingDoneRowCnt == 0);
		}

		TDS_DEBUG(TDS_DEBUG3, "SendPendingDone: putbytes");
		TdsPutbytes(&TdsPendingDoneToken, sizeof(TdsPendingDoneToken));
		TdsPutbytes(&TdsPendingDoneStatus, sizeof(TdsPendingDoneStatus));
		TdsPutbytes(&TdsPendingDoneCurCmd, sizeof(TdsPendingDoneCurCmd));

		/*
		 * For Client TDS Version less than or equal to 7.1 Done Row Count is
		 * of 4 bytes and for TDS versions higher than 7.1 it is of 8 bytes.
		 */
		if (tdsVersion <= TDS_VERSION_7_1_1)
		{
			uint32_t	TdsPendingDoneRowCnt_32;

			if (TdsPendingDoneRowCnt > PG_UINT32_MAX)
				ereport(FATAL, (errmsg("Row Count execeeds UINT32_MAX")));
			else
				TdsPendingDoneRowCnt_32 = (int32_t) TdsPendingDoneRowCnt;
			TdsPutbytes(&TdsPendingDoneRowCnt_32, sizeof(TdsPendingDoneRowCnt_32));
		}
		else
			TdsPutbytes(&TdsPendingDoneRowCnt, sizeof(TdsPendingDoneRowCnt));
	}
}

/*
 * Given a relation, fetch the attributes number which are part of the primary
 * key on this table.
 */
static AttrNumber *
getPkeyAttnames(Relation rel, int16 *indnkeyatts)
{
	Relation	indexRelation;
	ScanKeyData skey;
	SysScanDesc scan;
	HeapTuple	indexTuple;
	int			i;
	AttrNumber *result = NULL;

	/* initialize indnkeyatts to 0 in case no primary key exists */
	*indnkeyatts = 0;

	/* Prepare to scan pg_index for entries having indrelid = this rel. */
	indexRelation = table_open(IndexRelationId, AccessShareLock);
	ScanKeyInit(&skey,
				Anum_pg_index_indrelid,
				BTEqualStrategyNumber, F_OIDEQ,
				ObjectIdGetDatum(RelationGetRelid(rel)));

	scan = systable_beginscan(indexRelation, IndexIndrelidIndexId, true,
							  NULL, 1, &skey);

	while (HeapTupleIsValid(indexTuple = systable_getnext(scan)))
	{
		Form_pg_index index = (Form_pg_index) GETSTRUCT(indexTuple);

		/* we're only interested if it is the primary key */
		if (index->indisprimary)
		{
			*indnkeyatts = index->indnkeyatts;
			if (*indnkeyatts > 0)
			{
				result = (AttrNumber *) palloc(*indnkeyatts * sizeof(AttrNumber));

				for (i = 0; i < *indnkeyatts; i++)
					result[i] = (AttrNumber) DatumGetInt16(index->indkey.values[i]);
			}
			break;
		}
	}

	systable_endscan(scan);
	table_close(indexRelation, AccessShareLock);

	return result;
}

/*
 * Fill Table Name With NumParts, a multi-part table name, which was introduced in
 * TDS 7.2 for Column Metadata Token and introduced in TDS 7.1 revision 1 for TableName Token.
 */
static void
FillTabNameWithNumParts(StringInfo buf, uint8 numParts, TdsRelationMetaDataInfo relMetaDataInfo)
{
	StringInfoData tempBuf;

	initStringInfo(&tempBuf);

	/*
	 * XXX: In case a multi-part table name is used in the query, we should
	 * send the same fully qualified name here in multiple parts.  For
	 * example, if the following format is used in query: select * from t1; we
	 * should send only part with partname 't1'.  However, if the following
	 * format is used: select * from [dbo].[t1]; we should send two parts with
	 * partname 'dbo' and 't1';
	 *
	 * In order to get this information, we definitely need some parser
	 * support. Probably, we can save this information in portal while parsing
	 * the table names.
	 *
	 * For now, always send it in two parts namespace.table name and hope that
	 * client won't complain about the same.
	 */

	appendBinaryStringInfo(buf, (char *) &numParts, sizeof(numParts));
	while (numParts-- > 0)
	{
		uint16_t	partNameLen;
		char	   *partName = relMetaDataInfo->partName[numParts];

		resetStringInfo(&tempBuf);
		TdsUTF8toUTF16StringInfo(&tempBuf, partName, strlen(partName));

		partNameLen = htoLE16((uint16_t) pg_mbstrlen(partName));
		appendBinaryStringInfo(buf, (char *) &partNameLen, sizeof(partNameLen));
		appendBinaryStringInfo(buf, tempBuf.data, tempBuf.len);
	}

	pfree(tempBuf.data);
}

/*
 * Fill Table Name Without NumParts, a single-part table name, for Protocol versions below
 * TDS 7.2 for Column Metadata Token and below TDS 7.1 revision 1 for TableName Token.
 */
static void
FillTabNameWithoutNumParts(StringInfo buf, uint8 numParts, TdsRelationMetaDataInfo relMetaDataInfo)
{
	uint16_t	TableNameLen = 0;
	StringInfoData tempBuf;
	char	   *tableName = "";

	initStringInfo(&tempBuf);

	/*
	 * NumParts and PartName are not included in the response for TDS protocol
	 * versions lower than 7.1 revision (including TDS 7.1 revision 1 in case
	 * of ColumnMetadata Token). If the Table Name is in parts then we create
	 * a single string and convert it to UTF16 before putting it on the wire.
	 * For example for a table dbo.t1 we should send one single tableName as
	 * dbo.t1
	 */

	while (numParts-- > 0)
		tableName = psprintf("%s.%s", tableName, relMetaDataInfo->partName[numParts]);

	if (strlen(tableName))
		tableName++;			/* skip the first '.' */
	TableNameLen += htoLE16((uint16_t) pg_mbstrlen(tableName));

	TdsUTF8toUTF16StringInfo(&tempBuf, tableName, strlen(tableName));
	appendBinaryStringInfo(buf, (char *) &TableNameLen, sizeof(TableNameLen));
	appendBinaryStringInfo(buf, tempBuf.data, tempBuf.len);

	pfree(tempBuf.data);
}

/*
 * Get the lookup info that TdsPrintTup() needs.
 * Code is copied from backend/access/common/printtup.c
 */
static void
PrintTupPrepareInfo(DR_printtup *myState, TupleDesc typeinfo, int numAttrs)
{
	int16	   *formats = myState->portal->formats;
	int			i;

	/* get rid of any old data */
	if (myState->myinfo)
		pfree(myState->myinfo);
	myState->myinfo = NULL;

	myState->attrinfo = typeinfo;
	myState->nattrs = numAttrs;
	if (numAttrs <= 0)
		return;

	myState->myinfo = (PrinttupAttrInfo *)
		palloc0(numAttrs * sizeof(PrinttupAttrInfo));

	for (i = 0; i < numAttrs; i++)
	{
		PrinttupAttrInfo *thisState = myState->myinfo + i;
		int16		format = (formats ? formats[i] : 0);
		Form_pg_attribute attr = TupleDescAttr(typeinfo, i);

		thisState->format = format;
		if (format == 0)
		{
			getTypeOutputInfo(attr->atttypid,
							  &thisState->typoutput,
							  &thisState->typisvarlena);
			fmgr_info(thisState->typoutput, &thisState->finfo);
		}
		else if (format == 1)
		{
			getTypeBinaryOutputInfo(attr->atttypid,
									&thisState->typsend,
									&thisState->typisvarlena);
			fmgr_info(thisState->typsend, &thisState->finfo);
		}
		else
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					 errmsg("unsupported format code: %d", format)));
	}
}

static int32
resolve_numeric_typmod_from_append_or_mergeappend(Plan *plan, AttrNumber attno)
{
	ListCell	*lc;
	int32		max_precision = 0,
				max_scale = 0,
				precision = 0,
				scale = 0,
				integralDigitCount = 0,
				typmod = -1,
				result_typmod = -1;
	List		*planlist = NIL;
	if (IsA(plan, Append))
	{
		planlist = ((Append *) plan)->appendplans;
	}
	else if(IsA(plan, MergeAppend))
	{
		planlist = ((MergeAppend *) plan)->mergeplans; 
	}

	Assert(planlist != NIL);
	foreach(lc, planlist)
	{
		TargetEntry *tle;
		Plan 		*outerplan = (Plan *) lfirst(lc);

		/* if outerplan is SubqueryScan then use actual subplan */
		if (IsA(outerplan, SubqueryScan))
			outerplan = ((SubqueryScan *)outerplan)->subplan;

		tle = get_tle_by_resno(outerplan->targetlist, attno);
		if (IsA(tle->expr, Var))
		{
			Var *var = (Var *)tle->expr;
			if (var->varno == OUTER_VAR)
			{
				typmod = resolve_numeric_typmod_outer_var(outerplan, var->varattno);
			}
			else
			{
				typmod = resolve_numeric_typmod_from_exp(outerplan, (Node *)tle->expr);
			}
		}
		else
		{
			typmod = resolve_numeric_typmod_from_exp(outerplan, (Node *)tle->expr);
		}
		if (typmod == -1)
			continue;
		scale = (typmod - VARHDRSZ) & 0xffff;
		precision = ((typmod - VARHDRSZ) >> 16) & 0xffff;
		integralDigitCount = Max(precision - scale, max_precision - max_scale);
		max_scale = Max(max_scale, scale);
		max_precision = integralDigitCount + max_scale;
		/*
		 * If max_precision is more than TDS_MAX_NUM_PRECISION then adjust precision
		 * to TDS_MAX_NUM_PRECISION at the cost of scale.
		 */
		if (max_precision > TDS_MAX_NUM_PRECISION)
		{
			max_scale = Max(0, max_scale - (max_precision - TDS_MAX_NUM_PRECISION));
			max_precision = TDS_MAX_NUM_PRECISION;
		}
		result_typmod = ((max_precision << 16) | max_scale) + VARHDRSZ;
	}
	/* If max_precision is still default then use tds specific defaults */
	if (result_typmod == -1)
	{
		result_typmod = ((tds_default_numeric_precision << 16) | tds_default_numeric_scale) + VARHDRSZ;
	}
	return result_typmod;
}

static int32
resolve_numeric_typmod_outer_var(Plan *plan, AttrNumber attno)
{
	TargetEntry	*tle;
	Plan		*outerplan = NULL;

	if (IsA(plan, Append) || IsA(plan, MergeAppend))
		return resolve_numeric_typmod_from_append_or_mergeappend(plan, attno);
	else
		outerplan = outerPlan(plan);

	/* if outerplan is SubqueryScan then use actual subplan */
	if (IsA(outerplan, SubqueryScan))
		outerplan = ((SubqueryScan *)outerplan)->subplan;

	/* outerplan must not be NULL */
	Assert(outerplan);
	tle = get_tle_by_resno(outerplan->targetlist, attno);
	if (IsA(tle->expr, Var))
	{
		Var *var = (Var *)tle->expr;
		if (var->varno == OUTER_VAR)
		{
			return resolve_numeric_typmod_outer_var(outerplan, var->varattno);
		}
	}
	return resolve_numeric_typmod_from_exp(outerplan, (Node *)tle->expr);
}

/*
 * is_numeric_datatype - returns bool if given datatype is numeric or decimal.
 */
static bool
is_numeric_datatype(Oid typid)
{
	if (typid == NUMERICOID)
	{
		return true;
	}
	if (!OidIsValid(decimal_oid))
	{
		TypeName *typename = makeTypeNameFromNameList(list_make2(makeString("sys"), makeString("decimal")));
		decimal_oid = LookupTypeNameOid(NULL, typename, false);
	}
	return decimal_oid == typid;
}

/* look for a typmod to return from a numeric expression */
static int32
resolve_numeric_typmod_from_exp(Plan *plan, Node *expr)
{
	if (expr == NULL)
		return -1;
	switch (nodeTag(expr))
	{
		case T_Param:
			{
				Param *param = (Param *) expr;
				if (!is_numeric_datatype(param->paramtype))
				{
					/* typmod is undefined */
					return -1;
				}
				else
				{
					return param->paramtypmod;
				}
			}
		case T_Const:
			{
				Const	   *con = (Const *) expr;
				Numeric		num;

				if (!is_numeric_datatype(con->consttype) || con->constisnull)
				{
					/* typmod is undefined */
					return -1;
				}
				else
				{
					num = (Numeric) con->constvalue;
					return numeric_get_typmod(num);
				}
			}
		case T_Var:
			{
				Var		   *var = (Var *) expr;

				/* If this var referes to tuple returned by its outer plan then find the original tle from it */
				if (var->varno == OUTER_VAR)
				{
					Assert(plan);
					return (resolve_numeric_typmod_outer_var(plan, var->varattno));
				}
				return var->vartypmod;
			}
		case T_OpExpr:
			{
				OpExpr	   *op = (OpExpr *) expr;
				Node	   *arg1,
						   *arg2 = NULL;
				int32		typmod1 = -1,
							typmod2 = -1;
				uint8_t		scale1,
							scale2,
							precision1,
							precision2;
				uint8_t		scale,
							precision;
				uint8_t		integralDigitCount = 0;

				/*
				 * If one of the operands is part of aggregate function SUM()
				 * or AVG(), set has_aggregate_operand to true; in those cases
				 * resultant precision and scale calculation would be a bit
				 * different
				 */
				bool		has_aggregate_operand = false;

				Assert(list_length(op->args) == 2 || list_length(op->args) == 1);
				if (list_length(op->args) == 2)
				{
					arg1 = linitial(op->args);
					arg2 = lsecond(op->args);
					typmod1 = resolve_numeric_typmod_from_exp(plan, arg1);
					typmod2 = resolve_numeric_typmod_from_exp(plan, arg2);
					scale1 = (typmod1 - VARHDRSZ) & 0xffff;
					precision1 = ((typmod1 - VARHDRSZ) >> 16) & 0xffff;
					scale2 = (typmod2 - VARHDRSZ) & 0xffff;
					precision2 = ((typmod2 - VARHDRSZ) >> 16) & 0xffff;
				}
				else if (list_length(op->args) == 1)
				{
					arg1 = linitial(op->args);
					typmod1 = resolve_numeric_typmod_from_exp(plan, arg1);
					scale1 = (typmod1 - VARHDRSZ) & 0xffff;
					precision1 = ((typmod1 - VARHDRSZ) >> 16) & 0xffff;
					scale2 = 0;
					precision2 = 0;
				}
				else
				{
					/*
					 * Shoudn't get here, just need this code to suppress the
					 * compiler warnings
					 */
					precision1 = tds_default_numeric_precision;
					precision2 = tds_default_numeric_precision;
					scale1 = tds_default_numeric_scale;
					scale2 = tds_default_numeric_scale;
				}

				/*
				 * BABEL-2048 Handling arithmetic overflow exception when one
				 * of the operands is of NON-numeric datatype. Use
				 * tds_default_numeric_precision/scale if both operands are
				 * without typmod which probabaly won't happen. If one of the
				 * operand doesn't have typmod, apply the same typmod as the
				 * other operand. This makes sense because it's equivalent to
				 * casting the operand without typmod to the other operand's
				 * type and typmod then do the operation.
				 */
				if (typmod1 == -1 && typmod2 == -1)
				{
					precision = tds_default_numeric_precision;
					scale = tds_default_numeric_scale;
					return ((precision << 16) | scale) + VARHDRSZ;
				}
				else if (typmod1 == -1)
				{
					precision1 = precision2;
					scale1 = scale2;
				}
				else if (typmod2 == -1)
				{
					precision2 = precision1;
					scale2 = scale1;
				}

				/*
				 * Refer to details of precision and scale calculation in the
				 * following link:
				 * https://github.com/MicrosoftDocs/sql-docs/blob/live/docs/t-sql/data-types/precision-scale-and-length-transact-sql.md
				 */
				has_aggregate_operand = arg1->type == T_Aggref ||
					(list_length(op->args) == 2 && arg2->type == T_Aggref);

				switch (op->opfuncid)
				{
					case NUMERIC_ADD_OID:
					case NUMERIC_SUB_OID:
						integralDigitCount = Max(precision1 - scale1, precision2 - scale2);
						scale = Max(scale1, scale2);
						precision = integralDigitCount + 1 + scale;

						/*
						 * For addition and subtraction, skip scale adjustment
						 * when none of the operands is part of any aggregate
						 * function
						 */
						if (has_aggregate_operand &&
							integralDigitCount < (Min(TDS_MAX_NUM_PRECISION, precision) - scale))
							scale = Min(precision, TDS_MAX_NUM_PRECISION) - integralDigitCount;

						/*
						 * precision adjustment to TDS_MAX_NUM_PRECISION
						 */
						if (precision > TDS_MAX_NUM_PRECISION)
							precision = TDS_MAX_NUM_PRECISION;
						break;
					case NUMERIC_MUL_OID:
						scale = scale1 + scale2;
						precision = precision1 + precision2 + 1;

						/*
						 * For multiplication, skip scale adjustment when
						 * atleast one of the operands is part of aggregate
						 * function
						 */
						if (has_aggregate_operand && precision > TDS_MAX_NUM_PRECISION)
							precision = TDS_MAX_NUM_PRECISION;
						break;
					case NUMERIC_DIV_OID:
						scale = Max(6, scale1 + precision2 + 1);
						precision = precision1 - scale1 + scale2 + scale;
						break;
					case NUMERIC_MOD_OID:
					case NUMERIC_MOD_OID2:
						scale = Max(scale1, scale2);
						precision = Min(precision1 - scale1, precision2 - scale2) + scale;
						break;
					case NUMERIC_UPLUS_OID:
					case NUMERIC_UMINUS_OID:
						scale = scale1;
						precision = precision1;
						break;
					default:
						return -1;
				}

				/*
				 * Mitigate precision overflow if integral precision <= 38
				 * Otherwise it simply won't fit in 38 precision and let an
				 * overflow error be thrown in PrepareRowDescription.
				 */
				if (precision > TDS_MAX_NUM_PRECISION)
				{
					if (precision - scale > 32 && scale > 6)
					{
						/*
						 * Result might be rounded to 6 decimal places or the
						 * overflow error will be thrown if the integral part
						 * can't fit into 32 digits.
						 */
						precision = TDS_MAX_NUM_PRECISION;
						scale = 6;
					}
					else if (precision - scale <= TDS_MAX_NUM_PRECISION)
					{
						/*
						 * scale adjustment by delta is only applicable for
						 * division and (multiplcation having no aggregate
						 * operand)
						 */
						int			delta = precision - TDS_MAX_NUM_PRECISION;

						precision = TDS_MAX_NUM_PRECISION;
						scale = Max(scale - delta, 0);
					}

					/*
					 * Control reaching here for only arithmetic overflow
					 * cases
					 */
				}
				return ((precision << 16) | scale) + VARHDRSZ;
			}
		case T_FuncExpr:
			{
				FuncExpr   *func = (FuncExpr *) expr;
				Oid			func_oid = InvalidOid;
				int			rettypmod = -1;

				/* Be smart about length-coercion functions... */
				if (exprIsLengthCoercion(expr, &rettypmod))
					return rettypmod;

				/*
				 * Look up the return type typmod from a persistent store
				 * using the function oid.
				 */
				func_oid = func->funcid;
				Assert(func_oid != InvalidOid);

				if (func->funcresulttype != VOIDOID)
					rettypmod = pltsql_plugin_handler_ptr->pltsql_read_numeric_typmod(func_oid,
																					  func->args == NIL ? 0 : func->args->length,
																					  func->funcresulttype);
				return rettypmod;
			}
		case T_NullIfExpr:
			{
				/*
				 * Nullif returns a null value if the two specified
				 * expressions are equal, Otherwise it returns the first
				 * argument.
				 */
				NullIfExpr *nullif = (NullIfExpr *) expr;
				Node	   *arg1;

				Assert(nullif->args != NIL);

				arg1 = linitial(nullif->args);
				return resolve_numeric_typmod_from_exp(plan, arg1);
			}
		case T_CoalesceExpr:
			{
				/*
				 * Find max possible integral_precision and scale (fractional
				 * precision) in a CoalesceExpr
				 */
				CoalesceExpr *coale = (CoalesceExpr *) expr;
				ListCell   *lc;
				Node	   *arg;
				int32		arg_typmod;
				uint8_t		precision,
							max_integral_precision = 0,
							scale,
							max_scale = 0;

				Assert(coale->args != NIL);

				/* Loop through the list of Coalesce arguments */
				foreach(lc, coale->args)
				{
					arg = lfirst(lc);
					arg_typmod = resolve_numeric_typmod_from_exp(plan, arg);
					/* return -1 if we fail to resolve one of the arg's typmod */
					if (arg_typmod == -1)
						return -1;

					/*
					 * skip the const NULL, which should have 0 returned as
					 * typmod
					 */
					if (arg_typmod == 0)
						continue;
					scale = (arg_typmod - VARHDRSZ) & 0xffff;
					precision = ((arg_typmod - VARHDRSZ) >> 16) & 0xffff;
					max_scale = Max(scale, max_scale);
					max_integral_precision = Max(precision - scale, max_integral_precision);
				}
				return (((max_integral_precision + max_scale) << 16) | max_scale) + VARHDRSZ;
			}
		case T_CaseExpr:
			{
				/*
				 * Find max possible integral_precision and scale (fractional
				 * precision) in a CoalesceExpr
				 */
				CaseExpr   *case_expr = (CaseExpr *) expr;
				ListCell   *lc;
				CaseWhen   *casewhen;
				Node	   *casewhen_result;
				int32		typmod;
				uint8_t		precision,
							max_integral_precision = 0,
							scale,
							max_scale = 0;

				Assert(case_expr->args != NIL);

				/* Loop through the list of WHEN clauses */
				foreach(lc, case_expr->args)
				{
					casewhen = lfirst(lc);
					casewhen_result = (Node *) casewhen->result;
					typmod = resolve_numeric_typmod_from_exp(plan, casewhen_result);

					/*
					 * return -1 if we fail to resolve one of the result's
					 * typmod
					 */
					if (typmod == -1)
						return -1;

					/*
					 * skip the const NULL, which should have 0 returned as
					 * typmod
					 */
					if (typmod == 0)
						continue;
					scale = (typmod - VARHDRSZ) & 0xffff;
					precision = ((typmod - VARHDRSZ) >> 16) & 0xffff;
					max_scale = Max(scale, max_scale);
					max_integral_precision = Max(precision - scale, max_integral_precision);
				}
				return (((max_integral_precision + max_scale) << 16) | max_scale) + VARHDRSZ;
			}
		case T_Aggref:
			{
				/* select max(a) from t; max(a) is an Aggref */
				Aggref	   *aggref = (Aggref *) expr;
				TargetEntry *te;
				char	   *aggFuncName;
				int32		typmod;
				uint8_t		precision,
							scale;

				Assert(aggref->args != NIL);

				te = (TargetEntry *) linitial(aggref->args);
				typmod = resolve_numeric_typmod_from_exp(plan, (Node *) te->expr);
				aggFuncName = get_func_name(aggref->aggfnoid);

				scale = (typmod - VARHDRSZ) & 0xffff;
				precision = ((typmod - VARHDRSZ) >> 16) & 0xffff;

				/*
				 * If we recieve typmod as -1 we should fallback to default
				 * scale and precision Rather than using -1 typmod to
				 * calculate scale and precision which leads to TDS protocol
				 * error.
				 */
				if (typmod == -1)
				{
					scale = tds_default_numeric_scale;
					precision = tds_default_numeric_precision;
				}

				/*
				 * [BABEL-3074] NUMERIC overflow causes TDS error for
				 * aggregate function sum(); resultant precision should be
				 * tds_default_numeric_precision
				 */
				if (aggFuncName && strlen(aggFuncName) == 3 &&
					(strncmp(aggFuncName, "sum", 3) == 0))
					precision = tds_default_numeric_precision;

				/*
				 * For aggregate function avg(); resultant precision should be
				 * tds_default_numeric_precision and resultant scale =
				 * max(input scale, 6)
				 */
				if (aggFuncName && strlen(aggFuncName) == 3 &&
					(strncmp(aggFuncName, "avg", 3) == 0))
				{
					precision = tds_default_numeric_precision;
					scale = Max(scale, 6);
				}

				pfree(aggFuncName);
				return ((precision << 16) | scale) + VARHDRSZ;
			}
		case T_PlaceHolderVar:
			{
				PlaceHolderVar *phv = (PlaceHolderVar *) expr;

				return resolve_numeric_typmod_from_exp(plan, (Node *) phv->phexpr);
			}
		case T_RelabelType:
			{
				RelabelType *rlt = (RelabelType *) expr;

				if (rlt->resulttypmod != -1)
					return rlt->resulttypmod;
				else
					return resolve_numeric_typmod_from_exp(plan, (Node *) rlt->arg);
			}
			/* TODO handle more Expr types if needed */
		default:
			return -1;
	}
}

/* look for a typmod to return from a varbinary expression */
static int32
resolve_varbinary_typmod_from_exp(Node *expr)
{
	int32 actual_size = 0;

	if (expr == NULL)
		return -1;

	switch (nodeTag(expr))
	{
		case T_Const:
		{
			/*
			 * Generate the typmod from hex const input because typmod won't be
			 * specified.
			 */
			Const	   *con = (Const *) expr;
			if (!con->constisnull)
			{
				bytea	   *source = (bytea *) con->constvalue;
				actual_size = VARSIZE_ANY_EXHDR(source);
				
				/* if the actual size is greater than 8000, it should be varbinary(max) case as we have set a limit on scale */
				if (actual_size > VARBINARY_MAX_SCALE)
					return -1;
	
				return VARSIZE_ANY(source);
			}
			else
				return -1;
		}
		case T_FuncExpr:
		{
			FuncExpr   *func = (FuncExpr *) expr;
			Oid			func_oid = InvalidOid;
			int			rettypmod = -1;

			/* Be smart about length-coercion functions... */
			if (exprIsLengthCoercion(expr, &rettypmod))
				return rettypmod;

			/*
			 * Look up the return type typmod from a persistent store
			 * using the function oid.
			 */
			func_oid = func->funcid;
			Assert(func_oid != InvalidOid);

			if (func->funcresulttype != VOIDOID)
				rettypmod = pltsql_plugin_handler_ptr->pltsql_read_numeric_typmod(func_oid,
																				  func->args == NIL ? 0 : func->args->length,
																				  func->funcresulttype);
			return rettypmod;
		}
		/* TODO handle more Expr types if needed */
		default:
			return -1;
	}
}

void
InitTDSResponse(void)
{
	tds_estate = palloc(sizeof(TdsExecutionStateData));
	tds_estate->current_stack = 0;
	tds_estate->error_stack_offset = 0;
	tds_estate->cur_error_number = -1;
	tds_estate->cur_error_severity = -1;
	tds_estate->cur_error_state = -1;
}

void
TdsResponseReset(void)
{
	tds_estate = NULL;
}

/*
 * MakeEmptyParameterToken - prepare an empty parameter token
 *
 * In this function, we prepare a parameter token corresponding to the
 * caller provided pg_type.oid and corresponding atttypmod and attcollation.
 * Additionally, we assign NULL as value to the parameter.
 */
ParameterToken
MakeEmptyParameterToken(char *name, int atttypid, int32 atttypmod, int attcollation)
{
	ParameterToken temp = palloc0(sizeof(ParameterTokenData));
	TdsIoFunctionInfo finfo;
	TdsColumnMetaData *col;
	Oid			serverCollationOid;
	uint32_t	tdsVersion = GetClientTDSVersion();

	coll_info_t cinfo = TdsLookupCollationTableCallback(InvalidOid);

	serverCollationOid = cinfo.oid;
	if (unlikely(serverCollationOid == InvalidOid))
		elog(FATAL, "Oid of default collation is not valid, This might mean that value of server_collation_name GUC is invalid");

	initStringInfo(&(temp->paramMeta.colName));
	appendStringInfo(&(temp->paramMeta.colName), "%s", name);

	col = &(temp->paramMeta);
	finfo = TdsLookupTypeFunctionsByOid(atttypid, &atttypmod);
	SetParamMetadataCommonInfo(col, finfo);

	temp->paramOrdinal = -1;
	temp->len = -1;
	temp->maxLen = -1;
	temp->isNull = true;

	switch (finfo->sendFuncId)
	{
			/* TODO  boolean is equivalent to TSQL BIT type */
		case TDS_SEND_BIT:
			SetColMetadataForFixedType(col, TDS_TYPE_BIT, TDS_MAXLEN_BIT);
			temp->maxLen = 1;
			break;
		case TDS_SEND_TINYINT:
			SetColMetadataForFixedType(col, TDS_TYPE_INTEGER, TDS_MAXLEN_TINYINT);
			temp->maxLen = 1;
			break;
		case TDS_SEND_SMALLINT:
			SetColMetadataForFixedType(col, TDS_TYPE_INTEGER, TDS_MAXLEN_SMALLINT);
			temp->maxLen = 2;
			break;
		case TDS_SEND_INTEGER:
			SetColMetadataForFixedType(col, TDS_TYPE_INTEGER, TDS_MAXLEN_INT);
			temp->maxLen = 4;
			break;
		case TDS_SEND_BIGINT:
			SetColMetadataForFixedType(col, TDS_TYPE_INTEGER, TDS_MAXLEN_BIGINT);
			temp->maxLen = 8;
			break;
		case TDS_SEND_FLOAT4:
			SetColMetadataForFixedType(col, TDS_TYPE_FLOAT, TDS_MAXLEN_FLOAT4);
			temp->maxLen = 4;
			break;
		case TDS_SEND_FLOAT8:
			SetColMetadataForFixedType(col, TDS_TYPE_FLOAT, TDS_MAXLEN_FLOAT8);
			temp->maxLen = 8;
			break;
		case TDS_SEND_CHAR:
			SetColMetadataForCharTypeHelper(col, TDS_TYPE_CHAR,
											attcollation, (atttypmod - 4));
			/* if attypmod is -1, consider the datatype as CHAR(MAX) */
			if (atttypmod == -1)
				temp->maxLen = 0xFFFF;
			break;
		case TDS_SEND_NCHAR:
			SetColMetadataForCharTypeHelper(col, TDS_TYPE_NCHAR,
											attcollation, (atttypmod - 4) * 2);
			/* if attypmod is -1, consider the datatype as NCHAR(MAX) */
			if (atttypmod == -1)
				temp->maxLen = 0xFFFF;
			break;
		case TDS_SEND_VARCHAR:
			/* If this is one of the vector datatypes we should adjust the typmod. */
			if (is_this_a_vector_datatype(col->pgTypeOid))
				atttypmod = -1;
			SetColMetadataForCharTypeHelper(col, TDS_TYPE_VARCHAR,
											attcollation, (atttypmod == -1) ?
											atttypmod : (atttypmod - 4));
			/* if attypmod is -1, consider the datatype as VARCHAR(MAX) */
			if (atttypmod == -1)
				temp->maxLen = 0xFFFF;
			break;
		case TDS_SEND_NVARCHAR:
			SetColMetadataForCharTypeHelper(col, TDS_TYPE_NVARCHAR,
											attcollation, (atttypmod == -1) ?
											atttypmod : (atttypmod - 4) * 2);
			/* if attypmod is -1, consider the datatype as NVARCHAR(MAX) */
			if (atttypmod == -1)
				temp->maxLen = 0xFFFF;
			break;
		case TDS_SEND_MONEY:
			SetColMetadataForFixedType(col, TDS_TYPE_MONEYN, TDS_MAXLEN_MONEY);
			temp->maxLen = 8;
			break;
		case TDS_SEND_SMALLMONEY:
			SetColMetadataForFixedType(col, TDS_TYPE_MONEYN, TDS_MAXLEN_SMALLMONEY);
			temp->maxLen = 4;
			break;
		case TDS_SEND_TEXT:
			SetColMetadataForTextTypeHelper(col, TDS_TYPE_TEXT,
											attcollation, (atttypmod - 4));
			break;
		case TDS_SEND_NTEXT:
			SetColMetadataForTextTypeHelper(col, TDS_TYPE_NTEXT,
											attcollation, (atttypmod - 4) * 2);
			break;
		case TDS_SEND_DATE:
			if (tdsVersion < TDS_VERSION_7_3_A)

				/*
				 * If client being connected is using TDS version lower than
				 * 7.3A then TSQL treats DATE as NVARCHAR. Max len here would
				 * be 20 ('YYYY-MM-DD'). and Making use of default collation
				 * Oid.
				 */
				SetColMetadataForCharTypeHelper(col, TDS_TYPE_NVARCHAR, serverCollationOid, 20);
			else
			{
				SetColMetadataForDateType(col, TDS_TYPE_DATE);
				temp->maxLen = 3;
			}
			break;
		case TDS_SEND_DATETIME:
			SetColMetadataForFixedType(col, TDS_TYPE_DATETIMEN, TDS_MAXLEN_DATETIME);
			temp->maxLen = 8;
			break;
		case TDS_SEND_NUMERIC:
			{
				uint8_t		precision = 18,
							scale = 0;

				/*
				 * Get the precision and scale out of the typmod value if
				 * typmod is valid Otherwise
				 * tds_default_numeric_precision/scale will be used.
				 */
				if (atttypmod > VARHDRSZ)
				{
					scale = (atttypmod - VARHDRSZ) & 0xffff;
					precision = ((atttypmod - VARHDRSZ) >> 16) & 0xffff;
				}
				else
				{
					precision = tds_default_numeric_precision;
					scale = tds_default_numeric_scale;
				}
				SetColMetadataForNumericType(col, TDS_TYPE_NUMERICN, 17, precision, scale);
				temp->maxLen = 17;
			}
			break;
		case TDS_SEND_SMALLDATETIME:
			SetColMetadataForFixedType(col, TDS_TYPE_DATETIMEN, TDS_MAXLEN_SMALLDATETIME);
			temp->maxLen = 4;
			break;
		case TDS_SEND_IMAGE:
			SetColMetadataForImageType(col, TDS_TYPE_IMAGE);
			break;
		case TDS_SEND_BINARY:
			SetColMetadataForBinaryType(col, TDS_TYPE_BINARY, atttypmod - 4);
			/* if attypmod is -1, consider the datatype as BINARY(MAX) */
			if (atttypmod == -1)
				temp->maxLen = 0xFFFF;
			break;
		case TDS_SEND_VARBINARY:

			/*
			 * Generate the typmod from hex const input because typmod won't
			 * be specified
			 */
			SetColMetadataForBinaryType(col, TDS_TYPE_VARBINARY, (atttypmod == -1) ?
										atttypmod : atttypmod - VARHDRSZ);
			/* if attypmod is -1, consider the datatype as VARBINARY(MAX) */
			if (atttypmod == -1)
				temp->maxLen = 0xFFFF;
			break;
		case TDS_SEND_UNIQUEIDENTIFIER:
			SetColMetadataForFixedType(col, TDS_TYPE_UNIQUEIDENTIFIER, TDS_MAXLEN_UNIQUEIDENTIFIER);
			temp->maxLen = 16;
			break;
		case TDS_SEND_TIME:
			if (tdsVersion < TDS_VERSION_7_3_A)

				/*
				 * If client being connected is using TDS version lower than
				 * 7.3A then TSQL treats TIME as NVARCHAR. Max len here would
				 * be 32 ('hh:mm:ss[.nnnnnnn]'). and Making use of default
				 * collation Oid.
				 */
				SetColMetadataForCharTypeHelper(col, TDS_TYPE_NVARCHAR, serverCollationOid, 32);
			else
			{
				/*
				 * if time data has no specific scale specified in the query,
				 * default scale to be considered is 7 always. However,
				 * setting default scale to 6 since postgres supports upto 6
				 * digits after decimal point
				 */
				if (atttypmod == -1)
					atttypmod = DATETIMEOFFSETMAXSCALE;
				SetColMetadataForTimeType(col, TDS_TYPE_TIME, atttypmod);
				temp->maxLen = 5;
			}
			break;
		case TDS_SEND_DATETIME2:
			if (tdsVersion < TDS_VERSION_7_3_A)

				/*
				 * If client being connected is using TDS version lower than
				 * 7.3A then TSQL treats DATETIME2 as NVARCHAR. Max len here
				 * would be 54('YYYY-MM-DD hh:mm:ss[.nnnnnnn]'). and Making
				 * use of default collation Oid.
				 */
				SetColMetadataForCharTypeHelper(col, TDS_TYPE_NVARCHAR, serverCollationOid, 54);
			else
			{
				/*
				 * if Datetime2 data has no specific scale specified in the
				 * query, default scale to be considered is 7 always. However,
				 * setting default scale to 6 since postgres supports upto 6
				 * digits after decimal point
				 */
				if (atttypmod == -1)
					atttypmod = DATETIMEOFFSETMAXSCALE;
				SetColMetadataForTimeType(col, TDS_TYPE_DATETIME2, atttypmod);
				temp->maxLen = 8;
			}
			break;
		case TDS_SEND_XML:
			if (tdsVersion > TDS_VERSION_7_1_1)
				SetColMetadataForFixedType(col, TDS_TYPE_XML, 0);
			else

				/*
				 * If client being connected is using TDS version lower than
				 * or equal to 7.1 then TSQL treats XML as NText.
				 */
				SetColMetadataForTextTypeHelper(col, TDS_TYPE_NTEXT,
												attcollation, (atttypmod - 4) * 2);
			break;
		case TDS_SEND_SQLVARIANT:
			SetColMetadataForImageType(col, TDS_TYPE_SQLVARIANT);
			break;
		case TDS_SEND_DATETIMEOFFSET:
			if (tdsVersion < TDS_VERSION_7_3_A)

				/*
				 * If client being connected is using TDS version lower than
				 * 7.3A then TSQL treats DATETIMEOFFSET as NVARCHAR. Max len
				 * here would be 64('YYYY-MM-DD hh:mm:ss[.nnnnnnn]
				 * [+|-]hh:mm'). and Making use of default collation Oid.
				 */
				SetColMetadataForCharTypeHelper(col, TDS_TYPE_NVARCHAR, serverCollationOid, 64);
			else
			{
				if (atttypmod == -1)
					atttypmod = DATETIMEOFFSETMAXSCALE;
				SetColMetadataForTimeType(col, TDS_TYPE_DATETIMEOFFSET, atttypmod);
				temp->maxLen = 10;
			}
			break;

		case TDS_SEND_GEOGRAPHY:
		case TDS_SEND_GEOMETRY:
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					 errmsg("spatial type not supported as out parameter")));
			break;

		default:

			/*
			 * TODO: Need to create a mapping table for user defined data
			 * types and handle it here.
			 */
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					 errmsg("data type %d not supported as out parameter", atttypid)));
	}

	temp->type = col->metaEntry.type1.tdsTypeId;

	return temp;
}

/*
 * SendColumnMetadataToken - send the COLMETADATA token
 *
 * natts - number of attributes
 * sendRowStat - true if we need to send an additional ROWSTAT column, false
 * otherwise.
 * NB: The ROWSTAT columns (row status indicator) are sent as hidden columns,
 * at the end of each row with the column name ROWSTAT and data type INT4.  This
 * ROWSTAT column has one of the values - FETCH_SUCCEEDED or FETCH_MISSING.
 * Because the TDS protocol provides no way to send the trailing status column
 * without sending the previous columns, dummy data is sent for missing rows
 * (nullable fields set to null, fixed length fields set to 0, blank, or the
 * default for that column, as appropriate).
 */
void
SendColumnMetadataToken(int natts, bool sendRowStat)
{
	StringInfoData tempBuf;
	int			attno;
	char 		*db_name;						/* Store Current Database Name */
	
	uint32_t	tdsVersion = GetClientTDSVersion();

	/* Now send out the COLMETADATA token */
	TDS_DEBUG(TDS_DEBUG2, "SendColumnMetadataToken: token=0x%02x", TDS_TOKEN_COLMETADATA);
	TdsPutInt8(TDS_TOKEN_COLMETADATA);
	TdsPutInt16LE(sendRowStat ? natts + 1 : natts);

	initStringInfo(&tempBuf);

	for (attno = 0; attno < natts; attno++)
	{
		uint8		temp8;
		uint16		temp16;
		TdsColumnMetaData *col = &colMetaData[attno];

		/*
		 * Instead of hardcoding the userType to 0 at various strucutures
		 * inside col->metaEntry we can write 0x0000 (for versions lower than
		 * TDS 7.2) or 0x00000000 (for TDS 7.2 and higher) directly on the
		 * wire depending version;
		 *
		 * TODO: TDS doc mentions some non-zero values for timestamp and
		 * aliases NOTE: We have always sent UserType as 0 and clients have
		 * never complained about it.
		 */
		if (tdsVersion <= TDS_VERSION_7_1_1)
			TdsPutInt16LE(0);
		else
			TdsPutInt32LE(0);
		/* column meta */
		TdsPutbytes(&(col->metaEntry), col->metaLen);

		if (col->sendTableName)
		{
			uint8		numParts;

			if (col->relinfo != NULL)
			{
				numParts = 2;
				resetStringInfo(&tempBuf);

				/*
				 * In column Metatdata Token -- NumParts, a multi-part table
				 * name, was intoduced in TDS 7.2
				 */
				if (tdsVersion > TDS_VERSION_7_1_1)
					FillTabNameWithNumParts(&tempBuf, numParts, col->relinfo);
				else
					FillTabNameWithoutNumParts(&tempBuf, numParts, col->relinfo);
				TdsPutbytes(tempBuf.data, tempBuf.len);
			}
			else
			{
				/* Expression columns doesn't have table name */
				numParts = 1;

				/*
				 * In column Metatdata Token -- NumParts, a multi-part table
				 * name, was introduced in TDS 7.2
				 */
				if (tdsVersion > TDS_VERSION_7_1_1)
					TdsPutbytes(&numParts, sizeof(numParts));
				TdsPutInt16LE(0);
			}
		}

		/* For Spatial Types */
		/*
			* Check if it is spatial Data type
			* Send the Corresponding MetaData Columns
		*/			
		if (col->isSpatialType)
		{
			
			/* Current Database Name and Length are expected by the Driver */
			db_name = pltsql_plugin_handler_ptr->get_cur_db_name();
			temp8 = (uint8_t) pg_mbstrlen(db_name);
			resetStringInfo(&tempBuf);
			TdsUTF8toUTF16StringInfo(&tempBuf, db_name,
									strlen(db_name));
			TdsPutbytes(&temp8, sizeof(temp8));
			TdsPutbytes(tempBuf.data, tempBuf.len);

			/* Since Schema Name is always sys in Babelfish Server we can directly send it */
			temp8 = (uint8_t) pg_mbstrlen("sys");
			resetStringInfo(&tempBuf);
			TdsUTF8toUTF16StringInfo(&tempBuf, "sys",
									strlen("sys"));
			TdsPutbytes(&temp8, sizeof(temp8));
			TdsPutbytes(tempBuf.data, tempBuf.len);

			/* Type name and Length */
			temp8 = (uint8_t) pg_mbstrlen(col->typeName);
			resetStringInfo(&tempBuf);
			TdsUTF8toUTF16StringInfo(&tempBuf, col->typeName,
									strlen(col->typeName));
			TdsPutbytes(&temp8, sizeof(temp8));
			TdsPutbytes(tempBuf.data, tempBuf.len);

			/* assembly qualified name */
			temp16 = (uint16_t) pg_mbstrlen(col->assemblyName);
			resetStringInfo(&tempBuf);
			TdsUTF8toUTF16StringInfo(&tempBuf, col->assemblyName,
									strlen(col->assemblyName));
			TdsPutbytes(&temp16, sizeof(temp16));
			TdsPutbytes(tempBuf.data, tempBuf.len);
		}

		/*
		 * If it is an expression column, send "0" as the column len
		 *
		 * NOTE: Relaxing this condition to send "0" as the column len when
		 * column name is "?column?" (default column alias for columns with no
		 * name in engine)
		 *
		 * This is needed to send a column name for a column which is not part
		 * of a table but has an alias [BABEL-544]
		 *
		 */
		if (strcmp(col->colName.data, "?column?") == 0)
		{
			temp8 = 0;
			TdsPutbytes(&temp8, sizeof(temp8));
		}
		else
		{

			/* column length and name */
			if (col->colName.len > 0)
				temp8 = (uint8_t) pg_mbstrlen(col->colName.data);
			else
				temp8 = 0;

			resetStringInfo(&tempBuf);
			TdsUTF8toUTF16StringInfo(&tempBuf, col->colName.data,
									 col->colName.len);
			TdsPutbytes(&temp8, sizeof(temp8));
			TdsPutbytes(tempBuf.data, tempBuf.len);
		}
	}

	if (sendRowStat)
	{
		/*
		 * XXX: Since the column information for a ROWSTAT column is fixed,
		 * the value (except the userType) is hard-coded for now.  Should this
		 * come from the engine? This is also sent for FOR BROWSE queries.
		 */
		char		arr[] = {
			0x00, 0x00, 0x38, 0x07, 0x52, 0x00, 0x4f, 0x00, 0x57,
			0x00, 0x53, 0x00, 0x54, 0x00, 0x41, 0x00, 0x54, 0x00
		};

		/*
		 * Instead of hardcoding the userType to 0 in the above array we can
		 * write 0x0000 (for versions lower than TDS 7.2) or 0x00000000 (for
		 * TDS 7.2 and higher) directly on the wire depending version;
		 */
		if (tdsVersion <= TDS_VERSION_7_1_1)
			TdsPutInt16LE(0);
		else
			TdsPutInt32LE(0);

		TdsPutbytes(arr, sizeof(arr));
	}

	pfree(tempBuf.data);
}

/*
 * SendTabNameToken - send the TABNAME token
 *
 * It sends all the table names corresponding the columns included in the target
 * list.  For expression columns, we don't send any table name.
 */
void
SendTabNameToken(void)
{
	StringInfoData buf;
	ListCell   *lc;
	uint32_t	tdsVersion = GetClientTDSVersion();

	if (relMetaDataInfoList == NIL)
		return;

	initStringInfo(&buf);

	foreach(lc, relMetaDataInfoList)
	{
		TdsRelationMetaDataInfo relMetaDataInfo = (TdsRelationMetaDataInfo) lfirst(lc);
		uint8		numParts = 2;

		/*
		 * In Table Name token -- NumParts, a multi-part table name, was
		 * intoduced in tds 7.1 revision 1.
		 */
		if (tdsVersion > TDS_VERSION_7_1)
			FillTabNameWithNumParts(&buf, numParts, relMetaDataInfo);
		else
			FillTabNameWithoutNumParts(&buf, numParts, relMetaDataInfo);
	}

	TDS_DEBUG(TDS_DEBUG2, "SendTabNameToken: token=0x%02x", TDS_TOKEN_TABNAME);
	TdsPutInt8(TDS_TOKEN_TABNAME);
	TdsPutInt16LE((uint16_t) buf.len);
	TdsPutbytes(buf.data, buf.len);
	pfree(buf.data);

	TDSInstrumentation(INSTR_TDS_TOKEN_TABNAME);
}

/*
 * SendColInfoToken - send the COLINFO token
 *
 * It sends some additional info for a column:
 * colNum - column number in the result set
 * tableNum - number of the base table that the column was derived from. The value
 * is 0 for expression column.
 * status - EXPRESSION (the column was the result of an expression)
 * 			KEY (the column is part of a key for the associated table and result set)
 * 			HIDDEN (the column was not requested, but was added because it was part
 * 					of a key for the associated table)
 * 			DIFFERENT_NAME (the column name is different than the requested column
 * 					name in the case of a column alias)
 * colName - The base column name. This only occurs if DIFFERENT_NAME is set in Status.
 */
void
SendColInfoToken(int natts, bool sendRowStat)
{
	StringInfoData buf;
	StringInfoData tempBuf;
	int			attno;

	TDS_DEBUG(TDS_DEBUG2, "SendColInfoToken: token=0x%02x", TDS_TOKEN_COLINFO);
	TdsPutInt8(TDS_TOKEN_COLINFO);
	initStringInfo(&buf);
	initStringInfo(&tempBuf);

	for (attno = 0; attno < natts; attno++)
	{
		TdsColumnMetaData *col = &colMetaData[attno];
		uint8		colNum,
					tableNum,
					status = 0;
		uint8		temp8;

		colNum = attno + 1;

		if (col->relOid == 0)
		{
			status |= COLUMN_STATUS_EXPRESSION;
			tableNum = 0;
		}
		else
		{
			status = 0;
			tableNum = col->relinfo->tableNum;

			resetStringInfo(&tempBuf);

			if (strcmp(col->baseColName, col->colName.data) != 0)
				status |= COLUMN_STATUS_DIFFERENT_NAME;

			{
				int			tempatt;

				for (tempatt = 0; tempatt < col->relinfo->numkeyattrs; tempatt++)
					if (col->attrNum == col->relinfo->keyattrs[tempatt])
						status |= COLUMN_STATUS_KEY;
			}
		}

		/* column num, table num, status */
		appendBinaryStringInfo(&buf, (const char *) &colNum, sizeof(colNum));
		appendBinaryStringInfo(&buf, (const char *) &tableNum, sizeof(tableNum));
		appendBinaryStringInfo(&buf, (const char *) &status, sizeof(status));

		if (status & COLUMN_STATUS_DIFFERENT_NAME)
		{
			Assert(col->baseColName != NULL);
			temp8 = (uint8_t) pg_mbstrlen(col->baseColName);
			appendBinaryStringInfo(&buf, (const char *) &temp8, sizeof(uint8));
			TdsUTF8toUTF16StringInfo(&buf, col->baseColName, strlen(col->baseColName));
		}
	}

	if (sendRowStat)
	{
		uint8		colNum,
					tableNum,
					status = 0;

		colNum = natts + 1;
		tableNum = 0;
		status |= COLUMN_STATUS_EXPRESSION | COLUMN_STATUS_HIDDEN;

		/* column num, table num, status */
		appendBinaryStringInfo(&buf, (const char *) &colNum, sizeof(colNum));
		appendBinaryStringInfo(&buf, (const char *) &tableNum, sizeof(tableNum));
		appendBinaryStringInfo(&buf, (const char *) &status, sizeof(status));
	}

	TdsPutInt16LE((uint16_t) buf.len);
	TdsPutbytes(buf.data, buf.len);

	pfree(buf.data);
}

static
int
TdsGetGenericTypmod(Node *expr)
{
	int			rettypmod = -1;

	if (!expr)
		return rettypmod;

	switch (nodeTag(expr))
	{
		case T_FuncExpr:
			{
				FuncExpr   *func;
				Oid			func_oid = InvalidOid;

				func = (FuncExpr *) expr;

				/*
				 * Look up the return type typmod from a persistent store
				 * using function oid.
				 */
				func_oid = func->funcid;
				Assert(func_oid != InvalidOid);

				if (func->funcresulttype != VOIDOID)
					rettypmod = pltsql_plugin_handler_ptr->pltsql_get_generic_typmod(func_oid,
																					 func->args == NIL ? 0 : func->args->length, func->funcresulttype);
			}
			break;
		default:

			/*
			 * TODO: expectation is that apart from Func type expressions, we
			 * never get typmod = -1 when we reach TDS extension for
			 * CHAR/NCHAR datatypes. We should figure out a determinstic
			 * typmod for all other expression types inside the engine or
			 * babelfishpg_tsql extension.
			 */
			ereport(ERROR, (errcode(ERRCODE_DATA_EXCEPTION),
							errmsg("The string size for the given CHAR/NCHAR data is not defined. "
								   "Please use an explicit CAST or CONVERT to CHAR(n)/NCHAR(n)")));
			break;
	}

	return rettypmod;
}

/*
 * PrepareRowDescription - prepare the information needed to construct COLMETADATA
 * token, TABNAME token and COLINFO token.
 *
 * extendedInfo - 	If false, it doesn't collect the additional information needed
 * 					to construct the TABNAME token and COLINFO token.
 * fetchPkeys -		If true and extendedInfo is true, it fetches the primary keys
 * 					for a relation. (used for keyset and dynamic cursors)
 */
void
PrepareRowDescription(TupleDesc typeinfo, PlannedStmt *plannedstmt, List *targetlist,
					  int16 *formats, bool extendedInfo, bool fetchPkeys)
{
	int			natts = typeinfo->natts;
	int			attno;
	MemoryContext oldContext;
	ListCell   *tlist_item = list_head(targetlist);
	bool		sendTableName = false;
	uint8_t		precision = 18,
				scale = 0;

	relMetaDataInfoList = NIL;

	TdsErrorContext->err_text = "Preparing to Send Back the Tds response";

	SendPendingDone(true);

	/*
	 * The colMetaData is also used in the TdsPrintTup() callback below so we
	 * place it into the memory context that will be reset once per TCOP main
	 * loop iteration.
	 */
	oldContext = MemoryContextSwitchTo(MessageContext);
	colMetaData = palloc0(sizeof(TdsColumnMetaData) * natts);

	/*
	 * We collect all the information first so that we don't have to abort
	 * half way through the COLMETADATA tag in case of an error (like
	 * unsupported data type).
	 */
	for (attno = 0; attno < natts; attno++)
	{
		Oid			serverCollationOid;
		TdsIoFunctionInfo finfo;
		Form_pg_attribute att = TupleDescAttr(typeinfo, attno);
		Oid			atttypid = att->atttypid;
		int32		atttypmod = att->atttypmod;
		TdsColumnMetaData *col = &colMetaData[attno];
		uint32_t	tdsVersion = GetClientTDSVersion();
		TargetEntry *tle = NULL;
		coll_info_t cinfo = TdsLookupCollationTableCallback(InvalidOid);

		serverCollationOid = cinfo.oid;
		if (unlikely(serverCollationOid == InvalidOid))
			elog(FATAL, "Oid of default collation is not valid, This might mean that value of server_collation_name GUC is invalid");

		/*
		 * Get the IO function info from our type cache
		 */
		finfo = TdsLookupTypeFunctionsByOid(atttypid, &atttypmod);
		/* atttypid = getBaseTypeAndTypmod(atttypid, &atttypmod); */
#if 0
		{
			/* Test a reverse lookup */
			TdsIoFunctionInfo finfo2;
			int32_t		typeid = finfo->ttmtdstypeid;
			int32_t		typelen = finfo->ttmtdstypelen;

			elog(LOG, "found finfo for Oid %d: tdstype=%d tdstyplen=%d",
				 atttypid, typeid, typelen);
			if (!att->attbyval)
				typelen = 80;
			finfo2 = TdsLookupTypeFunctionsByTdsId(typeid, typelen);
			elog(LOG, "found reverse finfo for type %d,%d: Oid=%d",
				 typeid, typelen, finfo2->ttmtypeid);
		}
#endif

		/*
		 * Fill in column info that is common to all data types
		 */
		SetParamMetadataCommonInfo(col, finfo);
		initStringInfo(&(col->colName));
		appendStringInfoString(&col->colName, NameStr(att->attname));

		/* Do we have a non-resjunk tlist item? */
		while (tlist_item &&
			   ((TargetEntry *) lfirst(tlist_item))->resjunk)
			tlist_item = lnext(targetlist, tlist_item);
		if (tlist_item)
		{
			tle = (TargetEntry *) lfirst(tlist_item);

			col->relOid = tle->resorigtbl;
			col->attrNum = tle->resorigcol;

			tlist_item = lnext(targetlist, tlist_item);
		}
		else
		{
			/* No info available, so send zeroes */
			col->relOid = 0;
			col->attrNum = 0;
		}

		SetAttributesForColmetada(col);

		switch (finfo->sendFuncId)
		{
				/*
				 * In case of Not NULL constraint on the column, send the
				 * variant type. This is only done for the Fixed length datat
				 * types except uniqueidentifier.
				 *
				 * TODO PG boolean is equivalent to TSQL BIT type
				 */
			case TDS_SEND_BIT:
				if (col->attNotNull)
					SetColMetadataForFixedType(col, VARIANT_TYPE_BIT, TDS_MAXLEN_BIT);
				else
					SetColMetadataForFixedType(col, TDS_TYPE_BIT, TDS_MAXLEN_BIT);
				break;
			case TDS_SEND_TINYINT:
				if (col->attNotNull)
					SetColMetadataForFixedType(col, VARIANT_TYPE_TINYINT, TDS_MAXLEN_TINYINT);
				else
					SetColMetadataForFixedType(col, TDS_TYPE_INTEGER, TDS_MAXLEN_TINYINT);
				break;
			case TDS_SEND_SMALLINT:
				if (col->attNotNull)
					SetColMetadataForFixedType(col, VARIANT_TYPE_SMALLINT, TDS_MAXLEN_SMALLINT);
				else
					SetColMetadataForFixedType(col, TDS_TYPE_INTEGER, TDS_MAXLEN_SMALLINT);
				break;
			case TDS_SEND_INTEGER:
				if (col->attNotNull)
					SetColMetadataForFixedType(col, VARIANT_TYPE_INT, TDS_MAXLEN_INT);
				else
					SetColMetadataForFixedType(col, TDS_TYPE_INTEGER, TDS_MAXLEN_INT);
				break;
			case TDS_SEND_BIGINT:
				if (col->attNotNull)
					SetColMetadataForFixedType(col, VARIANT_TYPE_BIGINT, TDS_MAXLEN_BIGINT);
				else
					SetColMetadataForFixedType(col, TDS_TYPE_INTEGER, TDS_MAXLEN_BIGINT);
				break;
			case TDS_SEND_FLOAT4:
				if (col->attNotNull)
					SetColMetadataForFixedType(col, VARIANT_TYPE_REAL, TDS_MAXLEN_FLOAT4);
				else
					SetColMetadataForFixedType(col, TDS_TYPE_FLOAT, TDS_MAXLEN_FLOAT4);
				break;
			case TDS_SEND_FLOAT8:
				if (col->attNotNull)
					SetColMetadataForFixedType(col, VARIANT_TYPE_FLOAT, TDS_MAXLEN_FLOAT8);
				else
					SetColMetadataForFixedType(col, TDS_TYPE_FLOAT, TDS_MAXLEN_FLOAT8);
				break;
			case TDS_SEND_CHAR:
				if (atttypmod == -1 && tle != NULL)
					atttypmod = TdsGetGenericTypmod((Node *) tle->expr);

				SetColMetadataForCharTypeHelper(col, TDS_TYPE_CHAR,
												att->attcollation, (atttypmod - 4));
				break;
			case TDS_SEND_NCHAR:
				if (atttypmod == -1 && tle != NULL)
					atttypmod = TdsGetGenericTypmod((Node *) tle->expr);

				SetColMetadataForCharTypeHelper(col, TDS_TYPE_NCHAR,
												att->attcollation, (atttypmod - 4) * 2);
				break;
			case TDS_SEND_VARCHAR:
				/* If this is one of the vector datatypes we should adjust the typmod. */
				if (is_this_a_vector_datatype(col->pgTypeOid))
					atttypmod = -1;

				SetColMetadataForCharTypeHelper(col, TDS_TYPE_VARCHAR,
												att->attcollation, (atttypmod == -1) ?
												atttypmod : (atttypmod - 4));
				break;
			case TDS_SEND_NVARCHAR:
				SetColMetadataForCharTypeHelper(col, TDS_TYPE_NVARCHAR,
												att->attcollation, (atttypmod == -1) ?
												atttypmod : (atttypmod - 4) * 2);
				break;
			case TDS_SEND_MONEY:
				if (col->attNotNull)
					SetColMetadataForFixedType(col, VARIANT_TYPE_MONEY, TDS_MAXLEN_MONEY);
				else
					SetColMetadataForFixedType(col, TDS_TYPE_MONEYN, TDS_MAXLEN_MONEY);
				break;
			case TDS_SEND_SMALLMONEY:
				if (col->attNotNull)
					SetColMetadataForFixedType(col, VARIANT_TYPE_SMALLMONEY, TDS_MAXLEN_SMALLMONEY);
				else
					SetColMetadataForFixedType(col, TDS_TYPE_MONEYN, TDS_MAXLEN_SMALLMONEY);
				break;
			case TDS_SEND_TEXT:
				SetColMetadataForTextTypeHelper(col, TDS_TYPE_TEXT,
												att->attcollation, (atttypmod - 4));
				sendTableName |= col->sendTableName;
				break;
			case TDS_SEND_NTEXT:
				SetColMetadataForTextTypeHelper(col, TDS_TYPE_NTEXT,
												att->attcollation, (atttypmod - 4) * 2);
				sendTableName |= col->sendTableName;
				break;
			case TDS_SEND_DATE:
				if (tdsVersion < TDS_VERSION_7_3_A)

					/*
					 * If client being connected is using TDS version lower
					 * than 7.3A then TSQL treats DATE as NVARCHAR. Max len
					 * here would be 20 ('YYYY-MM-DD').
					 */
					SetColMetadataForCharTypeHelper(col, TDS_TYPE_NVARCHAR, serverCollationOid, 20);
				else
					SetColMetadataForDateType(col, TDS_TYPE_DATE);
				break;
			case TDS_SEND_DATETIME:
				if (col->attNotNull)
					SetColMetadataForFixedType(col, VARIANT_TYPE_DATETIME, TDS_MAXLEN_DATETIME);
				else
					SetColMetadataForFixedType(col, TDS_TYPE_DATETIMEN, TDS_MAXLEN_DATETIME);
				break;
			case TDS_SEND_NUMERIC:
				{
					/*
					 * Try to resolve the typmod from tle->expr when typmod is
					 * not specified TDS client requires a valid typmod other
					 * than -1.
					 */
					if (atttypmod == -1 && tle != NULL)
					{
						if (!plannedstmt || !plannedstmt->planTree)
						{
							ereport(ERROR,
									(errcode(ERRCODE_INTERNAL_ERROR),
									 errmsg("Internal error detected while calculating the precision of numeric expression"),
									 errhint("plannedstmt is NULL while calculating the precision of numeric expression when it contains outer var")));
						}
						atttypmod = resolve_numeric_typmod_from_exp(plannedstmt->planTree, (Node *) tle->expr);
					}

					/*
					 * Get the precision and scale out of the typmod value if
					 * typmod is valid Otherwise
					 * tds_default_numeric_precision/scale will be used.
					 */
					if (atttypmod > VARHDRSZ)
					{
						scale = (atttypmod - VARHDRSZ) & 0xffff;
						precision = ((atttypmod - VARHDRSZ) >> 16) & 0xffff;
						if (precision > TDS_MAX_NUM_PRECISION)
						{
							ereport(ERROR, (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
											errmsg("Arithmetic overflow error for data type numeric.")));
						}
					}
					else
					{
						precision = tds_default_numeric_precision;
						scale = tds_default_numeric_scale;
					}
					SetColMetadataForNumericType(col, TDS_TYPE_NUMERICN, 17, precision, scale);
				}
				break;
			case TDS_SEND_SMALLDATETIME:
				if (col->attNotNull)
					SetColMetadataForFixedType(col, VARIANT_TYPE_SMALLDATETIME, TDS_MAXLEN_SMALLDATETIME);
				else
					SetColMetadataForFixedType(col, TDS_TYPE_DATETIMEN, TDS_MAXLEN_SMALLDATETIME);
				break;
			case TDS_SEND_IMAGE:
				SetColMetadataForImageType(col, TDS_TYPE_IMAGE);
				sendTableName |= col->sendTableName;
				break;
			case TDS_SEND_BINARY:

				/*
				 * Explicitly set typemod for rowversion because typmod won't
				 * be specified
				 */
				if (finfo->ttmtdstypelen == ROWVERSION_SIZE)
					atttypmod = ROWVERSION_SIZE + VARHDRSZ;

				/*
				 * The default binary data length is 1 when maxLen isn't
				 * specified
				 */
				SetColMetadataForBinaryType(col, TDS_TYPE_BINARY, (atttypmod == -1) ?
											1 : atttypmod - VARHDRSZ);
				break;
			case TDS_SEND_VARBINARY:
				if (atttypmod == -1 && tle != NULL)
					atttypmod = resolve_varbinary_typmod_from_exp((Node *) tle->expr);
				SetColMetadataForBinaryType(col, TDS_TYPE_VARBINARY, (atttypmod == -1) ?
											atttypmod : atttypmod - VARHDRSZ);
				break;
			case TDS_SEND_UNIQUEIDENTIFIER:
				SetColMetadataForFixedType(col, TDS_TYPE_UNIQUEIDENTIFIER, TDS_MAXLEN_UNIQUEIDENTIFIER);
				break;
			case TDS_SEND_TIME:
				if (tdsVersion < TDS_VERSION_7_3_A)

					/*
					 * If client being connected is using TDS version lower
					 * than 7.3A then TSQL treats TIME as NVARCHAR. Max len
					 * here would be 32 ('hh:mm:ss[.nnnnnnn]'). and Making use
					 * of default collation Oid.
					 */
					SetColMetadataForCharTypeHelper(col, TDS_TYPE_NVARCHAR, serverCollationOid, 32);
				else
				{
					/*
					 * if time data has no specific scale specified in the
					 * query, default scale to be considered is 7 always.
					 * However, setting default scale to 6 since postgres
					 * supports upto 6 digits after decimal point
					 */
					if (atttypmod == -1)
						atttypmod = DATETIMEOFFSETMAXSCALE;
					SetColMetadataForTimeType(col, TDS_TYPE_TIME, atttypmod);
				}
				break;
			case TDS_SEND_DATETIME2:
				if (tdsVersion < TDS_VERSION_7_3_A)

					/*
					 * If client being connected is using TDS version lower
					 * than 7.3A then TSQL treats DATETIME2 as NVARCHAR. Max
					 * len here would be 54('YYYY-MM-DD hh:mm:ss[.nnnnnnn]').
					 * and Making use of default collation Oid.
					 */
					SetColMetadataForCharTypeHelper(col, TDS_TYPE_NVARCHAR, serverCollationOid, 54);
				else
				{
					/*
					 * if Datetime2 data has no specific scale specified in
					 * the query, default scale to be considered is 7 always.
					 * However, setting default scale to 6 since postgres
					 * supports upto 6 digits after decimal point
					 */
					if (atttypmod == -1)
						atttypmod = DATETIMEOFFSETMAXSCALE;
					SetColMetadataForTimeType(col, TDS_TYPE_DATETIME2, atttypmod);
				}
				break;
			case TDS_SEND_XML:
				if (tdsVersion > TDS_VERSION_7_1_1)
					SetColMetadataForFixedType(col, TDS_TYPE_XML, 0);
				else
				{
					/*
					 * If client being connected is using TDS version lower
					 * than or equal to 7.1 then TSQL treats XML as NText.
					 */
					SetColMetadataForTextTypeHelper(col, TDS_TYPE_NTEXT,
													att->attcollation, (atttypmod - 4) * 2);
					sendTableName |= col->sendTableName;
				}
				break;
			case TDS_SEND_SQLVARIANT:
				SetColMetadataForImageType(col, TDS_TYPE_SQLVARIANT);
				break;
			case TDS_SEND_DATETIMEOFFSET:
				if (tdsVersion < TDS_VERSION_7_3_A)

					/*
					 * If client being connected is using TDS version lower
					 * than 7.3A then TSQL treats DATETIMEOFFSET as NVARCHAR.
					 * Max len here would be 64('YYYY-MM-DD hh:mm:ss[.nnnnnnn]
					 * [+|-]hh:mm'). and Making use of default collation Oid.
					 */
					SetColMetadataForCharTypeHelper(col, TDS_TYPE_NVARCHAR, serverCollationOid, 64);
				else
				{
					if (atttypmod == -1)
						atttypmod = DATETIMEOFFSETMAXSCALE;
					SetColMetadataForTimeType(col, TDS_TYPE_DATETIMEOFFSET, atttypmod);
				}
				break;
			case TDS_SEND_GEOMETRY:
				SetColMetadataForGeometryType(col, TDS_TYPE_CLRUDT, TDS_MAXLEN_POINT, TDS_ASSEMBLY_TYPE_NAME_GEOMETRY, "geometry");
				break;
			case TDS_SEND_GEOGRAPHY:
				SetColMetadataForGeographyType(col, TDS_TYPE_CLRUDT, TDS_MAXLEN_POINT, TDS_ASSEMBLY_TYPE_NAME_GEOGRAPHY, "geography");
				break;
			default:

				/*
				 * TODO: Need to create a mapping table for user defined data
				 * types and handle it here.
				 */
				ereport(ERROR,
						(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
						 errmsg("data type %d not supported yet", atttypid)));
		}
	}

	MemoryContextSwitchTo(oldContext);

	if (extendedInfo || sendTableName)
	{
		uint8		tableNum = 0;

		oldContext = MemoryContextSwitchTo(MessageContext);
		relMetaDataInfoList = NULL;

		for (attno = 0; attno < natts; attno++)
		{
			TdsColumnMetaData *col = &colMetaData[attno];
			ListCell   *lc;
			bool		found = false;

			if (col->relOid == 0)
			{
				col->baseColName = NULL;
				col->relinfo = NULL;
				continue;
			}

			/* fetch the actual column name */
			col->baseColName = get_attname(col->relOid, col->attrNum, false);

			/* look for a relation entry match */
			foreach(lc, relMetaDataInfoList)
			{
				TdsRelationMetaDataInfo relMetaDataInfo = (TdsRelationMetaDataInfo) lfirst(lc);
				Oid			relOid = relMetaDataInfo->relOid;

				if (relOid == col->relOid)
				{
					found = true;
					col->relinfo = relMetaDataInfo;
					break;
				}
			}

			/* if not found, add one */
			if (!found)
			{
				Relation	rel;
				TdsRelationMetaDataInfo relMetaDataInfo;
				char	   *physical_schema_name;

				relMetaDataInfo = (TdsRelationMetaDataInfo) palloc(sizeof(TdsRelationMetaDataInfoData));
				tableNum++;

				relMetaDataInfo->relOid = col->relOid;
				relMetaDataInfo->tableNum = tableNum;

				rel = relation_open(col->relOid, AccessShareLock);

				/* fetch the primary key attributes if needed */
				if (fetchPkeys)
					relMetaDataInfo->keyattrs = getPkeyAttnames(rel, &relMetaDataInfo->numkeyattrs);
				else
				{
					relMetaDataInfo->keyattrs = NULL;
					relMetaDataInfo->numkeyattrs = 0;
				}

				/* fetch the relation name, schema name */
				relMetaDataInfo->partName[0] = RelationGetRelationName(rel);
				physical_schema_name = get_namespace_name(RelationGetNamespace(rel));

				/*
				 * Here, we are assuming that we must have received a valid
				 * schema name from the engine. So first try to find the
				 * logical schema name corresponding to received physical
				 * schema name. If we could not find the logical schema name
				 * then we can say that received schema name is shared schema
				 * and we do not have to translate it to logical schema name.
				 */
				if (pltsql_plugin_handler_ptr &&
					pltsql_plugin_handler_ptr->pltsql_get_logical_schema_name)
					relMetaDataInfo->partName[1] = (char *) pltsql_plugin_handler_ptr->pltsql_get_logical_schema_name(physical_schema_name, true);

				/*
				 * If we could not find logical schema name then send physical
				 * schema name only assuming its shared schema.
				 */
				if (relMetaDataInfo->partName[1] == NULL)
					relMetaDataInfo->partName[1] = strdup(physical_schema_name);

				if (physical_schema_name)
					pfree(physical_schema_name);

				relation_close(rel, AccessShareLock);

				relMetaDataInfoList = lappend(relMetaDataInfoList, relMetaDataInfo);
				col->relinfo = relMetaDataInfo;
			}
		}

		MemoryContextSwitchTo(oldContext);
	}
}

/*
 * SendReturnValueTokenInternal
 *
 * status - stored procedure (0x01) or UDF (0x02)
 * forceCoercion - true if it needs datatype coercion before sending the data
 */
void
SendReturnValueTokenInternal(ParameterToken token, uint8 status,
							 FmgrInfo *finfo, Datum datum, bool isNull,
							 bool forceCoercion)
{
	uint8		temp8;
	uint16		temp16;
	StringInfo	name;
	FmgrInfo	temp;
	uint32_t	tdsVersion = GetClientTDSVersion();

	SendPendingDone(true);

	/* token type */
	TDS_DEBUG(TDS_DEBUG2, "SendReturnValueTokenInternal: token=0x%02x", TDS_TOKEN_RETURNVALUE);
	temp8 = TDS_TOKEN_RETURNVALUE;
	TdsPutbytes(&temp8, sizeof(temp8));

	/* param ordinal */
	if (tdsVersion <= TDS_VERSION_7_1_1)

		/*
		 * "BY OBSERVATION" The param ordinal is set to 13 instead of starting
		 * from 0 for clients with TDS verstion lower than or equal to TDS 7.1
		 * revision 1;
		 *
		 * This isn't mentioned in any of the documentations and making this
		 * change is necessary Since without this change we get TDS Protocol
		 * error from the Driver for RPCs.
		 */
		temp16 = 13;			/* TODO: why 13? */
	else
		temp16 = token->paramOrdinal;
	TdsPutbytes(&temp16, sizeof(temp16));

	/* param name len and param name ((here column name is in UTF-8 format) */
	name = &(token->paramMeta.colName);
	if (name->len > 0)
	{
		StringInfoData tempName;

		initStringInfo(&tempName);
		TdsUTF8toUTF16StringInfo(&tempName, name->data, name->len);

		temp8 = (uint8_t) pg_mbstrlen(name->data);
		TdsPutbytes(&temp8, sizeof(temp8));
		TdsPutbytes(tempName.data, tempName.len);

		pfree(tempName.data);
	}
	else
	{
		temp8 = name->len;
		TdsPutbytes(&temp8, sizeof(temp8));
	}

	/* status */
	TdsPutbytes(&status, sizeof(status));

	/*
	 * Instead of hardcoding the userType to 0 at various strucutures inside
	 * col->metaEntry we can write 0x0000 (for versions lower than TDS 7.2) or
	 * 0x00000000 (for TDS 7.2 and higher) directly on the wire depending
	 * version;
	 *
	 * TODO: TDS doc mentions some non-zero values for timestamp and aliases
	 * NOTE: We have always sent UserType as 0 and clients have never
	 * complained about it.
	 */
	if (tdsVersion <= TDS_VERSION_7_1_1)
		TdsPutInt16LE(0);
	else
		TdsPutInt32LE(0);

	/* meta entries */
	TdsPutbytes(&(token->paramMeta.metaEntry), token->paramMeta.metaLen);

	if (isNull)
	{
		switch (token->paramMeta.metaEntry.type1.tdsTypeId)
		{
			case TDS_TYPE_TEXT:
			case TDS_TYPE_NTEXT:
			case TDS_TYPE_IMAGE:

				/*
				 * MS-TDS doc, section 2.2.4.2.1.3 - Null is represented by a
				 * length of -1 (0xFFFFFFFF).
				 */
				TdsPutUInt32LE(0xFFFFFFFF);
				break;
			case TDS_TYPE_CHAR:
			case TDS_TYPE_NCHAR:
			case TDS_TYPE_VARCHAR:
			case TDS_TYPE_NVARCHAR:
			case TDS_TYPE_BINARY:
			case TDS_TYPE_VARBINARY:
			case TDS_TYPE_XML:

				/*
				 * MS-TDS doc, section 2.2.4.2.1.3 - Null is represented by a
				 * length of -1 (0xFFFF).
				 */
				if (token->maxLen == 0xFFFF)
					TdsPutUInt64LE(PLP_NULL);
				else
					TdsPutUInt16LE(0xFFFF);
				break;
			default:

				/*
				 * MS-TDS doc, section 2.2.4.2.1.2 - Null is represented by a
				 * length of 0. (Fixed length datatypes)
				 */
				temp16 = 0;
				TdsPutbytes(&temp16, token->paramMeta.sizeLen);
				break;
		}

		/* we're done */
		return;
	}
	else if (forceCoercion)
	{
		int32		result = -1;
		Oid			castFuncOid = InvalidOid;
		CoercionPathType pathtype;

		/*
		 * In TDS, we should send the OUT parameters with the
		 * length/scale/precision specified by the caller.  In that case, we
		 * may need to do a self-casting. Here are the steps: 1. Find the
		 * self-cast function if it's available. 2. Call the typmodin function
		 * that returns the attypmod corresponding to the caller provided
		 * length/scale/precision. 3. Call the self-cast function to cast the
		 * datum with the above attypmod.
		 */

		/*
		 * Check if the type has a function for length/scale/precision
		 * coercion
		 */
		pathtype = find_typmod_coercion_function(token->paramMeta.pgTypeOid, &castFuncOid);

		/*
		 * If we found a function to perform the coercion, do it.  We don't
		 * support other types of coearcion, so just ignore it.
		 */
		if (pathtype == COERCION_PATH_FUNC)
			result = GetTypModForToken(token);

		/* If we found a valid attypmod, perform the casting. */
		if (result != -1)
		{
			datum = OidFunctionCall3(castFuncOid, datum,
									 Int32GetDatum(result),
									 BoolGetDatum(true));
		}
	}

	/* should in a transaction, because we'll do a catalog lookup */
	if (!finfo && IsTransactionState())
	{
		Oid			typoutputfunc;
		bool		typIsVarlena;

		Assert(token->paramMeta.pgTypeOid != InvalidOid);
		getTypeOutputInfo(token->paramMeta.pgTypeOid, &typoutputfunc, &typIsVarlena);
		fmgr_info(typoutputfunc, &temp);
		finfo = &temp;
	}

	/* send the data */
	(token->paramMeta.sendFunc) (finfo, datum, (void *) &token->paramMeta);
}

int
GetTypModForToken(ParameterToken token)
{
	int32		typmod = -1;
	Datum	   *datums = NULL;
	ArrayType  *arrtypmod = NULL;
	char	   *cstr = NULL;
	int			n;
	Oid			pgtypemodin;

	/*
	 * Forcing coercion needs catalog access.  Hence, we should be in a
	 * transaction.
	 */
	Assert(IsTransactionState());

	/*
	 * Prepare the argument for calling the typmodin function.  We need to
	 * pass the argument as an array.  Each type will have different number of
	 * elements in the array.
	 */
	n = 0;
	switch (token->paramMeta.metaEntry.type1.tdsTypeId)
	{
		case TDS_TYPE_CHAR:
		case TDS_TYPE_VARCHAR:
			/* We don't have to perform any length coercion for PLP data */
			if (token->maxLen == 0xFFFF)
				break;

			/* it only consists of the maxlen */
			datums = (Datum *) palloc(1 * sizeof(Datum));

			cstr = psprintf("%ld", (long) token->paramMeta.metaEntry.type2.maxSize);
			datums[n++] = CStringGetDatum(cstr);
			break;
		case TDS_TYPE_NCHAR:
		case TDS_TYPE_NVARCHAR:
			/* We don't have to perform any length coercion for PLP data */
			if (token->maxLen == 0xFFFF)
				break;

			/* it only consists of the maxlen */
			datums = (Datum *) palloc(1 * sizeof(Datum));

			cstr = psprintf("%ld", (long) token->paramMeta.metaEntry.type2.maxSize / 2);
			datums[n++] = CStringGetDatum(cstr);
			break;
		case TDS_TYPE_DECIMALN:
		case TDS_TYPE_NUMERICN:
			/* it consists of scale and precision */
			datums = (Datum *) palloc(2 * sizeof(Datum));

			cstr = psprintf("%ld", (long) token->paramMeta.metaEntry.type5.precision);
			datums[n++] = CStringGetDatum(cstr);
			cstr = psprintf("%ld", (long) token->paramMeta.metaEntry.type5.scale);
			datums[n++] = CStringGetDatum(cstr);
			break;
		case TDS_TYPE_TIME:
		case TDS_TYPE_DATETIME2:
			/* it only consists of scale */
			datums = (Datum *) palloc(1 * sizeof(Datum));

			cstr = psprintf("%ld", (long) token->paramMeta.metaEntry.type6.scale);
			datums[n++] = CStringGetDatum(cstr);
			break;
		case TDS_TYPE_BINARY:
		case TDS_TYPE_VARBINARY:
			/* We don't have to perform any length coercion for PLP data */
			if (token->maxLen == 0xFFFF)
				break;

			/* it only consists of the maxlen */
			datums = (Datum *) palloc(1 * sizeof(Datum));
			cstr = psprintf("%ld", (long) token->paramMeta.metaEntry.type7.maxSize);
			datums[n++] = CStringGetDatum(cstr);
			break;
		case TDS_TYPE_IMAGE:
			ereport(ERROR, (errcode(ERRCODE_DATA_EXCEPTION),
							errmsg("Data type 0x22(Image) is a deprecated LOB.\
					Deprecated types are not supported as output parameters.")));
			break;
		default:
			break;
	}

	/* If we've prepared the argument, proceed. */
	if (datums)
	{
		/* hardwired knowledge about cstring's representation details here */
		arrtypmod = construct_array(datums, n, CSTRINGOID,
									-2, false, 'c');

		pgtypemodin = get_typmodin(token->paramMeta.pgTypeOid);
		typmod = DatumGetInt32(OidFunctionCall1(pgtypemodin,
												PointerGetDatum(arrtypmod)));

		/* be tidy */
		pfree(datums);
		pfree(arrtypmod);
	}

	return typmod;
}

void
TdsSendEnvChange(int envid, const char *new_val, const char *old_val)
{
	StringInfoData newUtf16;
	StringInfoData oldUtf16;
	int16_t		totalLen;
	uint8		temp8;

	initStringInfo(&newUtf16);
	initStringInfo(&oldUtf16);

	SendPendingDone(true);

	if (new_val)
		TdsUTF8toUTF16StringInfo(&newUtf16, new_val, strlen(new_val));
	if (old_val)
		TdsUTF8toUTF16StringInfo(&oldUtf16, old_val, strlen(old_val));
	totalLen = 1				/* envid */
		+ 1						/* new len */
		+ newUtf16.len
		+ 1						/* old len */
		+ oldUtf16.len;

	TDS_DEBUG(TDS_DEBUG2, "TdsSendEnvChange: token=0x%02x", TDS_TOKEN_ENVCHANGE);
	temp8 = TDS_TOKEN_ENVCHANGE;
	TdsPutbytes(&temp8, sizeof(temp8));

	TdsPutbytes(&totalLen, sizeof(totalLen));
	TdsPutbytes(&envid, sizeof(temp8));

	if (new_val)
	{
		temp8 = newUtf16.len / 2;
		TdsPutbytes(&temp8, sizeof(temp8));
		TdsPutbytes(newUtf16.data, newUtf16.len);
	}
	else
	{
		temp8 = 0;
		TdsPutbytes(&temp8, sizeof(temp8));
	}

	if (old_val)
	{
		temp8 = oldUtf16.len / 2;
		TdsPutbytes(&temp8, sizeof(temp8));
		TdsPutbytes(oldUtf16.data, oldUtf16.len);
	}
	else
	{
		temp8 = 0;
		TdsPutbytes(&temp8, sizeof(temp8));
	}

	pfree(newUtf16.data);
	pfree(oldUtf16.data);
}

void
TdsSendEnvChangeBinary(int envid, void *new, int newNbytes,
					   void *old, int oldNbytes)
{
	int16_t		totalLen;
	uint8		temp8;

	SendPendingDone(true);

	totalLen = 1				/* envid */
		+ 1						/* new len */
		+ newNbytes
		+ 1						/* old len */
		+ oldNbytes;

	TDS_DEBUG(TDS_DEBUG2, "TdsSendEnvChangeBinary: token=0x%02x", TDS_TOKEN_ENVCHANGE);
	temp8 = TDS_TOKEN_ENVCHANGE;
	TdsPutbytes(&temp8, sizeof(temp8));

	TdsPutbytes(&totalLen, sizeof(totalLen));
	temp8 = envid;
	TdsPutbytes(&envid, sizeof(temp8));

	temp8 = newNbytes;
	TdsPutbytes(&temp8, sizeof(temp8));
	TdsPutbytes(new, newNbytes);

	temp8 = oldNbytes;
	TdsPutbytes(&temp8, sizeof(temp8));
	TdsPutbytes(old, oldNbytes);
}

void
TdsSendInfo(int number, int state, int class,
			char *message, int lineNo)
{
	TdsSendInfoOrError(TDS_TOKEN_INFO, number, state, class,
					   message,
					   "BABELFISH", /* TODO: where to get this? */
					   "",		/* TODO: where to get this? */
					   lineNo);
}

void
TdsSendError(int number, int state, int class,
			 char *message, int lineNo)
{
	/*
	 * If not already in RESPONSE mode, switch the TDS protocol to RESPONSE
	 * mode.
	 */
	TdsSetMessageType(TDS_RESPONSE);

	/*
	 * It is possible that we fail while trying to send a message to client
	 * (for example, because of encoding conversion failure). Therefore, we
	 * place a PG_TRY block here to handle those scenario.
	 */
	PG_TRY();
	{
		TdsSendInfoOrError(TDS_TOKEN_ERROR, number, state, class,
						   message,
						   "BABELFISH",
						   "",
						   lineNo);
	}
	PG_CATCH();
	{
		/* Send message to client that internal error occurred */
		TdsSendInfoOrError(TDS_TOKEN_ERROR, ERRCODE_PLTSQL_ERROR_NOT_MAPPED, 1, 16,
						   "internal error occurred",
						   "BABELFISH",
						   "",
						   lineNo);
		PG_RE_THROW();
	}
	PG_END_TRY();

	markErrorFlag = true;
}

void
TdsSendInfoOrError(int token, int number, int state, int class,
				   char *message, char *serverName, char *procName,
				   int lineNo)
{
	StringInfoData messageUtf16;
	StringInfoData serverNameUtf16;
	StringInfoData procNameUtf16;
	int			lineNoLen;
	int			messageLen = strlen(message);
	int			serverNameLen = strlen(serverName);
	int			procNameLen = strlen(procName);
	int16_t		messageLen_16;
	int32_t		number_32 = (int32_t) number;
	int32_t		lineNo_32 = (int32_t) lineNo;
	int16_t		totalLen;
	uint8		temp8;
	uint32_t	tdsVersion = GetClientTDSVersion();

	/*
	 * For Client TDS Version less than or equal to 7.1 Line Number is of 2
	 * bytes and for TDS versions higher than 7.1 it is of 4 bytes.
	 */
	if (tdsVersion <= TDS_VERSION_7_1_1)
		lineNoLen = sizeof(int16_t);
	else
		lineNoLen = sizeof(int32_t);

	initStringInfo(&messageUtf16);
	initStringInfo(&serverNameUtf16);
	initStringInfo(&procNameUtf16);

	TdsUTF8toUTF16StringInfo(&messageUtf16, message, messageLen);
	TdsUTF8toUTF16StringInfo(&serverNameUtf16, serverName, serverNameLen);
	TdsUTF8toUTF16StringInfo(&procNameUtf16, procName, procNameLen);

	messageLen_16 = messageUtf16.len / 2;

	SendPendingDone(true);

	totalLen = sizeof(number_32)	/* error number */
		+ 1						/* state */
		+ 1						/* class */
		+ sizeof(messageLen_16) /* message len */
		+ messageUtf16.len		/* message */
		+ 1						/* server_name_len */
		+ serverNameUtf16.len	/* server_name */
		+ 1						/* proc_name_len */
		+ procNameUtf16.len		/* proc_name */
		+ lineNoLen;			/* line_no */

	/* Send Info or Error Token. */
	TDS_DEBUG(TDS_DEBUG2, "TdsSendInfoOrError: token=0x%02x", token);
	temp8 = token;
	TdsPutbytes(&temp8, sizeof(temp8));
	TdsPutbytes(&totalLen, sizeof(totalLen));
	TdsPutbytes(&number_32, sizeof(number_32));

	temp8 = state;
	TdsPutbytes(&temp8, sizeof(temp8));

	temp8 = class;
	TdsPutbytes(&temp8, sizeof(temp8));

	TdsPutbytes(&messageLen_16, sizeof(messageLen_16));
	TdsPutbytes(messageUtf16.data, messageUtf16.len);

	temp8 = serverNameLen;
	TdsPutbytes(&temp8, sizeof(temp8));
	TdsPutbytes(serverNameUtf16.data, serverNameUtf16.len);

	temp8 = procNameLen;
	TdsPutbytes(&temp8, sizeof(temp8));
	TdsPutbytes(procNameUtf16.data, procNameUtf16.len);

	if (tdsVersion <= TDS_VERSION_7_1_1)
	{
		int16_t		lineNo_16;

		if (lineNo > PG_INT16_MAX)
			ereport(FATAL, (errmsg("Line Number execeeds INT16_MAX")));
		else
			lineNo_16 = (int16_t) lineNo;
		TdsPutbytes(&lineNo_16, lineNoLen);
	}
	else
		TdsPutbytes(&lineNo_32, lineNoLen);

	pfree(messageUtf16.data);
	pfree(serverNameUtf16.data);
	pfree(procNameUtf16.data);
}

void
TdsSendRowDescription(TupleDesc typeinfo, PlannedStmt *plannedstmt,
					  List *targetlist, int16 *formats)
{
	TDSRequest	request = TdsRequestCtrl->request;

	/* If we reach here, typeinfo should not be null. */
	Assert(typeinfo != NULL);

	/* Prepare the column metadata first */
	PrepareRowDescription(typeinfo, plannedstmt, targetlist, formats, false, false);

	/*
	 * If fNoMetadata flags is set in RPC header flag, the server doesn't need
	 * to send the metadata again for COLMETADATA token.  In that case the,
	 * the server sends only NoMetaData (0xFFFF) field in COLMETADATA token.
	 */
	if (request->reqType == TDS_REQUEST_SP_NUMBER)
	{
		TDSRequestSP req = (TDSRequestSP) request;

		/*
		 * Send Column Metadata for SP_PREPARE, SP_PREPEXEC, SP_EXECUTE and
		 * SP_EXECUTESQL even if the FLAG is set to true, since TSQL does the
		 * same.
		 */
		if ((req->spFlags & SP_FLAGS_NOMETADATA) && (req->spType != SP_PREPARE)
			&& (req->spType != SP_PREPEXEC) && (req->spType != SP_EXECUTE) && (req->spType != SP_EXECUTESQL))
		{
			TDS_DEBUG(TDS_DEBUG2, "SendColumnMetadataToken: token=0x%02x", TDS_TOKEN_COLMETADATA);
			TdsPutInt8(TDS_TOKEN_COLMETADATA);
			TdsPutInt8(0xFF);
			TdsPutInt8(0xFF);
			return;
		}
	}

	SendColumnMetadataToken(typeinfo->natts, false);
}

bool
TdsPrintTup(TupleTableSlot *slot, DestReceiver *self)
{
	TupleDesc	typeinfo = slot->tts_tupleDescriptor;
	DR_printtup *myState = (DR_printtup *) self;
	MemoryContext oldContext;
	int			natts = typeinfo->natts;
	int			attno;
	uint8_t		rowToken;
	TDSRequest	request = TdsRequestCtrl->request;
	bool		sendRowStat = false;
	int			nullMapSize = 0;
	int			simpleRowSize = 0;
	uint32_t	tdsVersion = GetClientTDSVersion();
	uint8_t    *nullMap = NULL;

	TdsErrorContext->err_text = "Writing the Tds response to the socket";
	if (request->reqType == TDS_REQUEST_SP_NUMBER)
	{
		TDSRequestSP req = (TDSRequestSP) request;

		/* ROWSTAT token is sent for sp_cursorfetch */
		if (req->spType == SP_CURSORFETCH)
			sendRowStat = true;
	}

	/* Set or update my derived attribute info, if needed */
	if (myState->attrinfo != typeinfo || myState->nattrs != natts)
		PrintTupPrepareInfo(myState, typeinfo, natts);

	/* Make sure the tuple is fully deconstructed */
	slot_getallattrs(slot);

	/* Switch into per-row context so we can recover memory below */
	oldContext = MemoryContextSwitchTo(myState->tmpcontext);

	if (tdsVersion >= TDS_VERSION_7_3_B)
	{
		/*
		 * NBCROW token was introduced in TDS version 7.3B. Determine the row
		 * type we send. For rows that don't contain any NULL values in
		 * variable size columns (like NVARCHAR) we can send the simple ROW
		 * (0xD1) format. Rows that do (specifically
		 * NVARCHAR/VARCHAR/CHAR/NCHAR/BINARY datatypes) need to be sent as
		 * NBCROW (0xD2). Count the number of nullable columns and build the
		 * null bitmap just in case while we are at it.
		 */

		if (sendRowStat)
			/* Extra bit for the ROWSTAT column */
			nullMapSize = (natts + 1 + 7) >> 3;
		else
			nullMapSize = (natts + 7) >> 3;

		nullMap = palloc0(nullMapSize);
		MemSet(nullMap, 0, nullMapSize * sizeof(int8_t));
		for (attno = 0; attno < natts; attno++)
		{
			TdsColumnMetaData *col = &colMetaData[attno];

			if (col->metaEntry.type1.flags & TDS_COLMETA_NULLABLE)
			{
				if (slot->tts_isnull[attno])
				{
					nullMap[attno / 8] |= (0x01 << (attno & 0x07));
					switch (col->metaEntry.type1.tdsTypeId)
					{
						case TDS_TYPE_VARCHAR:
						case TDS_TYPE_NVARCHAR:
							if (col->metaEntry.type2.maxSize == 0xffff)

								/*
								 * To send NULL for VARCHAR(max) or
								 * NVARCHAR(max), we have to indicate it using
								 * 0xffffffffffffffff (PLP_NULL)
								 */
								simpleRowSize += 8;
							else

								/*
								 * For regular case of VARCHAR/NVARCHAR, we
								 * have to send 0xffff (CHARBIN_NULL) to
								 * indicate NULL
								 */
								simpleRowSize += 2;
							break;
						case TDS_TYPE_VARBINARY:
							if (col->metaEntry.type7.maxSize == 0xffff)

								/*
								 * To send NULL for VARBINARY(max),we have to
								 * indicate it using 0xffffffffffffffff
								 * (PLP_NULL)
								 */
								simpleRowSize += 8;
							else

								/*
								 * For regular case of VARBINARY,we have to
								 * send 0xffff (CHARBIN_NULL) to indicate NULL
								 */
								simpleRowSize += 2;
							break;
						case TDS_TYPE_CHAR:
						case TDS_TYPE_NCHAR:
						case TDS_TYPE_BINARY:

							/*
							 * For these datatypes, we need to send 0xffff
							 * (CHARBIN_NULL) to indicate NULL
							 */
							simpleRowSize += 2;
							break;
						case TDS_TYPE_XML:
							/*
							 * To send NULL,we have to
							 * indicate it using 0xffffffffffffffff
							 * (PLP_NULL)
							 */
							simpleRowSize += 8;
							break;
						case TDS_TYPE_SQLVARIANT:

							/*
							 * For sql_variant, we need to send 0x00000000 to
							 * indicate NULL
							 */
							simpleRowSize += 4;
							break;
						default:

							/*
							 * for other datatypes, we need to send 0x00 (1
							 * byte) only
							 */
							simpleRowSize += 1;
							break;
					}
				}
			}
		}

		if (nullMapSize <= simpleRowSize)
		{
			rowToken = TDS_TOKEN_NBCROW;
		}
		else
		{
			rowToken = TDS_TOKEN_ROW;
		}
	}
	else

		/*
		 * ROW is only token to send data for TDS version lower or equal to
		 * 7.3A.
		 */
		rowToken = TDS_TOKEN_ROW;
	/* Send the row token and the NULL bitmap if it is NBCROW */
	TDS_DEBUG(TDS_DEBUG2, "rowToken = 0x%02x", rowToken);
	TdsPutbytes(&rowToken, sizeof(rowToken));

	if (rowToken == TDS_TOKEN_NBCROW)
	{
		TdsPutbytes(nullMap, nullMapSize);
		TDSInstrumentation(INSTR_TDS_TOKEN_NBCROW);
	}

	if (nullMap != NULL)
		pfree(nullMap);

	/* And finally send the actual column values */
	for (attno = 0; attno < natts; attno++)
	{
		PrinttupAttrInfo *thisState;
		Datum		attr;
		TdsColumnMetaData *col = &colMetaData[attno];

		if (slot->tts_isnull[attno])
		{
			/* Handle NULL values */
			/*
			 * when NBCROW token is used, all NULL values are sent using NULL
			 * bitmap only
			 */
			if (rowToken == TDS_TOKEN_ROW)
			{
				switch (col->metaEntry.type1.tdsTypeId)
				{
					case TDS_TYPE_VARCHAR:
					case TDS_TYPE_NVARCHAR:
						if (col->metaEntry.type2.maxSize == 0xffff)

							/*
							 * To send NULL for VARCHAR(max) or NVARCHAR(max),
							 * we have to indicate it using 0xffffffffffffffff
							 * (PLP_NULL)
							 */
							TdsPutUInt64LE(0xffffffffffffffff);
						else

							/*
							 * For regular case of VARCHAR/NVARCHAR, we have
							 * to send 0xffff (CHARBIN_NULL) to indicate NULL
							 */
							TdsPutInt16LE(0xffff);
						break;
					case TDS_TYPE_VARBINARY:
						if (col->metaEntry.type7.maxSize == 0xffff)

							/*
							 * To send NULL for VARBINARY(max),we have to
							 * indicate it using 0xffffffffffffffff (PLP_NULL)
							 */
							TdsPutUInt64LE(0xffffffffffffffff);
						else

							/*
							 * For regular case of VARBINARY,we have to send
							 * 0xffff (CHARBIN_NULL) to indicate NULL
							 */
							TdsPutInt16LE(0xffff);
						break;
					case TDS_TYPE_CHAR:
					case TDS_TYPE_NCHAR:
					case TDS_TYPE_BINARY:

						/*
						 * In case of TDS version lower than or equal to 7.3A,
						 * we need to send 0xffff (CHARBIN_NULL)
						 */
						TdsPutInt16LE(0xffff);
						break;
					case TDS_TYPE_XML:

						/*
						 * In case of TDS version lower than or equal to 7.3A,
						 * we need to send 0xffffffffffffffff (PLP_NULL)
						 */
						TdsPutUInt64LE(0xffffffffffffffff);
						break;
					case TDS_TYPE_SQLVARIANT:

						/*
						 * For sql_variant, we need to send 0x00000000 to
						 * indicate NULL
						 */
						TdsPutInt32LE(0);
						break;
					default:

						/*
						 * for these datatypes, we need to send 0x00 (1 byte)
						 * only
						 */
						TdsPutUInt8(0);
						break;
				}
			}
			continue;
		}

		thisState = myState->myinfo + attno;
		attr = slot->tts_values[attno];

		/*
		 * Here we catch undefined bytes in datums that are returned to the
		 * client without hitting disk; see comments at the related check in
		 * PageAddItem().  This test is most useful for uncompressed,
		 * non-external datums, but we're quite likely to see such here when
		 * testing new C functions.
		 */
		if (thisState->typisvarlena)
			VALGRIND_CHECK_MEM_IS_DEFINED(DatumGetPointer(attr),
										  VARSIZE_ANY(attr));

		/* Call the type specific output function */
		(col->sendFunc) (&thisState->finfo, attr, (void *) col);
	}

	/*
	 * For cursor fetch operation, we need to send the row status information.
	 * It can be either SP_CURSOR_FETCH_SUCCEEDED or SP_CURSOR_FETCH_MISSING.
	 * Since, we've reached here, we are definitely returning a tuple.  So, we
	 * should set the flag as succeeded.
	 *
	 * XXX: We need to figure out a way to set the flag
	 * SP_CURSOR_FETCH_MISSING when we can't fetch the underlying tuple.  It's
	 * only possible in case of sensitive cursors when the underlying tuple
	 * may have been deleted.  In that case, the tds protocol prepares a dummy
	 * row with the missing data (nullable fields set to null, fixed length
	 * fields set to 0, blank, or the default for that column, as appropriate)
	 * followed by SP_CURSOR_FETCH_MISSING as the value of ROWSTAT column.
	 */
	if (sendRowStat)
		(void) TdsPutInt32LE(SP_CURSOR_FETCH_SUCCEEDED);

	/* Return to caller's context, and flush row's temporary memory */
	MemoryContextSwitchTo(oldContext);
	MemoryContextReset(myState->tmpcontext);

	return true;
}

void
TdsPrintTupShutdown(void)
{
	pfree(colMetaData);
	colMetaData = NULL;
}

/* --------------------------------
 * TdsSendReturnStatus - send a return status token
 * --------------------------------
 */
void
TdsSendReturnStatus(int status)
{
	uint8		temp8;
	int32_t		tmp;

	TdsErrorContext->err_text = "Writing Return Status Token";
	SendPendingDone(true);

	TDS_DEBUG(TDS_DEBUG2, "TdsSendReturnStatus: token=0x%02x", TDS_TOKEN_RETURNSTATUS);
	temp8 = TDS_TOKEN_RETURNSTATUS;
	TdsPutbytes(&temp8, sizeof(temp8));

	tmp = htoLE32(status);
	TdsPutbytes(&status, sizeof(tmp));
}

/* --------------------------------
 * TdsSendDone - Queue a DONE message
 *
 * Since we don't know for sure if this is going to be the final DONE
 * message we only queue it at this point. The next time TdsPutbytes()
 * or TdsFlush is called we finalize the flags and send add it to
 * the output stream.
 * --------------------------------
 */
void
TdsSendDone(int token, int status, int curcmd, uint64_t nprocessed)
{
	bool		gucNocount = false;


	TdsErrorContext->err_text = "Writing Done Token";

	/* should be initialized already */
	Assert(pltsql_plugin_handler_ptr);
	if (pltsql_plugin_handler_ptr->pltsql_nocount_addr)
		gucNocount = *(pltsql_plugin_handler_ptr->pltsql_nocount_addr);

	if (TdsRequestCtrl)
		TdsRequestCtrl->isEmptyResponse = false;

	TDS_DEBUG(TDS_DEBUG2, "TdsSendDone: token=0x%02x, status=%d, curcmd=%d, "
			  "nprocessed=%lu nocount=%d",
			  token, status, curcmd, nprocessed, gucNocount);

	/*
	 * If we have a pending DONE token and encounter another one then the
	 * pending DONE is not the final one. Add the DONE_MORE flag and add it to
	 * the output buffer.
	 */
	SendPendingDone(true);

	/* Remember the DONE information as pending */
	TdsHavePendingDone = true;
	TdsPendingDoneNocount = gucNocount;
	TdsPendingDoneToken = token;
	TdsPendingDoneStatus = status;
	TdsPendingDoneCurCmd = curcmd;
	TdsPendingDoneRowCnt = nprocessed;

	if (markErrorFlag)
		TdsPendingDoneStatus |= TDS_DONE_ERROR;

	markErrorFlag = false;
}

int
TdsFlush(void)
{
	SendPendingDone(false);

	/* reset flags */
	markErrorFlag = false;

	/*
	 * The current execution stack must be zero.  Otherwise, some of our
	 * execution assumtion may have gone wrong.
	 */
	Assert(!tds_estate || tds_estate->current_stack == 0);

	/* reset error data */
	if (tds_estate)
		ResetTdsEstateErrorData();

	return TdsSocketFlush();
}

void
TDSStatementBeginCallback(PLtsql_execstate *estate, PLtsql_stmt *stmt)
{
	if (tds_estate == NULL)
		return;

	TDS_DEBUG(TDS_DEBUG3, "begin %d", tds_estate->current_stack);
	tds_estate->current_stack++;

	/* shouldn't have any un-handled error while begining the next statement */
	Assert(tds_estate->error_stack_offset == 0);

	if (stmt == NULL)
		return;

	/*
	 * TODO: It's possible that for some statements, we've to send a done toke
	 * when we start the command and another done token when we end the
	 * command. TRY..CATCH is one such example.  We can use this function to
	 * send the done token at the beginning of the command.
	 */
}

static void
StatementEnd_Internal(PLtsql_execstate *estate, PLtsql_stmt *stmt, bool error)
{
	int			token_type = TDS_TOKEN_DONEPROC;
	int			command_type = TDS_CMD_UNKNOWN;
	int			flags = 0;
	uint64_t	nprocessed = 0;
	bool		toplevel = false;
	bool		is_proc = false;
	bool		skip_done = false;
	bool		row_count_valid = false;

	tds_estate->current_stack--;
	TDS_DEBUG(TDS_DEBUG3, "end %d", tds_estate->current_stack);
	toplevel = (tds_estate->current_stack == 0);


	/*
	 * If we're ending a statement, that means we've already handled the
	 * error. In that case, just clear the error offset.
	 */
	tds_estate->error_stack_offset = 0;

	/*
	 * Return if we are inside a function. Continue if it's a trigger.
	 */
	if (estate && estate->func && estate->func->fn_oid != InvalidOid &&
		estate->func->fn_prokind == PROKIND_FUNCTION && estate->func->fn_is_trigger == PLTSQL_NOT_TRIGGER)
		return;

	if (stmt == NULL)
		return;

	/* TODO: handle all the cases */
	switch (stmt->cmd_type)
	{
		case PLTSQL_STMT_GOTO:
		case PLTSQL_STMT_RETURN:
			/* Used in inline table valued functions */
		case PLTSQL_STMT_RETURN_QUERY:
			/* Used in multi-statement table valued functions */
		case PLTSQL_STMT_DECL_TABLE:
		case PLTSQL_STMT_RETURN_TABLE:
			{
				/* Done token is not expected for these commands */
				skip_done = true;
			}
			break;
		case PLTSQL_STMT_ASSIGN:
		case PLTSQL_STMT_PUSH_RESULT:
			{
				command_type = TDS_CMD_SELECT;
				row_count_valid = true;
			}
			break;
		case PLTSQL_STMT_EXECSQL:
			{
				ListCell   *l;
				PLtsql_expr *expr = ((PLtsql_stmt_execsql *) stmt)->sqlstmt;

				/*
				 * XXX: Once an error occurs, the expr and expr->plan may be
				 * freed.  In that case, we've to save the command type in
				 * PLtsql_stmt_execsql before the execution.
				 */
				if (expr && expr->plan)
				{
					foreach(l, SPI_plan_get_plan_sources(expr->plan))
					{
						CachedPlanSource *plansource = (CachedPlanSource *) lfirst(l);

						if (plansource->commandTag)
						{
							if (plansource->commandTag == CMDTAG_INSERT)
							{
								command_type = TDS_CMD_INSERT;

								/*
								 * row_count should be invalid if the INSERT
								 * is inside the procedure of an INSERT-EXEC,
								 * or if the INSERT itself is an INSERT-EXEC
								 * and it just returned error.
								 */
								row_count_valid = !estate->insert_exec &&
									!(markErrorFlag &&
									  ((PLtsql_stmt_execsql *) stmt)->insert_exec);
							}
							else if (plansource->commandTag == CMDTAG_UPDATE)
							{
								command_type = TDS_CMD_UPDATE;
								row_count_valid = !estate->insert_exec;
							}
							else if (plansource->commandTag == CMDTAG_DELETE)
							{
								command_type = TDS_CMD_DELETE;
								row_count_valid = !estate->insert_exec;
							}

							/*
							 * [BABEL-2090] SELECT statement should show 'rows
							 * affected' count
							 */
							else if (plansource->commandTag == CMDTAG_SELECT)
							{
								command_type = TDS_CMD_SELECT;
								row_count_valid = !estate->insert_exec;
							}
						}
					}
				}

				/*
				 * Done token is not expected for INSERT/UPDATE/DELETE
				 * statements on table variables in user-defined functions.
				 */
				if (((PLtsql_stmt_execsql *) stmt)->mod_stmt_tablevar &&
					estate->func->fn_prokind == PROKIND_FUNCTION &&
					estate->func->fn_is_trigger == PLTSQL_NOT_TRIGGER &&
					strcmp(estate->func->fn_signature, "inline_code_block") != 0)
					skip_done = true;
			}
			break;
		case PLTSQL_STMT_EXEC:
		case PLTSQL_STMT_EXEC_BATCH:
		case PLTSQL_STMT_EXEC_SP:
			{
				is_proc = true;
				command_type = TDS_CMD_EXECUTE;
			}
			break;
		default:
			break;
	}

	/*
	 * XXX: For SP_CUSTOMTYPE, if we're done executing the top level stored
	 * procedure,  we need to send the return status and OUT parameters before
	 * the DONEPROC token.
	 */
	if (toplevel && is_proc)
	{
		TDSRequest	request = TdsRequestCtrl->request;

		if (request->reqType == TDS_REQUEST_SP_NUMBER)
		{
			TDSRequestSP req = (TDSRequestSP) request;

			if (req->spType == SP_CUSTOMTYPE)
				return;
		}
	}

	/*
	 * Send return status token if executed a procedure at top-level N.B. It's
	 * possible that the EXEC statement itself throws an error.  In that case,
	 * this token will follow an error token.  We should not send a return
	 * status in that case.
	 */
	if (!markErrorFlag && toplevel && is_proc)
	{
		if (stmt->cmd_type == PLTSQL_STMT_EXEC)
		{
			/*
			 * If we're returning from a TOP-level procedure, send the return
			 * status token.  It's possible that we've executed a scalar UDF
			 * with EXEC keyword.  In that case, we don't have to send the
			 * return status token.
			 */
			if (!((PLtsql_stmt_exec *) stmt)->is_scalar_func)
			{
				Assert(pltsql_plugin_handler_ptr->pltsql_read_proc_return_status != NULL);
				TdsSendReturnStatus(*(pltsql_plugin_handler_ptr->pltsql_read_proc_return_status));
			}
		}
		else
		{
			/*
			 * For EXEC batch, SP cursors and SP executeSQL, we just have to
			 * return 0 for a successful execution. Since, babelfishpg_tsql
			 * extension doesn't have return statement implementation for
			 * these cases, we've tosend it from here.
			 *
			 * TODO: Add this support in babelfishpg_tsql extension instead.
			 * In that case, we can remove this check.
			 */
			TdsSendReturnStatus(0);
		}
	}

	/*
	 * If we shouldn't send a done token for the current command, we can
	 * return from here.
	 */
	if (skip_done)
		return;

	/*
	 * If count is valid for this command, set the count and the corresponding
	 * flag.
	 */
	if (row_count_valid)
	{
		nprocessed = (error ? 0 : estate->eval_processed);
		flags |= TDS_DONE_COUNT;
	}

	if (toplevel && is_proc)
		token_type = TDS_TOKEN_DONEPROC;
	else if (toplevel)
		token_type = TDS_TOKEN_DONE;
	else
		token_type = TDS_TOKEN_DONEINPROC;

	if (toplevel)
		flags |= TDS_DONE_FINAL;
	else
		flags |= TDS_DONE_MORE;

	TdsSendDone(token_type, flags, command_type, nprocessed);
}

void
TDSStatementEndCallback(PLtsql_execstate *estate, PLtsql_stmt *stmt)
{
	if (tds_estate == NULL)
		return;

	StatementEnd_Internal(estate, stmt, false);
}

void
TDSStatementExceptionCallback(PLtsql_execstate *estate, PLtsql_stmt *stmt, bool terminate_batch)
{
	if (tds_estate == NULL)
		return;

	TDS_DEBUG(TDS_DEBUG3, "exception %d", tds_estate->current_stack);

	SetTdsEstateErrorData();

	/*
	 * If we're terminating the batch, then we should not send any done token
	 * from this level.  The done token will be sent from a higher level where
	 * the error got handled.
	 */
	if (terminate_batch)
	{
		if (tds_estate->error_stack_offset == 0)
		{
			/* TODO: save the command type */
		}

		tds_estate->current_stack--;
		tds_estate->error_stack_offset++;

		return;
	}

	StatementEnd_Internal(estate, stmt, true);

	/*
	 * TODO: We should add the current command in a queue.  In the current
	 * state, we don't know whether there is a TRY..CATCH in the upper level
	 * that catches this error.  In that case, we don't have to mark the error
	 * flag in the done token.  Once we have that information, we'll send done
	 * tokens for each entry in this queue and empty the queue.
	 */
}

/*
 * SendColumnMetadata - Api to Send the Column Metatadata,
 * used in sp_prepare and called from babelfishpg_tsql extension.
 */
void
SendColumnMetadata(TupleDesc typeinfo, List *targetlist, int16 *formats)
{
	/* This will only be used for sp_preapre request hence do not need to pass plannedstmt */
	TdsSendRowDescription(typeinfo, NULL, targetlist, formats);
	TdsPrintTupShutdown();
}

/*
 * Record error data in tds_estate
 */
static void
SetTdsEstateErrorData(void)
{
	int			number,
				severity,
				state;

	if (GetTdsEstateErrorData(&number, &severity, &state))
	{
		tds_estate->cur_error_number = number;
		tds_estate->cur_error_severity = severity;
		tds_estate->cur_error_state = state;
	}
}

/*
 * Reset error data in tds_estate
 */
static void
ResetTdsEstateErrorData(void)
{
	tds_estate->cur_error_number = -1;
	tds_estate->cur_error_severity = -1;
	tds_estate->cur_error_state = -1;
}

/*
 * Read error data in tds_estate
 */
bool
GetTdsEstateErrorData(int *number, int *severity, int *state)
{
	if (tds_estate != NULL &&
		tds_estate->cur_error_number != -1 &&
		tds_estate->cur_error_severity != -1 &&
		tds_estate->cur_error_state != -1)
	{
		if (number)
			*number = tds_estate->cur_error_number;
		if (severity)
			*severity = tds_estate->cur_error_severity;
		if (state)
			*state = tds_estate->cur_error_state;
		return true;
	}

	/*
	 * If tds_estate doesn't have valid error data, try to find it in
	 * exec_state_call_stack
	 */
	else
		return pltsql_plugin_handler_ptr->pltsql_get_errdata(number, severity, state);
}

/*
 */
static void
SetAttributesForColmetada(TdsColumnMetaData *col)
{
	HeapTuple	tp;
	Form_pg_attribute att_tup;

	/* Initialise to false if no valid heap tuple is found. */
	col->attNotNull = false;
	col->attidentity = false;
	col->attgenerated = false;

	/*
	 * Send the right column-metadata only for FMTONLY Statements. FIXME: We
	 * need to find a generic solution where we do not rely on the catalog for
	 * constraint information.
	 */
	if (pltsql_plugin_handler_ptr &&
		!(*pltsql_plugin_handler_ptr->pltsql_is_fmtonly_stmt))
		return;

	tp = SearchSysCache2(ATTNUM,
						 ObjectIdGetDatum(col->relOid),
						 Int16GetDatum(col->attrNum));

	if (HeapTupleIsValid(tp))
	{
		att_tup = (Form_pg_attribute) GETSTRUCT(tp);
		col->attNotNull = att_tup->attnotnull;
		if (att_tup->attgenerated != '\0')
			col->attgenerated = true;

		if (att_tup->attidentity != '\0')
			col->attidentity = true;

		ReleaseSysCache(tp);
	}
}

static bool
is_this_a_vector_datatype(Oid oid)
{
	Oid nspoid;

	if (sys_vector_oid == InvalidOid)
	{
		nspoid = get_namespace_oid("sys", true);
		if (nspoid == InvalidOid)
			return false;

		sys_vector_oid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid, CStringGetDatum("vector"), ObjectIdGetDatum(nspoid));
	}
	if (sys_vector_oid == oid)
		return true;

	if (sys_halfvec_oid == InvalidOid)
	{
		nspoid = get_namespace_oid("sys", true);
		if (nspoid == InvalidOid)
			return false;

		sys_halfvec_oid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid, CStringGetDatum("halfvec"), ObjectIdGetDatum(nspoid));
	}
	if (sys_halfvec_oid == oid)
		return true;

	if (sys_sparsevec_oid == InvalidOid)
	{
		nspoid = get_namespace_oid("sys", true);
		if (nspoid == InvalidOid)
			return false;

		sys_sparsevec_oid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid, CStringGetDatum("sparsevec"), ObjectIdGetDatum(nspoid));
	}
	return sys_sparsevec_oid == oid;
}