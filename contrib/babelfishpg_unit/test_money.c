#include "babelfishpg_unit.h"
#include "../babelfishpg_money/fixeddecimal.c"

/*
 * These are the test functions which returns a TestResult structure containing the result of the test.
 * We will expect some result and the obtained result is compared with the expected result using the TEST_ASSERT and TEST_ASSERT_TESTCASE macro.
 * If the obtained result matches the expected result, the test passes; otherwise, it fails.
 */

TestResult*
test_int4_fixeddecimal_ge(void)
{
    /*
     * This function checks whether val1 is greater than or equal to val2 or not.
     */  

    int val1[] = {1522, -100, 5, 0, -856, 0};
    int val2[] = {982, 200, 0, -24, -567, 0};

    int numValues = sizeof(val1) / sizeof(val1[0]);

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    for (int i = 0; i < numValues; i++) 
    {
        bool expected = (val1[i] >= val2[i]);
        Datum temp = DirectFunctionCall2(int4_fixeddecimal_ge, Int32GetDatum(val1[i]), Int32GetDatum(val2[i]));
        bool obtained = DatumGetBool(temp);  

        TEST_ASSERT_TESTCASE(expected == obtained, testResult);
    }

    TEST_ASSERT(expected == obtained, testResult);

    return testResult;
}


TestResult*
test_int4_fixeddecimal_le(void)
{
    /*
     * This function checks whether val1 is lesser than or equal to val2 or not.
     */   

    int val1[] = {1522, -100, 5, 0, -856, 0};
    int val2[] = {982, 200, 0, -24, -567, 0};

    int numValues = sizeof(val1) / sizeof(val1[0]);

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    for (int i = 0; i < numValues; i++) 
    {
        bool expected = (val1[i] <= val2[i]);
        Datum temp = DirectFunctionCall2(int4_fixeddecimal_le, Int32GetDatum(val1[i]), Int32GetDatum(val2[i]));
        bool obtained = DatumGetBool(temp);  

        TEST_ASSERT_TESTCASE(expected == obtained, testResult);
    }

    TEST_ASSERT(expected == obtained, testResult);

    return testResult;
}


TestResult*
test_int4_fixeddecimal_ne(void)
{
    /*
     * This function checks whether val1 is not equal to val2 or not.
     */   

    int val1[] = {1522, -100, 5, 0, -856, 0};
    int val2[] = {982, 200, 0, -24, -567, 0};

    int numValues = sizeof(val1) / sizeof(val1[0]);

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    for (int i = 0; i < numValues; i++) 
    {
        bool expected = (val1[i] != val2[i]);
        Datum temp = DirectFunctionCall2(int4_fixeddecimal_ne, Int32GetDatum(val1[i]), Int32GetDatum(val2[i]));
        bool obtained = DatumGetBool(temp);  

        TEST_ASSERT_TESTCASE(expected == obtained, testResult);
    }

    TEST_ASSERT(expected == obtained, testResult);

    return testResult;
}


TestResult*
test_int4_fixeddecimal_eq(void)
{
    /*
     * This function checks whether val1 is equal to val2 or not.
     */  

    int val1[] = {1522, -100, 5, 0, -856, 0};
    int val2[] = {982, 200, 0, -24, -567, 0};

    int numValues = sizeof(val1) / sizeof(val1[0]);

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    for (int i = 0; i < numValues; i++) 
    {
        bool expected = (val1[i] == val2[i]);
        Datum temp = DirectFunctionCall2(int4_fixeddecimal_eq, Int32GetDatum(val1[i]), Int32GetDatum(val2[i]));
        bool obtained = DatumGetBool(temp);  

        TEST_ASSERT_TESTCASE(expected == obtained, testResult);
    }

    TEST_ASSERT(expected == obtained, testResult);

    return testResult;
}


