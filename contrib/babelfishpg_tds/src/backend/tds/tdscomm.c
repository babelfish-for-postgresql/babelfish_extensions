/*-------------------------------------------------------------------------
 *
 * tdscomm.c
 *	  TDS Listener communication support Postgres
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  contrib/babelfishpg_tds/src/backend/tds/tdscomm.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "libpq/libpq.h"

#include "miscadmin.h"			/* for MyProcPort */
#include "access/xact.h"		/* for IsTransactionOrTransactionBlock() */
#include "utils/memutils.h"
#include "utils/guc.h"
#include "port/pg_bswap.h"
#include "utils/guc.h"
#include "utils/memutils.h"

#include "src/include/tds_debug.h"
#include "src/include/tds_int.h"
#include "src/include/faultinjection.h"

/* Globals */
MemoryContext TdsMemoryContext = NULL;


static uint32_t TdsBufferSize;
static char *TdsSendBuffer;
static int	TdsSendCur;			/* Next index to store a byte in TdsSendBuffer */
static int	TdsSendStart;		/* Next index to send a byte in TdsSendBuffer */
static uint8_t TdsSendMessageType;	/* Current TDS message in progress */

static bool TdsDoProcessHeader; /* Header is processed or not. */
static char *TdsRecvBuffer;
static int	TdsRecvStart;		/* Next index to read a byte from
								 * TdsRecvBuffer */
static int	TdsRecvEnd;			/* End of data available in TdsRecvBuffer */
static uint8_t TdsRecvMessageType;	/* Current TDS message in progress */
static uint8_t TdsRecvPacketStatus;
static int	TdsLeftInPacket;

static TdsSecureSocketApi tds_secure_read;
static TdsSecureSocketApi tds_secure_write;


/* Internal functions */
static void SocketSetNonblocking(bool nonblocking);
static int	InternalFlush(bool);
static void TdsConsumedBytes(int bytes);

/* Inline functions */

/* --------------------------------
 *	InternalPutbytes - send bytes to connection (not flushed until TdsFlush)
 *
 *	returns 0 if OK, EOF if trouble
 * --------------------------------
 */
static inline int
InternalPutbytes(void *bytes, size_t len)
{
	size_t		amount;
	unsigned char *s = bytes;

	while (len > 0)
	{
		/* If buffer is full, then flush it out */
		if (TdsSendCur >= TdsBufferSize)
		{
			SocketSetNonblocking(false);
			if (InternalFlush(false))
				return EOF;
		}
		amount = TdsBufferSize - TdsSendCur;
		if (amount > len)
			amount = len;
		memcpy(TdsSendBuffer + TdsSendCur, s, amount);
		TdsSendCur += amount;
		s += amount;
		len -= amount;
	}
	return 0;
}


/* --------------------------------
 * TdsSetMessageType - Set current TDS message context
 * --------------------------------
 */
void
TdsSetMessageType(uint8_t msgType)
{
	TdsSendMessageType = msgType;
}

/* --------------------------------
 * Low-level I/O routines begin here.
 *
 * These routines communicate with a frontend client across a connection.
 * --------------------------------
 */

/* --------------------------------
 *	SocketSetNonblocking - set socket blocking/non-blocking
 *
 * Sets the socket non-blocking if nonblocking is true, or sets it
 * blocking otherwise.
 * --------------------------------
 */
static void
SocketSetNonblocking(bool nonblocking)
{
	if (MyProcPort == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_CONNECTION_DOES_NOT_EXIST),
				 errmsg("there is no client connection")));

	MyProcPort->noblock = nonblocking;
}

/* --------------------------------
 *	TdsReadsocket - read data from socket
 *
 *	Data is read in a fix size buffer. Read socket will
 *	issue network read for left capacity in receive buffer
 * --------------------------------
 */
