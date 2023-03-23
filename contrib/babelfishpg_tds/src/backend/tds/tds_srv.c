/*-------------------------------------------------------------------------
 *
 * tds_srv.c
 *      register wire protocol hooks for TDS
 *
 * Copyright (c) 2021, PostgreSQL Global Development Group
 *
 * IDENTIFICATION
 *    contrib/babelfishpg_tds/src/backend/tds/tds_srv.c
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include <grp.h>
#include <unistd.h>
#include <sys/stat.h>

#include "commands/defrem.h"
#include "common/ip.h"
#include "miscadmin.h"
#include "parser/parse_expr.h"
#include "postmaster/postmaster.h"
#include "postmaster/protocol_extension.h"
#include "pgstat.h"
#include "storage/ipc.h"
#include "tcop/pquery.h"
#include "tcop/tcopprot.h"
#include "utils/guc.h"
#include "utils/pidfile.h"
#include "utils/portal.h"
#include "utils/ps_status.h"
#include "utils/timeout.h"
#include "utils/varlena.h"

#include "src/include/tds_int.h"
#include "src/include/tds_secure.h"
#include "src/include/tds_protocol.h"
#include "src/include/tds_response.h"
#include "src/include/err_handler.h"
#include "src/include/guc.h"

static listen_init_hook_type prev_listen_init;

static bool LoadedSSL = false;

/* Where the Unix socket files are (list of palloc'd strings) */
static List *sock_paths = NIL;

/* Declare the TDS context callback only once */
static ErrorContextCallback tdserrcontext;

TdsErrorContextData *TdsErrorContext = NULL;

static int	pe_accept(pgsocket server_fd, Port *port);
static void pe_listen_init(void);
static void pe_close(pgsocket server_fd);
static void pe_tds_init(void);
static int	pe_start(Port *port);
static void pe_authenticate(Port *port, const char **username);
static void pe_mainfunc(Port *port) pg_attribute_noreturn();
static void pe_send_message(ErrorData *edata);
static void pe_send_ready_for_query(CommandDest dest);
static int	pe_read_command(StringInfo inBuf);
static int	pe_process_command(void);
static void pe_end_command(QueryCompletion *qc, CommandDest dest);
static void pe_report_param_status(const char *name, char *val);
static void socket_close(int code, Datum arg);

/* the dest reveiver support is kept in a separate file */
#include "tdsprinttup.c"

static ProtocolExtensionConfig pe_config = {
	pe_accept,
	pe_close,
	pe_tds_init,
	pe_start,
	pe_authenticate,
	pe_mainfunc,
	pe_send_message,
	NULL,						/* not interested in cancel key */
	NULL,
	NULL,
	pe_send_ready_for_query,
	pe_read_command,
	pe_end_command,
	TdsPrintTup,
	TdsPrinttupStartup,
	TdsShutdown,
	TdsDestroy,
	pe_process_command,
	pe_report_param_status
};

/*
 * The generic socket support is kept in a separate file
 */
#include "support_funcs.c"

void
pe_init(void)
{
#ifdef USE_SSL
	/* Server will be started when this extension will be loaded */
	if (EnableSSL)
		if (Tds_be_tls_init(true) == 0)
			LoadedSSL = true;
#endif

	/* Install hooks */
	prev_listen_init = listen_init_hook;
	listen_init_hook = pe_listen_init;
}

void
pe_fin(void)
{
	/* Uninstall hooks. */
	listen_init_hook = prev_listen_init;
}

/*
 * pe_listen_init - Create the telnet server socket(s)
 */
static void
pe_listen_init(void)
{
	pe_create_server_ports();
}

/*
 * pe_accept - Accept a new incoming client connection
 */
static int
pe_accept(pgsocket server_fd, Port *port)
{
	return pe_create_connection(server_fd, port);
}

/*
 * pe_close - called to close server sockets in new backend
 */
static void
pe_close(pgsocket server_fd)
{
	StreamClose(server_fd);
}

/*
 * pe_init - equivalent of pq_init
 */