TestResult*
test_int4_fixeddecimal_lt(void)
{
    /*
     * This function checks whether val1 is less than val2 or not.
     */  

    int val1[] = {1522, -100, 5, 0, -856, 0};
    int val2[] = {982, 200, 0, -24, -567, 0};

    int numValues = sizeof(val1) / sizeof(val1[0]);

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    for (int i = 0; i < numValues; i++) 
    {
        bool expected = (val1[i] < val2[i]);
        Datum temp = DirectFunctionCall2(int4_fixeddecimal_lt, Int32GetDatum(val1[i]), Int32GetDatum(val2[i]));
        bool obtained = DatumGetBool(temp);  

        TEST_ASSERT_TESTCASE(expected == obtained, testResult);
    }

    TEST_ASSERT(expected == obtained, testResult);

    return testResult;
}


TestResult*
test_int4_fixeddecimal_cmp(void)
{
    /*
     * This function compares val1 and val2.
     * val1 > val2 then result will be 1
     * val1 == val2 then result will be 0
     * val1 < val2 then result will be -1
     */ 

    int val1[] = {1522, -100, 5, 0, -856, 0};
    int val2[] = {982, 200, 0, -24, -567, 0};

    int numValues = sizeof(val1) / sizeof(val1[0]);

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    for (int i = 0; i < numValues; i++) 
    {
        Datum val1_datum = Int32GetDatum(val1[i]);
        Datum val2_datum = Int32GetDatum(val2[i]);

        Datum expected;
        Datum obtained;
        char expected_str[MAX_TEST_MESSAGE_LENGTH];
        char obtained_str[MAX_TEST_MESSAGE_LENGTH];

        if(val1[i] > val2[i])
            expected = 1;
        else if(val1[i] < val2[i])
            expected = -1;
        else
            expected = 0;

        obtained = DirectFunctionCall2(int4_fixeddecimal_cmp, val1_datum, val2_datum);
        snprintf(expected_str, MAX_TEST_MESSAGE_LENGTH, "%ld", expected);
        snprintf(obtained_str, MAX_TEST_MESSAGE_LENGTH, "%ld", obtained);
        
        TEST_ASSERT_TESTCASE(expected == obtained, testResult);
    }

    TEST_ASSERT(expected == obtained, testResult);

    return testResult;
}


TestResult*
test_fixeddecimalum(void)
{
    /*
     * To establish the expected behavior of our code, it is crucial to test both positive and negative scenarios.
     * So in this test, we expect an out of range error.
     * When this error occurs as anticipated, the test is considered successful.
     */

    int64 arg1 = INT64_MIN;
    ErrorData *errorData;
    MemoryContext oldcontext;

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = false;

    oldcontext = CurrentMemoryContext;
    PG_TRY();
    {
        DirectFunctionCall1(fixeddecimalum, arg1);
    }
    PG_CATCH();
    {
        MemoryContextSwitchTo(oldcontext);
        errorData = CopyErrorData();
        FlushErrorState();
        snprintf(testResult->message, MAX_TEST_MESSAGE_LENGTH, "%s", errorData->message);
        testResult->result = true;
        FreeErrorData(errorData);
    }
    PG_END_TRY();

    // If the error doesn't occurr, then the following message gets displayed
    if(testResult->result == false)
        strncpy(testResult->message, ", Out of Range error doesn't occur", MAX_TEST_MESSAGE_LENGTH);

    return testResult;
}


TestResult*
test_fixeddecimal_int2_ge(void)
{
    /*
     * This function checks whether val1 is greater than or equal to val2 or not.
     */  

    int val1[] = {152, -100, 5, 0, -85, 0};
    int val2[] = {982, 200, 0, -24, -567, 0};

    int numValues = sizeof(val1) / sizeof(val1[0]);

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    for (int i = 0; i < numValues; i++) 
    {
        bool expected = (val1[i] >= val2[i]);
        Datum temp = DirectFunctionCall2(fixeddecimal_int2_ge, Int32GetDatum(val1[i]), Int32GetDatum(val2[i]));
        bool obtained = DatumGetBool(temp);  

        TEST_ASSERT_TESTCASE(expected == obtained, testResult);
    }

    TEST_ASSERT(expected == obtained, testResult);

    return testResult;
}


