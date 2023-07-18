#include "babelfishpg_unit.h"
#include "../babelfishpg_tds/src/include/tds_secure.h"


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
	 *  By comparing the number of bytes read against the expected value, we can verify the accuracy of the read operation 
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
	ReadPointer = 0;

	prelogin_request = strdup("1201000F0000010011A25E4571");
	buf = malloc(strlen(prelogin_request)/2);
	
	
	expected = strlen(prelogin_request)/2 - 8;
	obtained = test_ssl_handshake_read(h, buf, expected, mock_socket_read, ReadPointer);

	snprintf(expected_str, MAX_TEST_MESSAGE_LENGTH, "%d", expected);
    snprintf(obtained_str, MAX_TEST_MESSAGE_LENGTH, "%d", obtained);
	
	TEST_ASSERT_TESTCASE(expected == obtained, "1", expected_str, obtained_str, testResult);


	prelogin_request = strdup("32C4");
	buf = malloc(strlen(prelogin_request)/2);

	expected = strlen(prelogin_request)/2;
	obtained = test_ssl_handshake_read(h, buf, expected, mock_socket_read, ReadPointer);

	snprintf(expected_str, MAX_TEST_MESSAGE_LENGTH, "%d", expected);
    snprintf(obtained_str, MAX_TEST_MESSAGE_LENGTH, "%d", obtained);
	
	TEST_ASSERT_TESTCASE(expected == obtained, "2", expected_str, obtained_str, testResult);
	TEST_ASSERT(expected == obtained, testResult);


	free(buf);
    free(prelogin_request);

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

	char expected_str[MAX_TEST_MESSAGE_LENGTH];
    char obtained_str[MAX_TEST_MESSAGE_LENGTH];

	TestResult* testResult = palloc0(sizeof(TestResult));
	testResult->result = true;

	prelogin_request = strdup("1201000B00000100115461A23E");
	buf = malloc(strlen(prelogin_request)/2);

	h = BIO_new(BIO_s_mem());
	ReadPointer = 0;

    expected = strlen(prelogin_request)/2 - 8;
	obtained = test_ssl_handshake_read(h, buf, expected, mock_socket_read, ReadPointer);

	snprintf(expected_str, MAX_TEST_MESSAGE_LENGTH, "%d", expected);
    snprintf(obtained_str, MAX_TEST_MESSAGE_LENGTH, "%d", obtained);
	
	TEST_ASSERT_TESTCASE(expected != obtained, "1", expected_str, obtained_str, testResult);
	TEST_ASSERT(expected != obtained, testResult);
	if(testResult->result == true)
	{
        strncpy(testResult->message, ", SSL packet expand more than one TDS packet", MAX_TEST_MESSAGE_LENGTH);
	}

	free(buf);
    free(prelogin_request);
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
        snprintf(testResult->message, MAX_TEST_MESSAGE_LENGTH, "%s, %s", testResult->message, errorData->message);
        testResult->result = true;
        FreeErrorData(errorData);
    }
    PG_END_TRY();

    // If the error doesn't occurr, then the following message gets displayed
    if(testResult->result == false)
	{
        strncpy(testResult->message, ", Error doesn't occur since packet type is PRE_LOGIN", MAX_TEST_MESSAGE_LENGTH);
	}

	free(buf);
    free(prelogin_request);
	ReadPointer = 0;
 
    return testResult;

}