static int
TdsReadsocket(void)
{
	TdsErrorContext->err_text = "Reading data from socket";
	if (TdsRecvStart > 0)
	{
		if (TdsRecvEnd > TdsRecvStart)
		{
			/* still some unread data, left-justify it in the buffer */
			memmove(TdsRecvBuffer, TdsRecvBuffer + TdsRecvStart,
					TdsRecvEnd - TdsRecvStart);
			TdsRecvEnd -= TdsRecvStart;
			TdsRecvStart = 0;
		}
		else
			TdsRecvStart = TdsRecvEnd = 0;
	}

	/* Ensure that we're in blocking mode */
	SocketSetNonblocking(false);

	/* Can fill buffer from TdsRecvStart and upwards */
	for (;;)
	{
		int			r;

		r = tds_secure_read(MyProcPort, TdsRecvBuffer + TdsRecvEnd,
							TdsBufferSize - TdsRecvEnd);

		if (r < 0)
		{
			if (errno == EINTR)
				continue;		/* Ok if interrupted */

			/*
			 * Careful: an ereport() that tries to write to the client would
			 * cause recursion to here, leading to stack overflow and core
			 * dump!  This message must go *only* to the postmaster log.
			 */
			ereport(COMMERROR,
					(errcode_for_socket_access(),
					 errmsg("could not receive data from client: %m")));
			return EOF;
		}
		if (r == 0)
		{
			/*
			 * EOF detected.  We used to write a log message here, but it's
			 * better to expect the ultimate caller to do that.
			 */
			return EOF;
		}
		/* r contains number of bytes read, so just incr length */
		TdsRecvEnd += r;
		return 0;
	}

}

/* --------------------------------
 *	TdsProcessHeader - Process TDS header
 *
 *	TDS header is of 8 bytes and is prefixed before
 *	each packet in message
 * --------------------------------
 */
static int
TdsProcessHeader(void)
{
	uint16_t	data16;

	FAULT_INJECT(ParseHeaderType, TdsRecvBuffer);
	TdsErrorContext->err_text = "Processing TDS header";

	if (TdsLeftInPacket != 0)
		ereport(FATAL,
				(errcode(ERRCODE_PROTOCOL_VIOLATION),
				 errmsg("New TDS packet read encountered while "
						"last packet is not fully consumed")));
	/* Get atleast header worth of data */
	while (TdsRecvEnd - TdsRecvStart < TDS_PACKET_HEADER_SIZE)
	{
		if (TdsReadsocket())
			return EOF;
	}
	/* Message type */
	TdsRecvMessageType = TdsRecvBuffer[TdsRecvStart];
	/* Packet status */
	TdsRecvPacketStatus = TdsRecvBuffer[TdsRecvStart + 1];

	/* Packet length in network byte order (includes header size) */
	memcpy(&data16, TdsRecvBuffer + TdsRecvStart + 2, sizeof(data16));
	data16 = pg_ntoh16(data16);
	if (data16 > TdsBufferSize)
		ereport(FATAL,
				(errcode(ERRCODE_PROTOCOL_VIOLATION),
				 errmsg("Packet length %u exceeds packet size %u",
						data16, TdsBufferSize)));

	TdsLeftInPacket = data16 - TDS_PACKET_HEADER_SIZE;
	TdsRecvStart += TDS_PACKET_HEADER_SIZE;

	/* [BABEL-648] TDS packet with no TDS data is valid packet. */
	if (TdsLeftInPacket < 0)
		ereport(FATAL,
				(errcode(ERRCODE_PROTOCOL_VIOLATION),
				 errmsg("TDS packet with insufficient data")));

	TdsDoProcessHeader = false;
	TDS_DEBUG(TDS_DEBUG3, "TDS packet MessageType %d LeftInPacket %d Status %d",
			  TdsRecvMessageType, TdsLeftInPacket, TdsRecvPacketStatus);
	TDS_DEBUG(TDS_DEBUG3, "TDS receive buffer start %d end %d", TdsRecvStart, TdsRecvEnd);
	return 0;
}

/* --------------------------------
 *	TdsRecvbuf - load some bytes into the input buffer
 *
 *	returns 0 if OK, EOF if trouble
 * --------------------------------
 */
static int
TdsRecvbuf(void)
{
	TdsErrorContext->err_text = "Loading data into input buffer";
	/* Need to process the packet header */
	if (TdsLeftInPacket == 0 && TdsRecvStart < TdsRecvEnd)
	{
		if (TdsProcessHeader())
			return EOF;
		if (TdsLeftInPacket == 0)
			return 0;
	}
	/* No more data in the buffer to read */
	if (TdsRecvStart == TdsRecvEnd)
	{
		if (TdsReadsocket())
			return EOF;
		if (TdsLeftInPacket == 0)
		{
			if (TdsDoProcessHeader && TdsProcessHeader())
			{
				return EOF;
			}

			/*
			 * Last socket read only got header worth of data and if something
			 * is left to read.
			 */
			if ((TdsRecvStart == TdsRecvEnd) && (TdsLeftInPacket > 0))
			{
				if (TdsReadsocket())
					return EOF;
			}
		}
	}
	if (TdsRecvStart > TdsRecvEnd)
		ereport(FATAL,
				(errcode(ERRCODE_PROTOCOL_VIOLATION),
				 errmsg("TDS buffer start pointer %d beyond end pointer %d",
						TdsRecvStart, TdsRecvEnd)));
	return 0;
}

