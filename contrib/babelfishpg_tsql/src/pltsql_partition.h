/*-------------------------------------------------------------------------
 *
 * pltsql_partition.h
 *	  This file contains declartions of function externs used
 *	  for PL/tsql Partition.
 *
 * Portions Copyright (c) 2024, AWS
 * Portions Copyright (c) 1996-2024, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * IDENTIFICATION
 *	contrib/babelfishpg_tsql/src/pltsql_partition.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef PLTSQL_PARTITION_H
#define PLTSQL_PARTITION_H

#include "nodes/parsenodes.h"

/* Max number of partitions allowed for babelfish partitioned tables. */
#define MAX_PARTITIONS_LIMIT 15000

extern void bbf_create_partition_tables(CreateStmt *stmt);
extern void bbf_drop_handle_partitioned_table(DropStmt *stmt);
extern void bbf_alter_handle_partitioned_table(AlterTableStmt *stmt);
extern bool bbf_validate_partitioned_index_alignment(IndexStmt *stmt);
extern void rename_table_update_bbf_partitions_name(RenameStmt *stmt);

#endif							/* PLTSQL_PARTITION_H */
