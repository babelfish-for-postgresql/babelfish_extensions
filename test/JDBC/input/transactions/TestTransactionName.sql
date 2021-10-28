-- Tests for transaction name in babel

CREATE TABLE TestTxnName(C1 INT);
GO

-- Transaction name longer than 32 chars no allowed
BEGIN TRANSACTION longname11111111111111111111111111111111111111;
GO

-- Transaction name longer than 32 truncated
DECLARE @txnName varchar(100) = 'a1111111111111111111111111111111truncatethis';
BEGIN TRAN @txnName;
ROLLBACK TRAN a1111111111111111111111111111111
GO

SELECT @@trancount;
GO

-- Transaction/savepoint names are case sensitive
DECLARE @txnName varchar(100) = 'Abc';
DECLARE @spName varchar(100) = 'aBc';

BEGIN TRAN abc;
INSERT INTO TestTxnName VALUES(1);
SAVE TRAN @spName;
INSERT INTO TestTxnName VALUES(2);
SAVE TRAN abC;
INSERT INTO TestTxnName VALUES(3);
SAVE TRAN ABc;
INSERT INTO TestTxnName VALUES(4);
SAVE TRAN AbC;
INSERT INTO TestTxnName VALUES(5);
SAVE TRAN [aBC];
INSERT INTO TestTxnName VALUES(6);
BEGIN TRAN @txnName;
GO

SELECT C1 FROM TestTxnName ORDER BY C1;
GO

ROLLBACK TRAN [AbC];
SELECT C1 FROM TestTxnName ORDER BY C1;
GO

ROLLBACK TRAN ABc;
SELECT C1 FROM TestTxnName ORDER BY C1;
GO

ROLLBACK TRAN aBc;
SELECT C1 FROM TestTxnName ORDER BY C1;
GO

DECLARE @txnName varchar(100) = 'abc';
ROLLBACK TRAN @txnName;
SELECT C1 FROM TestTxnName ORDER BY C1;
GO

SELECT @@trancount;
GO

DECLARE @txnName varchar(100) = 'abc';
BEGIN TRAN @txnName;
COMMIT TRAN @txnName;
GO

SELECT @@trancount;
GO

DROP TABLE TestTxnName;
GO
