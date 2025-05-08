create database pivot_test
GO

use pivot_test
GO

create table StoreReceipt (
	OrderID INT,
	ItemID INT,
	Price DECIMAL(6,2),
	EmployeeID INT,
	StoreID INT,
	ManufactureID INT,
	PurchaseDate DATE
);
GO


insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (1, 2006, 485.14, 252, 7, 1209, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (2, 2146, 681.23, 296, 9, 1234, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (3, 2074, 960.42, 251, 4, 1245, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (4, 2005, 830.57, 220, 9, 1203, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (5, 2050, 649.41, 203, 5, 1200, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (6, 2082, 695.76, 269, 2, 1200, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (7, 2145, 766.23, 256, 9, 1249, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (8, 2085, 146.58, 201, 8, 1240, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (9, 2127, 819.74, 288, 5, 1202, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (10, 2036, 803.59, 270, 9, 1208, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (11, 2138, 704.37, 223, 5, 1208, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (12, 2016, 949.56, 287, 5, 1250, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (13, 2114, 187.16, 222, 5, 1200, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (14, 2081, 545.96, 269, 3, 1217, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (15, 2084, 843.16, 247, 9, 1218, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (16, 2004, 152.79, 251, 1, 1240, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (17, 2100, 313.51, 232, 8, 1201, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (18, 2001, 34.63, 211, 10, 1232, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (19, 2072, 76.61, 247, 9, 1228, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (20, 2069, 878.9, 209, 7, 1227, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (21, 2074, 124.01, 200, 4, 1226, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (22, 2061, 429.58, 204, 3, 1212, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (23, 2027, 709.99, 300, 6, 1238, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (24, 2056, 267.88, 202, 2, 1226, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (25, 2031, 271.77, 248, 4, 1228, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (26, 2080, 397.51, 220, 10, 1200, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (27, 2006, 525.4, 207, 8, 1247, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (28, 2010, 343.29, 276, 7, 1229, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (29, 2044, 808.24, 227, 1, 1216, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (30, 2073, 451.15, 228, 3, 1231, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (31, 2074, 808.82, 296, 9, 1214, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (32, 2018, 985.56, 221, 9, 1219, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (33, 2120, 18.1, 227, 10, 1243, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (34, 2094, 532.7, 234, 1, 1238, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (35, 2018, 675.61, 212, 4, 1211, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (36, 2052, 286.88, 201, 1, 1205, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (37, 2079, 351.51, 264, 1, 1217, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (38, 2089, 834.46, 264, 3, 1200, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (39, 2111, 564.39, 288, 9, 1213, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (40, 2045, 332.85, 278, 8, 1214, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (41, 2139, 814.19, 288, 5, 1220, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (42, 2106, 645.39, 218, 4, 1207, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (43, 2082, 185.88, 230, 9, 1234, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (44, 2078, 235.07, 232, 6, 1250, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (45, 2077, 307.92, 297, 5, 1248, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (46, 2021, 606.12, 262, 1, 1203, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (47, 2028, 622.14, 296, 7, 1246, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (48, 2092, 2.41, 224, 10, 1225, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (49, 2142, 447.79, 260, 7, 1245, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (50, 2006, 970.28, 272, 8, 1202, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (51, 2078, 459.75, 274, 9, 1221, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (52, 2128, 376.82, 294, 8, 1215, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (53, 2059, 357.59, 219, 2, 1211, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (54, 2058, 535.53, 271, 8, 1246, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (55, 2127, 661.96, 227, 1, 1219, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (56, 2053, 885.07, 275, 7, 1233, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (57, 2094, 55.32, 238, 4, 1208, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (58, 2055, 420.27, 264, 2, 1238, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (59, 2117, 306.36, 222, 4, 1234, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (60, 2077, 504.6, 266, 4, 1200, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (61, 2120, 279.1, 292, 2, 1226, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (62, 2113, 904.88, 299, 1, 1241, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (63, 2051, 496.42, 249, 7, 1203, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (64, 2136, 508.71, 262, 3, 1236, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (65, 2144, 421.24, 286, 9, 1236, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (66, 2119, 236.49, 277, 5, 1241, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (67, 2030, 215.66, 216, 3, 1246, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (68, 2024, 243.15, 245, 9, 1243, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (69, 2073, 397.63, 255, 8, 1235, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (70, 2079, 163.06, 229, 4, 1201, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (71, 2070, 550.83, 289, 7, 1214, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (72, 2069, 676.38, 278, 7, 1225, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (73, 2135, 778.12, 211, 10, 1214, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (74, 2127, 563.12, 258, 9, 1223, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (75, 2010, 502.25, 214, 7, 1218, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (76, 2050, 171.66, 271, 3, 1239, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (77, 2112, 364.88, 249, 2, 1215, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (78, 2090, 821.38, 269, 1, 1239, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (79, 2079, 19.88, 228, 1, 1202, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (80, 2047, 730.79, 255, 8, 1239, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (81, 2080, 664.81, 283, 10, 1215, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (82, 2137, 340.03, 236, 4, 1214, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (83, 2092, 4.28, 203, 10, 1218, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (84, 2003, 100.14, 253, 7, 1224, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (85, 2001, 952.61, 247, 2, 1212, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (86, 2054, 773.2, 210, 8, 1224, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (87, 2037, 65.9, 291, 6, 1214, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (88, 2092, 904.74, 224, 6, 1204, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (89, 2036, 485.19, 214, 10, 1203, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (90, 2148, 946.4, 211, 2, 1236, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (91, 2045, 703.15, 232, 7, 1204, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (92, 2093, 711.61, 200, 4, 1229, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (93, 2084, 103.15, 267, 2, 1209, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (94, 2049, 202.91, 289, 1, 1245, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (95, 2038, 760.1, 243, 8, 1241, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (96, 2026, 759.33, 253, 2, 1212, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (97, 2105, 125.73, 226, 10, 1218, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (98, 2011, 176.87, 294, 10, 1213, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (99, 2120, 501.65, 204, 9, 1240, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (100, 2138, 490.44, 232, 7, 1243, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (101, 2014, 346.61, 265, 9, 1215, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (102, 2062, 176.8, 285, 5, 1235, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (103, 2112, 113.92, 224, 8, 1229, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (104, 2073, 160.8, 267, 2, 1210, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (105, 2082, 588.15, 225, 3, 1229, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (106, 2138, 571.21, 213, 1, 1242, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (107, 2092, 814.36, 213, 9, 1243, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (108, 2089, 221.8, 220, 5, 1203, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (109, 2040, 501.46, 248, 10, 1244, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (110, 2096, 974.47, 204, 6, 1221, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (111, 2078, 914.56, 208, 3, 1239, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (112, 2118, 287.53, 215, 10, 1221, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (113, 2106, 415.27, 249, 8, 1242, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (114, 2145, 283.31, 227, 6, 1231, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (115, 2148, 950.09, 243, 10, 1211, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (116, 2137, 132.57, 269, 3, 1227, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (117, 2082, 440.25, 267, 9, 1204, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (118, 2015, 749.85, 229, 8, 1232, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (119, 2021, 209.93, 229, 9, 1250, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (120, 2006, 540.63, 283, 8, 1242, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (121, 2030, 197.56, 278, 9, 1215, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (122, 2123, 153.87, 259, 5, 1239, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (123, 2079, 444.55, 259, 1, 1200, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (124, 2146, 437.87, 231, 10, 1247, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (125, 2094, 74.57, 241, 8, 1237, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (126, 2084, 660.65, 251, 3, 1237, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (127, 2085, 366.69, 209, 3, 1238, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (128, 2031, 560.65, 254, 1, 1233, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (129, 2064, 410.85, 217, 5, 1208, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (130, 2095, 241.41, 289, 10, 1243, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (131, 2106, 163.57, 235, 9, 1218, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (132, 2128, 764.88, 291, 3, 1237, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (133, 2014, 936.97, 201, 10, 1218, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (134, 2141, 351.46, 287, 1, 1202, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (135, 2094, 277.08, 218, 1, 1211, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (136, 2064, 489.19, 251, 2, 1226, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (137, 2001, 190.54, 231, 7, 1222, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (138, 2007, 252.7, 290, 8, 1242, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (139, 2058, 413.1, 214, 3, 1226, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (140, 2140, 230.58, 227, 8, 1206, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (141, 2074, 940.96, 200, 8, 1200, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (142, 2071, 618.94, 203, 9, 1250, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (143, 2002, 115.65, 213, 4, 1201, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (144, 2010, 22.85, 254, 3, 1218, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (145, 2023, 901.21, 230, 2, 1245, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (146, 2139, 173.7, 246, 8, 1202, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (147, 2047, 848.18, 225, 5, 1221, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (148, 2084, 254.96, 250, 10, 1244, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (149, 2004, 298.15, 296, 10, 1231, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (150, 2009, 413.91, 292, 9, 1245, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (151, 2009, 664.17, 277, 4, 1240, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (152, 2049, 748.86, 205, 6, 1250, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (153, 2064, 935.97, 253, 9, 1218, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (154, 2129, 577.5, 290, 9, 1237, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (155, 2052, 496.99, 211, 2, 1215, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (156, 2144, 753.54, 270, 6, 1229, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (157, 2143, 644.8, 267, 7, 1201, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (158, 2131, 710.66, 292, 8, 1217, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (159, 2051, 336.83, 229, 9, 1229, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (160, 2031, 592.09, 248, 4, 1206, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (161, 2046, 129.18, 279, 10, 1207, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (162, 2101, 536.8, 282, 7, 1204, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (163, 2112, 960.31, 296, 2, 1240, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (164, 2100, 127.35, 235, 8, 1236, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (165, 2031, 352.12, 203, 9, 1208, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (166, 2035, 110.15, 243, 10, 1229, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (167, 2105, 531.13, 234, 7, 1220, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (168, 2046, 483.93, 279, 8, 1238, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (169, 2083, 669.86, 226, 2, 1243, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (170, 2040, 373.61, 208, 10, 1223, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (171, 2060, 355.5, 220, 10, 1200, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (172, 2120, 28.3, 284, 9, 1247, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (173, 2040, 357.99, 250, 6, 1212, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (174, 2103, 980.82, 288, 2, 1202, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (175, 2035, 813.47, 217, 1, 1235, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (176, 2110, 399.64, 285, 9, 1220, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (177, 2016, 44.06, 250, 6, 1207, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (178, 2096, 66.57, 292, 4, 1214, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (179, 2030, 33.38, 239, 10, 1215, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (180, 2073, 459.77, 240, 8, 1218, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (181, 2071, 875.42, 230, 3, 1217, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (182, 2041, 380.94, 255, 3, 1247, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (183, 2097, 914.44, 298, 3, 1210, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (184, 2105, 329.25, 210, 1, 1242, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (185, 2000, 457.91, 256, 2, 1231, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (186, 2098, 901.2, 261, 10, 1249, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (187, 2146, 236.33, 293, 10, 1223, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (188, 2117, 405.01, 279, 8, 1246, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (189, 2099, 272.14, 234, 6, 1205, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (190, 2145, 42.04, 299, 8, 1204, '2023-10-26');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (191, 2017, 399.9, 280, 4, 1242, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (192, 2058, 733.45, 277, 9, 1239, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (193, 2124, 809.67, 259, 3, 1246, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (194, 2059, 167.54, 221, 10, 1233, '2023-10-30');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (195, 2032, 441.79, 219, 6, 1238, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (196, 2101, 720.37, 286, 1, 1246, '2023-10-27');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (197, 2103, 820.5, 289, 6, 1206, '2023-10-28');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (198, 2010, 433.08, 276, 9, 1213, '2023-10-29');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (199, 2147, 779.36, 237, 2, 1245, '2023-10-25');
insert into StoreReceipt (OrderID, ItemID, Price, EmployeeID, StoreID, ManufactureID, PurchaseDate) values (200, 2084, 735.91, 223, 5, 1221, '2023-10-30');
GO

CREATE TABLE orders (
    orderId INT PRIMARY KEY,
    productId INT,
    employeeName VARCHAR(4),
    employeeCode VARBINARY(30),
    date DATE);
GO

CREATE TABLE products (
    productId int PRIMARY KEY,
    productName VARCHAR(30),
    productPrice INT
)

INSERT INTO products VALUES
    (1, 'mac', 250000),
    (2, 'iphone', 80000),
    (3, 'airpods', 20000),
    (4, 'charger', 2900),
    (5, 'ipad', 50000)
GO

INSERT INTO orders VALUES
    (101, 5,'empA', 0x656D7041, '2024-05-01'),
    (102, 3,'empA', 0x656D7041, '2024-05-01'),
    (103, 1,'empA', 0x656D7041, '2024-05-01'),
    (104, 2,'empA', 0x656D7041, '2024-05-01'),
    (105, 1,'empB', 0x656D7042, '2024-05-01'),
    (106, 2,'empB', 0x656D7042, '2024-05-01'),
    (110, 3,'empB', 0x656D7042, '2024-05-01'),
    (109, 4,'empB', 0x656D7042, '2024-05-01'),
    (108, 5,'empB', 0x656D7042, '2024-05-01'),
    (107, 5,'empB', 0x656D7042, '2024-05-01'),
    (111, 1,'empC', 0x656D7043, '2024-05-01'),
    (113, 1,'empC', 0x656D7043, '2024-05-01'),
    (115, 1,'empC', 0x656D7043, '2024-05-01'),
    (119, 1,'empC', 0x656D7043, '2024-05-01'),
    (201, 2,'empC', 0x656D7043, '2024-05-01'),
    (223, 2,'empC', 0x656D7043, '2024-05-01'),
    (224, 5,'empD', 0x656D7044, '2024-05-01'),
    (202, 3,'empD', 0x656D7044, '2024-05-01'),
    (190, 1,'empD', 0x656D7044, '2024-05-01');
GO

create schema pivot_schema;
GO

CREATE TABLE pivot_schema.products_sch (
    productId int PRIMARY KEY,
    productName VARCHAR(30),
    productPrice INT
)
GO

INSERT INTO pivot_schema.products_sch VALUES
    (1, 'mac', 250000),
    (2, 'iphone', 80000),
    (3, 'airpods', 20000),
    (4, 'charger', 2900),
    (5, 'ipad', 50000)
GO

create table pivot_insert_into(ManufactureID int, EmployeeID int, p1 int, p2 int, p3 int, p4 int, p5 int);
GO

CREATE PROCEDURE top_n_pivot
    (
    @Number int = 5
    )
AS
BEGIN
    SELECT TOP(@Number) ManufactureID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
    FROM
    (
        SELECT ManufactureID, ItemID, StoreID
        FROM StoreReceipt
    )as srctable
    PIVOT (
        COUNT (ItemID)
        FOR StoreID in ([2], [3], [4], [5], [6])
    ) AS pvt2
    ORDER BY 1
END;
GO

CREATE FUNCTION test_table_valued_function(@Number int)
RETURNS TABLE
AS
RETURN
    SELECT TOP(@Number) ManufactureID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
    FROM
    (
        SELECT ManufactureID, ItemID, StoreID
        FROM StoreReceipt
    )as srctable
    PIVOT (
        COUNT (ItemID)
        FOR StoreID in ([2], [3], [4], [5], [6])
    ) AS pvt2
    ORDER BY 1
GO

CREATE VIEW StoreReceipt_view
AS
SELECT * FROM StoreReceipt;
GO

-- BABEL-4558 
CREATE TABLE OSTable(
    [Oid] [int] NOT NULL,
    [Sid] [int] NOT NULL
)
GO


CREATE TABLE STable(
    [Id] [int] IDENTITY(1,1) NOT NULL,
    [Scode] [varchar](10) NOT NULL,
    [Type] [smallint] NOT NULL
)
GO

insert into OSTable (Oid, Sid) values (1, 2);
insert into OSTable (Oid, Sid) values (2, 8);
insert into OSTable (Oid, Sid) values (3, 5);
insert into OSTable (Oid, Sid) values (4, 11);
insert into OSTable (Oid, Sid) values (5, 12);
insert into OSTable (Oid, Sid) values (6, 8);
insert into OSTable (Oid, Sid) values (7, 5);
insert into OSTable (Oid, Sid) values (8, 2);
insert into OSTable (Oid, Sid) values (9, 15);
insert into OSTable (Oid, Sid) values (10, 1);
GO

insert into STable (Scode, Type) values ('vestibulum', 11);
insert into STable (Scode, Type) values ('eget', 15);
insert into STable (Scode, Type) values ('pharetra', 13);
insert into STable (Scode, Type) values ('nam', 15);
insert into STable (Scode, Type) values ('fermentum', 13);
insert into STable (Scode, Type) values ('hac', 12);
insert into STable (Scode, Type) values ('molestie', 10);
insert into STable (Scode, Type) values ('justo', 11);
insert into STable (Scode, Type) values ('lobortis', 7);
insert into STable (Scode, Type) values ('at', 3);
insert into STable (Scode, Type) values ('augue', 9);
insert into STable (Scode, Type) values ('luctus', 2);
insert into STable (Scode, Type) values ('nisi', 9);
insert into STable (Scode, Type) values ('sociis', 1);
insert into STable (Scode, Type) values ('ultrices', 14);
GO

-- table for aggregate with string value
CREATE TABLE seating_tbl (
    seatings VARCHAR(20) NOT NULL,
    left_right VARCHAR(20) NOT NULL
);
GO

INSERT INTO seating_tbl (seatings, left_right)
VALUES ('SEAT1', 'LEFT'),
       ('SEAT1', 'RIGHT'),
       ('SEAT2', 'LEFT'),
       ('SEAT3', 'LEFT'),
       ('SEAT3', 'RIGHT');
GO

create table trigger_testing(col nvarchar(60))
GO

create trigger pivot_trigger on trigger_testing after insert
as
begin
  SELECT 'OrderNumbers' AS OrderCountbyStore, [1] AS STORE1, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5
    FROM
    (
        SELECT StoreID, OrderID
        FROM StoreReceipt
    )AS SrcTable
    PIVOT (
        COUNT (OrderID)
        FOR StoreID IN ([1], [2], [3],[4], [5])
    ) AS pvt
end
GO