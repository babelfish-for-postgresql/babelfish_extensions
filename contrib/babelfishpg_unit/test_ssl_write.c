#include "babelfishpg_unit.h"
#include "../babelfishpg_tds/src/include/tds_secure.h"

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
     *  We will be comparing the number of bytes written against the expected value
     */

    BIO *h = NULL;
    char *buf = "011103";

    int expected;
    int obtained;

    char expected_str[MAX_TEST_MESSAGE_LENGTH];
    char obtained_str[MAX_TEST_MESSAGE_LENGTH];

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    h = BIO_new(BIO_s_mem());

    prelogin = malloc(strlen(buf)/2 + 8);

    expected = strlen(buf)/2;
    obtained = test_ssl_handshake_write(h, buf, expected, mock_socket_write);

    snprintf(expected_str, MAX_TEST_MESSAGE_LENGTH, "%d", expected);
    snprintf(obtained_str, MAX_TEST_MESSAGE_LENGTH, "%d", obtained);

    TEST_ASSERT_TESTCASE(expected == obtained, "1", expected_str, obtained_str, testResult);
    TEST_ASSERT(expected == obtained, testResult);

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

    TEST_ASSERT_TESTCASE(expected == obtained, "1", expected_str, obtained_str, testResult);
    if(testResult->result == true)
    {
        snprintf(testResult->message, MAX_TEST_MESSAGE_LENGTH, "%s, There is nothing to write", testResult->message);
    }
    else
    {
        snprintf(testResult->message, MAX_TEST_MESSAGE_LENGTH, "%s, We need to write %ld bytes", testResult->message, strlen(buf));
    }

    return testResult;
}
