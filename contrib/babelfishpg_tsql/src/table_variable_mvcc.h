#ifndef TABLE_VARIABLE_HEAPAM_H
#define TABLE_VARIABLE_HEAPAM_H

#include "access/heapam.h"

extern bool TVHeapTupleSatisfiesVisibility(HeapTuple tuple, Snapshot snapshot, Buffer buffer);
extern TM_Result TVHeapTupleSatisfiesUpdate(HeapTuple tuple, CommandId curcid, Buffer buffer);
extern HTSV_Result TVHeapTupleSatisfiesVacuum(HeapTuple stup, TransactionId OldestXmin, Buffer buffer);
extern HTSV_Result TVHeapTupleSatisfiesVacuumHorizon(HeapTuple htup, Buffer buffer, TransactionId *dead_after);

extern void init_failed_transactions_map(void);
extern void destroy_failed_transactions_map(void);
extern void add_failed_transaction(TransactionId xid);
extern bool find_failed_transaction(TransactionId xid);

#endif