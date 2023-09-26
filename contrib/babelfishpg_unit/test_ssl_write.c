#include "babelfishpg_unit.h"
#include "../babelfishpg_tds/src/include/tds_secure.h"

#ifdef USE_SSL
static char *prelogin; 

static ssize_t 
mock_socket_write(Port *port, const void *ptr, size_t len)
{

    /*
     *  Mock function of tds_secure_raw_write() present in tdssecure.c file
     */

    const unsigned char *ptr_u8 = (const unsigned char *) ptr;
    signed char *prelogin_ptr = (signed char *) prelogin;
    int i;
    for (i = 0; i < len; i++) 
        sscanf((const char *) &ptr_u8[i * 2], "%2hhx", (signed char *) &prelogin_ptr[i]);
    return len;
}


TestResult*
test_ssl_handshakeWrite(void)
{

    /*
     *  We will generate a message and pass it to the handshake write function
     *  We will be comparing the number of bytes written against the expected value and comparing the actual hexadecimal text
     */

    BIO *h = NULL;
    char *buf = "011103";
    char *expected_str;
    char *obtained_str;

    int expected;
    int obtained;

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    h = BIO_new(BIO_s_mem());

    prelogin = malloc(strlen(buf)/2 + 8);
    expected = strlen(buf)/2;
    expected_str = (char *)malloc(expected + 1);
    strncpy(expected_str, buf, expected);
    expected_str[expected] = '\0';

    obtained = test_ssl_handshake_write(h, buf, expected, mock_socket_write);

    obtained_str = (char *)malloc(obtained + 1);
    strncpy(obtained_str, buf, obtained);
    obtained_str[obtained] = '\0';

    /*
     * if number of bytes are same then we will compare actual data
     */
    if(expected == obtained)
    {
        TEST_ASSERT_TESTCASE(strcmp(obtained_str, expected_str) == 0, testResult);
    }
    TEST_ASSERT(strcmp(obtained_str, expected_str) == 0, testResult);

    free(expected_str);
    free(obtained_str);
    return testResult;

}


TestResult*
test_ssl_handshakeWrite_sizeCheck(void)
{

    /*
     *  We will send a message of size less than zero
     *  We will evaluate whether the function correctly detects and handles this condition.
     */

    BIO *h = NULL;
    char *buf = NULL; 

    int expected;
    int obtained;

    char expected_str[MAX_TEST_MESSAGE_LENGTH];
    char obtained_str[MAX_TEST_MESSAGE_LENGTH];

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    h = BIO_new(BIO_s_mem());

    expected = -1;
    obtained = test_ssl_handshake_write(h, buf, expected, mock_socket_write);

    snprintf(expected_str, MAX_TEST_MESSAGE_LENGTH, "%d", expected);
    snprintf(obtained_str, MAX_TEST_MESSAGE_LENGTH, "%d", obtained);

    TEST_ASSERT_TESTCASE(expected == obtained, testResult);
    if(testResult->result == true)
    {
        snprintf(testResult->message, MAX_TEST_MESSAGE_LENGTH, "%s There is nothing to write", testResult->message);
    }
    else
    {
        snprintf(testResult->message, MAX_TEST_MESSAGE_LENGTH, "%s We need to write %ld bytes", testResult->message, strlen(buf));
    }

    return testResult;
}

#endif
