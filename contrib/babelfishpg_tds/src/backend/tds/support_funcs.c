/*-------------------------------------------------------------------------
 *
 * support_funcs.c
 *		Socket related support functions for loadable protocol extensions
 *
 * Copyright (c) 2021, PostgreSQL Global Development Group
 *
 * IDENTIFICATION
 *	  contrib/babelfishpg_tds/src/backend/tds/support_funcs.c
 *
 *-------------------------------------------------------------------------
 */

/*---- Function declarations ----*/

static void	pe_create_server_ports(void);
static int	pe_create_server_port(int family, const char *hostName,
								  unsigned short portNumber,
								  const char *unixSocketDir,
								  ProtocolExtensionConfig *protocol_config);
static int	pe_create_connection(pgsocket server_fd, Port *port);


#ifdef HAVE_UNIX_SOCKETS
static int	Lock_AF_UNIX(const char *unixSocketDir, const char *unixSocketPath);
static int	Setup_AF_UNIX(const char *sock_path);
#endif							/* HAVE_UNIX_SOCKETS */

/*
 * pe_create_server_ports - create server ports as per config
 */
static void
pe_create_server_ports(void)
{
	int		status;
	bool	listen_addr_saved = false;

	if (ListenAddresses)
	{
		char	   *rawstring;
		List	   *elemlist;
		ListCell   *l;
		int			success = 0;

		/* Need a modifiable copy of ListenAddresses */
		//rawstring = pstrdup(pe_listen_addrs);
		rawstring = pstrdup(ListenAddresses);

		/* Parse string into list of hostnames */
		if (!SplitGUCList(rawstring, ',', &elemlist))
		{
			/* syntax error in list */
			ereport(FATAL,
					(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					 errmsg("invalid list syntax in parameter \"%s\"",
							"listen_addresses")));
		}

		foreach(l, elemlist)
		{
			char	   *curhost = (char *) lfirst(l);

			if (strcmp(curhost, "*") == 0)
				status = pe_create_server_port(AF_UNSPEC, NULL,
											   (unsigned short) pe_port,
											   NULL,
											   &pe_config);
			else
				status = pe_create_server_port(AF_UNSPEC, curhost,
											   (unsigned short) pe_port,
											   NULL,
											   &pe_config);

			if (status == STATUS_OK)
			{
				success++;
				/* record the first successful host addr in lockfile */
				if (!listen_addr_saved)
				{
					AddToDataDirLockFile(LOCK_FILE_LINE_LISTEN_ADDR, curhost);
					listen_addr_saved = true;
				}
			}
			else
				ereport(WARNING,
						(errmsg("could not create listen socket for \"%s\"",
								curhost)));
		}

		if (!success && elemlist != NIL)
			ereport(WARNING,
					(errmsg("could not create any TCP/IP sockets to accept TDS connections")));

		list_free(elemlist);
		pfree(rawstring);
	}
}


/*
 * pe_create_server_port -- open a "listening" port to accept connections.
 * Implementation copied from StreamClose() in src/backend/libpq/pqcomm.c
 *
 * family should be AF_UNIX or AF_UNSPEC; portNumber is the port number.
 * For AF_UNIX ports, hostName should be NULL and unixSocketDir must be
 * specified.  For TCP ports, hostName is either NULL for all interfaces or
 * the interface to listen on, and unixSocketDir is ignored (can be NULL).
 *
 * Successfully opened sockets are added to the ListenSocket[] array (of
 * length MaxListen), at the first position that isn't PGINVALID_SOCKET.
 *
 * RETURNS: STATUS_OK or STATUS_ERROR
 *
 * NOTE: This is mostly a copy of StreamServerPort()
 */

static int
pe_create_server_port(int family, const char *hostName,
					  unsigned short portNumber,
					  const char *unixSocketDir,
					  ProtocolExtensionConfig *protocol_config)

