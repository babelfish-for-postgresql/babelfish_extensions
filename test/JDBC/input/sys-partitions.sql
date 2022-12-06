SELECT (CASE WHEN (partition_id IS NULL) THEN 0 ELSE 1 END),
        (CASE WHEN (object_id IS NULL) THEN 0 ELSE 1 END),
        (CASE WHEN (index_id IS NULL) THEN 0 ELSE 1 END),
        partition_number,hobt_id,
        (CASE WHEN ("rows" IS NULL) THEN 0 ELSE 1 END),
        filestream_filegroup_id,
        data_compression,data_compression_desc FROM sys.partitions;
GO
