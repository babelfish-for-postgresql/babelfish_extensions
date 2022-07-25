CREATE TABLE [bbl_1319_Item] (
    [_id] int NOT NULL IDENTITY,
    [Name] nvarchar(max) NULL,
    CONSTRAINT [PK_Item] PRIMARY KEY ([_id])
)
GO

CREATE TABLE [bbl_1319_Tag] (  [_id] int NOT NULL IDENTITY,
    [Label] nvarchar(max) NULL,
    [Count] int NOT NULL,
    [Item_id] int NOT NULL,
    CONSTRAINT [PK_Tag] PRIMARY KEY ([_id]),
    CONSTRAINT [FK_Tag_Item_Item_id] FOREIGN KEY ([Item_id]) REFERENCES [bbl_1319_Item] ([_id]) ON DELETE CASCADE
)
GO


