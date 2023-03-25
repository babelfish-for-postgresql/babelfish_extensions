/*-------------------------------------------------------------------------
 *
 * tdssecure.c
 *	  TDS Listener TLS connection code
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  contrib/babelfishpg_tds/src/backend/tds/tdssecure.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include <signal.h>
#include <fcntl.h>
#include <ctype.h>
#include <sys/socket.h>
#include <netdb.h>
#include <netinet/in.h>
#ifdef HAVE_NETINET_TCP_H
#include <netinet/tcp.h>
#include <arpa/inet.h>
#endif

#include "libpq/libpq.h"
#include "miscadmin.h"
#include "pgstat.h"
#include "tcop/tcopprot.h"
#include "utils/memutils.h"
#include "storage/ipc.h"
#include "storage/proc.h"

#include "src/include/tds_secure.h"
#include "src/include/tds_int.h"

int			tds_ssl_min_protocol_version;
int			tds_ssl_max_protocol_version;
#ifdef USE_SSL
/*
 * SslRead - TDS secure read function, similar to my_sock_read
 */
static int
SslRead(BIO * h, char *buf, int size)
{
	int			res = 0;

	if (buf != NULL)
	{
		res = secure_raw_read(((Port *) BIO_get_data(h)), buf, size);
		BIO_clear_retry_flags(h);
		if (res <= 0)
		{
			/* If we were interrupted, tell caller to retry */
			if (errno == EINTR || errno == EWOULDBLOCK || errno == EAGAIN)
			{
				BIO_set_retry_read(h);
			}
		}
	}

	return res;
}

/*
 * my_tds_sock_read - TDS secure read function, similar to my_sock_read
 * During the initial handshake, strip off the inital 8 bytes header, when
 * filling in the data in buf called from openssl library
 */
static int
SslHandShakeRead(BIO * h, char *buf, int size)
{
	int			res = 0;

	if ((res = SslRead(h, buf, size)) <= 0)
		return res;

	/* very first packet of prelogin SSL handshake */
	if (size > 0 && res > 0 && buf[0] == TDS_PRELOGIN)
	{

		if (res < TDS_PACKET_HEADER_SIZE)
		{
			int			remainingRead = TDS_PACKET_HEADER_SIZE - res;
			char		tempBuf[TDS_PACKET_HEADER_SIZE];

			res = 0;

			/*
			 * Read the complete remaining of the header and throw away the
			 * bytes
			 */
			while (res < remainingRead)
			{
				int			tmp_res = 0;

				if ((tmp_res = SslRead(h, tempBuf, remainingRead - res)) <= 0)
				{
					return tmp_res;
				}
				res += tmp_res;
			}

			/*
			 * Read the actual data and return the res of the actual data read
			 * Don't worry if complete read, Openssl library will take care
			 */
			if ((res = SslRead(h, buf, size)) <= 0)
				return res;
		}
		else
		{
			int			tmp_res = 0;
			int			i = TDS_PACKET_HEADER_SIZE;

			for (i = TDS_PACKET_HEADER_SIZE; i < res; i++)
			{
				buf[i - TDS_PACKET_HEADER_SIZE] = buf[i];
			}
			res -= TDS_PACKET_HEADER_SIZE;

			/*
			 * Read remaining of the data. Even if the read is less than
			 * requested size due to whatever reasons, we are good, since we
			 * are returning the correct res value, so caller will take care
			 * of reading the remaining data
			 */
			if ((tmp_res = SslRead(h, &buf[res], TDS_PACKET_HEADER_SIZE)) <= 0)
				return tmp_res;
			res += tmp_res;
		}
	}

	return res;
}

/*
 * SslWrite - Tds secure write function, similar to my_sock_write.
 */
static int
SslWrite(BIO * h, const char *buf, int size)
{
	int			res = 0;

	res = secure_raw_write(((Port *) BIO_get_data(h)), buf, size);
	BIO_clear_retry_flags(h);
	if (res <= 0)
	{
		/* If we were interrupted, tell caller to retry */
		if (errno == EINTR || errno == EWOULDBLOCK || errno == EAGAIN)
		{
			BIO_set_retry_write(h);
		}
	}

	return res;
}

/*
 * TdsSshHandShakeWrite - Tds secure write function, similar to my_sock_write.
 * During the initial handshake add the 8 bytes header to the final data which
 * is sent to client
 */