#if 0
/* --------------------------------
 *	TdsGetbyte	- get a single byte from connection, or return EOF
 * --------------------------------
 */
static int
TdsGetbyte(void)
{
	while (TdsLeftInPacket == 0 || TdsRecvStart >= TdsRecvEnd)
	{
		if (TdsRecvbuf())		/* If nothing in buffer, then recv some */
			return EOF;			/* Failed to recv data */
	}
	--TdsLeftInPacket;
	return (unsigned char) TdsRecvBuffer[TdsRecvStart++];
}
#endif

/* --------------------------------
 * TdsFillHeader - Make TDS header for current message
 *
 * Header is of fix 8 byte
 * --------------------------------
 */
static void
TdsFillHeader(bool lastPacket)
{
	uint16_t	net16;

	/* Message type */
	TdsSendBuffer[0] = TdsSendMessageType;
	/* Packet status */
	TdsSendBuffer[1] = (lastPacket) ? 0x1 : 0x0;
	/* Packet length including header */
	net16 = pg_hton16(TdsSendCur - TdsSendStart);
	memcpy(TdsSendBuffer + 2, &net16, sizeof(net16));
	net16 = 0;
	memcpy(TdsSendBuffer + 4, &net16, sizeof(net16));	/* TODO  get server pid */
	TdsSendBuffer[6] = 0;		/* TODO  generate packet id */
	TdsSendBuffer[7] = 0;		/* unused */
}

/* --------------------------------
 *	InternalFlush - flush pending output
 *
 * Returns 0 if OK (meaning everything was sent, or operation would block
 * and the socket is in non-blocking mode), or EOF if trouble.
 * --------------------------------
 */
static int
InternalFlush(bool lastPacket)
{
	static int	lastReportedSendErrno = 0;

	char	   *bufptr = TdsSendBuffer + TdsSendStart;
	char	   *bufend = TdsSendBuffer + TdsSendCur;

	TdsErrorContext->err_text = "TDS InternalFlush - Sending data to the client";
	/* Writing the packet for the first time */
	if (TdsSendStart == 0)
	{
		TdsFillHeader(lastPacket);
	}

	if (lastPacket)
		TdsSendMessageType = 0;

	while (bufptr < bufend)
	{
		int			r;

		DebugPrintBytes("TDS InternalFlush", bufptr, bufend - bufptr);
		r = tds_secure_write(MyProcPort, bufptr, bufend - bufptr);

		if (r <= 0)
		{
			if (errno == EINTR)
				continue;		/* Ok if we were interrupted */

			/*
			 * Ok if no data writable without blocking, and the socket is in
			 * non-blocking mode.
			 */
			if (errno == EAGAIN ||
				errno == EWOULDBLOCK)
			{
				return 0;
			}

			/*
			 * Careful: an ereport() that tries to write to the client would
			 * cause recursion to here, leading to stack overflow and core
			 * dump!  This message must go *only* to the postmaster log.
			 *
			 * If a client disconnects while we're in the midst of output, we
			 * might write quite a bit of data before we get to a safe query
			 * abort point.	 So, suppress duplicate log messages.
			 */
			if (errno != lastReportedSendErrno)
			{
				lastReportedSendErrno = errno;
				ereport(COMMERROR,
						(errcode_for_socket_access(),
						 errmsg("could not send data to client: %m")));
			}

			/*
			 * We drop the buffered data anyway so that processing can
			 * continue, even though we'll probably quit soon. We also set a
			 * flag that'll cause the next CHECK_FOR_INTERRUPTS to terminate
			 * the connection.
			 */
			TdsSendStart = 0;
			TdsSendCur = TDS_PACKET_HEADER_SIZE;
			ClientConnectionLost = 1;
			InterruptPending = 1;
			return EOF;
		}

		lastReportedSendErrno = 0;	/* reset after any successful send */
		bufptr += r;
		TdsSendStart += r;
	}

	TdsSendStart = 0;
	TdsSendCur = TDS_PACKET_HEADER_SIZE;
	return 0;
}

