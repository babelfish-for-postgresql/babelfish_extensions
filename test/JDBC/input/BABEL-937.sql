select JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','$.name','Smith');
go

select JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','$.skills[0]','Azure');
go

select JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','strict $.name','Smith');
go

select JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','append lax $.skills','Azure');
go

select JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','append $.skills','Azure');
go
