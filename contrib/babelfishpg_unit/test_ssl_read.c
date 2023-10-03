#include "babelfishpg_unit.h"
#include "../babelfishpg_tds/src/include/tds_secure.h"

#ifdef USE_SSL
static char *prelogin_request;
static int ReadPointer = 0;


static ssize_t
mock_socket_read(Port *port, void *ptr, size_t len)
{

    /*
     *  Mock function of tds_secure_raw_read() present in tdssecure.c file
     */

    int i;
    for (i = ReadPointer; i < ReadPointer + len; i++) 
        sscanf(&prelogin_request[i * 2], "%2hhx", (unsigned char *)ptr + i);
    ReadPointer += len;
    return len;
}


TestResult*
test_ssl_handshakeRead(void)
{

    /*
     *  We will generate a prelogin request message and pass it to the handshake read function for processing
     *  By comparing the number of bytes read against the expected value and comparing actual bytes, we can verify the accuracy of the read operation 
     */

    BIO *h = NULL;
    char *buf = NULL;
    char *expected_str;
    int expected;
    int obtained;
    char *null_terminated_expected;
    char *null_terminated_buf;

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    h = BIO_new(BIO_s_mem());
    ReadPointer = 0;

    prelogin_request = strdup("1201000F0000010011A25E4571");
    buf = malloc(strlen(prelogin_request)/2);
    expected = strlen(prelogin_request)/2 - 8;

    expected_str = (char *)malloc(strlen(prelogin_request)/2);
    for (int i = 0; i < expected; i++) 
        sscanf(&prelogin_request [i * 2], "%2hhx", (char *)expected_str + i);
    
    obtained = test_ssl_handshake_read(h, buf, expected, mock_socket_read, ReadPointer);

    null_terminated_expected = strdup(expected_str);
    null_terminated_buf = strdup(buf);

    /*
     * if number of bytes are same then we will compare actual data
     */
    if(expected == obtained)
    {
        TEST_ASSERT_TESTCASE(strcmp(null_terminated_buf, null_terminated_expected) == 0, testResult);
    }
    TEST_ASSERT(strcmp(null_terminated_buf, null_terminated_expected) == 0, testResult);

    free(buf);
    free(prelogin_request);
    free(expected_str);
    free(null_terminated_expected);
    free(null_terminated_buf);
    return testResult;

}


TestResult*
test_ssl_handshakeRead_oversize(void)
{

    /*
     *  In this scenario, we will send a message size that exceeds the total packet length
     *  We will examine whether the function effectively detects the oversized message and generates the appropriate response
     */

    BIO *h = NULL;
    char *buf = NULL;

    int expected;
    int obtained;
    int obtained_next;
    char *expected_str;
    char *obtained_str;
    char *null_terminated_expected;
    char *null_terminated_obtained;

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = true;

    prelogin_request = strdup("1201000F0000010011A25E4571");
    buf = malloc(strlen(prelogin_request)/2);

    h = BIO_new(BIO_s_mem());
    ReadPointer = 0;

    expected = strlen(prelogin_request)/2 - 5;
    obtained = test_ssl_handshake_read(h, buf, expected, mock_socket_read, ReadPointer);

    expected_str = (char *)malloc(strlen(prelogin_request)/2);
    for (int i = 0; i < expected; i++) 
        sscanf(&prelogin_request [i * 2], "%2hhx", (char *)expected_str + i);

    obtained_str = (char *)malloc(expected+1);
    memcpy(obtained_str, buf, obtained);
    obtained_next = test_ssl_handshake_read(h, buf, expected - obtained, mock_socket_read, ReadPointer);
    memcpy(obtained_str + obtained, buf, obtained_next);
    null_terminated_expected = strdup(expected_str);
    null_terminated_obtained = strdup(obtained_str);
    
    TEST_ASSERT_TESTCASE(strcmp(null_terminated_expected, null_terminated_obtained) == 0, testResult);
    TEST_ASSERT(strcmp(null_terminated_expected, null_terminated_obtained) == 0, testResult);
    if(testResult->result == true)
    {
        strncpy(testResult->message, "SSL packet expand more than one TDS packet", MAX_TEST_MESSAGE_LENGTH);
    }

    free(buf);
    free(prelogin_request);
    free(expected_str);
    free(obtained_str);
    free(null_terminated_expected);
    free(null_terminated_obtained);
    ReadPointer = 0;
 
    return testResult;

}


TestResult*
test_ssl_handshakeRead_pkt_type(void)
{

    /*
     *  We will generate a message other than the prelogin request by modifying the packet type field within the packet.
     *  We will verify if the function correctly identifies and handles messages other than the prelogin request
     *  ensuring appropriate error handling and response generation.
     */

    BIO *h = NULL;
    char *buf = NULL;

    ErrorData *errorData;
    MemoryContext oldcontext;

    TestResult* testResult = palloc0(sizeof(TestResult));
    testResult->result = false;

    prelogin_request = strdup("100100090000010011");
    buf = malloc(strlen(prelogin_request)/2);

    h = BIO_new(BIO_s_mem());
    ReadPointer = 0;

    oldcontext = CurrentMemoryContext;
    PG_TRY();
    {
        test_ssl_handshake_read(h, buf, 0, mock_socket_read, ReadPointer);
    }
    PG_CATCH();
    {
        MemoryContextSwitchTo(oldcontext);
        errorData = CopyErrorData();
        FlushErrorState();
        snprintf(testResult->message, MAX_TEST_MESSAGE_LENGTH, "%s", testResult->message, errorData->message);
        testResult->result = true;
        FreeErrorData(errorData);
    }
    PG_END_TRY();

    // If the error doesn't occurr, then the following message gets displayed
    if(testResult->result == false)
    {
        strncpy(testResult->message, "Error doesn't occur since packet type is PRE_LOGIN", MAX_TEST_MESSAGE_LENGTH);
    }

    free(buf);
    free(prelogin_request);
    ReadPointer = 0;
 
    return testResult;

}

#endif
