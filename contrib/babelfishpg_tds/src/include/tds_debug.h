/*-------------------------------------------------------------------------
 *
 * tds_debug.h
 *	  Debugging functions/macros used internally in the TDS Listener
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/tds/tds_debug.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef TDS_DEBUG_H
#define TDS_DEBUG_H

#include <postgres.h>

#include <ctype.h>

#define DebugPrintBytes(_c, _s, _len) \
do \
{ \
	int i; \
	StringInfoData h; \
	StringInfoData a; \
	if (!TDS_DEBUG_ENABLED(TDS_DEBUG3)) \
		break; \
	initStringInfo(&h); \
	initStringInfo(&a); \
	for(i = 0; i < _len; i++) \
	{ \
		if (i % 16 == 0) \
		{ \
			if (i != 0) \
			{ \
				/* append characters and start new line */ \
				appendStringInfo(&h, "	 %s\n ", a.data); \
				resetStringInfo(&a); \
			} \
			/* print the offset */ \
			appendStringInfo(&h, " %04x:", i); \
		} \
		appendStringInfo(&h, " %02x", (unsigned char)(_s)[i]); \
		if (isascii((_s)[i]) && (_s)[i] >= ' ') \
			appendStringInfoChar(&a, (_s)[i]); \
		else \
			appendStringInfoChar(&a, '.'); \
	} \
	if (i % 16 != 0) \
	{ \
		while (i++ % 16 != 0) \
			appendStringInfoString(&h, "   "); \
		appendStringInfo(&h, "	 %s", a.data); \
	} \
	if (h.len == 0) \
		appendStringInfo(&h, "<empty>"); \
	elog(LOG, "MESSAGE: %s\n %s", (_c), h.data); \
	pfree(h.data); \
	pfree(a.data); \
} while(0)

#define DebugPrintMessage(_c, _m) \
do \
{ \
	DebugPrintBytes((_c), (_m)->data, (_m->len)); \
} while(0)

#define DebugPrintMessageData(_c, _m) \
do \
{ \
	DebugPrintBytes((_c), (_m).data, (_m.len)); \
} while(0)

#define DebugPrintLoginMessage(_r) \
do \
{ \
	StringInfoData s; \
	Assert((_r) != NULL); \
	if (!TDS_DEBUG_ENABLED(TDS_DEBUG3)) \
		break; \
	initStringInfo(&s); \
	appendStringInfo(&s, "\n Login (_r) {\n"); \
	appendStringInfo(&s, "	length: %u\n", (_r)->length); \
	appendStringInfo(&s, "	tdsVersion: 0x%08x\n", (_r)->tdsVersion); \
	appendStringInfo(&s, "	packetSize: %d\n", (_r)->packetSize); \
	appendStringInfo(&s, "	optionFlags1: 0x%02x\n", (_r)->optionFlags1); \
	appendStringInfo(&s, "	optionFlags2: 0x%02x\n", (_r)->optionFlags2); \
	appendStringInfo(&s, "	typeFlags: 0x%02x\n", (_r)->typeFlags); \
	appendStringInfo(&s, "	timezone: 0x%08x\n", (_r)->clientTimezone); \
	appendStringInfo(&s, "	lcid: 0x%08x\n", (_r)->clientLcid); \
	if ((_r)->hostname != NULL) \
		appendStringInfo(&s, "	hostname: %s\n", (_r)->hostname); \
	if ((_r)->username != NULL) \
		appendStringInfo(&s, "	username: %s\n", (_r)->username); \
	if ((_r)->appname != NULL) \
		appendStringInfo(&s, "	appname: %s\n", (_r)->appname); \
	if ((_r)->servername != NULL) \
		appendStringInfo(&s, "	servername: %s\n", (_r)->servername); \
	if ((_r)->library != NULL) \
		appendStringInfo(&s, "	library: %s\n", (_r)->library); \
	if ((_r)->language != NULL) \
		appendStringInfo(&s, "	language: %s\n", (_r)->language); \
	if ((_r)->database != NULL) \
		appendStringInfo(&s, "	database: %s\n", (_r)->database); \
	appendStringInfo(&s, "}"); \
	elog(LOG, "%s", s.data); \
	pfree(s.data); \
} while(0)

#endif							/* TDS_DEBUG_H */
