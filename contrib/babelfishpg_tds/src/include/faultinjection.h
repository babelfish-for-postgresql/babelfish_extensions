/*-------------------------------------------------------------------------
 *
 * faultinjection.h
 *	  This file contains definitions for structures and externs used
 *	  internally by the Fault Injection Framework
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * contrib/babelfish_tds/src/include/faultinjection.h
 *
 *-------------------------------------------------------------------------
 */
#include "nodes/pg_list.h"

#define FAULT_NAME_MAX_LENGTH 100
#define INVALID_TAMPER_BYTE -1

typedef enum FaultInjectorType_e
{
	TestType = 0,
	ParseHeaderType,
	PreParsingType,
	ParseRpcType,
	PostParsingType,
	InvalidType
} FaultInjectorType_e;

typedef struct FaultInjectionType
{
	FaultInjectorType_e type;
	char		faultTypeName[FAULT_NAME_MAX_LENGTH];
	List	   *injected_entries;
} FaultInjectionType;

extern FaultInjectionType FaultInjectionTypes[];

typedef struct FaultInjectorEntry_s
{
	char		faultName[FAULT_NAME_MAX_LENGTH];	/* name of the fault */
	FaultInjectorType_e type;
	int			num_occurrences;	/* 0 when diabled */
	void		(*fault_callback) (void *arg, int *num_occurrences);
} FaultInjectorEntry_s;

extern const FaultInjectorEntry_s Faults[];

extern int	tamperByte;

#define TEST_LIST	const FaultInjectorEntry_s Faults[]
#define TEST_TYPE_LIST FaultInjectionType FaultInjectionTypes[]

/*
 * Example of defining a Test Type
 *
 * TEST_TYPE_LIST = {
 * 	{TestType, "Test", NIL}
 * };
 */

/*
 * Example of defining a test of previously defined type
 *
 * static void
 * test_fault1(void *arg)
 * {
 * ...
 * }
 *
 * TEST_LIST = {
 * 	{"test_fault1", TestType, 0, &test_fault1},
 * 	{"", InvalidType, 0, NULL} -- keep this as last
 * };
 */

extern bool trigger_fault_injection;
extern void TriggerFault(FaultInjectorType_e type, void *arg);

#ifdef FAULT_INJECTOR
#define FAULT_INJECT(type, arg) TriggerFault(type, (void *) (arg))
#else
#define FAULT_INJECT(type, arg) ((void)0)
#endif
