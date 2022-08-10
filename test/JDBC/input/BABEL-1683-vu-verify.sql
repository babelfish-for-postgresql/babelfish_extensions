-- NVARCHAR(128)
INSERT INTO babel_1683_vu_prepare_table_nvarchar1 VALUES (1, NULL)
go

INSERT INTO babel_1683_vu_prepare_table_nvarchar1(a) VALUES (2)
go

SELECT * FROM babel_1683_vu_prepare_table_nvarchar1
go

-- SYSNAME not explicitly defined as NULL
INSERT INTO babel_1683_vu_prepare_table_sysname1 VALUES (1, NULL)
go

INSERT INTO babel_1683_vu_prepare_table_sysname1(a) VALUES (2)
go

SELECT * FROM babel_1683_vu_prepare_table_sysname1
go

-- SYSNAME explicitly defined as NULL
INSERT INTO babel_1683_vu_prepare_table_sysname2 VALUES (1, NULL)
go

INSERT INTO babel_1683_vu_prepare_table_sysname2(a) VALUES (2)
go

SELECT * FROM babel_1683_vu_prepare_table_sysname2
go

-- ALTER TABLE ADD <column> stmt
-- NVARCHAR(128)
ALTER TABLE babel_1683_vu_prepare_table_nvarchar2 ADD b NVARCHAR(128)
go

INSERT INTO babel_1683_vu_prepare_table_nvarchar2 VALUES (1, NULL)
go

INSERT INTO babel_1683_vu_prepare_table_nvarchar2(a) VALUES (2)
go

SELECT * FROM babel_1683_vu_prepare_table_nvarchar2
go

-- SYSNAME not explicitly defined as NULL
ALTER TABLE babel_1683_vu_prepare_table_sysname3 ADD b SYSNAME
go

INSERT INTO babel_1683_vu_prepare_table_sysname3 VALUES (1, NULL)
go

INSERT INTO babel_1683_vu_prepare_table_sysname3(a) VALUES (2)
go

SELECT * FROM babel_1683_vu_prepare_table_sysname3
go

-- SYSNAME explicitly defined as NULL
ALTER TABLE babel_1683_vu_prepare_table_sysname4 ADD b SYSNAME NULL
go

INSERT INTO babel_1683_vu_prepare_table_sysname4 VALUES (1, NULL)
go

INSERT INTO babel_1683_vu_prepare_table_sysname4(a) VALUES (2)
go

SELECT * FROM babel_1683_vu_prepare_table_sysname4
go

