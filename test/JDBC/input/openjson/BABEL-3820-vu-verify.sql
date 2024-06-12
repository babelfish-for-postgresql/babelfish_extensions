-- Expect error
exec openjson_3820_p1
go

-- Expect empty result and no error
exec openjson_3820_p2
go

-- Expect an error for no path
exec openjson_3820_p3
go

-- Expect result
exec openjson_3820_p4
go

-- Expect error in strict mode
exec openjson_3820_p5
go

-- Expect empty result because path does not exist
exec openjson_3820_p6
go

-- Expect proper json result
exec openjson_3820_p7
go

-- Expect proper json result
exec openjson_3820_p8
go

-- Expect error for incorrect path
exec openjson_3820_p9
go

-- Expect empty result for non existent path
exec openjson_3820_p10
go

-- Expect error in strict mode
exec openjson_3820_p11
go