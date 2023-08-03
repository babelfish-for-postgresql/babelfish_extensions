SELECT CAST(123456.25 AS real) AS value_as_real, CAST(CAST(123456.25 AS real) AS decimal(30,2)) AS value_casted_to_decimal_30_2;
GO

select cast(cast(123457.145637867 as real) as numeric (30, 20));
GO

select cast((cast(123456.00 as real)) as numeric(30,2));
GO

INSERT INTO babel_3066_vu_prepare_t1 VALUES (122.34562), (735412.97354), (-467822.56378), (-456.24516), (1234.465), ('inf'), ('-inf'), ('nan');
GO
INSERT INTO babel_3066_vu_prepare_t1 VALUES (123456789123456789123456789123456789.123456789);
GO

SELECT CAST(col1 as numeric(30,2)) as value_casted_to_decimal_30_2 from babel_3066_vu_prepare_t1;
GO
SELECT CAST(col1 as numeric(30,20)) as value_casted_to_decimal_30_20 from babel_3066_vu_prepare_t1;
GO
SELECT CAST(col1 as numeric(30,4)) as value_casted_to_decimal_30_4 from babel_3066_vu_prepare_t1;
GO
SELECT CAST(col1 as numeric(38,38)) as value_casted_to_decimal_38_38 from babel_3066_vu_prepare_t1;
GO

INSERT INTO babel_3066_vu_prepare_t2 values (CAST(1234.156 as real)), (CAST(-3256.55 as real)), (CAST(1234.6513 as real)), (CAST(1324567.45267781 as real)), (CAST(12.2 as real)), (CAST(122.34562 as real)), (CAST(735412.97354 as real));
GO

INSERT INTO babel_3066_vu_prepare_t2 values (123456789123456789123456789123456789.123456789);
GO

SELECT col1 from babel_3066_vu_prepare_t2;
GO

select CAST(CAST(col1 AS real) AS decimal(30,2)) from babel_3066_vu_prepare_t2;
GO

SELECT babel_3066_vu_prepare_t1.col1, babel_3066_vu_prepare_t2.col1 
FROM babel_3066_vu_prepare_t1 JOIN babel_3066_vu_prepare_t2
ON cast (babel_3066_vu_prepare_t1.col1 as real) = CAST(CAST(babel_3066_vu_prepare_t2.col1 AS real) AS decimal(30,2));
GO

