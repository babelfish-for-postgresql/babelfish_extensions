exec sp_updatestats;
go

exec sp_updatestats 'no';
go

exec sp_updatestats 'resample';
go

exec sp_updatestats @resample='resample';
go

exec sp_updatestats resample;
go

exec sp_updatestats @resample;
go

exec sp_updatestats @resample='sdlfkjsdf';
go

exec sp_updatestats 'resdflskjf';
go

exec sp_updatestats @random_option='resample';
go