static void
pe_tds_init(void)
{
	PLtsql_protocol_plugin **pltsql_plugin_handler_ptr_tmp;

	/* This is client backend */
	MyBackendType = B_BACKEND;

	TdsClientInit();

	/*
	 * If this is a TDS client, we install the TDS specific protocol function
	 * hooks. XXX: All of them should be removed in future.
	 */
	lookup_param_hook = TdsFindParam;

	/* Set up a rendezvous point with pltsql plugin */
	pltsql_plugin_handler_ptr_tmp = (PLtsql_protocol_plugin **)
		find_rendezvous_variable("PLtsql_protocol_plugin");

	/* unlikely */
	if (!pltsql_plugin_handler_ptr_tmp)
		elog(ERROR, "failed to setup rendezvous variable for pltsql plugin");

	*pltsql_plugin_handler_ptr_tmp = pltsql_plugin_handler_ptr;

	memset(pltsql_plugin_handler_ptr, 0, sizeof(PLtsql_protocol_plugin));

	pltsql_plugin_handler_ptr->send_info = &TdsSendInfo;
	pltsql_plugin_handler_ptr->send_done = &TdsSendDone;
	pltsql_plugin_handler_ptr->send_env_change = &TdsSendEnvChange;
	pltsql_plugin_handler_ptr->get_tsql_error = &get_tsql_error_details;
	pltsql_plugin_handler_ptr->stmt_beg = TDSStatementBeginCallback;
	pltsql_plugin_handler_ptr->stmt_end = TDSStatementEndCallback;
	pltsql_plugin_handler_ptr->stmt_exception = TDSStatementExceptionCallback;
	pltsql_plugin_handler_ptr->send_column_metadata = SendColumnMetadata;
	pltsql_plugin_handler_ptr->get_mapped_error_list = &get_mapped_error_list;
	pltsql_plugin_handler_ptr->get_mapped_tsql_error_code_list = &get_mapped_tsql_error_code_list;

	pltsql_plugin_handler_ptr->get_login_domainname = &get_tds_login_domainname;
	pltsql_plugin_handler_ptr->set_guc_stat_var = &TdsSetGucStatVariable;
	pltsql_plugin_handler_ptr->set_at_at_stat_var = &TdsSetAtAtStatVariable;
	pltsql_plugin_handler_ptr->set_db_stat_var = &TdsSetDatabaseStatVariable;
	pltsql_plugin_handler_ptr->get_stat_values = &tds_stat_get_activity;
	pltsql_plugin_handler_ptr->invalidate_stat_view = &invalidate_stat_table;
	pltsql_plugin_handler_ptr->get_host_name = &get_tds_host_name;
	pltsql_plugin_handler_ptr->get_context_info = &get_tds_context_info;
	pltsql_plugin_handler_ptr->set_context_info = &set_tds_context_info;
	pltsql_plugin_handler_ptr->get_datum_from_byte_ptr = &TdsBytePtrToDatum;
	pltsql_plugin_handler_ptr->get_datum_from_date_time_struct = &TdsDateTimeTypeToDatum;

	invalidate_stat_table_hook = invalidate_stat_table;
	guc_newval_hook = TdsSetGucStatVariable;

	/* set up process-exit hook to close the socket */
	on_proc_exit(socket_close, 0);
}

/*
 * pe_start - equivalent of ProcessStartupPacket()
 *
 *  This function needs to communicate with the client
 *  at least to the point where it can fill in the
 *  database_name and user_name in the Port. It cannot
 *  do anything that would require actual database
 *  access.
 */
