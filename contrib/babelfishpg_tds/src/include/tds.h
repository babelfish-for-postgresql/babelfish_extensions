/*-------------------------------------------------------------------------
 * tds_instr.h
 *
 * Header file for BabelFish tds. Defining structures used to talk between the extensions
 *
 * Copyright (c) 2021, Amazon Web Services, Inc. or its affiliates. All Rights Reserved
 *-------------------------------------------------------------------------
 */


/*
 * When we load instrumentation extension, we create a rendezvous variable named
 * "TdsInstrPlugin" that points to an instance of type TdsInstrPlugin.
 *
 * We use this rendezvous variable to safely share information with
 * the engine even before the extension is loaded.  If you call
 * find_rendezvous_variable("TdsInstrPlugin") and find  that *result
 * is NULL, then the extension has not been loaded.  If you find
 * that *result is non-NULL, it points to an instance of the 
 * TdsInstrPlugin struct shown here.
 */
typedef struct TdsInstrPlugin
{
	/* Function pointers set up by the plugin */
	void (*tds_instr_increment_metric) (int metric);
} TdsInstrPlugin;

extern TdsInstrPlugin **tds_instr_plugin_ptr;

#define TDSInstrumentation(metric)												\
({	if ((tds_instr_plugin_ptr && (*tds_instr_plugin_ptr) && (*tds_instr_plugin_ptr)->tds_instr_increment_metric))	\
		(*tds_instr_plugin_ptr)->tds_instr_increment_metric(metric);		\
})

