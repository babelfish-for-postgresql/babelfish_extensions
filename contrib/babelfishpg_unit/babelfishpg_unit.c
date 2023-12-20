#include "babelfishpg_unit.h"

Datum babelfishpg_unit_run_tests(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(babelfishpg_unit_run_tests);


#define NCOLS (5)

#define TEST_NAME_COLUMN 0
#define STATUS_NAME_COLUMN (TEST_NAME_COLUMN + 1)
#define MESSAGE_NAME_COLUMN (STATUS_NAME_COLUMN + 1)
#define RUNTIME_NAME_COLUMN (MESSAGE_NAME_COLUMN + 1)
#define ENABLED_NAME_COLUMN (RUNTIME_NAME_COLUMN + 1)

#define TEXT_HEADER_SIZE (28)

typedef struct 
{
    TestResult *(*test_func)();
    bool enabled;
    char test_func_name[MAX_TEST_NAME_LENGTH];
    char category[MAX_TEST_NAME_LENGTH];
} TestInfo;

typedef struct 
{
    bool nulls[NCOLS];
    TupleDesc tupledesc;
    int test_run;
    int current_test;
    int num_tests;

    /*
     * When running categories or a list of tests ensure we don't run any test
     * more than once.  Simply maintain an array of booleans that indicate
     * a test has been already included in this test run to prevent duplicates.
     * It has 1-1 mapping to the tests array just below.
     */
    short *test_included;
} StateInfo;


static char* PASS = "pass";
static char* FAIL = "fail";
static char* NOT_RUN = "no run";
static char* ENABLED = "enabled";
static char* DISABLED = "disabled";


/*
 *    Add test metadata here.  
 *  
 *      . Add function declaration
 *      . Add row to tests array that identifies your test containing:
 *          . Pointer to test function (takes no params and returns a TestResult pointer
 *          . enabled flag, true to enable
 *          . Human readable test name
 *          . Human readable category, tests can then be run by category, name, or all
 *
 *      . Update for test declarations are needed in babelfishpg_unit.h
 *      . New tests can be added in their own file or an existing file if applicable.  If
 *        adding to a new file, update Makefile to reference the new source file.
 */


TestInfo tests[]=
{
    {&test_int4_fixeddecimal_ge, true, "GreaterThanOrEqualToCheck_INT4_FIXEDDECIMAL", "babelfish_money_datatype"},
    {&test_int4_fixeddecimal_le, true, "LesserThanOrEqualToCheck_INT4_FIXEDDECIMAL", "babelfish_money_datatype"},
    {&test_int4_fixeddecimal_ne, true, "NotEqualToCheck_INT4_FIXEDDECIMAL", "babelfish_money_datatype"},
    {&test_int4_fixeddecimal_eq, true, "EqualToCheck_INT4_FIXEDDECIMAL", "babelfish_money_datatype"},
    {&test_int4_fixeddecimal_lt, true, "LesserThanCheck_INT4_FIXEDDECIMAL", "babelfish_money_datatype"},
    {&test_int4_fixeddecimal_cmp, true, "Comparison_INT4_FIXEDDECIMAL", "babelfish_money_datatype"},
    {&test_fixeddecimalum, true, "FIXEDDECIMALUM", "babelfish_money_datatype"},
    {&test_fixeddecimal_int2_ge, true, "GreaterThanOrEqualToCheck_FIXEDDECIMAL_INT2", "babelfish_money_datatype"},
    {&test_fixeddecimal_int2_le, true, "LesserThanOrEqualToCheck_FIXEDDECIMAL_INT2", "babelfish_money_datatype"},
    {&test_fixeddecimal_int2_gt, true, "GreaterThanCheck_FIXEDDECIMAL_INT2", "babelfish_money_datatype"},
    {&test_fixeddecimal_int2_ne, true, "NotEqualToCheck_FIXEDDECIMAL_INT2", "babelfish_money_datatype"},
    {&test_fixeddecimal_int2_cmp, true, "Comparison_FIXEDDECIMAL_INT2", "babelfish_money_datatype"},
};


// Forward declarations
TestResult *run_test(TestInfo *test);
void setNull(StateInfo *state, bool message);
void calc_num_tests(StateInfo *state);
void calc_tests_for_run(StateInfo *state, int arg_size, VarChar **args);
int calc_next_test(StateInfo *state, int position);


/*
 *  run_test
 *
 *  Run a single test as specified by TestInfo.  Return the result of
 *  running the test (TestResult) which contains pass/fail, runtime, and
 *  if supplied by the test a message concerning the test run.
 *
 */
TestResult *
run_test(TestInfo *test) 
{
    return test->test_func();
}


/*
 *  setNull
 *
 *  When returning a row or test run it is necessary to specify which columns
 *  are null.  Only the message column can be null so if the message parameter
 *  is true, that column is set to be null
 *
 */
void
setNull(StateInfo *state, bool message)
{
	int i;

	for (i=0; i<NCOLS; i++) 
		state->nulls[i] = false;

	if (message) 
		state->nulls[MESSAGE_NAME_COLUMN] = true;
}


/*
 * calc_num_tests
 *
 * Calculate the total number of tests available to run, store
 * it in the supplied state.
 */
void
calc_num_tests(StateInfo *state) 
{
    state->num_tests = sizeof(tests) / sizeof(TestInfo);
}


/*
 * calc_tests_for_run
 *
 * Given a list of test names or test categories scan the list
 * of all tests and mark an array the same length as the list
 * of all tests with those to run.
 */
void
calc_tests_for_run(StateInfo *state, int argc, text **argv)
{
    int i, j;
    text **arg_ptr = argv;

    if (argc == 0) 
    {
        memset(state->test_included, 1, state->num_tests * sizeof(short));
        return;
    }


    for (i=0; i<argc; i++, arg_ptr++)
    {
        /*
         * In each iteration, testname will point to one string argument we pass to the function
         * It will cover all 'argc' arguments we pass in all iterations
         */
        char *testname = text_to_cstring(*arg_ptr);     
        for (j = 0; j < state->num_tests; j++)
        {
            if ((strcmp(tests[j].test_func_name, testname) == 0) ||
                (strcmp(tests[j].category, testname) == 0)) {
                state->test_included[j] = true;
            }
        }
        pfree(testname);
    }
}


/*
 * calc_next_test
 *
 * Pass in the position in the test included array and start
 * searching forward from position inclusive until end of array
 * or until a test to run is found.  If a test is found return
 * that position, otherwise return the number of tests indicating
 * we are beyond the range of tests and therefore there is no
 * tests remaining to be run.
 */
int
calc_next_test(StateInfo *state, int position)
{
    if (position >= state->num_tests)
        return state->num_tests;


    while (state->test_included[position] == false)
    {
        if (position >= state->num_tests) 
        {
            state->current_test = state->num_tests;
            return  state->num_tests;
        }

        position++;
    }

    return position;
}


Datum
babelfishpg_unit_run_tests(PG_FUNCTION_ARGS) 
{
    FuncCallContext *fctx;
    TupleDesc tupledesc;
    Datum result;
    Datum values[NCOLS];
    HeapTuple tuple;
    MemoryContext mctx;
    TestInfo *test;
    TestResult *tr;
    int nargs = PG_NARGS();
    text **args =  NULL;
    int i;
    StateInfo* state;
    ArrayType *arr;
    Datum *decontructed_arr;
    bool *nulls;

    if (SRF_IS_FIRSTCALL())
    {

        /*
         * First call, allocate state needed for multiple
         * calls to this routine. 
         */
        fctx = SRF_FIRSTCALL_INIT();
        mctx = MemoryContextSwitchTo(fctx->multi_call_memory_ctx);
        state = palloc0(sizeof(StateInfo));

        calc_num_tests(state);

        /*
         * Based on input parameters calculate tests to
         * run.  Run all if no parameters provided, default
         * case
         */
    
        if (nargs > 0)
        {   
            /*
             * Deconstructed the array for accessing the args passed to the function and 
             * Storing the content of parameters in 'args'
             */
            arr = PG_GETARG_ARRAYTYPE_P(0);
            deconstruct_array(arr, TEXTOID, -1, false, TYPALIGN_INT, &decontructed_arr, &nulls, &nargs);
            
            args = palloc(nargs * sizeof(text *));
            for (i=0; i<nargs; i++) 
                args[i] = DatumGetTextP(decontructed_arr[i]);
        }


        state->test_included = palloc0(state->num_tests * sizeof(short));
        calc_tests_for_run(state, nargs, args);
        state->current_test = calc_next_test(state, 0);
        if (args != NULL) 
            pfree(args);

        /*
		 * Create the tuple returned to the caller.  Set up the
		 * table with the specified columns below.  This only
		 * needs to be setup on the first call.
		 */
		tupledesc = CreateTemplateTupleDesc(NCOLS);
		TupleDescInitEntry(tupledesc, (AttrNumber) TEST_NAME_COLUMN+1, "TEST_NAME", TEXTOID, -1, 0);
		TupleDescInitEntry(tupledesc, (AttrNumber) STATUS_NAME_COLUMN+1, "STATUS", TEXTOID, -1, 0);
		TupleDescInitEntry(tupledesc, (AttrNumber) MESSAGE_NAME_COLUMN+1, "MESSAGE", TEXTOID, -1, 0);
		TupleDescInitEntry(tupledesc, (AttrNumber) RUNTIME_NAME_COLUMN+1, "RUNTIME", INT8OID, -1, 0);
		TupleDescInitEntry(tupledesc, (AttrNumber) ENABLED_NAME_COLUMN+1, "ENABLED", TEXTOID, -1, 0);

        state->tupledesc = BlessTupleDesc(tupledesc);
        fctx->user_fctx = state;
        MemoryContextSwitchTo(mctx);
    }

    /*
     * Retrieve State Info needed to run the actual test
     */
    fctx = SRF_PERCALL_SETUP();
    state = fctx->user_fctx;
    tupledesc = state->tupledesc;

    if (state->current_test < state->num_tests) {
        instr_time start, end;
        test = &tests[state->current_test];
        setNull(state, false);
        INSTR_TIME_SET_CURRENT(start);
        
        /*
         * If enabled actually run the test
         */
        if (test->enabled) 
        {
            tr = run_test(test);
            state->test_run++;
        } else 
        {
            tr = palloc0(sizeof(TestResult));
        }

        /*
         * Compute timing information and if a message was returned and
         * set message column to null if it is null message
         */
        INSTR_TIME_SET_CURRENT(end);

        tr->run_time = INSTR_TIME_GET_MICROSEC(end) - INSTR_TIME_GET_MICROSEC(start);
        if (tr->message == NULL)
            setNull(state, true);

        /*
		 * Set the information for a row of data indicating test failure or pass
		 */
		values[TEST_NAME_COLUMN] = PointerGetDatum(cstring_to_text(test->test_func_name));
		values[STATUS_NAME_COLUMN] = PointerGetDatum(cstring_to_text(test->enabled ? 
				(tr->result ? PASS : FAIL) : NOT_RUN));
		values[MESSAGE_NAME_COLUMN] = PointerGetDatum(cstring_to_text(tr->message));
		values[RUNTIME_NAME_COLUMN] = PointerGetDatum(tr->run_time);
		values[ENABLED_NAME_COLUMN] = PointerGetDatum(cstring_to_text(test->enabled ? ENABLED : DISABLED));
		tuple = heap_form_tuple(state->tupledesc, values, state->nulls);
		result = HeapTupleGetDatum(tuple);

        /*
         * Set the state to run the next test on the next function call
         */
        state->current_test = calc_next_test(state, state->current_test + 1);

        pfree(tr);

        SRF_RETURN_NEXT(fctx, result);
    }

    /*
     * All the requested tests have been processed, do final return
     */
    pfree(state->test_included);
    pfree(state);
    SRF_RETURN_DONE(fctx);
}
