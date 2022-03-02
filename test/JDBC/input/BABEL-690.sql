CREATE FUNCTION func50() Returns varchar As begin RETURN ('ababababababababababababababaabbababababa'); END
GO
SELECT func50()
GO

CREATE FUNCTION func51() Returns nvarchar As begin RETURN ('ababababababababababababababaabbababababa'); END
GO
SELECT func51()
GO

CREATE FUNCTION func52() Returns char As begin RETURN ('ababababababababababababababaabbababababa'); END
GO
SELECT func52()
GO

-- should return an error stating that 'The text data type is invalid for return values.'
CREATE FUNCTION func53() Returns text As begin RETURN ('ababababababababababababababaabbababababa'); END
GO

CREATE FUNCTION func54() Returns nchar As begin RETURN ('ababababababababababababababaabbababababa'); END
GO
SELECT func54()
GO

-- should return an error stating that 'The ntext data type is invalid for return values.'
CREATE FUNCTION func55() Returns ntext As begin RETURN ('ababababababababababababababaabbababababa'); END
GO

DROP FUNCTION func50
go
DROP FUNCTION func51
go
DROP FUNCTION func52
go
DROP FUNCTION IF EXISTS func53
go
DROP FUNCTION func54
go
DROP FUNCTION IF EXISTS func55
go