/* --------------------------------
 * TdsCommInit - Setup TDS comm context
 * --------------------------------
 */
void
TdsCommInit(uint32_t bufferSize,
			TdsSecureSocketApi secure_read,
			TdsSecureSocketApi secure_write)
{
	tds_secure_read = secure_read;
	tds_secure_write = secure_write;
	TdsDoProcessHeader = true;

	/*
	 * Create our own long term memory context for things like the send and
	 * recieve buffers and caches.
	 */
	Assert(TdsMemoryContext == NULL);
	TdsMemoryContext = AllocSetContextCreate(TopMemoryContext,
											 "TDS Listener",
											 ALLOCSET_DEFAULT_SIZES);

	TdsBufferSize = bufferSize;

	TdsCommReset();
}

/* --------------------------------
 * TdsCommReset - Reset TDS variables and allocate socket buffers
 * --------------------------------
 */
void
TdsCommReset(void)
{
	MemoryContext oldContext;

	TdsRecvMessageType = TdsSendMessageType = 0;
	TdsRecvPacketStatus = 0;
	TdsRecvStart = TdsRecvEnd = TdsLeftInPacket = 0;
	TdsSendStart = 0;
	TdsSendCur = TDS_PACKET_HEADER_SIZE;

	oldContext = MemoryContextSwitchTo(TdsMemoryContext);
	TdsRecvBuffer = palloc(TdsBufferSize);
	TdsSendBuffer = palloc(TdsBufferSize);
	MemoryContextSwitchTo(oldContext);
}

/* --------------------------------
 * TdsCommShutdown - Shutdown TDS comm context
 * --------------------------------
 */
void
TdsCommShutdown(void)
{
	Assert(TdsSendMessageType == 0);

	/*
	 * Both send and receive buffers should not have any valid data at this
	 * point in time
	 */
	Assert(TdsSendStart == 0 && TdsSendCur == TDS_PACKET_HEADER_SIZE);
	Assert(TdsRecvStart == TdsRecvEnd && TdsLeftInPacket == 0);

	pfree(TdsSendBuffer);
	pfree(TdsRecvBuffer);
	if (TdsMemoryContext != NULL)
	{
		MemoryContextDelete(TdsMemoryContext);
		TdsMemoryContext = NULL;
	}
}

/*	--------------------------------
 *	TdsSetBufferSize - Change network buffer size
 *
 *	During login handshake, client might ask for different
 *	packet size. Adjust buffer size accordingly
 *	--------------------------------
 */
void
TdsSetBufferSize(uint32_t newSize)
{
	TDS_DEBUG(TDS_DEBUG3, "TdsSetBufferSize current size %u new size %u",
			  TdsBufferSize, newSize);

	if (newSize == TdsBufferSize)
		return;

	/*
	 * Both send and receive buffers should not have any valid data at this
	 * point in time
	 */
	if (TdsSendStart != 0 ||
		TdsSendCur != TDS_PACKET_HEADER_SIZE ||
		TdsRecvStart != TdsRecvEnd ||
		TdsLeftInPacket != 0)
	{
		TDS_DEBUG(TDS_DEBUG1, "TDS buffers in inconsistent state; "
				  "TdsSendStart: %d TdsSendCur: %d TdsRecvStart: %d "
				  "TdsRecvEnd: %d TdsLeftInPacket: %d",
				  TdsSendStart, TdsSendCur, TdsRecvStart,
				  TdsRecvEnd, TdsLeftInPacket);
		ereport(FATAL,
				(errcode(ERRCODE_PROTOCOL_VIOLATION),
				 errmsg("TDS buffers in inconsistent state")));
	}

	TdsSendBuffer = repalloc(TdsSendBuffer, newSize);
	TdsRecvBuffer = repalloc(TdsRecvBuffer, newSize);

	TdsBufferSize = newSize;
	TdsRecvStart = TdsRecvEnd = TdsLeftInPacket = 0;
}

/* --------------------------------
 * TdsCheckMessageType - Check current TDS message context
 * --------------------------------
 */
