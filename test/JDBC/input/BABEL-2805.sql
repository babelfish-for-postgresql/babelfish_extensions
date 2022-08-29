SELECT a, b FROM (VALUES (1, 2), (3, 4), (5, 6), (7, 8), (9, 10) ) AS MyTable(a, b);  
GO

select t.* from sys.dm_os_host_info
CROSS APPLY 
(
    VALUES
          (1001, 'host_platform', 0, host_platform),
          (1002, 'host_distribution', 0, host_distribution),
          (1003, 'host_release', 0, host_release),
          (1004, 'host_service_pack_level', 0, host_service_pack_level),
          (1005, 'host_sku', host_sku, ''),
          (1006, 'HardwareGeneration', '', ''),
          (1007, 'ServiceTier', '', ''),
          (1008, 'ReservedStorageSizeMB', '0', '0'),
          (1009, 'UsedStorageSizeMB', '0', '0')
) t(id, [name], internal_value, [value])
GO
