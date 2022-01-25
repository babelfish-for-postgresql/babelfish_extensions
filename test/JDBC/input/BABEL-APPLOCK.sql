-- Part #1: single-session tests

-- default params
BEGIN TRAN;
exec sp_getapplock @Resource = 'lock1', @LockMode = 'SHARED';
COMMIT;
GO

-- given params
exec sp_getapplock @Resource = 'lock1', @LockMode = 'EXCLUSIVE', @LockOwner = 'SESSION', @LockTimeout = 10, @DbPrincipal = 'dbo';
GO

exec sp_releaseapplock @Resource = 'lock1', @LockOwner = 'SESSION';
GO

-- null params not allowed
exec sp_getapplock @Resource = null, @LockMode = 'shared';
GO

exec sp_getapplock @Resource = 'lock1', @LockMode = null;
GO

-- parameters are case-insensitive except for the lock name

exec sp_getapplock @Resource = 'lock1', @LockMode = 'Shared', @LockOwner = 'session';
GO

exec sp_getapplock @Resource = 'LOCK1', @LockMode = 'Exclusive', @LockOwner = 'SESSION';
GO

exec sp_releaseapplock @Resource = 'lock1', @LockOwner = 'SESSION';
GO

exec sp_releaseapplock @Resource = 'LOCK1', @LockOwner = 'session';
GO

-- implicit unlocking, lock will be gone after commit
BEGIN TRAN;
exec sp_getapplock @Resource = 'lock1', @LockMode = 'SHARED', @LockOwner = 'TRANSACTION';
GO
COMMIT;
GO

-- explicit unlocking (trx & session)
BEGIN TRAN;
exec sp_getapplock @Resource = 'lock1', @LockMode = 'SHARED', @LockOwner = 'TRANSACTION';
GO
exec sp_releaseapplock @Resource = 'lock1';
GO
COMMIT;
GO

exec sp_getapplock @Resource = 'lock1', @LockMode = 'SHARED', @LockOwner = 'SESSION';
GO

exec sp_releaseapplock @Resource = 'lock1', @LockOwner = 'SESSION';
GO

-- aquire lock multiple times, and need to unlock same number of times too

exec sp_getapplock @Resource = 'lock1', @LockMode = 'SHARED', @LockOwner = 'SESSION';
GO

exec sp_getapplock @Resource = 'lock1', @LockMode = 'SHARED', @LockOwner = 'SESSION';
GO

exec sp_releaseapplock @Resource = 'lock1', @LockOwner = 'SESSION';
GO

exec sp_releaseapplock @Resource = 'lock1', @LockOwner = 'SESSION';
GO

-- APPLOCK_MODE tests
exec sp_getapplock @Resource = 'test1', @LockMode = 'shared', @LockOwner = 'session';
GO

select APPLOCK_MODE ('dbo', 'test1', 'session'); -- should show 'Shared'
go

exec sp_getapplock @Resource = 'test1', @LockMode = 'update', @LockOwner = 'session';
GO

select APPLOCK_MODE ('dbo', 'test1', 'session'); -- should show 'Update'
go

exec sp_releaseapplock @Resource = 'test1', @LockOwner = 'session';
GO

exec sp_releaseapplock @Resource = 'test1', @LockOwner = 'session';
GO

exec sp_getapplock @Resource = 'test1', @LockMode = 'update', @LockOwner = 'session';
GO

exec sp_getapplock @Resource = 'test1', @LockMode = 'IntentExclusive', @LockOwner = 'session';
GO

select APPLOCK_MODE ('dbo', 'test1', 'session'); -- should show 'UpdateIntentExclusive'
go

exec sp_releaseapplock @Resource = 'test1', @LockOwner = 'session';
GO

exec sp_releaseapplock @Resource = 'test1', @LockOwner = 'session';
GO

exec sp_getapplock @Resource = 'test1', @LockMode = 'exclusive', @LockOwner = 'session';
GO

select APPLOCK_MODE ('dbo', 'test1', 'session'); -- should show "Exclusive"
go

exec sp_releaseapplock @Resource = 'test1', @LockOwner = 'session';
GO

select APPLOCK_MODE ('dbo', 'test1', 'session'); -- should show "NoLock"
go

-- APPLOCK_TEST tests
SELECT APPLOCK_TEST('dbo', 'lock1', 'Exclusive', 'Session');
GO

SELECT APPLOCK_TEST('public', 'MyAppLock', 'Shared', 'Transaction') -- should throw error
GO

BEGIN TRAN
SELECT APPLOCK_TEST('dbo', 'lock1', 'Shared', 'Transaction');
COMMIT
GO

BEGIN TRAN
exec sp_getapplock @Resource = 'lock1', @LockMode = 'exclusive', @LockOwner = 'Transaction'
SELECT APPLOCK_TEST('dbo', 'lock1', 'Shared', 'Transaction');
COMMIT
GO

