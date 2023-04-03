/*-------------------------------------------------------------------------
 *
 * fault_injection_tests.c
 *	  TDS test cases for Fault Injection Framework
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  contrib/babelfishpg_tds/src/backend/fault_injection/fault_injection_tests.c
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "lib/stringinfo.h"
#include "miscadmin.h"

#include "src/include/tds_int.h"
#include "src/include/tds_request.h"
#include "src/include/faultinjection.h"

#include <stdio.h>
#include <string.h>

/* test cases */
static void
test_fault1(void *arg, int *num_occurrences)
{
	StringInfo	buf = (StringInfo) arg;

	(*num_occurrences) -= 1;

	if (buf->len > 0)
		appendStringInfo(buf, ", ");

	appendStringInfo(buf, "test_fault1");
}

static void
test_fault2(void *arg, int *num_occurrences)
{
	StringInfo	buf = (StringInfo) arg;

	(*num_occurrences) -= 1;

	if (buf->len > 0)
		appendStringInfo(buf, ", ");

	appendStringInfo(buf, "test_fault2");
}

/*
 * In this function, we tamper bytes of the input argument sequentially and
 * call TDS parser function.  The expectation is the parser code can throw and
 * error, but it should not crash.
 */
static void
tamper_request_sequential(void *arg, char tamper_byte)
{
	StringInfo	buf,
				tmp;
	MemoryContext oldcontext;
	int			i;

	struct TdsMessageWrapper *wrapper = (struct TdsMessageWrapper *) arg;
	uint64_t	offset = 0;
	uint32_t	tdsVersion = GetClientTDSVersion();

	/* Skip if its an Attention Request. */
	if (wrapper->messageType == TDS_ATTENTION)
		return;

	oldcontext = MemoryContextSwitchTo(MessageContext);
	buf = wrapper->message;
	tmp = makeStringInfo();

	/*
	 * Skip the offset part, otherwise, we'll throw FATAL error and terminate
	 * the connection
	 *
	 * Note: In the ALL_HEADERS rule, the Query Notifications header and the
	 * Transaction Descriptor header were introduced in TDS 7.2. We need to to
	 * Process them only for TDS versions more than or equal to 7.2, otherwise
	 * we do not increment the offset.
	 */
	if (tdsVersion > TDS_VERSION_7_1_1)
		offset = ProcessStreamHeaders(buf);
	for (i = offset; i < buf->len; i++)
	{
		PG_TRY();
		{
			appendBinaryStringInfoNT(tmp, buf->data, buf->len);

			tmp->data[i] = tamper_byte;

			switch (wrapper->messageType)
			{
				case TDS_QUERY: /* Simple SQL BATCH */
					{
						(void) GetSQLBatchRequest(tmp);
					}
					break;
				case TDS_RPC:	/* Remote procedure call */
					{
						(void) GetRPCRequest(tmp);
					}
					break;
				case TDS_TXN:	/* Transaction management request */
					{
						(void) GetTxnMgmtRequest(tmp);
					}
					break;
			}
		}
		PG_CATCH();
		{
			FlushErrorState();
		}
		PG_END_TRY();

		resetStringInfo(tmp);
	}
	if (tmp->data)
		pfree(tmp->data);
	pfree(tmp);

	MemoryContextSwitchTo(oldcontext);
}

static void
pre_parsing_tamper_request(void *arg, int *num_occurrences)
{
	(*num_occurrences) -= 1;

	/* tamper byte with all 0s */
	tamper_request_sequential(arg, 0x00);
	/* tamper byte with all Fs */
	tamper_request_sequential(arg, 0xFF);
	/* tamper byte with a random byte value */
	tamper_request_sequential(arg, (10 * rand() % 0xFF));
}


/*
 * In this function, we tamper bytes at particular offset and call
 * call TDS RPC parser function. The expectation is the parser code can throw and
 * error, but it should not crash.
 */
static void
tamper_rpc_request(void *arg, uint64_t offset, int tamper_byte)
{
	struct TdsMessageWrapper *wrapper = (struct TdsMessageWrapper *) arg;
	MemoryContext oldcontext = MemoryContextSwitchTo(MessageContext);

	StringInfo	buf = wrapper->message;
	StringInfo	tmp = makeStringInfo();

	PG_TRY();
	{
		appendBinaryStringInfoNT(tmp, buf->data, buf->len);

		tmp->data[offset] = tamper_byte;

		(void) GetRPCRequest(tmp);
	}
	PG_CATCH();
	{
		FlushErrorState();
	}
	PG_END_TRY();


	if (tmp->data)
		pfree(tmp->data);
	pfree(tmp);

	MemoryContextSwitchTo(oldcontext);
}

