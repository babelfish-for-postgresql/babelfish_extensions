CREATE VIEW bitfloatpl_vu AS SELECT CAST(1 AS sys.BIT) + CAST(1234.03456 as float) AS result;
GO

CREATE VIEW bitfloatmi_vu AS SELECT CAST(1 AS sys.BIT) - CAST(1234.03456 as float) AS result;
GO

CREATE VIEW bitfloatmul_vu AS SELECT CAST(1 AS sys.BIT) * CAST(1234.03456 as float) AS result;
GO

CREATE VIEW bitfloatdiv_vu AS SELECT CAST(1 AS sys.BIT) / CAST(1234.03456 as float) AS result;
GO

CREATE VIEW bitfloatdivfail_vu AS SELECT CAST(1 AS sys.BIT) / CAST(0 as float) AS result;
GO

CREATE VIEW floatbitpl_vu AS SELECT CAST(1234.03456 as float) + CAST(1 AS sys.BIT) AS result;
GO

CREATE VIEW floatbitmi_vu AS SELECT CAST(1234.03456 as float) - CAST(1 AS sys.BIT) AS result;
GO

CREATE VIEW floatbitmul_vu AS SELECT CAST(1234.03456 as float) * CAST(1 AS sys.BIT) AS result;
GO

CREATE VIEW floatbitdiv_vu AS SELECT CAST(1234.03456 as float) / CAST(1 AS sys.BIT) AS result;
GO

CREATE VIEW floatbitdivfail_vu AS SELECT CAST(1234.03456 as float) / CAST(0 AS sys.BIT) AS result;
GO

CREATE VIEW bitbigintpl_vu AS SELECT CAST(1 AS sys.BIT) + CAST(1 as BIGINT) AS A, CAST(0 AS sys.BIT) + CAST(1 AS BIGINT) AS B, CAST(1 AS sys.BIT) + CAST(0 as BIGINT) AS C, CAST(0 AS sys.BIT) + CAST(0 as BIGINT) AS D;
GO

CREATE VIEW bitbigintmi_vu AS SELECT CAST(1 AS sys.BIT) - CAST(1 as BIGINT) AS A, CAST(0 AS sys.BIT) - CAST(1 as BIGINT) AS B, CAST(1 AS sys.BIT) - CAST(0 as BIGINT) AS C, CAST(0 AS sys.BIT) - CAST(0 as BIGINT) AS D;
GO

CREATE VIEW bitbigintmul_vu AS SELECT CAST(1 AS sys.BIT) * CAST(1 as BIGINT) AS A, CAST(0 AS sys.BIT) * CAST(1 AS BIGINT) AS B, CAST(1 AS sys.BIT) * CAST(0 as BIGINT) AS C, CAST(0 AS sys.BIT) * CAST(0 as BIGINT) AS D;
GO

CREATE VIEW bitbigintdiv_vu AS SELECT CAST(1 AS sys.BIT) / CAST(1 as BIGINT) AS A, CAST(0 AS sys.BIT) / CAST(1 AS BIGINT) AS B;
GO

CREATE VIEW bitbigintdivfail_vu AS SELECT CAST(1 AS sys.BIT) / CAST(0 as BIGINT) AS A;
GO

CREATE VIEW bitnumericpl_vu AS SELECT CAST(1 AS sys.BIT) + CAST(1234.03456 as numeric) AS result;
GO

CREATE VIEW bitnumericmi_vu AS SELECT CAST(1 AS sys.BIT) - CAST(1234.03456 as numeric) AS result;
GO

CREATE VIEW bitnumericmul_vu AS SELECT CAST(1 AS sys.BIT) * CAST(1234.03456 as numeric) AS result;
GO

CREATE VIEW bitnumericdiv_vu AS SELECT CAST(1 AS sys.BIT) / CAST(1234.03456 as numeric) AS result;
GO

CREATE VIEW bitsmallmoneymul_vu AS SELECT CAST(1 AS sys.BIT) * CAST(1234.0356 as sys.SMALLMONEY) AS A, CAST(0 AS sys.BIT) * CAST(1234.0356 as sys.SMALLMONEY) AS B;
GO

CREATE VIEW bitsmallmoneydiv_vu AS SELECT CAST(1 AS sys.BIT) / CAST(1234.0346 as sys.SMALLMONEY) AS A, CAST(0 AS sys.BIT) / CAST(1234.0346 as sys.SMALLMONEY) AS B;
GO

CREATE VIEW smallmoneybitmul_vu AS SELECT CAST(1234.0346 as sys.SMALLMONEY) * CAST(1 as sys.BIT) AS A, CAST(1234.0346 as sys.SMALLMONEY) * CAST(0 as sys.BIT) AS B;
GO

CREATE VIEW smallmoneybitdiv_vu AS SELECT CAST(1234.0456 as sys.SMALLMONEY) / CAST(1 as sys.BIT) AS result;
GO

CREATE VIEW bitsmallmoneydivfail_vu AS SELECT CAST(1 AS sys.BIT) / CAST(0 as sys.SMALLMONEY) AS A;
GO

CREATE VIEW smallmoneybitdivfail_vu AS SELECT CAST(123.456 as sys.SMALLMONEY) / CAST(0 as sys.BIT) AS result;
GO