{
	pgsocket	fd;
	int			err;
	int			maxconn;
	int			ret;
	char		portNumberStr[32];
	const char *familyDesc;
	char		familyDescBuf[64];
	const char *addrDesc;
	char		addrBuf[NI_MAXHOST];
	char	   *service;
	struct addrinfo *addrs = NULL,
			   *addr;
	struct addrinfo hint;
	int			added = 0;

#ifdef HAVE_UNIX_SOCKETS
	char		unixSocketPath[MAXPGPATH];
#endif
#if !defined(WIN32) || defined(IPV6_V6ONLY)
	int			one = 1;
#endif

	/* Initialize hint structure */
	MemSet(&hint, 0, sizeof(hint));
	hint.ai_family = family;
	hint.ai_flags = AI_PASSIVE;
	hint.ai_socktype = SOCK_STREAM;

#ifdef HAVE_UNIX_SOCKETS
	if (family == AF_UNIX)
	{
		/*
		 * Create unixSocketPath from portNumber and unixSocketDir and lock
		 * that file path
		 */
		UNIXSOCK_PATH(unixSocketPath, portNumber, unixSocketDir);
		if (strlen(unixSocketPath) >= UNIXSOCK_PATH_BUFLEN)
		{
			ereport(LOG,
					(errmsg("Unix-domain socket path \"%s\" is too long (maximum %d bytes)",
							unixSocketPath,
							(int) (UNIXSOCK_PATH_BUFLEN - 1))));
			return STATUS_ERROR;
		}
		if (Lock_AF_UNIX(unixSocketDir, unixSocketPath) != STATUS_OK)
			return STATUS_ERROR;
		service = unixSocketPath;
	}
	else
#endif							/* HAVE_UNIX_SOCKETS */
	{
		snprintf(portNumberStr, sizeof(portNumberStr), "%d", portNumber);
		service = portNumberStr;
	}

	ret = pg_getaddrinfo_all(hostName, service, &hint, &addrs);
	if (ret || !addrs)
	{
		if (hostName)
			ereport(LOG,
					(errmsg("could not translate host name \"%s\", service \"%s\" to address: %s",
							hostName, service, gai_strerror(ret))));
		else
			ereport(LOG,
					(errmsg("could not translate service \"%s\" to address: %s",
							service, gai_strerror(ret))));
		if (addrs)
			pg_freeaddrinfo_all(hint.ai_family, addrs);
		return STATUS_ERROR;
	}

	for (addr = addrs; addr; addr = addr->ai_next)
	{
		if (family != AF_UNIX && addr->ai_family == AF_UNIX)
		{
			/*
			 * Only set up a unix domain socket when they really asked for it.
			 * The service/port is different in that case.
			 */
			continue;
		}

		/* See if there is still room to add 1 more socket. */
		if (!listen_have_free_slot())
			break;

		/* set up address family name for log messages */
		switch (addr->ai_family)
		{
			case AF_INET:
				familyDesc = _("IPv4");
				break;
#ifdef HAVE_IPV6
			case AF_INET6:
				familyDesc = _("IPv6");
				break;
#endif
#ifdef HAVE_UNIX_SOCKETS
			case AF_UNIX:
				familyDesc = _("Unix");
				break;
#endif
			default:
				snprintf(familyDescBuf, sizeof(familyDescBuf),
						 _("unrecognized address family %d"),
						 addr->ai_family);
				familyDesc = familyDescBuf;
				break;
		}

		/* set up text form of address for log messages */
#ifdef HAVE_UNIX_SOCKETS
		if (addr->ai_family == AF_UNIX)
			addrDesc = unixSocketPath;
		else
#endif
		{
			pg_getnameinfo_all((const struct sockaddr_storage *) addr->ai_addr,
							   addr->ai_addrlen,
							   addrBuf, sizeof(addrBuf),
							   NULL, 0,
							   NI_NUMERICHOST);
			addrDesc = addrBuf;
		}

		if ((fd = socket(addr->ai_family, SOCK_STREAM, 0)) == PGINVALID_SOCKET)
		{
			ereport(LOG,
					(errcode_for_socket_access(),
			/* translator: first %s is IPv4, IPv6, or Unix */
					 errmsg("could not create %s socket for address \"%s\": %m",
							familyDesc, addrDesc)));
			continue;
		}

#ifndef WIN32

		/*
		 * Without the SO_REUSEADDR flag, a new postmaster can't be started
		 * right away after a stop or crash, giving "address already in use"
		 * error on TCP ports.
		 *
		 * On win32, however, this behavior only happens if the
		 * SO_EXCLUSIVEADDRUSE is set. With SO_REUSEADDR, win32 allows
		 * multiple servers to listen on the same address, resulting in
		 * unpredictable behavior. With no flags at all, win32 behaves as Unix
		 * with SO_REUSEADDR.
		 */
		if (addr->ai_family != AF_UNIX)
		{
			if ((setsockopt(fd, SOL_SOCKET, SO_REUSEADDR,
							(char *) &one, sizeof(one))) == -1)
			{
				ereport(LOG,
						(errcode_for_socket_access(),
				/* translator: first %s is IPv4, IPv6, or Unix */
						 errmsg("setsockopt(SO_REUSEADDR) failed for %s address \"%s\": %m",
								familyDesc, addrDesc)));
				closesocket(fd);
				continue;
			}
		}
#endif

#ifdef IPV6_V6ONLY
		if (addr->ai_family == AF_INET6)
		{
			if (setsockopt(fd, IPPROTO_IPV6, IPV6_V6ONLY,
						   (char *) &one, sizeof(one)) == -1)
			{
				ereport(LOG,
						(errcode_for_socket_access(),
				/* translator: first %s is IPv4, IPv6, or Unix */
						 errmsg("setsockopt(IPV6_V6ONLY) failed for %s address \"%s\": %m",
								familyDesc, addrDesc)));
				closesocket(fd);
				continue;
			}
		}
#endif

		/*
		 * Note: This might fail on some OS's, like Linux older than
		 * 2.4.21-pre3, that don't have the IPV6_V6ONLY socket option, and map
		 * ipv4 addresses to ipv6.  It will show ::ffff:ipv4 for all ipv4
		 * connections.
		 */
		err = bind(fd, addr->ai_addr, addr->ai_addrlen);
		if (err < 0)
		{
			int			saved_errno = errno;

			ereport(LOG,
					(errcode_for_socket_access(),
			/* translator: first %s is IPv4, IPv6, or Unix */
					 errmsg("could not bind %s address \"%s\": %m",
							familyDesc, addrDesc),
					 saved_errno == EADDRINUSE ?
					 (addr->ai_family == AF_UNIX ?
					  errhint("Is another postmaster already running on port %d?",
							  (int) portNumber) :
					  errhint("Is another postmaster already running on port %d?"
							  " If not, wait a few seconds and retry.",
							  (int) portNumber)) : 0));
			closesocket(fd);
			continue;
		}

#ifdef HAVE_UNIX_SOCKETS
		if (addr->ai_family == AF_UNIX)
		{
			if (Setup_AF_UNIX(service) != STATUS_OK)
			{
				closesocket(fd);
				break;
			}
		}
#endif

		/*
		 * Select appropriate accept-queue length limit.  PG_SOMAXCONN is only
		 * intended to provide a clamp on the request on platforms where an
		 * overly large request provokes a kernel error (are there any?).
		 */
		maxconn = MaxBackends * 2;
		if (maxconn > PG_SOMAXCONN)
			maxconn = PG_SOMAXCONN;

		err = listen(fd, maxconn);
		if (err < 0)
		{
			ereport(LOG,
					(errcode_for_socket_access(),
			/* translator: first %s is IPv4, IPv6, or Unix */
					 errmsg("could not listen on %s address \"%s\": %m",
							familyDesc, addrDesc)));
			closesocket(fd);
			continue;
		}

#ifdef HAVE_UNIX_SOCKETS
		if (addr->ai_family == AF_UNIX)
			ereport(LOG,
					(errmsg("listening on Unix socket \"%s\"",
							addrDesc)));
		else
#endif
			ereport(LOG,
			/* translator: first %s is IPv4 or IPv6 */
					(errmsg("listening on %s address \"%s\", port %d",
							familyDesc, addrDesc, (int) portNumber)));

		listen_add_socket(fd, protocol_config);
		added++;
	}

	pg_freeaddrinfo_all(hint.ai_family, addrs);

	if (!added)
		return STATUS_ERROR;

	return STATUS_OK;
}

