CREATE VIEW host_id_4272_v1 AS (SELECT CASE WHEN CAST(HOST_ID() AS INT) >= 0 THEN 'HOST_ID() returns number' ELSE 'HOST_ID() unexpected value' END) 
GO

CREATE PROCEDURE host_id_4272_p1 AS (SELECT CASE WHEN CAST(HOST_ID() AS INT) >= 0 THEN 'HOST_ID() returns number' ELSE 'HOST_ID() unexpected value' END);
GO
