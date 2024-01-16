#include "babelfishpg_unit.h"
#include "../babelfishpg_tsql/src/hooks.c"

/*
 * Unit testing for GetNewTempObjectId.
 * 
 * It's best to not run this in parallel with other sessions connected to the same database,
 * since we are directly manipulating ShmemVariableCache for testing purposes.
 * 
 * This also means that there's a small chance that tests may fail if there are other sessions
 * consuming OIDs at the same time, between us releasing/acquiring locks in this function.
 */
TestResult *test_pltsql_GetNewTempObjectId(void)
{
    TestResult* testResult = palloc0(sizeof(TestResult));
    Oid result = 0;
    testResult->result = true;

    /* First assignment. Note we also test the case for nextOid in wraparound, so we start at FirstNormalObjectId. */
    LWLockAcquire(OidGenLock, LW_EXCLUSIVE);
    ShmemVariableCache->nextOid = 0;
    ShmemVariableCache->tempOidStart = InvalidOid;
    ShmemVariableCache->oidCount = 1000;
    LWLockRelease(OidGenLock);
    temp_oid_buffer_start = INT_MIN;
    temp_oid_buffer_size = 100;

    PG_TRY();
    {
        persist_temp_oid_buffer_start_disable_catalog_update = true;
        result = pltsql_GetNewTempObjectId();
    }
    PG_FINALLY();
    {
        persist_temp_oid_buffer_start_disable_catalog_update = false;
    }
    PG_END_TRY();

    TEST_ASSERT_TESTCASE(result == FirstNormalObjectId, testResult);
    TEST_ASSERT(result == FirstNormalObjectId, testResult);

    /* Check oidCount as well. */
    LWLockAcquire(OidGenLock, LW_EXCLUSIVE);
    TEST_ASSERT_TESTCASE(ShmemVariableCache->oidCount == 900, testResult);
    TEST_ASSERT(ShmemVariableCache->oidCount == 900, testResult);
    LWLockRelease(OidGenLock);

    /* 
     * Next value should be incremented by 1.
     */
    result = pltsql_GetNewTempObjectId();
    TEST_ASSERT_TESTCASE(result == (FirstNormalObjectId + 1), testResult);
    TEST_ASSERT(result == (FirstNormalObjectId + 1), testResult);

    return testResult;
}

TestResult *test_pltsql_GetNewTempObjectId_tempOidStartSet(void)
{
    TestResult* testResult = palloc0(sizeof(TestResult));
    Oid result = 0;
    testResult->result = true;

    /*
     * If tempOidStart is set properly in ShmemVariableCache, we will start there instead.
     */
    LWLockAcquire(OidGenLock, LW_EXCLUSIVE);
    ShmemVariableCache->tempOidStart = 222222;
    LWLockRelease(OidGenLock);
    temp_oid_buffer_start = INT_MIN;

    PG_TRY();
    {
        persist_temp_oid_buffer_start_disable_catalog_update = true;
        result = pltsql_GetNewTempObjectId();
    }
    PG_FINALLY();
    {
        persist_temp_oid_buffer_start_disable_catalog_update = false;
    }
    PG_END_TRY();

    TEST_ASSERT_TESTCASE(result == 222222, testResult);
    TEST_ASSERT(result == 222222, testResult);

    return testResult;
}

TestResult *test_pltsql_GetNewTempObjectId_oidCount(void)
{
    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    /*
     * Check oidCount properly set to VAR_OID_PREFETCH. 
     */
    LWLockAcquire(OidGenLock, LW_EXCLUSIVE);
    ShmemVariableCache->nextOid = 0;
    ShmemVariableCache->tempOidStart = InvalidOid;
    ShmemVariableCache->oidCount = 100;
    LWLockRelease(OidGenLock);
    temp_oid_buffer_start = INT_MIN;
    temp_oid_buffer_size = 100;
    PG_TRY();
    {
        persist_temp_oid_buffer_start_disable_catalog_update = true;
        pltsql_GetNewTempObjectId();
    }
    PG_FINALLY();
    {
        persist_temp_oid_buffer_start_disable_catalog_update = false;
    }
    PG_END_TRY();

    LWLockAcquire(OidGenLock, LW_EXCLUSIVE);
    TEST_ASSERT_TESTCASE(ShmemVariableCache->oidCount == VAR_OID_PREFETCH, testResult);
    TEST_ASSERT(ShmemVariableCache->oidCount == VAR_OID_PREFETCH, testResult);
    LWLockRelease(OidGenLock);

    return testResult;
}

TestResult *test_pltsql_GetNewTempObjectId_endWraparound(void)
{
    TestResult* testResult = palloc0(sizeof(TestResult));
    Oid result = 0;
    testResult->result = true;

    /*
     * Assignment when end of buffer would wrap into reserved OIDs.
     */
    LWLockAcquire(OidGenLock, LW_EXCLUSIVE);
    ShmemVariableCache->nextOid = OID_MAX - 100;
    ShmemVariableCache->tempOidStart = InvalidOid;
    ShmemVariableCache->oidCount = 1000;
    LWLockRelease(OidGenLock);
    temp_oid_buffer_start = INT_MIN;
    temp_oid_buffer_size = 101;

    PG_TRY();
    {
        persist_temp_oid_buffer_start_disable_catalog_update = true;
        result = pltsql_GetNewTempObjectId();
    }
    PG_FINALLY();
    {
        persist_temp_oid_buffer_start_disable_catalog_update = false;
    }
    PG_END_TRY();

    TEST_ASSERT_TESTCASE(result == FirstNormalObjectId, testResult);
    TEST_ASSERT(result == FirstNormalObjectId, testResult);

    return testResult;
}

