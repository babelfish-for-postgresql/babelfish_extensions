-- enable FULLTEXT
-- tsql user=jdbc_user password=12345678
SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'ignore', 'false')
GO

-- sys.babelfish_fts_rewrite()
CREATE VIEW fts_rewrite_prepare_v1 AS (SELECT sys.babelfish_fts_rewrite('"one two three"'));
GO

CREATE PROCEDURE fts_rewrite_prepare_p1 AS (SELECT sys.babelfish_fts_rewrite('one'));
GO

CREATE FUNCTION fts_rewrite_prepare_f1()
RETURNS sys.SYSNAME AS
        BEGIN
                RETURN (SELECT sys.babelfish_fts_rewrite('"one : two"'))
        END
GO

-- sys.replace_special_chars_fts()
CREATE VIEW replace_special_chars_fts_prepare_v1 AS (SELECT sys.replace_special_chars_fts('"one`two"'));
GO

CREATE PROCEDURE replace_special_chars_fts_prepare_p1 AS (SELECT sys.replace_special_chars_fts(':one'));
GO

CREATE FUNCTION replace_special_chars_fts_prepare_f1()
RETURNS sys.SYSNAME AS
        BEGIN
                RETURN (SELECT sys.replace_special_chars_fts('"one : two"'))
        END
GO