static void
pre_parsing_tamper_rpc_request_sptype(void *arg, int *num_occurrences)
{
	uint64_t	offset = 0;
	struct TdsMessageWrapper *wrapper = (struct TdsMessageWrapper *) arg;

	if (wrapper->messageType != TDS_RPC)
		return;

	(*num_occurrences) -= 1;

	if (GetClientTDSVersion() > TDS_VERSION_7_1_1)
		offset = ProcessStreamHeaders(wrapper->message);

	offset += 2;				/* Skip length. */

	if (tamperByte != INVALID_TAMPER_BYTE)
		tamper_rpc_request(arg, offset, tamperByte);
	else
		tamper_rpc_request(arg, offset, rand() % 0xFF);

}

static void
parsing_tamper_rpc_parameter_datatype(void *arg, int *num_occurrences)
{
	struct TdsMessageWrapper *wrapper = (struct TdsMessageWrapper *) arg;

	if (wrapper->messageType != TDS_RPC)
		return;

	(*num_occurrences) -= 1;

	if (tamperByte != INVALID_TAMPER_BYTE)
		tamper_rpc_request(arg, wrapper->offset, tamperByte);
	else
		tamper_rpc_request(arg, wrapper->offset, rand() % 0xFF);
}

static void
throw_error(void *arg, int *num_occurrences)
{
	(*num_occurrences) -= 1;
	elog(ERROR, "error triggered from fault injection");
}

static void
throw_error_comm(void *arg, int *num_occurrences)
{
	(*num_occurrences) -= 1;
	elog(FATAL, "FATAL error triggered from fault injection");
}

static void
throw_error_buffer(void *arg, int *num_occurrences)
{
	char		buffer[3] = {'\0'};
	int			can = 0;
	char		tem[10] = "aaaaaaaaaa";

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Warray-bounds"
#pragma GCC diagnostic ignored "-Wstringop-overflow"
	memcpy(buffer, tem, 10);
#pragma GCC diagnostic pop
	if (can != 0)
		elog(LOG, "Buffer overflowed \n");
	else
		elog(LOG, "Did not Overflow \n");
}

/*
 * Type declarations
 *
 * Format: {Enum type, Type name, Callback list}
 *
 * Enum type: type from FaultInjectorType_e
 * Type name: user visible name for this type
 * Callback list: fault callback list for this type; set it to NIL
 */
TEST_TYPE_LIST =
{
	{
		TestType, "Test", NIL
	},
	{
		ParseHeaderType, "TDS request header", NIL
	},
	{
		PreParsingType, "TDS pre-parsing", NIL
	},
	{
		PostParsingType, "TDS post-parsing", NIL
	},
	{
		ParseRpcType, "TDS RPC Parsing", NIL
	}
};

/*
 * Test declarations
 *
 * Format: {Test name, Type name, 0, Callback function}
 *
 * Test name: name of the test used to trigger this fault
 * Type name: type of the test
 * Callback function: callback function executed when this test is triggered
 */
TEST_LIST =
{
	{
		"test_fault1", TestType, 0, &test_fault1
	},
	{
		"test_fault2", TestType, 0, &test_fault2
	},
	{
		"tds_comm_throw_error", ParseHeaderType, 0, &throw_error_comm
	},
	{
		"pre_parsing_tamper_request", PreParsingType, 0, &pre_parsing_tamper_request
	},
	{
		"pre_parsing_tamper_rpc_request_sptype", PreParsingType, 0, &pre_parsing_tamper_rpc_request_sptype
	},
	{
		"parsing_tamper_rpc_parameter_datatype", ParseRpcType, 0, &parsing_tamper_rpc_parameter_datatype
	},
	{
		"pre_parsing_throw_error", PreParsingType, 0, &throw_error
	},
	{
		"post_parsing_throw_error", PostParsingType, 0, &throw_error
	},
	{
		"buffer_overflow_test", PreParsingType, 0, &throw_error_buffer
	},
	{
		"", InvalidType, 0, NULL
	}							/* keep this as last */
};
