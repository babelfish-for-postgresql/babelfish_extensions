# Babelfish Unit Test Framework

Babelfish has introduced a new extension named babelfishpg_unit which enables us to run unit tests. Please follow the [build instructions](../../contrib/README.md) to build and install the babelfishpg_unit extension.

To maintain a well-organized structure, the directory layout will be as follows:

- babelfish_extensions
    - contrib
        - babelfishpg_common
        - babelfishpg_money
        - babelfishpg_tsql
        - babelfishpg_tds
        - babelfishpg_unit
            - Makefile
            - babelfishpg_unit.control
            - babelfishpg_unit--1.0.0.sql 
            - babelfishpg_unit.c 
            - babelfishpg_unit.h 
            - test_1.c
            - test_2.c

## How to add unit tests for babelfish?

- To add a new test to the existing framework, within the framework's directory, create a new .c file and name it according to the test we want to add (e.g., test_1.c). Add the function in the file which is to be tested.
    - Declare the function you want to test as extern in babelfishpg_unit.h. Eg:
        ```
        extern TestResult* test_int4_fixeddecimal_ge(void)
        ```
    - Metadata for each test function is added as a row in the tests array, containing the necessary information for the test. This tests array is located in babelfishpg_unit.c. Eg:
        ```
        TestInfo tests[]=
        {
            {&test_int4_fixeddecimal_ge, true, "GreaterThanOrEqualToCheck_INT4_FIXEDDECIMAL", "babelfish_money_datatype"},
        };
        ```
    - Return type of all functions which are to be tested must be TestInfo*.
    - Every function should have some expected and obtained output. One should use TEST_ASSERT_TESTCASE(expected == obtained, testResult) first and then TEST_ASSERT(expected == obtained, testResult) to obtain the status of a test. In the TEST_ASSERT_TESTCASE marco, we only set the result field of TestResult struct to true/false based on result. In TEST_ASSERT, we decide whether all the tests have passed or not. Eg:
        ```
        TestResult* test_int4_fixeddecimal_ge(void)
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
        ```

    - If you want to put any custom message for any test in the output table, use :
        - snprintf(testResult->message, MAX_TEST_MESSAGE_LENGTH, "%s", errorData->message);
        - This will fill the message column with expected message. When the tests are run, if the condition is met, then you will observe the same message corresponding to that text.
    
    - If there is any ASSERTION error and TEST_ASSERT_TESTCASE and TEST_ASSERT macros are used to check the condition, then message column will be filled with the error message providing the line where the assertion failed.

