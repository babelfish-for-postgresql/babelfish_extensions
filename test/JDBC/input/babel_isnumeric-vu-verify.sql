SELECT * FROM babel_isnumeric_vu_prepare_t1
GO
-- Test bigint
SELECT ISNUMERIC(bigint_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test int
SELECT ISNUMERIC(int_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test smallint
SELECT ISNUMERIC(smallint_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test tinyint
SELECT ISNUMERIC(tinyint_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test bit
SELECT ISNUMERIC(bit_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test decimal
SELECT ISNUMERIC(decimal_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test numeric
SELECT ISNUMERIC(numeric_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test float
SELECT ISNUMERIC(float_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test real
SELECT ISNUMERIC(real_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test money
SELECT ISNUMERIC(money_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test smallmoney
SELECT ISNUMERIC(smallmoney_type)
FROM babel_isnumeric_vu_prepare_t1
GO

-- Test valid and invalid operators and literals
select isnumeric(1234567890)
GO
select isnumeric('28903')
GO
select isnumeric('+')
GO
select isnumeric('+ ')
GO
-- Blocked due to BABEL-2853
--select isnumeric($)
--GO
select isnumeric('$24,23.43')
GO
-- Blocked due to BABEL-2853
--select isnumeric(€)
--GO
select isnumeric('+ 1')
GO
select isnumeric('$+1.1234')
GO
select isnumeric('+$1.1234')
GO
select isnumeric(' $ + 1.1234')
GO
select isnumeric(' + $ 1.1234')
GO

select isnumeric('abcdefghijklmnop')
GO
select isnumeric('24.89.43')
GO
select isnumeric('€24,2.3.43')
GO
select isnumeric('+-')
GO
select isnumeric('23$')
GO
select isnumeric(null)
GO
select isnumeric(' ')
GO
select isnumeric('1 .1234')
GO
select isnumeric('+1 .1234')
GO
select isnumeric('$1 .1234')
GO