CREATE TABLE Purchasing (
  OrderID int,
  EmployeeID int,
  VendorID int
);
GO

CREATE TABLE insertTest(VendorID INT)
GO


INSERT INTO Purchasing(OrderID, EmployeeID, VendorID) VALUES (1, 52, 158);
INSERT INTO Purchasing(OrderID, EmployeeID, VendorID) VALUES (2, 44, 146);
INSERT INTO Purchasing(OrderID, EmployeeID, VendorID) VALUES (3, 25, 142);
INSERT INTO Purchasing(OrderID, EmployeeID, VendorID) VALUES (4, 66, 460);
INSERT INTO Purchasing(OrderID, EmployeeID, VendorID) VALUES (5, 37, 154);
INSERT INTO Purchasing(OrderID, EmployeeID, VendorID) VALUES (6, 53, 564);
INSERT INTO Purchasing(OrderID, EmployeeID, VendorID) VALUES (7, 36, 156);
GO