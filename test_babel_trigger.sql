CREATE TABLE #babel_2177(id int)
go

-- will fail and print error when trying to create trigger on temp table 
CREATE TRIGGER trigger_babel_2177 ON #babel_2177
AFTER INSERT
AS
	INSERT into #babel_2177 VALUES (7)
go

drop table #babel_2177;
GO
