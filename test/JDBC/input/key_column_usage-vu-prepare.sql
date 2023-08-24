CREATE DATABASE key_column_usage_vu_prepare_db;
GO

USE key_column_usage_vu_prepare_db;
GO

CREATE TABLE key_column_usage_vu_prepare_tbl1(
    arg1 INT NOT NULL,
    arg2 NVARCHAR(20) NOT NULL,
    CONSTRAINT arg3 PRIMARY KEY CLUSTERED (
        arg1 ASC,
        arg2 ASC
    ) WITH (
        PAD_INDEX = OFF,
        STATISTICS_NORECOMPUTE = OFF,
        IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON,
        OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF
    ) ON [PRIMARY]
) ON [PRIMARY];
GO

CREATE TABLE key_column_usage_vu_prepare_tbl2 (
    arg1 NVARCHAR(20) NOT NULL,
    arg2 NCHAR(50) NOT NULL,
    arg3 INT NOT NULL,
    CONSTRAINT arg4 PRIMARY KEY CLUSTERED (
        arg1 ASC
    ) WITH (
        PAD_INDEX = OFF,
        STATISTICS_NORECOMPUTE = OFF,
        IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON,
        ALLOW_PAGE_LOCKS = ON,
        OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF
    ) ON [PRIMARY]
) ON [PRIMARY];
GO