static int
SslHandShakeWrite(BIO * h, const char *buf, int size)
{
	StringInfoData str;
	char		tmp[2];
	uint16_t	tsize;
	int			res = 0;

	/* Nothing to write */
	if (size < 0)
		return size;

	initStringInfo(&str);
	appendStringInfoChar(&str, TDS_PRELOGIN);
	appendStringInfoChar(&str, TDS_PACKET_HEADER_STATUS_EOM);
	tsize = pg_hton16(size + TDS_PACKET_HEADER_SIZE);
	memcpy(&tmp, (char *) &tsize, 2);

	appendStringInfoChar(&str, tmp[0]);
	appendStringInfoChar(&str, tmp[1]);
	appendStringInfoChar(&str, 0x00);
	appendStringInfoChar(&str, 0x00);
	appendStringInfoChar(&str, 0x00);
	appendStringInfoChar(&str, 0x00);

	appendBinaryStringInfo(&str, buf, size);
	buf = str.data;
	size += TDS_PACKET_HEADER_SIZE;

	/* Write the complete data */
	while (res < size)
	{
		int			tmp_res = 0;

		if ((tmp_res = SslWrite(h, &buf[res], size - res)) <= 0)
			return tmp_res;
		res += tmp_res;
	}

	/*
	 * Below assertion should not be failed in ideal case. If it gets failed
	 * then it means that we wrote TDS HEADER and buf on the wire without any
	 * error above but number of bytes written is still less than
	 * TDS_PACKET_HEADER_SIZE which is unexpected in any case.
	 */
	Assert(res >= TDS_PACKET_HEADER_SIZE);

	/*
	 * We are returning (res - TDS_PACKET_HEADER_SIZE) here because we are
	 * asked to write "size" number of bytes and callee does not know anything
	 * about TDS packet header.
	 */
	return (res - TDS_PACKET_HEADER_SIZE);
}

/*
 * TdsBioSecureSocket - Similar to my_BIO_s_socket
 * Used to setup, TDS listener read and write API
 * for the initial SSL handshake
 */
BIO_METHOD *
TdsBioSecureSocket(BIO_METHOD * my_bio_methods)
{
	if (my_bio_methods == NULL)
	{
		BIO_METHOD *biom = (BIO_METHOD *) BIO_s_socket();
#ifdef HAVE_BIO_METH_NEW
		int			my_bio_index;

		my_bio_index = BIO_get_new_index();
		if (my_bio_index == -1)
			return NULL;
		my_bio_index |= (BIO_TYPE_DESCRIPTOR | BIO_TYPE_SOURCE_SINK);
		my_bio_methods = BIO_meth_new(my_bio_index, "PostgreSQL backend socket");
		if (!my_bio_methods)
			return NULL;
		if (!BIO_meth_set_write(my_bio_methods, SslHandShakeWrite) ||
			!BIO_meth_set_read(my_bio_methods, SslHandShakeRead) ||
			!BIO_meth_set_gets(my_bio_methods, BIO_meth_get_gets(biom)) ||
			!BIO_meth_set_puts(my_bio_methods, BIO_meth_get_puts(biom)) ||
			!BIO_meth_set_ctrl(my_bio_methods, BIO_meth_get_ctrl(biom)) ||
			!BIO_meth_set_create(my_bio_methods, BIO_meth_get_create(biom)) ||
			!BIO_meth_set_destroy(my_bio_methods, BIO_meth_get_destroy(biom)) ||
			!BIO_meth_set_callback_ctrl(my_bio_methods, BIO_meth_get_callback_ctrl(biom)))
		{
			BIO_meth_free(my_bio_methods);
			my_bio_methods = NULL;
			return NULL;
		}
#else
		my_bio_methods = malloc(sizeof(BIO_METHOD));
		if (!my_bio_methods)
			return NULL;
		memcpy(my_bio_methods, biom, sizeof(BIO_METHOD));
		my_bio_methods->bread = SslHandShakeRead;
		my_bio_methods->bwrite = SslHandShakeWrite;
#endif
	}
	return my_bio_methods;
}
#endif

/*
 * Frees the strcture for the SSL
 */
void
TdsFreeSslStruct(Port *port)
{
#ifdef USE_SSL
	if (port->ssl)
	{
		/*
		 * Don't call the SSL_shutdown - since it shutdowns the connection
		 */
		SSL_free(port->ssl);
		port->ssl = NULL;
		port->ssl_in_use = false;
	}
#endif
}

/*
 *	Read data from a secure connection.
 */
