CREATE TABLE [babel_1319_vu_prepare_Item] (
    [_id] int NOT NULL IDENTITY,
    [Name] nvarchar(max) NULL,
    CONSTRAINT [PK_Item] PRIMARY KEY ([_id])
)
GO

CREATE TABLE [babel_1319_vu_prepare_Tag] (  [_id] int NOT NULL IDENTITY,
    [Label] nvarchar(max) NULL,
    [Count] int NOT NULL,
    [Item_id] int NOT NULL,
    CONSTRAINT [PK_Tag] PRIMARY KEY ([_id]),
    CONSTRAINT [FK_Tag_Item_Item_id] FOREIGN KEY ([Item_id]) REFERENCES [babel_1319_vu_prepare_Item] ([_id]) ON DELETE CASCADE
)
GO

CREATE INDEX [babel_1319_IX_Tag_Item_id] ON [babel_1319_vu_prepare_Tag] ([Item_id])
GO

INSERT INTO [babel_1319_vu_prepare_Item] ([Name])
VALUES ('ItemOne')
GO

