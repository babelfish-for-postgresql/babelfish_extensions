#include "executor/executor.h"
#include "executor/execParallel.h"
#include "fmgr.h"
#include "nodes/execnodes.h"

/* Key for sharing additional context for Babelfish */
#define BABELFISH_PARALLEL_KEY_FIXED		UINT64CONST(0xBBF0000000000001)
#define BABELFISH_PARALLEL_KEY_TEMP_RELIDS	UINT64CONST(0xBBF0000000000002)

extern ExecInitParallelPlan_hook_type prev_ExecInitParallelPlan_hook;
extern ParallelQueryMain_hook_type prev_ParallelQueryMain_hook;

extern void bbf_ExecInitParallelPlan(EState *estate, ParallelContext *pcxt, bool estimate);
extern void bbf_ParallelQueryMain(shm_toc *toc);
extern bool bbf_ExecCheckOneRelPerms(RTEPermissionInfo *perminfo);
