#include "babelfishpg_unit.h"

#include "access/table.h"
#include "catalog/namespace.h"
#include "catalog/pg_class.h"
#include "parser/parser.h"
#include "storage/itemptr.h"
#include "utils/queryenvironment.h"
#include "utils/rel.h"
#include "utils/syscache.h"

/*
 * BABEL-7273: ENR (T-SQL temp table) catalog tuple operations.
 *
 * fmgr_security_definer() sets sql_dialect to PG while a PG function runs on
 * a TDS connection.  A FATAL raised there exits without restoring it, so the
 * temp table cleanup at proc_exit runs in PG dialect.  The ENR scan already
 * allowed PG dialect on a TDS connection, but the ENR drop did not.  The
 * callers then fell back to CatalogTupleDelete() with the ENR tuple's TID,
 * which is not a real heap TID, and crashed in heap_delete().
 *
 * These tests build a minimal ENR by hand, so they need no TDS connection.
 */

#define TEST_ENR_NAME	"babel_7273_unit_enr"
#define TEST_ENR_OID	((Oid) 4294967000U)

static bool
fake_tds_connection(void)
{
	return true;
}

static bool
fake_non_tds_connection(void)
{
	return false;
}

/* Register an ENR temp table with no catalog tuples in a new query env. */
static EphemeralNamedRelation
setup_test_enr(void)
{
	EphemeralNamedRelation enr;

	create_queryEnv2(CurrentMemoryContext, false);

	enr = palloc0(sizeof(EphemeralNamedRelationData));
	enr->md.name = pstrdup(TEST_ENR_NAME);
	enr->md.reliddesc = TEST_ENR_OID;
	enr->md.enrtype = ENR_TSQL_TEMP;
	enr->md.parent_oid = InvalidOid;

	/* Name has no '#', so the ENR does not track uncommitted tuples. */
	register_ENR(currentQueryEnv, enr);

	return enr;
}

static void
teardown_test_enr(EphemeralNamedRelation enr)
{
	if (currentQueryEnv)
		unregister_ENR(currentQueryEnv, TEST_ENR_NAME);
	remove_queryEnv();
	list_free_deep(enr->md.cattups[ENR_CATTUP_CLASS]);
	pfree(enr->md.name);
	pfree(enr);
}

/* A pg_class tuple for the test ENR, copied from a real row with a real TID. */
static HeapTuple
make_pg_class_tuple(void)
{
	HeapTuple		tup;
	Form_pg_class	form;

	tup = SearchSysCacheCopy1(RELOID, ObjectIdGetDatum(RelationRelationId));
	if (!HeapTupleIsValid(tup))
		elog(ERROR, "cache lookup failed for relation %u", RelationRelationId);

	form = (Form_pg_class) GETSTRUCT(tup);
	form->oid = TEST_ENR_OID;
	form->relpersistence = RELPERSISTENCE_TEMP;
	form->relisshared = false;
	form->relhastriggers = false;
	form->relrowsecurity = false;
	form->relispartition = false;

	return tup;
}

/*
 * The copy of a tuple stored in an ENR must have an invalid TID, because it
 * never lives on a heap page.  The input tuple keeps its own TID.
 */
TestResult *
test_enr_add_tuple_invalidates_tid(void)
{
	TestResult	   *testResult = palloc0(sizeof(TestResult));
	EphemeralNamedRelation enr;
	Relation		pg_class_rel;
	HeapTuple		tup;
	HeapTuple		stored;
	int				saved_dialect = sql_dialect;

	testResult->result = true;

	pg_class_rel = table_open(RelationRelationId, RowExclusiveLock);
	enr = setup_test_enr();
	tup = make_pg_class_tuple();

	PG_TRY();
	{
		bool		added;

		sql_dialect = SQL_DIALECT_TSQL;
		added = ENRAddTuple(pg_class_rel, tup);

		TEST_ASSERT_TESTCASE(added, testResult);
		TEST_ASSERT_TESTCASE(list_length(enr->md.cattups[ENR_CATTUP_CLASS]) == 1, testResult);

		stored = (HeapTuple) linitial(enr->md.cattups[ENR_CATTUP_CLASS]);
		TEST_ASSERT_TESTCASE(stored != tup, testResult);
		TEST_ASSERT_TESTCASE(!ItemPointerIsValid(&stored->t_self), testResult);
		TEST_ASSERT_TESTCASE(ItemPointerIsValid(&tup->t_self), testResult);
	}
	PG_FINALLY();
	{
		sql_dialect = saved_dialect;
		teardown_test_enr(enr);
		heap_freetuple(tup);
		table_close(pg_class_rel, RowExclusiveLock);
	}
	PG_END_TRY();

	TEST_ASSERT(ENR add stores tuple with invalid TID, testResult);

	return testResult;
}