static int
pe_start(Port *port)
{
	int			rc;
	MemoryContext oldContext;

	/* we're ready to begin the communication with the TDS client */
	if ((pltsql_plugin_handler_ptr))
		pltsql_plugin_handler_ptr->is_tds_client = true;

	/*
	 * Initialise The Global Variable TdsErrorContext, which is to be used
	 * throughout TDS.  We could have allocated the same in TdsMemoryContext.
	 * But, during reset connection, we reset the same.  We don't want to
	 * reset TdsErrorContext at that point of time.  So, allocate the memory
	 * in TopMemoryContext.
	 */
	oldContext = MemoryContextSwitchTo(TopMemoryContext);
	TdsErrorContext = palloc(sizeof(TdsErrorContextData));
	MemoryContextSwitchTo(oldContext);

	/* Push the error context */
	tdserrcontext.callback = TdsErrorContextCallback;
	tdserrcontext.arg = TdsErrorContext;
	tdserrcontext.previous = error_context_stack;
	error_context_stack = &tdserrcontext;

	if ((rc = TdsProcessLogin(port, LoadedSSL)) == -1)
	{
		return STATUS_ERROR;
	}

	/* Pop the error context stack */
	error_context_stack = tdserrcontext.previous;

	return rc;
}

static void
pe_authenticate(Port *port, const char **username)
{

	/* Initialize the TDS backend status array in shmem */
	tdsstat_initialize();

	/* This should be set already, but let's make sure */
	ClientAuthInProgress = true;	/* limit visibility of log messages */

	/*
	 * In EXEC_BACKEND case, we didn't inherit the contents of pg_hba.conf
	 * etcetera from the postmaster, and have to load them ourselves.
	 *
	 * FIXME: [fork/exec] Ugh.  Is there a way around this overhead?
	 */
#ifdef EXEC_BACKEND

	/*
	 * load_hba() and load_ident() want to work within the PostmasterContext,
	 * so create that if it doesn't exist (which it won't).  We'll delete it
	 * again later, in PostgresMain.
	 */
	if (PostmasterContext == NULL)
		PostmasterContext = AllocSetContextCreate(TopMemoryContext,
												  MC_Postmaster,
												  ALLOCSET_DEFAULT_SIZES);

	if (!load_hba())
	{
		/*
		 * It makes no sense to continue if we fail to load the HBA file,
		 * since there is no way to connect to the database in this case.
		 */
		ereport(FATAL,
				(errmsg("could not load pg_hba.conf")));
	}

	if (!load_ident())
	{
		/*
		 * It is ok to continue if we fail to load the IDENT file, although it
		 * means that you cannot log in using any of the authentication
		 * methods that need a user name mapping. load_ident() already logged
		 * the details of error to the log.
		 */
	}
#endif

	/*
	 * Perform authentication exchange.
	 */
	set_ps_display("authentication");

	/*
	 * Set up a timeout in case a buggy or malicious client fails to respond
	 * during authentication.  Since we're inside a transaction and might do
	 * database access, we have to use the statement_timeout infrastructure.
	 */
	enable_timeout_after(STATEMENT_TIMEOUT, AuthenticationTimeout * 1000);

	/*
	 * Now perform authentication exchange.
	 */
	TdsClientAuthentication(port);	/* might not return, if failure */

	/*
	 * Done with authentication.  Disable the timeout, and log if needed.
	 */
	disable_timeout(STATEMENT_TIMEOUT, false);

	/* Log only if Log_connections is set. */
	if (Log_connections)
	{
		StringInfoData logmsg;

		initStringInfo(&logmsg);
		appendStringInfo(&logmsg, _("connection authorized: user=%s,"),
						 port->user_name);
		if (port->application_name)
			appendStringInfo(&logmsg, _(" application=%s,"),
							 port->application_name);

		appendStringInfo(&logmsg, _(" Tds Version=0x%X."), GetClientTDSVersion());

		ereport(LOG, errmsg_internal("%s", logmsg.data));
		pfree(logmsg.data);
	}

	set_ps_display("startup");

	ClientAuthInProgress = false;	/* client_min_messages is active now */

	*username = port->user_name;
}

static void
pe_mainfunc(Port *port)
{
	/*
	 * This protocol doesn't need anything other than the default behavior of
	 * PostgresMain(). Note that PostgresMain() will connect to the database
	 * and in turn will call our pe_authenticate() function.
	 */
	PostgresMain(port->database_name,
				 port->user_name);
}

static void
pe_send_message(ErrorData *edata)
{
	if (edata->output_to_client)
		emit_tds_log(edata);
}

