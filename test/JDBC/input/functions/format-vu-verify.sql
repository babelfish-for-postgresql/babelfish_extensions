select FORMAT(d, 'd','en-us') from date_testing;
GO
select FORMAT(d, 'D','en-us') from date_testing;
GO
select FORMAT(d, 'f','en-us') from date_testing;
GO
select FORMAT(d, 'F','en-us') from date_testing;
GO
select FORMAT(d, 'g','en-us') from date_testing;
GO
select FORMAT(d, 'G','en-us') from date_testing;
GO
select FORMAT(dt, 'd','en-us') from datetime_testing;
GO
select FORMAT(dt, 'D','en-us') from datetime_testing;
GO
select FORMAT(dt, 'f','en-us') from datetime_testing;
GO
select FORMAT(dt2, 'd','en-us') from datetime2_testing;
GO
select FORMAT(dt2, 'D','en-us') from datetime2_testing;
GO
select FORMAT(dt2, 'f','en-us') from datetime2_testing;
GO
select FORMAT(dt2, 'F','en-us') from datetime2_testing;
GO
select FORMAT(dt2, 'g','en-us') from datetime2_testing;
GO
select FORMAT(dt2, 'G','en-us') from datetime2_testing;
GO
select FORMAT(sdt, 'd','en-us') from smalldatetime_testing;
GO
select FORMAT(sdt, 'D','en-us') from smalldatetime_testing;
GO
select FORMAT(sdt, 'f','en-us') from smalldatetime_testing;
GO
select FORMAT(sdt, 'F','en-us') from smalldatetime_testing;
GO
select FORMAT(ti, 'c','en-us') from time_testing;
GO
select FORMAT(ti, 'd','en-us') from time_testing;
GO
select FORMAT(ti, 'D','en-us') from time_testing;
GO
select FORMAT(ti, 'f','en-us') from time_testing;
GO

SELECT FORMAT(ti, 'C', 'en-us') from tinyint_testing;
GO
SELECT FORMAT(ti, 'C0', 'en-us') from tinyint_testing;
GO
SELECT FORMAT(si, 'C', 'aa-DJ') from smallint_testing;
GO
SELECT FORMAT(si, 'C6', 'en-us') from smallint_testing;
GO
SELECT FORMAT(it, 'C', 'en-us') from int_testing;
GO
SELECT FORMAT(it, 'C6', 'en-us') from int_testing;
GO
SELECT FORMAT(bi, 'C', 'en-us') from bigint_testing;
GO
SELECT FORMAT(bi, 'C6', 'en-us') from bigint_testing;
GO
SELECT FORMAT(dt, 'C', 'en-us') from decimal_testing;
GO
SELECT FORMAT(dt, 'C6', 'en-us') from decimal_testing;
GO
SELECT FORMAT(nt, 'C', 'en-us') from numeric_testing;
GO
SELECT FORMAT(nt, 'C6', 'en-us') from numeric_testing;
GO
SELECT FORMAT(rt, 'C', 'en-us') from real_testing;
GO
SELECT FORMAT(rt, 'C9', 'en-us') from real_testing;
GO
SELECT FORMAT(ft, 'C', 'en-us') from float_testing;
GO
SELECT FORMAT(ft, 'C9', 'en-us') from float_testing;
GO
SELECT FORMAT(sm, 'C', 'en-us') from smallmoney_testing;
GO
SELECT FORMAT(sm, 'C9', 'en-us') from smallmoney_testing;
GO
SELECT FORMAT(mt, 'C', 'en-us') from money_testing;
GO
SELECT FORMAT(mt, 'C9', 'en-us') from money_testing;
GO
SELECT FORMAT(rt, 'C', 'en-us') from real_testing2;
GO
SELECT FORMAT(rt, 'C9', 'en-us') from real_testing2;
GO
SELECT FORMAT(ft, 'C', 'en-us') from float_testing2;
GO
SELECT FORMAT(ft, 'C9', 'en-us') from float_testing2;
GO
