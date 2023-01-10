SELECT * FROM str_vu_prepare_v1
GO

-- test different number of input agruments, default lenghth = 10 and default decimal = 0
SELECT * FROM str_vu_prepare_v2
GO

-- only third argument could be null, otherwise return null
SELECT * FROM str_vu_prepare_v4
GO

-- test with all datatypes that could implicitly converted to numeric
SELECT * FROM str_vu_prepare_v5
GO

-- test with all datatypes that could implicitly converted to int
SELECT * FROM str_vu_prepare_v6
GO

-- returns null on negative second or third input argument
SELECT * FROM str_vu_prepare_v7
GO

-- returns null when length > 8000, due to row size limit
SELECT * FROM str_vu_prepare_v8
GO

-- throws error when float_exp input has precision > 38
SELECT * FROM str_vu_prepare_v9
GO

-- throws error when length input exceed input of int32
SELECT * FROM str_vu_prepare_v10
GO

-- throws error when decimal input exceed input of int32
SELECT * FROM str_vu_prepare_v11
GO

-- won't over flow
SELECT * FROM str_vu_prepare_v12
GO

-- integer length of input expression exceeds the specified length, returns ** for the specified length
-- negative sign is also count as one digit in integer part
SELECT * FROM str_vu_prepare_v13
GO

-- when input decimal greater than length - integer digits, go with length's constraint
SELECT * FROM str_vu_prepare_v14
GO

-- actual max precision 17, round to 17th digit and pad rest of significant digits with zeros
SELECT * FROM str_vu_prepare_v15
GO

-- max scale is 16, add num of preceding spaces when decimal is more than 16
SELECT * FROM str_vu_prepare_v16
GO

-- decimal point and negative sign count as one digit
SELECT * FROM str_vu_prepare_v17
GO

-- when there's one extra digit from carried over, go with the length and decimal constraint before rounding
SELECT * FROM str_vu_prepare_v18
GO

EXEC str_vu_prepare_p1
GO

-- test different number of input agruments, default lenghth = 10 and default decimal = 0
EXEC str_vu_prepare_p2
GO

-- null inputs
-- no input arguments, throw error
EXEC str_vu_prepare_p3
GO

-- only third argument could be null, otherwise return null
EXEC str_vu_prepare_p4
GO

-- test with all datatypes that could implicitly converted to numeric
EXEC str_vu_prepare_p5
GO

-- test with all datatypes that could implicitly converted to int
EXEC str_vu_prepare_p6
GO

-- returns null on negative second or third input argument
EXEC str_vu_prepare_p7
GO

-- returns null when length > 8000, due to row size limit
EXEC str_vu_prepare_p8
GO

-- throws error when float_exp input has precision > 38
EXEC str_vu_prepare_p9
GO

-- throws error when length input exceed input of int32
EXEC str_vu_prepare_p10
GO

-- throws error when decimal input exceed input of int32
EXEC str_vu_prepare_p11
GO

-- won't over flow
EXEC str_vu_prepare_p12
GO

-- integer length of input expression exceeds the specified length, returns ** for the specified length
-- negative sign is also count as one digit in integer part
EXEC str_vu_prepare_p13
GO

-- when input decimal greater than length - integer digits, go with length's constraint
EXEC str_vu_prepare_p14
GO

-- actual max precision 17, round to 17th digit and pad rest of significant digits with zeros
EXEC str_vu_prepare_p15
GO

-- max scale is 16, add num of preceding spaces when decimal is more than 16
EXEC str_vu_prepare_p16
GO

-- decimal point and negative sign count as one digit
EXEC str_vu_prepare_p17
GO

-- when there's one extra digit from carried over, go with the length and decimal constraint before rounding
EXEC str_vu_prepare_p18
GO
