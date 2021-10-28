create table t_babel_1331 (a int, b int);
insert into t_babel_1331 values (1, 1), (2, 2), (3, 3), (4, 4), (5, 5);
go

declare cur cursor for select * from t_babel_1331
open cur
fetch cur
fetch next from cur
fetch prior from cur
fetch last from cur
fetch first from cur
fetch absolute 2 from cur
fetch relative 2 from cur
close cur
deallocate cur
go
