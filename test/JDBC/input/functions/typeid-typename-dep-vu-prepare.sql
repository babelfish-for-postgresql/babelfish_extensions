CREATE TYPE typeid_typename_dep_vu_prepare_t1 FROM INT;
GO

CREATE SCHEMA typeid_typename_dep_vu_prepare_s1;
GO

CREATE TYPE typeid_typename_dep_vu_prepare_s1.typeid_typename_dep_vu_prepare_t1 FROM INT;
GO

CREATE VIEW typeid_typename_dep_vu_prepare_view1 AS
SELECT TYPE_NAME(TYPE_ID('typeid_typename_dep_vu_prepare_t1')) AS [1 Part Data Type Name], TYPE_NAME(TYPE_ID('typeid_typename_dep_vu_prepare_s1.typeid_typename_dep_vu_prepare_t1')) AS [2 Part Data Type Name];
GO

CREATE PROC typeid_typename_dep_vu_prepare_proc1 AS
SELECT TYPE_NAME(TYPE_ID('typeid_typename_dep_vu_prepare_t1')) AS [1 Part Data Type Name], TYPE_NAME(TYPE_ID('typeid_typename_dep_vu_prepare_s1.typeid_typename_dep_vu_prepare_t1')) AS [2 Part Data Type Name];
GO

CREATE VIEW typeid_typename_dep_vu_prepare_view2 AS
SELECT TYPE_NAME(TYPE_ID('datetime')) AS [TYPE_NAME];
GO

CREATE PROC typeid_typename_dep_vu_prepare_proc2 AS
SELECT TYPE_NAME(TYPE_ID('datetime')) AS [TYPE_NAME];
GO

CREATE LOGIN typeid_typename_dep_vu_prepare_log1 WITH PASSWORD = '12345678';
GO

CREATE USER typeid_typename_dep_vu_prepare_user1 FOR LOGIN typeid_typename_dep_vu_prepare_log1;
GO

