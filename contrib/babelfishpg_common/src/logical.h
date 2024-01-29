#ifndef LOGICAL_H
#define LOGICAL_H

#include "postgres.h"

/*
 *    IsLogicalWorker() is sufficient for native PG applyworker but will
 *    not work with external providers like pglogical, so will rely on
 *    SessionReplicationRole being replica since most of the providers seem
 *    to set this GUC.
 */
#define IS_LOGICAL_RECEIVER() (IsLogicalWorker() || SessionReplicationRole == SESSION_REPLICATION_ROLE_REPLICA)

/*
 * There are two criterias for walsender:
 * 1. MyReplicationSlot is logical.
 * 2. This is a logical walsender process.
 */
#define IS_LOGICAL_SENDER() \
        ((MyReplicationSlot != NULL && SlotIsLogical(MyReplicationSlot)) || \
		 (MyWalSnd != NULL && MyWalSnd->kind == REPLICATION_KIND_LOGICAL))

#endif							/* LOGICAL_H */
