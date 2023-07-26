-- enable CONTAINS
SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'ignore', 'false')
GO

-- Test sys.babelfish_fts_contains_rewrite
SELECT * FROM fts_contains_rewrite_v1
GO

-- Test sys.babelfish_fts_contains_pgconfig
SELECT * FROM fts_contains_pgconfig_v1
GO

-- Full syntax of CONTAINS: https://github.com/MicrosoftDocs/sql-docs/blob/live/docs/t-sql/queries/contains-transact-sql.md

-- test basic CONTAINS use: ... CONTAINS(col_name, <simple_term>) ...
-- <simple_term> ::= { word | "phrase" }
EXEC fts_contains_vu_prepare_p1 'love'
GO

EXEC fts_contains_vu_prepare_p1 'other'
GO

EXEC fts_contains_vu_prepare_p1 'arts'
GO

EXEC fts_contains_vu_prepare_p1 'performing'
GO

EXEC fts_contains_vu_prepare_p1 'performance'
GO

EXEC fts_contains_vu_prepare_p1 'quick'
GO

EXEC fts_contains_vu_prepare_p1 'grow'
GO

EXEC fts_contains_vu_prepare_p1 'actually'
GO

EXEC fts_contains_vu_prepare_p1 'helped'
GO

EXEC fts_contains_vu_prepare_p1 'version'
GO

EXEC fts_contains_vu_prepare_p1 '"come back"'
GO

EXEC fts_contains_vu_prepare_p1 '"much of the"'
GO

EXEC fts_contains_vu_prepare_p1 '"due to"'
GO

EXEC fts_contains_vu_prepare_p1 '"per cent"'
GO

EXEC fts_contains_vu_prepare_p1 '"so-called"'
GO


EXEC fts_contains_vu_prepare_p1 '"stand up"'
GO

EXEC fts_contains_vu_prepare_p1 '"every month"'
GO

EXEC fts_contains_vu_prepare_p1 '"as a result"'
GO

EXEC fts_contains_vu_prepare_p1 '"in Australia"'
GO

EXEC fts_contains_vu_prepare_p1 '"daily news"'
GO

-- REST NOT SUPPORTED YET

-- test prefix term: ... CONTAINS(col_name, <prefix_term>) ...
-- <prefix term> ::= { "word*" | "phrase*" } 
EXEC fts_contains_vu_prepare_p1 '"conf*"', 20
GO

EXEC fts_contains_vu_prepare_p1 '"pass*"'
GO

EXEC fts_contains_vu_prepare_p1 '"daily n*"'
GO

EXEC fts_contains_vu_prepare_p1 '"t*"', 20
GO

EXEC fts_contains_vu_prepare_p1 '"independent *"'
GO

-- test inflectional generation term: ... CONTAINS(col_name, <inflectional_generation_term>) ...
-- <inflectional_generation_term> ::= FORMSOF ( INFLECTIONAL, <simple_term> [ ,...n ] )
EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, love)'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, arts)'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, performing)'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, quick)'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, helped)'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, "come back")'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, "stand up")'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, "move forward")'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, play, move)'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, play, "plan to")'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, "play with", "plan to")'
GO


-- test thesaurus generation term: ... CONTAINS(col_name, <thesaurus_generation_term>) ...
-- <thesaurus_generation_term> ::= FORMSOF ( THESAURUS, <simple_term> [ ,...n ] )
EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, love)'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, arts)'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, performing)'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, quick)'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, helped)'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, "come back")'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, "stand up")'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, "move forward")'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, play, move)'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, play, "plan to")'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, "play with", "plan to")'
GO

-- boolean operators
-- test boolean operator (<NOT>, <AND NOT>, <OR>) of <contains_search_condition>
-- <AND> ::= { AND | & }  
-- <AND NOT> ::= { AND NOT | &! }  
-- <OR> ::= { OR | | } 
-- For now only support <simple_term>, <prefix_term>, <generation_term>
-- test bools of combinations of different kinds of terms

-- <simple_term> <bool> <simple_term>
EXEC fts_contains_vu_prepare_p1 'try AND not'
GO

EXEC fts_contains_vu_prepare_p1 'try & not'
GO

EXEC fts_contains_vu_prepare_p1 'red AND NOT blue'
GO

EXEC fts_contains_vu_prepare_p1 'try &! not'
GO

EXEC fts_contains_vu_prepare_p1 'red OR blue'
GO

EXEC fts_contains_vu_prepare_p1 'plan | move'
GO

-- <simple_term> <bool> <prefix_term>
EXEC fts_contains_vu_prepare_p1 'try AND "n*"'
GO

EXEC fts_contains_vu_prepare_p1 'try & "n*"'
GO

EXEC fts_contains_vu_prepare_p1 'red AND NOT "b*"'
GO

EXEC fts_contains_vu_prepare_p1 'try &! "n*"'
GO

EXEC fts_contains_vu_prepare_p1 'red OR "bl*"'
GO

EXEC fts_contains_vu_prepare_p1 'plan | "mon*"'
GO

-- <prefix_term> <bool> <simple_term>
EXEC fts_contains_vu_prepare_p1 '"n*" AND try'
GO

EXEC fts_contains_vu_prepare_p1 '"n*" & try'
GO

EXEC fts_contains_vu_prepare_p1 '"red*" AND NOT blue'
GO

