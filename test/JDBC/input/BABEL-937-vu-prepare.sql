create view babel_937_vu_v1 as
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','$.name','James');
go
