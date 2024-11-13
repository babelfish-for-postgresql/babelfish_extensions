CREATE TABLE TestHash(
nvarchar_data nvarchar(32) NOT NULL,
varchar_data varchar(32) NOT NULL,
cast_hashbytes_nvarchar_data  AS (cast ( hashbytes('sha1', nvarchar_data) AS varbinary(20) )) PERSISTED NOT NULL,
convert_hashbytes_nvarchar_data AS (convert( varbinary(20),  hashbytes('sha1',nvarchar_data))) PERSISTED NOT NULL,
cast_hashbytes_varchar_data  AS (cast ( hashbytes('sha1', varchar_data) AS varbinary(20) )) PERSISTED NOT NULL,
convert_hashbytes_varchar_data AS (convert( varbinary(20),  hashbytes('sha1',varchar_data))) PERSISTED NOT NULL
);
GO