/*-------------------------------------------------------------------------
 *
 * guc.h
 *	  This file contains extern declarations for GUCs
 *        used by the TDS listener.
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/guc.h
 *
 *-------------------------------------------------------------------------
 */

extern int pe_port;
extern char *pe_listen_addrs;
extern char *pe_unix_socket_directories;
extern char *product_version;
extern int pe_unix_socket_permissions;
extern char *pe_unix_socket_group;
extern bool tds_ssl_encrypt;
extern int tds_default_numeric_precision;
extern int tds_default_numeric_scale;
extern int32_t tds_default_protocol_version;
extern int32_t tds_default_packet_size;
extern int tds_debug_log_level;
extern char *default_server_name;
extern bool enable_drop_babelfish_role;
extern bool enable_alter_babelfish_role;