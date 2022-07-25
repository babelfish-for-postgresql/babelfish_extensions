CREATE INDEX [bbl_1319_IX_Tag_Item_id] ON [bbl_1319_Tag] ([Item_id])
GO

INSERT INTO [bbl_1319_Item] ([Name])
VALUES ('ItemOne')
GO

DELETE FROM [bbl_1319_Item] WHERE [Name] = 'ItemOne'
GO
