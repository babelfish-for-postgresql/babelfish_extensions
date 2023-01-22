drop function test_sp_volatility_f1
go

drop function test_sp_volatility_schema1.test_sp_volatility_f1
go

drop schema test_sp_volatility_schema1
go

drop function [test_sp_volatility_schema1 with .dot and spaces].test_sp_volatility_f1
go

drop schema [test_sp_volatility_schema1 with .dot and spaces]
go

use test_sp_volatility_db1
go

drop function test_sp_volatility_schema2.test_sp_volatility_f1
go

drop function test_sp_volatility_f2
go

drop schema test_sp_volatility_schema2
go

drop function test_sp_volatility_function_very_long_with_length_greater_than_63_but_less_equal_than_128_random_text_aaaaaaaaaaaaaaaaaaaaaaaaaa;
go

drop function test_sp_volatility_schema_very_long_with_length_greater_than_63_but_less_equal_than_128_random_text_aaaaaaaaaaaaaaaaaaaaaaaaaaaa.test_sp_volatility_function_very_long_with_length_greater_than_63_but_less_equal_than_128_random_text_aaaaaaaaaaaaaaaaaaaaaaaaaa;
go

drop schema test_sp_volatility_schema_very_long_with_length_greater_than_63_but_less_equal_than_128_random_text_aaaaaaaaaaaaaaaaaaaaaaaaaaaa;
go

drop user test_sp_volatility_user
go

use master
go

drop database test_sp_volatility_db1
go

drop login test_sp_volatility_login
go

