/*-------------------------------------------------------------------------
 *
 * tds_protocol.h
 *	  Definitions for TDS protocol related structures and functions
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/tds/tds_protocol.h
 *
 *-------------------------------------------------------------------------
 */

#ifndef TDS_PROTOCOL_H
#define TDS_PROTOCOL_H

#include "src/include/tds_request.h"

/*
 * Once the TDS login handshake is done, the backend should be in any of the
 * following phasees:
 *
 * TDS_REQUEST_PHASE_INIT		-- initial state
 * TDS_REQUEST_PHASE_FETCH		-- fetch a TDS packet and generate a TDSRequest
 * TDS_REQUEST_PHASE_PROCESS	-- process the request
 * TDS_REQUEST_PHASE_FLUSH		-- flush the response
 * TDS_REQUEST_PHASE_ERROR		-- handle error
 *
 * Once the login handshake is done, the backend enters the initial state.  After
 * that it goes into the following loop:
 *
 * Step INIT:		Initializations.  Currently, it's a no-op.
 * 				Goto step FETCH
 *
 * Step Fetch:		Fetch and parse a new TDS packet and generate a TDSRequest.
 * 				Goto step ERROR in case of any error via elog()
 * 				Goto step PROCESS otherwise
 *
 * Step PROCESS:	Process the request and generate next libpq request (if any)
 * 					that will be sent to the TCOP loop.
 * 					Remain in step PROCESS if a libpq request is generated and return
 * 					to TCOP loop
 * 				Goto step ERROR in case of any error via elog()
 * 				Goto step FLUSH if processing of the request is complete
 *
 * Step FLUSH:		Flush the response (call TdsFlush), reset the request
 * 					context and perform other cleanups (if any).  Any error
 * 					in this step will violate the TDS protocol.
 * 				Goto step ERROR in case of any error via elog() (should be FATAL?)
 * 				Goto step Fetch
 *
 * Step ERROR:		Must have generated at least one error token before going
 * 					into this phase.  Generate more error tokens if required.
 * 				Goto step FLUSH
 */
#define TDS_REQUEST_PHASE_INIT		0
#define TDS_REQUEST_PHASE_FETCH		1
#define TDS_REQUEST_PHASE_PROCESS	2
#define TDS_REQUEST_PHASE_FLUSH		3
#define TDS_REQUEST_PHASE_ERROR		4

/*
 * We store the information required to process each phase in the following
 * structure.
 */
typedef struct
{
	MemoryContext requestContext;	/* temporary request context */
	TDSRequest	request;		/* current request in-progress */
	uint8_t		phase;			/* current TDS_REQUEST_PHASE_* (see above) */
	uint8_t		status;			/* current status of the request */

	/* denotes whether we've sent at least one done token */
	bool		isEmptyResponse;

}			TdsRequestCtrlData;

extern TdsRequestCtrlData * TdsRequestCtrl;

#endif							/* TDS_PROTOCOL_H */
