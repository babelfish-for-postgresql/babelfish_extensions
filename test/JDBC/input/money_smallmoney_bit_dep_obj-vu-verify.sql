SELECT * FROM bitfloatpl_vu;
GO

SELECT * FROM bitfloatmi_vu;
GO

SELECT * FROM bitfloatmul_vu;
GO

SELECT * FROM bitfloatdiv_vu;
GO

SELECT * FROM floatbitpl_vu;
GO

SELECT * FROM floatbitmul_vu;
GO

SELECT * FROM floatbitmi_vu;
GO

SELECT * FROM floatbitdiv_vu;
GO

SELECT * FROM bitbigintpl_vu;
GO

SELECT * FROM bitbigintmi_vu;
GO

SELECT * FROM bitbigintmul_vu;
GO

SELECT * FROM bitbigintdiv_vu;
GO

SELECT * FROM bitfloatdivfail_vu;
GO

SELECT * FROM bitnumericpl_vu;
GO

SELECT * FROM bitnumericmi_vu;
GO

SELECT * FROM bitnumericmul_vu;
GO

SELECT * FROM bitnumericdiv_vu;
GO

SELECT * FROM bitbigintdivfail_vu;
GO

SELECT * FROM floatbitdivfail_vu;
GO

SELECT * FROM bitsmallmoneydiv_vu;
GO

SELECT * FROM bitsmallmoneymul_vu;
GO

SELECT * FROM smallmoneybitdivfail_vu;
GO

SELECT * FROM smallmoneybitdiv_vu;
GO

SELECT * FROM smallmoneybitmul_vu;
GO

SELECT * FROM bitsmallmoneydivfail_vu;
GO

SELECT * FROM bitsmallmoneypl_vu;
GO

SELECT * FROM bitsmallmoneymi_vu;
GO

SELECT * FROM smallmoneybitpl_vu;
GO

SELECT * FROM smallmoneybitmi_vu;
GO

SELECT * FROM floormaxmoney_vu;
GO

SELECT * FROM ceilingminmoney_vu;
GO

SELECT * FROM powersmallmoney_vu;
GO

SELECT * FROM powermoney_vu;
GO

SELECT * FROM powersmallmoneyfail_vu;
GO

SELECT * FROM powermoneyfail_vu;
GO

-- bit arithmetic is not supported
-- this fails
SELECT CAST(1 AS sys.BIT) + CAST(1 as sys.BIT) AS A, CAST(0 AS sys.BIT) / CAST(1 AS sys.BIT) AS B, CAST(1 AS sys.BIT) * CAST(0 as sys.BIT) AS C, CAST(0 AS sys.BIT) - CAST(0 as sys.BIT) AS D;
GO