bool
TdsCheckMessageType(uint8_t msgType)
{
	return (TdsRecvMessageType == msgType);
}

#if 0
/* --------------------------------
 *	TdsPeekbyte - peek at next byte from connection
 *
 *	Same as TdsGetbyte() except we don't advance the pointer.
 * --------------------------------
 */
int
TdsPeekbyte(void)
{
	while (TdsLeftInPacket == 0 || TdsRecvStart >= TdsRecvEnd)
	{
		if (TdsRecvbuf())		/* If nothing in buffer, then recv some */
			return EOF;			/* Failed to recv data */
	}
	return (unsigned char) TdsRecvBuffer[TdsRecvStart];
}
#endif

/* --------------------------------
 *	TdsReadNextBuffer - reads buffer from socket
 * --------------------------------
 */
int
TdsReadNextBuffer(void)
{
	TdsErrorContext->err_text = "Reading buffer from socket";
	while ((TdsLeftInPacket > 0 && TdsRecvStart >= TdsRecvEnd) || TdsDoProcessHeader)
	{
		if (TdsRecvbuf())		/* If nothing in buffer, then recv some */
			return EOF;			/* Failed to recv data */
	}
	return 0;
}

/* ---------------------------------
 *	TdsConsumedBytes - reduce TdsLeftInPacket by number of bytes consumed/read
 * ---------------------------------
 */
static void
TdsConsumedBytes(int bytes)
{
	TdsLeftInPacket -= bytes;
	if (TdsLeftInPacket == 0)
		TdsDoProcessHeader = true;
}

/* --------------------------------
 *	TdsGetbytes - get a known number of bytes from connection
 *
 *	returns 0 if OK, EOF if trouble
 * --------------------------------
 */
int
TdsGetbytes(char *s, size_t len)
{
	size_t		amount;

	TDS_DEBUG(TDS_DEBUG3, "TdsGetbytes LeftInPacket %d RecvStart %d RecvEnd %d",
			  TdsLeftInPacket, TdsRecvStart, TdsRecvEnd);
	while (len > 0)
	{
		while (TdsLeftInPacket == 0 || TdsRecvStart >= TdsRecvEnd)
		{
			if (TdsRecvbuf())	/* If nothing in buffer, then recv some */
				return EOF;		/* Failed to recv data */
		}
		TdsErrorContext->err_text = "";
		amount = Min(TdsLeftInPacket, TdsRecvEnd - TdsRecvStart);
		if (amount > len)
			amount = len;
		memcpy(s, TdsRecvBuffer + TdsRecvStart, amount);
		TdsRecvStart += amount;
		TdsConsumedBytes(amount);
		s += amount;
		len -= amount;
	}
	return 0;
}

/* --------------------------------
 *	PAGTdsDiscardbytes - throw away a known number of bytes
 *
 *	same as TdsGetbytes except we do not copy the data to anyplace.
 *	this is used for resynchronizing after read errors.
 *
 *	returns 0 if OK, EOF if trouble
 * --------------------------------
 */
int
TdsDiscardbytes(size_t len)
{
	size_t		amount;

	while (len > 0)
	{
		while (TdsLeftInPacket == 0 || TdsRecvStart >= TdsRecvEnd)
		{
			if (TdsRecvbuf())	/* If nothing in buffer, then recv some */
				return EOF;		/* Failed to recv data */
		}
		TdsErrorContext->err_text = "";
		amount = Min(TdsLeftInPacket, TdsRecvEnd - TdsRecvStart);
		if (amount > len)
			amount = len;
		TdsRecvStart += amount;
		TdsConsumedBytes(amount);
		len -= amount;
	}
	return 0;
}

/* --------------------------------
 *	TdsPutbytes - send bytes to connection (not flushed until TdsFlush)
 *
 *	returns 0 if OK, EOF if trouble
 * --------------------------------
 */
int
TdsPutbytes(void *s, size_t len)
{
	int			res;

	res = InternalPutbytes(s, len);
	return res;
}

/* --------------------------------
 *      TdsPutDate - send one 24-bit unsigned integer
 *      		in LITTLE_ENDIAN
 *
 *      returns 0 if OK, EOF if trouble
 * --------------------------------
 */
int
TdsPutDate(uint32_t value)
{
	uint32_t	tmp = htoLE32(value);

	return InternalPutbytes(&tmp, 3);
}