#ifdef HAVE_UNIX_SOCKETS

/*
 * Lock_AF_UNIX -- configure unix socket file path
 * Implementation copied from Lock_AF_UNIX() in
 * src/backend/libpq/pqcomm.c
 */
static int
Lock_AF_UNIX(const char *unixSocketDir, const char *unixSocketPath)
{
	/* no lock file for abstract sockets */
	if (unixSocketPath[0] == '@')
		return STATUS_OK;

	/*
	 * Grab an interlock file associated with the socket file.
	 *
	 * Note: there are two reasons for using a socket lock file, rather than
	 * trying to interlock directly on the socket itself.  First, it's a lot
	 * more portable, and second, it lets us remove any pre-existing socket
	 * file without race conditions.
	 */
	CreateSocketLockFile(unixSocketPath, true, unixSocketDir);

	/*
	 * Once we have the interlock, we can safely delete any pre-existing
	 * socket file to avoid failure at bind() time.
	 */
	(void) unlink(unixSocketPath);

	/*
	 * Remember socket file pathnames for later maintenance.
	 */
	sock_paths = lappend(sock_paths, pstrdup(unixSocketPath));

	return STATUS_OK;
}


/*
 * Setup_AF_UNIX -- configure unix socket permissions
 * Implementation copied from Setup_AF_UNIX() in
 * src/backend/libpq/pqcomm.c
 */
