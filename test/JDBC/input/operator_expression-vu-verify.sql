-- bigint : Int 8(int64) : -9223372036854775808 to 9223372036854775807
-- int : int 4(int32) : -2147483648 to 2147483647
-- smallint : int 2(int16) : -32768 to 32767
-- tinyint : int 1(int8) : 0 to 255
-- money: -922337203685477.5808 to 922337203685477.5807
-- Smallmoney: -214748.3648 to 214748.3647

-- Testing declare
DECLARE @revenue MONEY = 10000.00; DECLARE @costs MONEY = 6000.00; DECLARE @targetMargin money = 0.40;
select (@revenue - @costs) * 1.13
go