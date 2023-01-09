DROP TABLE IF EXISTS sys_all_columns_vu_prepare_table
DROP TABLE IF EXISTS sys_all_columns_vu_prepare_t1
DROP TABLE IF EXISTS sys_all_columns_vu_prepare_t2
GO

CREATE TABLE sys_all_columns_vu_prepare_table (
	sac_int_col INT PRIMARY KEY,
	sac_text_col_not_null VARCHAR(50) NOT NULL,
	sac_date_col DATETIME
)
GO

CREATE TABLE sys_all_columns_vu_prepare_t1 (
	intcol int,
	char128col varchar(128),
	bitcol bit,
	datecol date,
	moneycol money,
	datetimecol datetime,
)
GO

CREATE TABLE sys_all_columns_vu_prepare_t2 (
	col_one INT PRIMARY KEY,
	col_two INT,
	col_three INT IDENTITY(1,1),
	col_computed AS col_one * col_two
)
GO