/* --------------------------------
 *	TdsPutInt8 - send one byte
 *
 *	returns 0 if OK, EOF if trouble
 * --------------------------------
 */
int
TdsPutInt8(int8_t value)
{
	return InternalPutbytes(&value, sizeof(value));
}

/* --------------------------------
 *	TdsPutInt64LE - send one 64-bit integer in LITTLE_ENDIAN
 *
 *	returns 0 if OK, EOF if trouble
 * --------------------------------
 */
int
TdsPutInt64LE(int64_t value)
{
	int64_t		tmp = htoLE64(value);

	return InternalPutbytes(&tmp, sizeof(tmp));
}

/* --------------------------------
 *      TdsPutUInt16LE - send one 16-bit unsigned integer in LITTLE_ENDIAN
 *
 *      returns 0 if OK, EOF if trouble
 * --------------------------------
 */
int
TdsPutUInt16LE(uint16_t value)
{
	uint16_t	tmp = htoLE16(value);

	return InternalPutbytes(&tmp, sizeof(tmp));
}

/* --------------------------------
 *	TdsPutUInt8 - send one byte
 *
 *	returns 0 if OK, EOF if trouble
 * --------------------------------
 */
int
TdsPutUInt8(uint8_t value)
{
	return InternalPutbytes(&value, sizeof(value));
}

/* --------------------------------
 *	TdsPutInt16LE - send one 16-bit integer in LITTLE_ENDIAN
 *
 *	returns 0 if OK, EOF if trouble
 * --------------------------------
 */
int
TdsPutInt16LE(int16_t value)
{
	int16_t		tmp = htoLE16(value);

	return InternalPutbytes(&tmp, sizeof(tmp));
}

/* --------------------------------
 *	TdsPutInt32LE - send one 32-bit integer in LITTLE_ENDIAN
 *
 *	returns 0 if OK, EOF if trouble
 * --------------------------------
 */
int
TdsPutInt32LE(int32_t value)
{
	int32_t		tmp = htoLE32(value);

	return InternalPutbytes(&tmp, sizeof(tmp));
}

/* --------------------------------
 *      TdsPutUInt32LE - send one 32-bit unsigned integer in LITTLE_ENDIAN
 *
 *      returns 0 if OK, EOF if trouble
 * --------------------------------
 */
int
TdsPutUInt32LE(uint32_t value)
{
	uint32_t	tmp = htoLE32(value);

	return InternalPutbytes(&tmp, sizeof(tmp));
}

/* --------------------------------
 *	TdsPutUInt64LE - send one unsigned 64-bit integer in LITTLE_ENDIAN
 *
 *	returns 0 if OK, EOF if trouble
 * --------------------------------
 */
int
TdsPutUInt64LE(uint64_t value)
{
	uint64_t	tmp = htoLE64(value);

	return InternalPutbytes(&tmp, sizeof(tmp));
}

/* --------------------------------
 *	TdsPutFloat4LE - send one 32-bit float in LITTLE_ENDIAN
 *
 *	returns 0 if OK, EOF if trouble
 * --------------------------------
 */
int
TdsPutFloat4LE(float4 value)
{
	uint32		tmp;
	union
	{
		float4		f;
		int32		i;
	}			swap;

	swap.f = value;
	tmp = htoLE32(swap.i);

	return InternalPutbytes(&tmp, sizeof(tmp));
}

/* --------------------------------
 *	TdsPutFloat8LE - send one 64-bit float in LITTLE_ENDIAN
 *
 *	returns 0 if OK, EOF if trouble
 * --------------------------------
 */
int
TdsPutFloat8LE(float8 value)
{
	uint64		tmp;
	union
	{
		float8		f;
		int64		i;
	}			swap;

	swap.f = value;
	tmp = htoLE64(swap.i);

	return InternalPutbytes(&tmp, sizeof(tmp));
}

/* --------------------------------
 *	TdsSocketFlush - flush pending output
 *
 *	returns 0 if OK, EOF if trouble
 * --------------------------------
 */
int
TdsSocketFlush(void)
{
	SocketSetNonblocking(false);
	return InternalFlush(true);
}

