/*-------------------------------------------------------------------------
 *
 * tds_secure.h
 *	  This file contains definitions for functions to register
 *	  read and write TLS functions for Tds listener
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/tds/tds_secure.h
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#ifdef HAVE_NETINET_TCP_H
#include <netinet/tcp.h>
#include <arpa/inet.h>
#endif

#ifdef USE_OPENSSL
#include <openssl/ssl.h>
#include <openssl/dh.h>
#include <openssl/conf.h>
#endif
#ifndef OPENSSL_NO_ECDH
#include <openssl/ec.h>
#endif

#include "libpq/libpq.h"
#include "port/pg_bswap.h"

BIO_METHOD *TdsBioSecureSocket(BIO_METHOD * my_bio_methods);

extern int	tds_ssl_min_protocol_version;
extern int	tds_ssl_max_protocol_version;

/* TDS specific function defined in tds-secure-openssl.c (modified copy of be-secure-openssl.c) */
int			Tds_be_tls_init(bool isServerStart);
void		Tds_be_tls_destroy(void);	/* TODO: call through our signal
										 * handler(SIGHUP_handler)/PG_TDS_fin */
int			Tds_be_tls_open_server(Port *port);
extern void Tds_be_tls_close(Port *port);
ssize_t		Tds_be_tls_read(Port *port, void *ptr, size_t len, int *waitfor);
ssize_t		Tds_be_tls_write(Port *port, void *ptr, size_t len, int *waitfor);

/* function defined in tdssecure.c and called from tdscomm.c */
ssize_t
			tds_secure_read(Port *port, void *ptr, size_t len);
ssize_t
			tds_secure_write(Port *port, void *ptr, size_t len);

/* function defined in tdssecure.c and called from tdslogin.c */
void		TdsFreeSslStruct(Port *port);