/*
 * In PG dialect on a TDS connection, an ENR tuple must be dropped from the
 * ENR, the same as the ENR scan returns it.  This is the dialect state during
 * temp table cleanup after a FATAL inside a PG function.
 */
TestResult *
test_enr_drop_tuple_pg_dialect_tds(void)
{
	TestResult	   *testResult = palloc0(sizeof(TestResult));
	EphemeralNamedRelation enr;
	Relation		pg_class_rel;
	HeapTuple		tup;
	int				saved_dialect = sql_dialect;
	is_bbf_tds_connection_hook_type saved_hook = is_bbf_tds_connection_hook;

	testResult->result = true;

	pg_class_rel = table_open(RelationRelationId, RowExclusiveLock);
	enr = setup_test_enr();
	tup = make_pg_class_tuple();

	PG_TRY();
	{
		HeapTuple	stored;
		bool		dropped;

		sql_dialect = SQL_DIALECT_TSQL;
		TEST_ASSERT_TESTCASE(ENRAddTuple(pg_class_rel, tup), testResult);

		/* Drop the stored copy, as the cleanup path gets it from the ENR scan. */
		stored = heap_copytuple((HeapTuple) linitial(enr->md.cattups[ENR_CATTUP_CLASS]));

		sql_dialect = SQL_DIALECT_PG;
		is_bbf_tds_connection_hook = fake_tds_connection;
		dropped = ENRDropTuple(pg_class_rel, stored);

		TEST_ASSERT_TESTCASE(dropped, testResult);
		TEST_ASSERT_TESTCASE(enr->md.cattups[ENR_CATTUP_CLASS] == NIL, testResult);

		heap_freetuple(stored);
	}
	PG_FINALLY();
	{
		sql_dialect = saved_dialect;
		is_bbf_tds_connection_hook = saved_hook;
		teardown_test_enr(enr);
		heap_freetuple(tup);
		table_close(pg_class_rel, RowExclusiveLock);
	}
	PG_END_TRY();

	TEST_ASSERT(ENR drop succeeds in PG dialect on TDS connection, testResult);

	return testResult;
}

/*
 * When the ENR does not take the drop and the tuple has no heap TID,
 * ENRDropTuple() must raise an ERROR.  Otherwise its callers pass the
 * invalid TID to CatalogTupleDelete() and heap_delete() crashes.
 */
TestResult *
test_enr_drop_tuple_invalid_tid_errors(void)
{
	TestResult	   *testResult = palloc0(sizeof(TestResult));
	EphemeralNamedRelation enr;
	Relation		pg_class_rel;
	HeapTuple		tup;
	MemoryContext	oldcxt = CurrentMemoryContext;
	int				saved_dialect = sql_dialect;
	is_bbf_tds_connection_hook_type saved_hook = is_bbf_tds_connection_hook;
	bool			got_error = false;
	bool			dropped = false;

	testResult->result = true;

	pg_class_rel = table_open(RelationRelationId, RowExclusiveLock);
	enr = setup_test_enr();
	tup = make_pg_class_tuple();
	ItemPointerSetInvalid(&tup->t_self);

	/* PG dialect, not a TDS connection: the ENR refuses the drop. */
	sql_dialect = SQL_DIALECT_PG;
	is_bbf_tds_connection_hook = fake_non_tds_connection;

	PG_TRY();
	{
		dropped = ENRDropTuple(pg_class_rel, tup);
	}
	PG_CATCH();
	{
		ErrorData  *edata;

		MemoryContextSwitchTo(oldcxt);
		edata = CopyErrorData();
		FlushErrorState();

		got_error = (edata->elevel == ERROR &&
					 strstr(edata->message, "tuple has no heap TID") != NULL);
		snprintf(testResult->testcase_message, MAX_TEST_MESSAGE_LENGTH,
				 "%s", edata->message);
		FreeErrorData(edata);
	}
	PG_END_TRY();

	sql_dialect = saved_dialect;
	is_bbf_tds_connection_hook = saved_hook;
	teardown_test_enr(enr);
	heap_freetuple(tup);
	table_close(pg_class_rel, RowExclusiveLock);

	TEST_ASSERT_TESTCASE(got_error, testResult);
	TEST_ASSERT_TESTCASE(!dropped, testResult);
	TEST_ASSERT(ENR drop of tuple without heap TID raises ERROR, testResult);

	return testResult;
}