int
TdsReadNextPendingBcpRequest(StringInfo message)
{
	int			readBytes = 0;

	if (TdsReadNextBuffer() == EOF)
		return EOF;
	Assert(TdsRecvMessageType == TDS_BULK_LOAD);


	readBytes = TdsLeftInPacket;
	enlargeStringInfo(message, readBytes);
	if (TdsGetbytes(message->data + message->len, readBytes))
		return EOF;
	message->len += readBytes;

	/* if this is the last packet, then notify the caller. */
	if (TdsRecvPacketStatus & TDS_PACKET_HEADER_STATUS_EOM)
		return 1;
	return 0;
}

int
TdsDiscardAllPendingBcpRequest()
{
	int			readBytes = 0;

	while (1)
	{
		if (TdsReadNextBuffer() == EOF)
			return EOF;
		Assert(TdsRecvMessageType == TDS_BULK_LOAD);


		readBytes = TdsLeftInPacket;
		if (TdsDiscardbytes(readBytes))
			return EOF;

		/* if this is the last packet, break the loop */
		if (TdsRecvPacketStatus & TDS_PACKET_HEADER_STATUS_EOM)
			return 1;
	}
	return 0;
}

/* --------------------------------
 * TdsReadNextRequest - Read new request
 *
 * Put message into input sting info and
 * status out parameter - returns the status from first packet header
 * message type in out parameter
 * Return 0 for success and EOF for trouble
 * --------------------------------
 */
int
TdsReadNextRequest(StringInfo message, uint8_t *status, uint8_t *messageType)
{
	int			readBytes = 0;
	bool		isFirst = true;

	while (1)
	{
		if (TdsReadNextBuffer() == EOF)
			return EOF;
		TdsErrorContext->err_text = "Save the status from first packet header";

		/*
		 * If this is the first packet header for this TDS request, save the
		 * status.
		 */
		if (isFirst)
		{
			*messageType = TdsRecvMessageType;
			*status = TdsRecvPacketStatus;
			isFirst = false;
		}
		readBytes = TdsLeftInPacket;
		enlargeStringInfo(message, readBytes);
		if (TdsGetbytes(message->data + message->len, readBytes))
			return EOF;
		message->len += readBytes;

		/* if this is the last packet, break the loop */
		if (TdsRecvPacketStatus & TDS_PACKET_HEADER_STATUS_EOM)
		{
			if (TdsLeftInPacket == 0 && TdsRecvStart == TdsRecvEnd)
				TdsDoProcessHeader = true;
			return 0;
		}

		/*
		 * If this is a Bulk Load Request then read only the first packet of
		 * the request. We will fetch the rest of the data as and when
		 * required during the processing phase.
		 */
		if (TdsRecvMessageType == TDS_BULK_LOAD)
		{
			TdsDoProcessHeader = true;
			return 0;
		}
	}
	return 0;
}

/* --------------------------------
 * TdsReadMessage - Read and verify given message type
 *
 * Put message into input sting info
 * Return 0 for success and EOF for trouble
 * --------------------------------
 */
int
TdsReadMessage(StringInfo message, uint8_t messageType)
{
	uint8_t		curMsgType;
	uint8_t		status;

	/* Make sure that last write is flushed */
	if (TdsSendStart != 0 || TdsSendCur != TDS_PACKET_HEADER_SIZE)
		ereport(FATAL,
				(errcode(ERRCODE_PROTOCOL_VIOLATION),
				 errmsg("TDS last write did not flush")));

	if (TdsReadNextRequest(message, &status, &curMsgType))
		return EOF;
	/* TODO Map to proper error code for TDS client */
	if (messageType != curMsgType)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("Invalid message type %u, expected %u",
						curMsgType, messageType)));
	return 0;
}

/* --------------------------------
 * TdsWriteMessage - Write given message type
 *
 * Send given message over wire
 * Return 0 for success and EOF for trouble
 * --------------------------------
 */
int
TdsWriteMessage(StringInfo message, uint8_t messageType)
{
	/* No write should be active */
	if (TdsSendMessageType != 0)
		ereport(FATAL,
				(errcode(ERRCODE_PROTOCOL_VIOLATION),
				 errmsg("TDS message write %u already in progress",
						TdsSendMessageType)));

	TdsSetMessageType(messageType);
	if (TdsPutbytes(message->data, message->len))
		return EOF;
	if (TdsSocketFlush())
		return EOF;
	return 0;
}

bool
TdsGetRecvPacketEomStatus(void)
{
	return TdsRecvPacketStatus & TDS_PACKET_HEADER_STATUS_EOM;
}
