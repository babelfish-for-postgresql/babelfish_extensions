#include "babelfishpg_unit.h"
#include "../babelfishpg_money/fixeddecimal.c"

/*
 * These are the test functions which returns a TestResult structure containing the result of the test.
 */

TestResult*
test_int4_fixeddecimal_ge(void)
{
    Datum val1;
    Datum val2;

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    val1 = 1522;
    val2 = 982;

    bool expected = true;
    Datum temp = DirectFunctionCall2(int4_fixeddecimal_ge, val1, val2);
    bool obtained = DatumGetBool(temp);  

    /*
     * The expected result is true, indicating that val1 is greater than or equal to val2.
     * The obtained result is compared with the expected result using the TEST_ASSERT macro.
     * If the obtained result matches the expected result, the test passes; otherwise, it fails.
     */  

    TEST_ASSERT(expected == obtained, expected?"True":"False", obtained?"True":"False", testResult);
    return testResult;
}


TestResult*
test_int4_fixeddecimal_le(void)
{
    Datum val1;
    Datum val2;

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    val1 = 2345;
    val2 = 1245;

    bool expected = false;
    Datum temp = DirectFunctionCall2(int4_fixeddecimal_le, val1, val2);
    bool obtained = DatumGetBool(temp);    

    TEST_ASSERT(expected == obtained, expected?"True":"False", obtained?"True":"False", testResult);
    return testResult;
}


TestResult*
test_int4_fixeddecimal_ne(void)
{
    Datum val1;
    Datum val2;

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    val1 = 56;
    val2 = 198;

    bool expected = true;
    Datum temp = DirectFunctionCall2(int4_fixeddecimal_ne, val1, val2);
    bool obtained = DatumGetBool(temp);    

    TEST_ASSERT(expected == obtained, expected?"True":"False", obtained?"True":"False", testResult);
    return testResult;
}


TestResult*
test_int4_fixeddecimal_eq(void)
{
    Datum val1;
    Datum val2;

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    val1 = 45;
    val2 = 94;

    bool expected = false;
    Datum temp = DirectFunctionCall2(int4_fixeddecimal_eq, val1, val2);
    bool obtained = DatumGetBool(temp);    

    TEST_ASSERT(expected == obtained, expected?"True":"False", obtained?"True":"False", testResult);
    return testResult;
}


TestResult*
test_int4_fixeddecimal_lt(void)
{
    Datum val1;
    Datum val2;

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    val1 = 100;
    val2 = 10;

    bool expected = false;
    Datum temp = DirectFunctionCall2(int4_fixeddecimal_lt, val1, val2);
    bool obtained = DatumGetBool(temp);    

    TEST_ASSERT(expected == obtained, expected?"True":"False", obtained?"True":"False", testResult);
    return testResult;
}


TestResult*
test_int4_fixeddecimal_cmp(void)
{
    Datum val1;
    Datum val2;
    Datum expected;
    Datum obtained;
    char expected_str[MAX_TEST_MESSAGE_LENGTH];
    char obtained_str[MAX_TEST_MESSAGE_LENGTH];

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    val1 = 110;
    val2 = 100;

    /*
     * val1 > val2 then result will be 1
     * val1 == val2 then result will be 0
     * val1 < val2 then result will be -1
     */

    expected = 1;
    obtained = DirectFunctionCall2(int4_fixeddecimal_cmp, val1, val2);   

    snprintf(expected_str, MAX_TEST_MESSAGE_LENGTH, "%ld", expected);
    snprintf(obtained_str, MAX_TEST_MESSAGE_LENGTH, "%ld", obtained);

    TEST_ASSERT(expected == obtained, expected_str, obtained_str, testResult);
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
        strncpy(testResult->message, errorData->message, MAX_TEST_MESSAGE_LENGTH);
        testResult->result = true;
        FreeErrorData(errorData);
    }
    PG_END_TRY();

    return testResult;
}


TestResult*
test_fixeddecimal_int2_ge(void)
{
    Datum val1;
    Datum val2;

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    val1 = 365;
    val2 = 982;

    bool expected = false;
    Datum temp = DirectFunctionCall2(fixeddecimal_int2_ge, val1, val2);
    bool obtained = DatumGetBool(temp);    

    TEST_ASSERT(expected == obtained, expected?"True":"False", obtained?"True":"False", testResult);
    return testResult;
}


TestResult*
test_fixeddecimal_int2_le(void)
{
    Datum val1;
    Datum val2;

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    val1 = 365;
    val2 = 982;

    bool expected = true;
    Datum temp = DirectFunctionCall2(fixeddecimal_int2_le, val1, val2);
    bool obtained = DatumGetBool(temp);    

    TEST_ASSERT(expected == obtained, expected?"True":"False", obtained?"True":"False", testResult);
    return testResult;
}


TestResult*
test_fixeddecimal_int2_gt(void)
{
    Datum val1;
    Datum val2;

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    val1 = 365;
    val2 = 982;

    bool expected = false;
    Datum temp = DirectFunctionCall2(fixeddecimal_int2_gt, val1, val2);
    bool obtained = DatumGetBool(temp);    

    TEST_ASSERT(expected == obtained, expected?"True":"False", obtained?"True":"False", testResult);
    return testResult;
}


TestResult*
test_fixeddecimal_int2_ne(void)
{
    Datum val1;
    Datum val2;

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    val1 = 365;
    val2 = 982;

    bool expected = true;
    Datum temp = DirectFunctionCall2(fixeddecimal_int2_ne, val1, val2);
    bool obtained = DatumGetBool(temp);    

    TEST_ASSERT(expected == obtained, expected?"True":"False", obtained?"True":"False", testResult);
    return testResult;
}


TestResult*
test_fixeddecimal_int2_cmp(void)
{
    Datum val1;
    Datum val2;
    Datum expected;
    Datum obtained;
    char expected_str[MAX_TEST_MESSAGE_LENGTH];
    char obtained_str[MAX_TEST_MESSAGE_LENGTH];

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    val1 = 100;
    val2 = 110;

    expected = -1;
    obtained = DirectFunctionCall2(fixeddecimal_int2_cmp, val1, val2);   

    snprintf(expected_str, MAX_TEST_MESSAGE_LENGTH, "%ld", expected);
    snprintf(obtained_str, MAX_TEST_MESSAGE_LENGTH, "%ld", obtained);

    TEST_ASSERT(expected == obtained, expected_str, obtained_str, testResult);
    return testResult;
}
