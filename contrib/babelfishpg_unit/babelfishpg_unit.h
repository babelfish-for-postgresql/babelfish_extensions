#include "postgres.h"
#include "fmgr.h"
#include "utils/builtins.h"
#include "utils/elog.h"
#include <utils/array.h>
#include "access/htup_details.h"
#include "access/clog.h"
#include "catalog/pg_type.h"
#include "funcapi.h"
#include "access/rmgr.h"
#include "access/xlog_internal.h"
#include "storage/smgr.h"

#include "utils/memutils.h"

#define MAX_TEST_NAME_LENGTH (256)
#define MAX_TEST_MESSAGE_LENGTH (2048)

typedef struct 
{
    bool result;
    char message[MAX_TEST_MESSAGE_LENGTH];
    char testcase_message[MAX_TEST_MESSAGE_LENGTH];
    uint64 run_time;
} TestResult;


#define TEST_ASSERT(condition, pResult)   \
do {                                \
    if(pResult->result == false){   \
        snprintf((pResult)->message, \
                MAX_TEST_MESSAGE_LENGTH, \
                "Test assertion '%s' failed at %s:%d",  \
                #condition, __FILE__, __LINE__);      \
    }               \
} while (0)


#define TEST_ASSERT_TESTCASE(condition, pResult)   \
do {                                \
    if (!(condition)) {                 \
        (pResult)->result = false;  \
    }               \
} while (0)


extern TestResult *test_int4_fixeddecimal_ge(void);
extern TestResult *test_int4_fixeddecimal_le(void);
extern TestResult *test_int4_fixeddecimal_ne(void);
extern TestResult *test_int4_fixeddecimal_eq(void);
extern TestResult *test_int4_fixeddecimal_lt(void);
extern TestResult *test_int4_fixeddecimal_cmp(void);
extern TestResult *test_fixeddecimalum(void);
extern TestResult *test_fixeddecimal_int2_ge(void);
extern TestResult *test_fixeddecimal_int2_le(void);
extern TestResult *test_fixeddecimal_int2_gt(void);
extern TestResult *test_fixeddecimal_int2_ne(void);
extern TestResult *test_fixeddecimal_int2_cmp(void);