static int
Setup_AF_UNIX(const char *sock_path)
{
	/* no file system permissions for abstract sockets */
	if (sock_path[0] == '@')
		return STATUS_OK;

	/*
	 * Fix socket ownership/permission if requested.  Note we must do this
	 * before we listen() to avoid a window where unwanted connections could
	 * get accepted.
	 */
	Assert(pe_unix_socket_group);
	if (pe_unix_socket_group[0] != '\0')
	{
#ifdef WIN32
		elog(WARNING, "configuration item unix_socket_group is not supported on this platform");
#else
		char	   *endptr;
		unsigned long val;
		gid_t		gid;

		val = strtoul(pe_unix_socket_group, &endptr, 10);
		if (*endptr == '\0')
		{						/* numeric group id */
			gid = val;
		}
		else
		{						/* convert group name to id */
			struct group *gr;

			gr = getgrnam(pe_unix_socket_group);
			if (!gr)
			{
				ereport(LOG,
						(errmsg("group \"%s\" does not exist",
								pe_unix_socket_group)));
				return STATUS_ERROR;
			}
			gid = gr->gr_gid;
		}
		if (chown(sock_path, -1, gid) == -1)
		{
			ereport(LOG,
					(errcode_for_file_access(),
					 errmsg("could not set group of file \"%s\": %m",
							sock_path)));
			return STATUS_ERROR;
		}
#endif
	}

	if (chmod(sock_path, pe_unix_socket_permissions) == -1)
	{
		ereport(LOG,
				(errcode_for_file_access(),
				 errmsg("could not set permissions of file \"%s\": %m",
						sock_path)));
		return STATUS_ERROR;
	}
	return STATUS_OK;
}
#endif							/* HAVE_UNIX_SOCKETS */

/*
 * pe_create_connection -- create a new connection with client using
 *		server port.  Set port->sock to the FD of the new connection.
 *		Implementation copied from StreamConnection() in
 *		src/backend/libpq/pqcomm.c
 *
 * ASSUME: that this doesn't need to be non-blocking because
 *		the Postmaster uses select() to tell when the socket is ready for
 *		accept().
 *
 * RETURNS: STATUS_OK or STATUS_ERROR
 *
 * NOTE: this is mostly a copy of StreamConnection
 */
