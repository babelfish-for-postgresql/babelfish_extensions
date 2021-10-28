-- supported collation
SELECT COLLATIONPROPERTY('Traditional_Spanish_CS_AS', 'CodePage'), COLLATIONPROPERTY('Traditional_Spanish_CS_AS', 'ComparisonStyle'), COLLATIONPROPERTY('Traditional_Spanish_CS_AS', 'Version'), COLLATIONPROPERTY('Traditional_Spanish_CS_AS', 'LCID');
go

SELECT COLLATIONPROPERTY('Traditional_Spanish_CS_AS', 'INVALID');
go

SELECT COLLATIONPROPERTY('INVALID', 'LCID');
go
