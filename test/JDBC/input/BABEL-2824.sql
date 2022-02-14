USE master
GO

CREATE TABLE [dbo].[smtableint](
    [c_id] [int] NOT NULL,
    [c_d_id] [tinyint] NOT NULL,
    [c_w_id] [int] NOT NULL,
	[name1] [nvarchar(20)],
	[name2] [nvarchar(25)]
) ON [PRIMARY]
GO

INSERT INTO [dbo].[smtableint] VALUES (1, 2, 3, 'a1', 'a2'), (4, 5, 6, 'a11', 'a22'), (7, 8, 9, 'a111', 'a222')
GO

EXEC sp_describe_undeclared_parameters N'INSERT INTO [dbo].[smtableint]([c_id],[c_d_id],[c_w_id],[name1],[name2]) values (@PaRaM1,@PaRaM2,@PaRaM3,@PaRaM4,@PaRaM5)'
GO

-- Test long input string
CREATE TABLE t_numerics_dt(
    c_bigintXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  BIGINT  NOT NULL
    , c_decimal_1_0 DECIMAL(1,0)    NOT NULL
    , c_decimal_1_1 DECIMAL(1,1)    NOT NULL
    , c_decimal_12_3    DECIMAL(12,3)   NOT NULL
    , c_decimal_38_0    DECIMAL(38,0)   NOT NULL
    , c_decimal_38_5    DECIMAL(38,5)   NOT NULL
    , c_float   FLOAT   NOT NULL
    , c_float_8 FLOAT(8)    NOT NULL
    , c_float_24    FLOAT(24)   NOT NULL
    , c_float_25    FLOAT(25)   NOT NULL
    , c_float_48    FLOAT(48)   NOT NULL
    , c_int INT NOT NULL
    , c_money   MONEY   NOT NULL
    , c_numeric_1_0 NUMERIC(1,0)    NOT NULL
    , c_numeric_1_1 NUMERIC(1,1)    NOT NULL
    , c_numeric_12_3    NUMERIC(12,3)   NOT NULL
    , c_numeric_38_0    NUMERIC(38,0)   NOT NULL
    , c_numeric_38_5    NUMERIC(38,5)   NOT NULL
    , c_real    INT NOT NULL
)
go

EXEC sp_describe_undeclared_parameters N'INSERT INTO t_numerics_dt(
    c_bigintXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ,c_decimal_1_0 ,c_decimal_1_1 ,c_decimal_12_3 ,c_decimal_38_0 ,c_decimal_38_5 ,c_float ,c_float_8 ,c_float_24 ,c_float_25 ,c_float_48 ,c_int ,c_money ,c_numeric_1_0 ,c_numeric_1_1 ,c_numeric_12_3 ,c_numeric_38_0 ,c_numeric_38_5 ,c_real ) VALUES ( @p1 ,@p2 ,@p3 ,@p4 ,@p5 ,@p6 ,@p7 ,@p8 ,@p9 ,@p10 ,@p11 ,@p12 ,@p13 ,@p14 ,@p15 ,@p16 ,@p17 ,@p18 ,@p19 )'
go

-- cleanup
DROP TABLE [dbo].[smtableint]
GO
DROP TABLE t_numerics_dt
GO
