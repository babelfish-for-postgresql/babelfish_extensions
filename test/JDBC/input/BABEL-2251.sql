-- 21 format specifiers and  21 additional parameters
RAISERROR(N'test %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s', 1, 1, N'1',N'1',N'1',N'1',N'1',N'1',N'1',N'1',N'1',N'1',N'1',N'1',N'1',N'1',N'1',N'1',N'1',N'1',N'1',N'1',N'1');
GO

-- 21 format specifiers and 3 additional parameters
RAISERROR(N'test %d %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s', 1, 1, 100,N'1',N'1')
GO

-- 20 format specifiers and 20 additional parameters
RAISERROR(N'test %s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s', 1, 1, N'a', N'a', N'a', N'a',N'a', N'a', N'a', N'a', N'a', N'a', N'a', N'a', N'a', N'a', N'a', N'a', N'a', N'a', N'a', N'a')
GO

-- 20 format specifiers and no additional parameters
RAISERROR(N'test %s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s', 1, 1)
GO

-- 20 format specifiers and no additional parameters, but message contains escaped % (invalid message string)
RAISERROR(N'escaped %% with other additional parameters %s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s', 1, 1)
GO

-- message string does not contain any parameters
RAISERROR(N'message string does not contain any parameter', 1, 1)
GO

--invalid message string
RAISERROR(N'contains an invalid message%', 1, 1, N'123')
GO

--empty message string
RAISERROR(N'', 1, 1)
GO

--message string of length 1
RAISERROR(N'a', 1, 1)
GO

--BABEL-2251
RAISERROR('Hello 
%s %s %s %s %s %s %s %s %s %s %s %s %s %s %s 
%s %s %s %s %s %s %s %s %s %s %s %s %s %s %s 
', 16, 1)
GO