TestResult *test_pltsql_GetNewTempObjectId_endBuffer(void)
{
    TestResult* testResult = palloc0(sizeof(TestResult));
    Oid result = 0;
    testResult->result = true;

    /*
     * Assignment when end of buffer is MAX_OID.
     */
    LWLockAcquire(OidGenLock, LW_EXCLUSIVE);
    ShmemVariableCache->nextOid = OID_MAX - 10;
    ShmemVariableCache->tempOidStart = InvalidOid;
    ShmemVariableCache->oidCount = 1000;
    LWLockRelease(OidGenLock);
    temp_oid_buffer_start = INT_MIN;
    temp_oid_buffer_size = 10;

    PG_TRY();
    {
        persist_temp_oid_buffer_start_disable_catalog_update = true;
        result = pltsql_GetNewTempObjectId();
    }
    PG_FINALLY();
    {
        persist_temp_oid_buffer_start_disable_catalog_update = false;
    }
    PG_END_TRY();

    /*
     * Check for proper assignment and proper wraparound.
     */
    TEST_ASSERT_TESTCASE(result == (OID_MAX - 10), testResult);
    TEST_ASSERT(result == (OID_MAX - 10), testResult);

    for (int i = 0; i < 10; i++)
    {
        PG_TRY();
        {
            persist_temp_oid_buffer_start_disable_catalog_update = true;
            result = pltsql_GetNewTempObjectId();
        }
        PG_FINALLY();
        {
            persist_temp_oid_buffer_start_disable_catalog_update = false;
        }
        PG_END_TRY();
    }

    TEST_ASSERT_TESTCASE(result == (OID_MAX - 10), testResult);
    TEST_ASSERT(result == (OID_MAX - 10), testResult);

    return testResult;
}

/*
 * Unit testing for GetNewTempOidWithIndex.
 * 
 * Testing is similar to the above, since this is mostly a wrapper around
 * GetNewTempObjectId. Cases that can't be covered by unit tests are 
 * covered in JDBC tests.
 */
TestResult *test_pltsql_GetNewTempOidWithIndex(void)
{
    TestResult* testResult = palloc0(sizeof(TestResult));
    Oid result = 0;
    Relation rel = table_open(RelationRelationId, RowExclusiveLock);
    testResult->result = true;

    /* First assignment. Note we also test the case for nextOid in wraparound, so we start at FirstNormalObjectId. */
    LWLockAcquire(OidGenLock, LW_EXCLUSIVE);
    ShmemVariableCache->nextOid = 0;
    ShmemVariableCache->tempOidStart = InvalidOid;
    ShmemVariableCache->oidCount = 1000;
    LWLockRelease(OidGenLock);
    temp_oid_buffer_start = INT_MIN;
    temp_oid_buffer_size = 100;
    
    PG_TRY();
    {
        persist_temp_oid_buffer_start_disable_catalog_update = true;
        result = pltsql_GetNewTempOidWithIndex(rel, ClassOidIndexId, Anum_pg_class_oid);
    }
    PG_FINALLY();
    {
        persist_temp_oid_buffer_start_disable_catalog_update = false;
    }
    PG_END_TRY();

    TEST_ASSERT_TESTCASE(result == FirstNormalObjectId, testResult);
    TEST_ASSERT(result == FirstNormalObjectId, testResult);

    table_close(rel, RowExclusiveLock);

    return testResult;
}

TestResult *test_pltsql_GetNewTempOidWithIndex_endBuffer(void)
{
    TestResult* testResult = palloc0(sizeof(TestResult));
    Oid result = 0;
    Relation rel = table_open(RelationRelationId, RowExclusiveLock);
    testResult->result = true;

    /*
     * Assignment when end of buffer is MAX_OID.
     */
    LWLockAcquire(OidGenLock, LW_EXCLUSIVE);
    ShmemVariableCache->nextOid = OID_MAX - 10;
    ShmemVariableCache->tempOidStart = InvalidOid;
    ShmemVariableCache->oidCount = 1000;
    LWLockRelease(OidGenLock);
    temp_oid_buffer_start = INT_MIN;
    temp_oid_buffer_size = 10;

    PG_TRY();
    {
        persist_temp_oid_buffer_start_disable_catalog_update = true;
        result = pltsql_GetNewTempOidWithIndex(rel, ClassOidIndexId, Anum_pg_class_oid);
    }
    PG_FINALLY();
    {
        persist_temp_oid_buffer_start_disable_catalog_update = false;
    }
    PG_END_TRY();

    /*
     * Check for proper assignment and proper wraparound.
     */
    TEST_ASSERT_TESTCASE(result == (OID_MAX - 10), testResult);
    TEST_ASSERT(result == (OID_MAX - 10), testResult);

    for (int i = 0; i < 10; i++)
    {
        PG_TRY();
        {
            persist_temp_oid_buffer_start_disable_catalog_update = true;
            result = pltsql_GetNewTempOidWithIndex(rel, ClassOidIndexId, Anum_pg_class_oid);
        }
        PG_FINALLY();
        {
            persist_temp_oid_buffer_start_disable_catalog_update = false;
        }
        PG_END_TRY();
    }

    TEST_ASSERT_TESTCASE(result == (OID_MAX - 10), testResult);
    TEST_ASSERT(result == (OID_MAX - 10), testResult);

    table_close(rel, RowExclusiveLock);

    return testResult;
}
