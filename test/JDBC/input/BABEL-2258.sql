select 'foo' where 'bar ' = 'bar';
go

select 'foo' where 0xAE = 0xAE00;
go

select 'foo' where 101.5E5 = 1015E4;
go

select 'foo' where (select 'bar ') = (select 'bar');
go