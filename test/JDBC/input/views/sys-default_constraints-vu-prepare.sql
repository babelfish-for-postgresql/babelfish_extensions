DROP TABLE IF EXISTS sys_default_constraints_vu_prepare_t1
GO

CREATE TABLE sys_default_constraints_vu_prepare_t1 (column_a INT, column_b INT)
GO

ALTER TABLE sys_default_constraints_vu_prepare_t1 ADD CONSTRAINT DF_sdd_column_b DEFAULT 50 FOR column_b
GO

CREATE TABLE sys_default_definitions_vu_prepare
(
column_a varchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL DEFAULT ('12'),
column_b datetime NOT NULL DEFAULT getdate(),
column_c int NOT NULL DEFAULT 0,
column_d bit DEFAULT 1,
column_e int
)
GO

ALTER TABLE sys_default_definitions_vu_prepare ADD CONSTRAINT default_column_e_int DEFAULT 50 FOR column_e;
ALTER TABLE sys_default_definitions_vu_prepare ADD CONSTRAINT default_column_a_weird DEFAULT N'42' FOR column_a;
GO