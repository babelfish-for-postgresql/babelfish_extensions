-- Drop dependent objects first
DROP TRIGGER IF EXISTS charindex_tests.trg_validate_text;
DROP VIEW IF EXISTS charindex_tests.text_view;
DROP VIEW IF EXISTS charindex_tests.text_view1;
DROP FUNCTION IF EXISTS charindex_tests.find_text;
DROP VIEW IF EXISTS charindex_tests.find_binary;
DROP VIEW IF EXISTS charindex_tests.find_binary1;
DROP VIEW IF EXISTS charindex_tests.find_varbinary;
DROP VIEW IF EXISTS charindex_tests.find_varbinary1;

-- Drop all tables
DROP TABLE IF EXISTS charindex_tests.TestChar;
DROP TABLE IF EXISTS charindex_tests.TestNChar;
DROP TABLE IF EXISTS charindex_tests.TestFixedChar;
DROP TABLE IF EXISTS charindex_tests.TestFixedNChar;
DROP TABLE IF EXISTS charindex_tests.chinese_variants;
DROP TABLE IF EXISTS charindex_tests.japanese_variants;
DROP TABLE IF EXISTS charindex_tests.UnicodeTest;
DROP TABLE IF EXISTS charindex_tests.BinaryTypes;
DROP TABLE IF EXISTS charindex_tests.NullTests;
DROP TABLE IF EXISTS charindex_tests.ComplexBinary;
DROP TABLE IF EXISTS charindex_tests.SpecialBinary;
DROP TABLE IF EXISTS charindex_tests.text_base;
DROP TABLE IF EXISTS charindex_tests.binary_base;

-- Drop user-defined types
DROP TYPE IF EXISTS charindex_tests.varbinary_udt;
DROP TYPE IF EXISTS charindex_tests.binary_udt;

-- Drop the schema
DROP SCHEMA IF EXISTS charindex_tests;
GO