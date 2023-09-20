-- dummy test to check if schema is being rewritten
IF (EXISTS (select * from information_schema.test))
BEGIN
    SELECT 1
END;
GO

WHILE (select avg(a) from information_schema.test group by b) < 300
BEGIN
    SELECT 1
END;
GO

SELECT 
CASE 
	WHEN (EXISTS (SELECT * FROM INFORMATION_SCHEMA.test)) THEN 'TRUE'
	ELSE 'FALSE'
END
GO

-- regular test cases
CREATE TABLE [dbo].[My_Table_4320](
    [My_ID] [varchar](3) NOT NULL,
    [My_Column] [varchar](250) NOT NULL
)
go

IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'My_Table_4320'))
BEGIN
    SELECT 'TABLE EXISTS - THIS IS CORRECT'
END
ELSE
BEGIN
    SELECT 'TABLE NOT EXISTS - THIS IS WRONG, BECAUSE IT DOES EXIST'
END
GO

WHILE (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'My_Table_4320'))
BEGIN
    SELECT 'TABLE EXISTS - THIS IS CORRECT';
    break;
END
GO

IF (NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'My_Table_4320'))
BEGIN
    SELECT 'TABLE NOT EXISTS - THIS IS WRONG, BECAUSE IT DOES EXIST'
END
ELSE
BEGIN
    SELECT 'TABLE EXISTS - THIS IS CORRECT'
END
GO

SELECT 
CASE 
	WHEN (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'My_Table_43201')) THEN 'TABLE EXISTS'
	ELSE 'TABLE DOES NOT EXIST'
END
GO

SELECT CASE
 WHEN (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'My_Table_4320') = 1 THEN 'TABLE EXISTS'
 ELSE 'TABEL DOES NOT EXIST'
END;
GO

-- table identifier truncation
CREATE TABLE ncHdbdnjcnkejnjkcnreunjaknsaowlmfkrngvurtkanajhruddhbcmiuqwpalkdmfhcnbxndwue (a int)
go

IF (NOT EXISTS(select * from ncHdbdnjcnkejnjkcnreunjaknsaowlmfkrngvurtkanajhruddhbcmiuqwpalkdmfhcnbxndwue))
BEGIN
    SELECT 'Expected result'
END
GO

-- table and column name truncation
CREATE TABLE jakldnhjcDhdeuqpdkancjdtueqjanckdalejnxutuwmxdjajcneiqmalnfenirlenlaplqirncsrju (ncHdbdnjcnkejnjkcnreunjaknsaowlmfkrngvurtkanajhruddhbcmiuqwpalkdmfhcnbxndwue int)
GO

IF (NOT EXISTS(select ncHdbdnjcnkejnjkcnreunjaknsaowlmfkrngvurtkanajhruddhbcmiuqwpalkdmfhcnbxndwue from jakldnhjcDhdeuqpdkancjdtueqjanckdalejnxutuwmxdjajcneiqmalnfenirlenlaplqirncsrju))
BEGIN
    SELECT 'Expected result'
END
GO

DROP TABLE jakldnhjcDhdeuqpdkancjdtueqjanckdalejnxutuwmxdjajcneiqmalnfenirlenlaplqirncsrju;
GO

DROP TABLE ncHdbdnjcnkejnjkcnreunjaknsaowlmfkrngvurtkanajhruddhbcmiuqwpalkdmfhcnbxndwue;
GO

DROP TABLE [dbo].[My_Table_4320];
GO