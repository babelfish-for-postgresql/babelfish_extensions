-- Test strict mode where path does not exist
-- Expect error
exec openjson_3820_p1
go

-- Test lax mode where path does not exist
-- Expect empty result and no error
exec openjson_3820_p2
go

-- Test strict mode where path does not exist
-- Expect an error for no path
exec openjson_3820_p3
go

-- Test standard OPENJSON call
-- Expect result
exec openjson_3820_p4
go

-- Test strict mode where path does not exist
-- Expect error in strict mode
exec openjson_3820_p5
go

-- Test lax mode where path does not exist
-- Expect empty result because path does not exist
exec openjson_3820_p6
go

-- Test OPENJSON strict call where path exists
-- Expect json result
exec openjson_3820_p7
go

-- Test OPENJSON strict call where path exists, strict is mixed case, 
-- and no space between "strict" and the path. Expect json result
exec openjson_3820_p8
go

-- Test OPENJSON strict with incorrect path
-- Expect error
exec openjson_3820_p9
go

-- Test OPENJSON with incorrect path
-- Expect empty result
exec openjson_3820_p10
go

-- Test strict mode where path does not exist
-- Expect error in strict mode
exec openjson_3820_p11
go