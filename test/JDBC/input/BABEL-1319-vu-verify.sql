CREATE INDEX [babel_1319_IX_Tag_Item_id] ON [babel_1319_vu_prepare_Tag] ([Item_id])
GO

INSERT INTO [babel_1319_vu_prepare_Item] ([Name])
VALUES ('ItemOne')
GO

DELETE FROM [babel_1319_vu_prepare_Item] WHERE [Name] = 'ItemOne'
GO