static void
pe_send_ready_for_query(CommandDest dest)
{
	/*
	 * If we've already sent the login ack and initialized the protocol,
	 * return from here.  We're ready to process the next query.
	 */
	if (TdsRequestCtrl)
		return;

	/* Initialize the TDS backend information */
	tdsstat_bestart();

	/* Push the error context */
	tdserrcontext.callback = TdsErrorContextCallback;
	tdserrcontext.arg = TdsErrorContext;
	tdserrcontext.previous = error_context_stack;
	error_context_stack = &tdserrcontext;

	/* If first time, we should send the login ack */
	TdsSendLoginAck(MyProcPort);

	/* Pop the error context stack */
	error_context_stack = tdserrcontext.previous;
}

static int
pe_read_command(StringInfo inBuf)
{
	int			rc;

	/* Push the error context */
	tdserrcontext.callback = TdsErrorContextCallback;
	tdserrcontext.arg = TdsErrorContext;
	tdserrcontext.previous = error_context_stack;
	error_context_stack = &tdserrcontext;

	rc = TdsSocketBackend();

	/* Pop the error context stack */
	error_context_stack = tdserrcontext.previous;
	return rc;
}

static int
pe_process_command()
{
	int			result;

	/* Push the error context */
	tdserrcontext.callback = TdsErrorContextCallback;
	tdserrcontext.arg = TdsErrorContext;
	tdserrcontext.previous = error_context_stack;
	error_context_stack = &tdserrcontext;

	result = TdsSocketBackend();

	/*
	 * If no transaction is on-going, enforce transaction state cleanup before
	 * calling pgstat_report_stat function which requires a clean transaction
	 * state.
	 */
	if (!IsTransactionOrTransactionBlock())
		Cleanup_xact_PgStat();

	/* Pop the error context stack */
	error_context_stack = tdserrcontext.previous;
	return result;
}

static void
pe_end_command(QueryCompletion *qc, CommandDest dest)
{
	/* no-op */
}

static void
pe_report_param_status(const char *name, char *val)
{
	/* no-op */
}

/* --------------------------------
 *		socket_close - shutdown TDS at backend exit
 *
 * This is same as socket_close() in pqcomm.c, but for a TDS backend.
 * --------------------------------
 */
static void
socket_close(int code, Datum arg)
{
	/* Nothing to do in a standalone backend, where MyProcPort is NULL. */
	if (MyProcPort != NULL)
	{
#ifdef ENABLE_GSS
		/*
		 * Shutdown GSSAPI layer.  This section does nothing when interrupting
		 * BackendInitialize(), because pg_GSS_recvauth() makes first use of
		 * "ctx" and "cred".
		 *
		 * Note that we don't bother to free MyProcPort->gss, since we're
		 * about to exit anyway.
		 */
		if (MyProcPort->gss)
		{
			OM_uint32	min_s;

			if (MyProcPort->gss->ctx != GSS_C_NO_CONTEXT)
				gss_delete_sec_context(&min_s, &MyProcPort->gss->ctx, NULL);

			if (MyProcPort->gss->cred != GSS_C_NO_CREDENTIAL)
				gss_release_cred(&min_s, &MyProcPort->gss->cred);
		}
#endif							/* ENABLE_GSS */

		/*
		 * Cleanly shut down SSL layer.  Nowhere else does a postmaster child
		 * call this, so this is safe when interrupting BackendInitialize().
		 */
#ifdef USE_SSL
		if (MyProcPort->ssl_in_use)
			Tds_be_tls_close(MyProcPort);
#endif

		/*
		 * Formerly we did an explicit close() here, but it seems better to
		 * leave the socket open until the process dies.  This allows clients
		 * to perform a "synchronous close" if they care --- wait till the
		 * transport layer reports connection closure, and you can be sure the
		 * backend has exited.
		 *
		 * We do set sock to PGINVALID_SOCKET to prevent any further I/O,
		 * though.
		 */
		MyProcPort->sock = PGINVALID_SOCKET;
	}
}