int
pe_create_connection(pgsocket server_fd, Port *port)
{
	/* accept connection and fill in the client (remote) address */
	port->raddr.salen = sizeof(port->raddr.addr);
	if ((port->sock = accept(server_fd,
							 (struct sockaddr *) &port->raddr.addr,
							 &port->raddr.salen)) == PGINVALID_SOCKET)
	{
		ereport(LOG,
				(errcode_for_socket_access(),
				 errmsg("could not accept new connection: %m")));

		/*
		 * If accept() fails then postmaster.c will still see the server
		 * socket as read-ready, and will immediately try again.  To avoid
		 * uselessly sucking lots of CPU, delay a bit before trying again.
		 * (The most likely reason for failure is being out of kernel file
		 * table slots; we can do little except hope some will get freed up.)
		 */
		pg_usleep(100000L);		/* wait 0.1 sec */
		return STATUS_ERROR;
	}

	/* fill in the server (local) address */
	port->laddr.salen = sizeof(port->laddr.addr);
	if (getsockname(port->sock,
					(struct sockaddr *) &port->laddr.addr,
					&port->laddr.salen) < 0)
	{
		ereport(LOG,
				(errmsg("getsockname() failed: %m")));
		return STATUS_ERROR;
	}

	/* select NODELAY and KEEPALIVE options if it's a TCP connection */
	if (port->laddr.addr.ss_family != AF_UNIX)
	{
		int			on;
#ifdef WIN32
		int			oldopt;
		int			optlen;
		int			newopt;
#endif

#ifdef	TCP_NODELAY
		on = 1;
		if (setsockopt(port->sock, IPPROTO_TCP, TCP_NODELAY,
					   (char *) &on, sizeof(on)) < 0)
		{
			ereport(LOG,
					(errmsg("setsockopt(%s) failed: %m", "TCP_NODELAY")));
			return STATUS_ERROR;
		}
#endif
		on = 1;
		if (setsockopt(port->sock, SOL_SOCKET, SO_KEEPALIVE,
					   (char *) &on, sizeof(on)) < 0)
		{
			ereport(LOG,
					(errmsg("setsockopt(%s) failed: %m", "SO_KEEPALIVE")));
			return STATUS_ERROR;
		}

#ifdef WIN32

		/*
		 * This is a Win32 socket optimization.  The OS send buffer should be
		 * large enough to send the whole Postgres send buffer in one go, or
		 * performance suffers.  The Postgres send buffer can be enlarged if a
		 * very large message needs to be sent, but we won't attempt to
		 * enlarge the OS buffer if that happens, so somewhat arbitrarily
		 * ensure that the OS buffer is at least PQ_SEND_BUFFER_SIZE * 4.
		 * (That's 32kB with the current default).
		 *
		 * The default OS buffer size used to be 8kB in earlier Windows
		 * versions, but was raised to 64kB in Windows 2012.  So it shouldn't
		 * be necessary to change it in later versions anymore.  Changing it
		 * unnecessarily can even reduce performance, because setting
		 * SO_SNDBUF in the application disables the "dynamic send buffering"
		 * feature that was introduced in Windows 7.  So before fiddling with
		 * SO_SNDBUF, check if the current buffer size is already large enough
		 * and only increase it if necessary.
		 *
		 * See https://support.microsoft.com/kb/823764/EN-US/ and
		 * https://msdn.microsoft.com/en-us/library/bb736549%28v=vs.85%29.aspx
		 */
		optlen = sizeof(oldopt);
		if (getsockopt(port->sock, SOL_SOCKET, SO_SNDBUF, (char *) &oldopt,
					   &optlen) < 0)
		{
			ereport(LOG,
					(errmsg("getsockopt(%s) failed: %m", "SO_SNDBUF")));
			return STATUS_ERROR;
		}
		newopt = PQ_SEND_BUFFER_SIZE * 4;
		if (oldopt < newopt)
		{
			if (setsockopt(port->sock, SOL_SOCKET, SO_SNDBUF, (char *) &newopt,
						   sizeof(newopt)) < 0)
			{
				ereport(LOG,
						(errmsg("setsockopt(%s) failed: %m", "SO_SNDBUF")));
				return STATUS_ERROR;
			}
		}
#endif

		/*
		 * Also apply the current keepalive parameters.  If we fail to set a
		 * parameter, don't error out, because these aren't universally
		 * supported.  (Note: you might think we need to reset the GUC
		 * variables to 0 in such a case, but it's not necessary because the
		 * show hooks for these variables report the truth anyway.)
		 */
		(void) pq_setkeepalivesidle(tcp_keepalives_idle, port);
		(void) pq_setkeepalivesinterval(tcp_keepalives_interval, port);
		(void) pq_setkeepalivescount(tcp_keepalives_count, port);
		(void) pq_settcpusertimeout(tcp_user_timeout, port);
	}

	return STATUS_OK;
}
