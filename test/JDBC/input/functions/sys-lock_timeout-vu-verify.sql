
-- Check default value for lock_timeout guc
SELECT @@lock_timeout;
GO

-- SET lock_timeout to 2 seconds (2000 ms)
SET lock_timeout 2000;
GO
SELECT @@lock_timeout;
GO

-- SET guc to max value (INT_MAX)
SET lock_timeout 2147483647;
GO
SELECT @@lock_timeout;
GO

-- SET guc to value greater than INT_MAX
SET lock_timeout 2147483648; -- Shoud throw error
GO

-- SET guc to min value (INT_MIN)
SET lock_timeout -2147483648;
GO
SELECT @@lock_timeout;
GO

-- SET guc to value less than INT_MIN
SET lock_timeout -2147483649; -- Shoud throw error
GO

-- SET guc to 0
SET lock_timeout 0;
GO
SELECT @@lock_timeout;
GO

-- RESET guc to -1
SET lock_timeout -1;
GO
SELECT @@lock_timeout;
GO