EXEC fts_contains_vu_prepare_p1 '"try*" &! not'
GO

EXEC fts_contains_vu_prepare_p1 '"bl*" OR red'
GO

EXEC fts_contains_vu_prepare_p1 '"mon*" | plan'
GO

-- <prefix_term> <bool> <prefix_term>
EXEC fts_contains_vu_prepare_p1 '"n*" AND "red*"'
GO

EXEC fts_contains_vu_prepare_p1 '"red*" & "n*"'
GO

EXEC fts_contains_vu_prepare_p1 '"red*" AND NOT "b*"'
GO

EXEC fts_contains_vu_prepare_p1 '"bl*" &! "r*"'
GO

EXEC fts_contains_vu_prepare_p1 '"bla*" OR "red*"'
GO

EXEC fts_contains_vu_prepare_p1 '"red*" | "bla*"'
GO

-- <simple_term> <bool> <generation_term>
EXEC fts_contains_vu_prepare_p1 'name AND FORMSOF(INFLECTIONAL, need)'
GO

EXEC fts_contains_vu_prepare_p1 'name & FORMSOF(INFLECTIONAL, need)'
GO

EXEC fts_contains_vu_prepare_p1 'name AND NOT FORMSOF(INFLECTIONAL, need)'
GO

EXEC fts_contains_vu_prepare_p1 'name &! FORMSOF(INFLECTIONAL, need)'
GO

EXEC fts_contains_vu_prepare_p1 'plan OR FORMSOF(INFLECTIONAL, move)'
GO

EXEC fts_contains_vu_prepare_p1 'plan | FORMSOF(INFLECTIONAL, move)'
GO

EXEC fts_contains_vu_prepare_p1 'name AND FORMSOF(THESAURUS, need)'
GO

EXEC fts_contains_vu_prepare_p1 'name & FORMSOF(THESAURUS, need)'
GO

EXEC fts_contains_vu_prepare_p1 'name AND NOT FORMSOF(THESAURUS, need)'
GO

EXEC fts_contains_vu_prepare_p1 'name &! FORMSOF(THESAURUS, need)'
GO

EXEC fts_contains_vu_prepare_p1 'plan OR FORMSOF(THESAURUS, move)'
GO

EXEC fts_contains_vu_prepare_p1 'plan | FORMSOF(THESAURUS, move)'
GO


-- <generation_term> <bool> <simple_term>
EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, need) AND name'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, need) & name'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, need) AND NOT name'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, need) &! name'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, move) OR plan'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, move) | plan'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, need) AND name'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, need) & name'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, need) AND NOT name'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, need) &! name'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, move) OR plan'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, move) | plan'
GO


-- <prefix_term> <bool> <generation_term>
EXEC fts_contains_vu_prepare_p1 '"nam*" AND FORMSOF(INFLECTIONAL, need)'
GO

EXEC fts_contains_vu_prepare_p1 '"nam*" & FORMSOF(INFLECTIONAL, need)'
GO

EXEC fts_contains_vu_prepare_p1 '"nam*" AND NOT FORMSOF(INFLECTIONAL, need)'
GO

EXEC fts_contains_vu_prepare_p1 '"nam*" &! FORMSOF(INFLECTIONAL, need)'
GO

EXEC fts_contains_vu_prepare_p1 '"nam*" OR FORMSOF(INFLECTIONAL, move)'
GO

EXEC fts_contains_vu_prepare_p1 '"pla*" | FORMSOF(INFLECTIONAL, move)'
GO

EXEC fts_contains_vu_prepare_p1 '"nam*" AND FORMSOF(THESAURUS, need)'
GO

EXEC fts_contains_vu_prepare_p1 '"nam*" & FORMSOF(THESAURUS, need)'
GO

EXEC fts_contains_vu_prepare_p1 '"nam*" AND NOT FORMSOF(THESAURUS, need)'
GO

EXEC fts_contains_vu_prepare_p1 '"nam*" &! FORMSOF(THESAURUS, need)'
GO

EXEC fts_contains_vu_prepare_p1 '"pla*" OR FORMSOF(THESAURUS, move)'
GO

EXEC fts_contains_vu_prepare_p1 '"pla*" | FORMSOF(THESAURUS, move)'
GO


-- <generation_term> <bool> <prefix_term>
EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, need) AND "nam*"'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, need) & "nam*"'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, need) AND NOT "nam*"'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, need) &! "nam*"'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, move) OR "pla*"'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, move) | "pla*"'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, need) AND "nam*"'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, need) & "nam*"'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, need) AND NOT "nam*"'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, need) &! "nam*"'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, move) OR "pla*"'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, move) | "pla*"'
GO


-- <generation_term> <bool> <generation_term>
EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, need) AND FORMSOF(THESAURUS, name)'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAUSUS, need) & FORMSOF(INFLECTIONAL, name)'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, need) AND NOT FORMSOF(THESAURUS, name)'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, need) &! FORMSOF(INFLECTIONAL, name)'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(INFLECTIONAL, move) OR FORMSOF(THESAURUS, move)'
GO

EXEC fts_contains_vu_prepare_p1 'FORMSOF(THESAURUS, move) | FORMSOF(INFLECTIONAL, plan)'
GO

-- disable CONTAINS
SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'strict', 'false')
GO