TestResult*
test_fixeddecimal_int2_le(void)
{
    /*
     * This function checks whether val1 is less than or equal to val2 or not.
     */  

    int val1[] = {152, -100, 5, 0, -85, 0};
    int val2[] = {982, 200, 0, -24, -567, 0};

    int numValues = sizeof(val1) / sizeof(val1[0]);

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    for (int i = 0; i < numValues; i++) 
    {
        bool expected = (val1[i] <= val2[i]);
        Datum temp = DirectFunctionCall2(fixeddecimal_int2_le, Int32GetDatum(val1[i]), Int32GetDatum(val2[i]));
        bool obtained = DatumGetBool(temp);  

        TEST_ASSERT_TESTCASE(expected == obtained, testResult);
    }

    TEST_ASSERT(expected == obtained, testResult);

    return testResult;
}


TestResult*
test_fixeddecimal_int2_gt(void)
{
    /*
     * This function checks whether val1 is greater than val2 or not.
     */  

    int val1[] = {152, -100, 5, 0, -85};
    int val2[] = {982, 200, 0, -24, -567};

    int numValues = sizeof(val1) / sizeof(val1[0]);

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    for (int i = 0; i < numValues; i++) 
    {
        bool expected = (val1[i] > val2[i]);
        Datum temp = DirectFunctionCall2(fixeddecimal_int2_ge, Int32GetDatum(val1[i]), Int32GetDatum(val2[i]));
        bool obtained = DatumGetBool(temp);  

        TEST_ASSERT_TESTCASE(expected == obtained, testResult);
    }

    TEST_ASSERT(expected == obtained, testResult);

    return testResult;
}


TestResult*
test_fixeddecimal_int2_ne(void)
{
    /*
     * This function checks whether val1 is not equal to val2 or not.
     */  

    int val1[] = {5, 0, -85};
    int val2[] = {0, -24, -567};

    int numValues = sizeof(val1) / sizeof(val1[0]);

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    for (int i = 0; i < numValues; i++) 
    {
        bool expected = (val1[i] != val2[i]);
        Datum temp = DirectFunctionCall2(fixeddecimal_int2_ge, Int32GetDatum(val1[i]), Int32GetDatum(val2[i]));
        bool obtained = DatumGetBool(temp);  

        TEST_ASSERT_TESTCASE(expected == obtained, testResult);
    }

    TEST_ASSERT(expected == obtained, testResult);

    return testResult;
}


TestResult*
test_fixeddecimal_int2_cmp(void)
{
    /*
     * This function compares val1 and val2.
     * val1 > val2 then result will be 1
     * val1 == val2 then result will be 0
     * val1 < val2 then result will be -1
     */ 

    int val1[] = {152, -100, 5, 0, -85, 0};
    int val2[] = {982, 200, 0, -24, -567, 0};

    int numValues = sizeof(val1) / sizeof(val1[0]);

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    for (int i = 0; i < numValues; i++) 
    {
        Datum val1_datum = Int32GetDatum(val1[i]);
        Datum val2_datum = Int32GetDatum(val2[i]);

        Datum expected;
        Datum obtained;
        char expected_str[MAX_TEST_MESSAGE_LENGTH];
        char obtained_str[MAX_TEST_MESSAGE_LENGTH];

        if(val1[i] > val2[i])
            expected = 1;
        else if(val1[i] < val2[i])
            expected = -1;
        else
            expected = 0;

        obtained = DirectFunctionCall2(fixeddecimal_int2_cmp, val1_datum, val2_datum);
        snprintf(expected_str, MAX_TEST_MESSAGE_LENGTH, "%ld", expected);
        snprintf(obtained_str, MAX_TEST_MESSAGE_LENGTH, "%ld", obtained);
        
        TEST_ASSERT_TESTCASE(expected == obtained, testResult);
    }

    TEST_ASSERT(expected == obtained, testResult);

    return testResult;
}
