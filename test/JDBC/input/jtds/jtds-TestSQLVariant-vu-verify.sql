
--[BABEL-582]Checking all base datatypes for sql_variant
--The following list of base datatypes cannot be stored by using sql_variant:
--[datetimeoffset(SQL server 2012), geography, geometry, hierarchyid, image, ntext, nvarchar(max),
--rowversion (timestamp), text, varchar(max), varbinary(max), User-defined types, xml]

Select * from testsqlvariant_sourceTable1;
go

Select * from testsqlvariant_sourceTable2;
go


Select * from testsqlvariant_sourceTable3;
go


Select * from testsqlvariant_sourceTable4;
go


Select * from testsqlvariant_sourceTable5;
go

Select * from testsqlvariant_sourceTable6;
go


Select * from testsqlvariant_sourceTable7;
go


SELECT * FROM testsqlvariant_money_dt;
go

Select * from testsqlvariant_sourceTable8;
go


Select * from testsqlvariant_sourceTable9;
go


Select * from testsqlvariant_sourceTable10;
go


Select * from testsqlvariant_sourceTable11;
go


Select * from testsqlvariant_sourceTable12;
go


Select * from testsqlvariant_sourceTable13;
go


Select * from testsqlvariant_sourceTable14;
go


Select * from testsqlvariant_sourceTable15;
go


Select * from testsqlvariant_sourceTable16;
go

Select * from testsqlvariant_sourceTable17;
go

Select * from testsqlvariant_sourceTable18;
go

Select * from testsqlvariant_sourceTable19;
go

Select * from testsqlvariant_sourceTable20;
go

Select * from testsqlvariant_sourceTable21;
go

Select * from testsqlvariant_sourceTable22;
go

Select * from testsqlvariant_vu_prepare_view1;
go

Select * from testsqlvariant_vu_prepare_view2;
go
