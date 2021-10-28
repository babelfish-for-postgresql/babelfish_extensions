use master;
GO

CREATE TABLE [BABEL-2515]
(
  [PartitionId] [smallint] NOT NULL,
  CONSTRAINT [PK_DataRecord2056] PRIMARY KEY CLUSTERED ( [PartitionId] ASC )
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90)
  ON [XFPS_DataRecord2056]([PartitionId])
)
ON [XFPS_DataRecord2056]([PartitionId]);
GO

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_storage_on_partition', 'ignore';
GO

CREATE TABLE [BABEL-2515]
(
  [PartitionId] [smallint] NOT NULL,
  CONSTRAINT [PK_DataRecord2056] PRIMARY KEY CLUSTERED ( [PartitionId] ASC )
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90)
  ON [XFPS_DataRecord2056]([PartitionId])
)
ON [XFPS_DataRecord2056]([PartitionId]);
GO

DROP TABLE [BABEL-2515]
GO

-- reset to default
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_storage_on_partition', 'strict';
GO