ssize_t
tds_secure_read(Port *port, void *ptr, size_t len)
{
	ssize_t		n;
	int			waitfor;

	/* Deal with any already-pending interrupt condition. */
	ProcessClientReadInterrupt(false);

retry:
#ifdef USE_SSL
	waitfor = 0;
	if (port->ssl_in_use)
	{
		/* TDS specific TLS read */
		n = Tds_be_tls_read(port, ptr, len, &waitfor);
	}
	else
#endif
	{
		n = secure_raw_read(port, ptr, len);
		waitfor = WL_SOCKET_READABLE;
	}

	/* In blocking mode, wait until the socket is ready */
	if (n < 0 && !port->noblock && (errno == EWOULDBLOCK || errno == EAGAIN))
	{
		WaitEvent	event;

		Assert(waitfor);

		ModifyWaitEvent(FeBeWaitSet, 0, waitfor, NULL);

		WaitEventSetWait(FeBeWaitSet, -1 /* no timeout */ , &event, 1,
						 WAIT_EVENT_CLIENT_READ);

		/*
		 * If the postmaster has died, it's not safe to continue running,
		 * because it is the postmaster's job to kill us if some other backend
		 * exists uncleanly.  Moreover, we won't run very well in this state;
		 * helper processes like walwriter and the bgwriter will exit, so
		 * performance may be poor.  Finally, if we don't exit, pg_ctl will be
		 * unable to restart the postmaster without manual intervention, so no
		 * new connections can be accepted.  Exiting clears the deck for a
		 * postmaster restart.
		 *
		 * (Note that we only make this check when we would otherwise sleep on
		 * our latch.  We might still continue running for a while if the
		 * postmaster is killed in mid-query, or even through multiple queries
		 * if we never have to wait for read.  We don't want to burn too many
		 * cycles checking for this very rare condition, and this should cause
		 * us to exit quickly in most cases.)
		 */
		if (event.events & WL_POSTMASTER_DEATH)
			ereport(FATAL,
					(errcode(ERRCODE_ADMIN_SHUTDOWN),
					 errmsg("terminating connection due to unexpected postmaster exit")));

		/* Handle interrupt. */
		if (event.events & WL_LATCH_SET)
		{
			ResetLatch(MyLatch);
			ProcessClientReadInterrupt(true);

			/*
			 * We'll retry the read. Most likely it will return immediately
			 * because there's still no data available, and we'll wait for the
			 * socket to become ready again.
			 */
		}
		goto retry;
	}

	/*
	 * Process interrupts that happened during a successful (or non-blocking,
	 * or hard-failed) read.
	 */
	ProcessClientReadInterrupt(false);

	return n;
}

/*
 *	Write data to a secure connection.
 */
ssize_t
tds_secure_write(Port *port, void *ptr, size_t len)
{
	ssize_t		n;
	int			waitfor;

	/* Deal with any already-pending interrupt condition. */
	ProcessClientWriteInterrupt(false);

retry:
	waitfor = 0;
#ifdef USE_SSL
	if (port->ssl_in_use)
	{
		/* TDS specific SSL write */
		n = Tds_be_tls_write(port, ptr, len, &waitfor);
	}
	else
#endif
	{
		n = secure_raw_write(port, ptr, len);
		waitfor = WL_SOCKET_WRITEABLE;
	}

	if (n < 0 && !port->noblock && (errno == EWOULDBLOCK || errno == EAGAIN))
	{
		WaitEvent	event;

		Assert(waitfor);

		ModifyWaitEvent(FeBeWaitSet, 0, waitfor, NULL);

		WaitEventSetWait(FeBeWaitSet, -1 /* no timeout */ , &event, 1,
						 WAIT_EVENT_CLIENT_WRITE);

		/* See comments in secure_read. */
		if (event.events & WL_POSTMASTER_DEATH)
			ereport(FATAL,
					(errcode(ERRCODE_ADMIN_SHUTDOWN),
					 errmsg("terminating connection due to unexpected postmaster exit")));

		/* Handle interrupt. */
		if (event.events & WL_LATCH_SET)
		{
			ResetLatch(MyLatch);
			ProcessClientWriteInterrupt(true);

			/*
			 * We'll retry the write. Most likely it will return immediately
			 * because there's still no buffer space available, and we'll wait
			 * for the socket to become ready again.
			 */
		}
		goto retry;
	}

	/*
	 * Process interrupts that happened during a successful (or non-blocking,
	 * or hard-failed) write.
	 */
	ProcessClientWriteInterrupt(false);

	return n;
}
