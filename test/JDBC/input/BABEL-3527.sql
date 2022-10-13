-- Set escape_hatch_checkpoint to ignore
SELECT set_config('babelfishpg_tsql.escape_hatch_checkpoint', 'ignore', 'false')
GO

CHECKPOINT 5
GO

CHECKPOINT -5
GO

CHECKPOINT 100000000
GO

CHECKPOINT "Invalid Input"
GO

-- Set escape_hatch_checkpoint to strict
SELECT set_config('babelfishpg_tsql.escape_hatch_checkpoint', 'strict', 'false')
GO

CHECKPOINT 5
GO

CHECKPOINT 100000000
GO

CHECKPOINT -5
GO

CHECKPOINT "Invalid Input"
GO