-- Create table
CREATE TABLE fts_table
(
        id INT NOT NULL PRIMARY KEY IDENTITY(1,1),
        text_column TEXT,
        char_column CHAR(50),
        nvarchar_column NVARCHAR(150),
        varchar_column VARCHAR(100),
        ntext_column NTEXT,
        nchar_column NCHAR(75)
)
GO

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 1: database 📊 multilingual 索引 extended text for full-text search testing', N'CHAR1:📊datab', N'索引 query 📊 | ID:1', N'VARCHAR1: database 📊 multilingual 索引', N'NTEXT Row 1: database 📊 multilingual 索引 詳細情報 detailed database query information with 情報 and 索引', N'NCHAR1:📊test1');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 2: 処理 Japanese index 🌍 extended text for full-text search testing', N'CHAR2:服务器', N'処理 Japanese index 🌍 | ID:2', N'VARCHAR2: database index search', N'NTEXT Row 2: 処理 Japanese index 🌍 詳細情報 detailed index server information with 処理 and 服务器', N'NCHAR2:服务器2');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 3: 表格 Chinese column testing 🚀 ☀☁☂ extended text for full-text search testing', N'CHAR3:☀☁☂', N'Search search column | ID:3', N'VARCHAR3: search column query', N'NTEXT Row 3: 表格 Chinese column testing 🚀 ☀☁☂ 詳細情報 detailed search column information with インデックス and 表格', N'NCHAR3:searc3');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 4: Query data 情報 search 🖥️ extended text for full-text search testing', N'CHAR4:情報', N'情報 服务器 testing | ID:4', N'VARCHAR4: Query data 情報 search 🖥️', N'NTEXT Row 4: Query data 情報 search 🖥️ 詳細情報 detailed system data information with 情報 and 服务器', N'NCHAR4:多言語4');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 5: search 🎯 multilingual 搜索 extended text for full-text search testing', N'CHAR5:🎯searc', N'search 管理 | ID:5', N'VARCHAR5: database search search', N'NTEXT Row 5: search 🎯 multilingual 搜索 詳細情報 detailed search index information with 管理 and 搜索', N'NCHAR5:♪♫♬5');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 6: data database index query 📊 ←→↑↓ extended text for full-text search testing', N'CHAR6:系统', N'系统 index 📊 | ID:6', N'VARCHAR6: data index query', N'NTEXT Row 6: data database index query 📊 ←→↑↓ 詳細情報 detailed data index information with 管理 and 系统', N'NCHAR6:管理6');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 7: 测试 Chinese server testing 🎯 extended text for full-text search testing', N'CHAR7:✓✔✗', N'测试 Chinese server testing 🎯 | ID:7', N'VARCHAR7: 测试 Chinese server testing 🎯', N'NTEXT Row 7: 测试 Chinese server testing 🎯 詳細情報 detailed table server information with 検索 and 测试', N'NCHAR7:🎯test7');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 8: Query testing 検索 search 🚀 extended text for full-text search testing', N'CHAR8:検索', N'Search search testing | ID:8', N'VARCHAR8: database search search', N'NTEXT Row 8: Query testing 検索 search 🚀 詳細情報 detailed search testing information with 検索 and 表格', N'NCHAR8:表格8');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 9: English database with search and 💾 ∑∏∫ extended text for full-text search testing', N'CHAR9:💾datab', N'処理 系统 testing | ID:9', N'VARCHAR9: database search query', N'NTEXT Row 9: English database with search and 💾 ∑∏∫ 詳細情報 detailed database search information with 処理 and 系统', N'NCHAR9:datab9');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 10: Mixed table テスト 服务器 📊 extended text for full-text search testing', N'CHAR10:服务器', N'table テスト | ID:10', N'VARCHAR10: Mixed table テスト 服务器 📊', N'NTEXT Row 10: Mixed table テスト 服务器 📊 詳細情報 detailed table data information with テスト and 服务器', N'NCHAR10:多言語10');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 11: Search server with テスト 🔍 extended text for full-text search testing', N'CHAR11:±×÷', N'表格 data 🔍 | ID:11', N'VARCHAR11: database server search', N'NTEXT Row 11: Search server with テスト 🔍 詳細情報 detailed server data information with テスト and 表格', N'NCHAR11:±×÷11');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 12: English search with server and 🔍 ♪♫♬ extended text for full-text search testing', N'CHAR12:サーバ', N'English search with server and 🔍 ♪♫♬ | ID:12', N'VARCHAR12: search server query', N'NTEXT Row 12: English search with server and 🔍 ♪♫♬ 詳細情報 detailed search server information with サーバー and 信息', N'NCHAR12:サーバー12');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 13: Search column with インデックス 📊 extended text for full-text search testing', N'CHAR13:📊colum', N'Search column database | ID:13', N'VARCHAR13: Search column with インデックス 📊', N'NTEXT Row 13: Search column with インデックス 📊 詳細情報 detailed column database information with インデックス and 查询', N'NCHAR13:📊test13');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 14: system 🎨 multilingual 信息 extended text for full-text search testing', N'CHAR14:信息', N'サーバー 信息 testing | ID:14', N'VARCHAR14: database system search', N'NTEXT Row 14: system 🎨 multilingual 信息 詳細情報 detailed system table information with サーバー and 信息', N'NCHAR14:信息14');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 15: Search server with システム 💾 αβγδ extended text for full-text search testing', N'CHAR15:αβγδ', N'server システム | ID:15', N'VARCHAR15: server table query', N'NTEXT Row 15: Search server with システム 💾 αβγδ 詳細情報 detailed server table information with システム and 搜索', N'NCHAR15:serve15');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 16: Mixed search インデックス 系统 🔍 extended text for full-text search testing', N'CHAR16:インデ', N'系统 index 🔍 | ID:16', N'VARCHAR16: Mixed search インデックス 系统 🔍', N'NTEXT Row 16: Mixed search インデックス 系统 🔍 詳細情報 detailed search index information with インデックス and 系统', N'NCHAR16:多言語16');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 17: Search index with システム ⭐ extended text for full-text search testing', N'CHAR17:⭐index', N'Search index with システム ⭐ | ID:17', N'VARCHAR17: database index search', N'NTEXT Row 17: Search index with システム ⭐ 詳細情報 detailed index system information with システム and 表格', N'NCHAR17:♪♫♬17');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 18: database database search query 💾 αβγδ extended text for full-text search testing', N'CHAR18:索引', N'Search database search | ID:18', N'VARCHAR18: database search query', N'NTEXT Row 18: database database search query 💾 αβγδ 詳細情報 detailed database search information with テーブル and 索引', N'NCHAR18:テーブル18');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 19: 测试 system table 📈 extended text for full-text search testing', N'CHAR19:±×÷', N'インデックス 测试 testing | ID:19', N'VARCHAR19: 测试 system table 📈', N'NTEXT Row 19: 测试 system table 📈 詳細情報 detailed server table information with インデックス and 测试', N'NCHAR19:📈test19');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 20: Testing data table インデックス 🎨 extended text for full-text search testing', N'CHAR20:インデ', N'data インデックス | ID:20', N'VARCHAR20: database data search', N'NTEXT Row 20: Testing data table インデックス 🎨 詳細情報 detailed data table information with インデックス and 数据库', N'NCHAR20:数据库20');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 21: Query testing 処理 search 🔍 αβγδ extended text for full-text search testing', N'CHAR21:🔍index', N'索引 testing 🔍 | ID:21', N'VARCHAR21: index testing query', N'NTEXT Row 21: Query testing 処理 search 🔍 αβγδ 詳細情報 detailed index testing information with 処理 and 索引', N'NCHAR21:index21');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 22: 表格 system column 📈 extended text for full-text search testing', N'CHAR22:表格', N'表格 system column 📈 | ID:22', N'VARCHAR22: 表格 system column 📈', N'NTEXT Row 22: 表格 system column 📈 詳細情報 detailed search column information with テーブル and 表格', N'NCHAR22:多言語22');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 23: database database table query 🔍 extended text for full-text search testing', N'CHAR23:±×÷', N'Search database table | ID:23', N'VARCHAR23: database database search', N'NTEXT Row 23: database database table query 🔍 詳細情報 detailed database table information with システム and 查询', N'NCHAR23:±×÷23');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 24: Testing column server 情報 📊 ±×÷ extended text for full-text search testing', N'CHAR24:情報', N'情報 查询 testing | ID:24', N'VARCHAR24: column server query', N'NTEXT Row 24: Testing column server 情報 📊 ±×÷ 詳細情報 detailed column server information with 情報 and 查询', N'NCHAR24:情報24');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 25: Search data with データベース 🖥️ extended text for full-text search testing', N'CHAR25:🖥️data', N'data データベース | ID:25', N'VARCHAR25: Search data with データベース 🖥️', N'NTEXT Row 25: Search data with データベース 🖥️ 詳細情報 detailed data search information with データベース and 服务器', N'NCHAR25:🖥️test25');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 26: 索引 Chinese column testing 🎨 extended text for full-text search testing', N'CHAR26:索引', N'索引 column 🎨 | ID:26', N'VARCHAR26: database column search', N'NTEXT Row 26: 索引 Chinese column testing 🎨 詳細情報 detailed column column information with テスト and 索引', N'NCHAR26:索引26');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 27: Query system 情報 search 📊 ©®™ extended text for full-text search testing', N'CHAR27:©®™', N'Query system 情報 search 📊 ©®™ | ID:27', N'VARCHAR27: search system query', N'NTEXT Row 27: Query system 情報 search 📊 ©®™ 詳細情報 detailed search system information with 情報 and 管理', N'NCHAR27:searc27');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 28: 系统 system table ⭐ extended text for full-text search testing', N'CHAR28:処理', N'Search testing table | ID:28', N'VARCHAR28: 系统 system table ⭐', N'NTEXT Row 28: 系统 system table ⭐ 詳細情報 detailed testing table information with 処理 and 系统', N'NCHAR28:多言語28');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 29: Query testing データベース search 📈 extended text for full-text search testing', N'CHAR29:📈data', N'データベース 搜索 testing | ID:29', N'VARCHAR29: database data search', N'NTEXT Row 29: Query testing データベース search 📈 詳細情報 detailed data testing information with データベース and 搜索', N'NCHAR29:♠♣♥29');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 30: Query table サーバー search 🖥️ ←→↑↓ extended text for full-text search testing', N'CHAR30:索引', N'table サーバー | ID:30', N'VARCHAR30: table table query', N'NTEXT Row 30: Query table サーバー search 🖥️ ←→↑↓ 詳細情報 detailed table table information with サーバー and 索引', N'NCHAR30:サーバー30');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 31: Mixed search テーブル 信息 💾 extended text for full-text search testing', N'CHAR31:©®™', N'信息 column 💾 | ID:31', N'VARCHAR31: Mixed search テーブル 信息 💾', N'NTEXT Row 31: Mixed search テーブル 信息 💾 詳細情報 detailed search column information with テーブル and 信息', N'NCHAR31:💾test31');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 32: Testing index testing テスト 🌍 extended text for full-text search testing', N'CHAR32:テスト', N'Testing index testing テスト 🌍 | ID:32', N'VARCHAR32: database index search', N'NTEXT Row 32: Testing index testing テスト 🌍 詳細情報 detailed index testing information with テスト and 表格', N'NCHAR32:表格32');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 33: 信息 system table 🌍 ♪♫♬ extended text for full-text search testing', N'CHAR33:🌍serve', N'Search server table | ID:33', N'VARCHAR33: server table query', N'NTEXT Row 33: 信息 system table 🌍 ♪♫♬ 詳細情報 detailed server table information with 検索 and 信息', N'NCHAR33:serve33');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 34: index database data query 🎨 extended text for full-text search testing', N'CHAR34:管理', N'サーバー 管理 testing | ID:34', N'VARCHAR34: index database data query 🎨', N'NTEXT Row 34: index database data query 🎨 詳細情報 detailed index data information with サーバー and 管理', N'NCHAR34:多言語34');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 35: 系统 Chinese database testing ⭐ extended text for full-text search testing', N'CHAR35:∑∏∫', N'database 検索 | ID:35', N'VARCHAR35: database database search', N'NTEXT Row 35: 系统 Chinese database testing ⭐ 詳細情報 detailed database database information with 検索 and 系统', N'NCHAR35:∑∏∫35');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 36: データベース Japanese column 🔍 ✓✔✗ extended text for full-text search testing', N'CHAR36:データ', N'测试 data 🔍 | ID:36', N'VARCHAR36: column data query', N'NTEXT Row 36: データベース Japanese column 🔍 ✓✔✗ 詳細情報 detailed column data information with データベース and 测试', N'NCHAR36:データベース36');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 37: server 🖥️ multilingual 服务器 extended text for full-text search testing', N'CHAR37:🖥️serve', N'server 🖥️ multilingual 服务器 | ID:37', N'VARCHAR37: server 🖥️ multilingual 服务器', N'NTEXT Row 37: server 🖥️ multilingual 服务器 詳細情報 detailed server index information with サーバー and 服务器', N'NCHAR37:🖥️test37');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 38: Mixed search 情報 搜索 ⭐ extended text for full-text search testing', N'CHAR38:搜索', N'Search search system | ID:38', N'VARCHAR38: database search search', N'NTEXT Row 38: Mixed search 情報 搜索 ⭐ 詳細情報 detailed search system information with 情報 and 搜索', N'NCHAR38:搜索38');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 39: Query database システム search 🔍 ✓✔✗ extended text for full-text search testing', N'CHAR39:✓✔✗', N'システム 信息 testing | ID:39', N'VARCHAR39: query database query', N'NTEXT Row 39: Query database システム search 🔍 ✓✔✗ 詳細情報 detailed query database information with システム and 信息', N'NCHAR39:query39');

INSERT INTO fts_table (text_column, char_column, nvarchar_column, varchar_column, ntext_column, nchar_column)
VALUES (N'Row 40: English column with system and 🌍 extended text for full-text search testing', N'CHAR40:処理', N'column 処理 | ID:40', N'VARCHAR40: English column with system and 🌍', N'NTEXT Row 40: English column with system and 🌍 詳細情報 detailed column system information with 処理 and 查询', N'NCHAR40:多言語40');
GO

-- Test cases for fts_table
CREATE UNIQUE INDEX ucid ON fts_table(id)
GO

CREATE FULLTEXT INDEX ON fts_table(
        text_column,
        char_column,
        varchar_column,
        nvarchar_column,
        ntext_column,
        nchar_column) KEY INDEX ucid
GO

-- disable FULLTEXT
SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'strict', 'false')
GO