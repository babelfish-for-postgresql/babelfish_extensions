SELECT * FROM Purchasing;
GO

-- Verify DELETE TOP without parens
-- This should fail
DELETE TOP 2 FROM Purchasing;
GO

DELETE TOP (2) FROM Purchasing;
GO

SELECT * FROM Purchasing;
GO

-- Verify UPDATE TOP without parens
-- This should fail
UPDATE TOP 2 Purchasing SET VendorID = 0;
GO

UPDATE TOP (2) Purchasing SET VendorID = 0;
GO

SELECT * FROM Purchasing;
GO

SELECT * FROM insertTest
GO

-- Verify INSERT TOP without parens
-- This should fail

INSERT TOP 3 INTO insertTest(VendorID) SELECT VendorID FROM Purchasing
GO

INSERT TOP (3) INTO insertTest(VendorID) SELECT VendorID FROM Purchasing
GO

SELECT * FROM insertTest
GO

