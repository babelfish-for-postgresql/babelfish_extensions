#include "odbc_handler.h"
#include "database_objects.h"
#include "query_generator.h"

#include <filesystem>
#include <fstream>
#include <gtest/gtest.h>
#include <sqlext.h>

using std::vector;
using std::map;
using std::pair;

const string NULL_STR = "<NULL>";

class Data_Types : public testing::Test {

  protected:

  // Called before the first test in this test suite.
  static void SetUpTestSuite() {
  }

  // Called after the last test in this test suite
  static void TearDownTestSuite() {
  }
};

// Helper method that takes a string of values to be inserted and returns a string of those values with order of 
// column data appended. 
// SAMPLE INPUT: "("c"), ("b"), ("a")"
// SAMPLE OUTPUT: "("c", 1), ("b", 2), ("a", 3)"
string processInsertedValuesString(string insertedValues) {
  string processedString = "";
  int orderOfInsertion = 1;
  for (auto iterator = insertedValues.begin(); iterator < insertedValues.end(); iterator++) {
    string getStr(1, *iterator);
    if (getStr.compare(")") == 0) {
      processedString = processedString + ", " + std::to_string(orderOfInsertion);
      orderOfInsertion++;
    }
    processedString+=(*iterator);
  }
  return processedString;
}

// Checks if a file is empty
bool is_empty(std::ifstream& pFile)
{
    return pFile.peek() == std::ifstream::traits_type::eof();
}

// Helper function that reads from a file and returns the contents as a string
string readFromFile(string relativePath) {
  int bufferLen = 1024;
  char * buffer = new char [bufferLen];
  char * fname;

  std::ifstream dataFile(relativePath);
  if (is_empty(dataFile)) {
    return "";
  }

  std::filesystem::path fp{relativePath};
  int fsize = std::filesystem::file_size(fp);
  while (fsize > bufferLen){
    dataFile.read(buffer, bufferLen);
    fsize -= bufferLen;
  }
  dataFile.read(buffer, fsize);
  dataFile.close();
  return string(buffer);
}

// Helper function that iterates over & fetches data, and compares retrieved value to expected value 
void fetchAndCompare(OdbcHandler& odbcHandler, vector<vector<string>> expectedValues) {
  SQLLEN cb = SQL_NO_TOTAL;
  RETCODE rcode;

  int bufferLen = 1024;
  char buffer[1024];
  int totalNumRows = expectedValues[0].size();
  int totalNumCols = expectedValues.size();

  for (short row = 0; row < totalNumRows; row++) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
    for (short col = 0; col < totalNumCols; col++) {
      rcode = SQLGetData(odbcHandler.GetStatementHandle(), col+1, SQL_C_CHAR, buffer, bufferLen, &cb);
      ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

      if (expectedValues[col][row].compare(NULL_STR) == 0) {
        ASSERT_EQ(cb, SQL_NULL_DATA);
        break;
      }
      ASSERT_EQ(expectedValues[col][row], buffer);
    }
  }
}

// Common code for data types tests
void DataTypesTestCommon(const string &table_name, 
  vector<pair <string, string>> &table_columns,
  const string &inserted_values,
  const vector<vector<string>> &expected_values) {

  OdbcHandler odbcHandler;

  const string ORDER_BY_COLS = "OrderOfInsertion";
  table_columns.push_back({ORDER_BY_COLS, "INT"});

  DatabaseObjects dbObjects;
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(table_name, table_columns));

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));
  if (!inserted_values.empty()) {
    ASSERT_NO_FATAL_FAILURE(
      odbcHandler.ExecQuery(InsertStatement(table_name, processInsertedValuesString(inserted_values)))
    );
  }
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(SelectStatement(table_name, { "*" }, { ORDER_BY_COLS })));

  SQLSMALLINT sNumCols;
  SQLNumResultCols(odbcHandler.GetStatementHandle(), &sNumCols);
  ASSERT_EQ(sNumCols, table_columns.size());

  fetchAndCompare(odbcHandler, expected_values);
}

// Test retrieval of type BigInt
TEST_F(Data_Types, BigInt) {

  const string TEST_TABLE = "BIGINT_dt";
  vector<pair<string,string>> TABLE_COLUMNS = {
    {"a", "BIGINT"}
  };
  const string INSERTED_VALUES = 
  "(NULL), (-9223372036854775808), (-024112329), (-10), (-0000000000000000002), (0), (0000000000000000086), (0001202), (122100), "
  "(9223372036854775807)";

  const vector<vector<string>> EXPECTED_VALUES = {
    {NULL_STR, "-9223372036854775808", "-24112329", "-10", "-2", "0", "86", "1202", "122100", "9223372036854775807"}
  };

  DataTypesTestCommon(TEST_TABLE, TABLE_COLUMNS, INSERTED_VALUES, EXPECTED_VALUES);
}

// Test retrieval of type Bit
TEST_F(Data_Types, Bit) {

  const string TEST_TABLE = "BIT_dt";
  vector<pair<string,string>> TABLE_COLUMNS = {
    {"a", "BIT"}
  };
  const string INSERTED_VALUES = "(NULL), (0), (1)";
  const vector<vector<string>> EXPECTED_VALUES = {
    {NULL_STR, "0", "1"}
  };

  DataTypesTestCommon(TEST_TABLE, TABLE_COLUMNS, INSERTED_VALUES, EXPECTED_VALUES);
}

// Test retrieval of type Char
TEST_F(Data_Types, Char) {

  const string TEST_TABLE = "CHAR_dt";
  vector<pair<string,string>> TABLE_COLUMNS = {
    {"a", "CHAR(24)"},
    {"b", "NCHAR(24)"}
  };
  const string INSERTED_VALUES = "(NULL, NULL), (' ',' '), (' John',' Doe'), ('John','Doe')";
  const vector<vector<string>> EXPECTED_VALUES = {
    {NULL_STR,  "                        ", " John                   ", "John                    "}, 
    {NULL_STR,  "                        ", " Doe                    ", "Doe                     "}
  };

  DataTypesTestCommon(TEST_TABLE, TABLE_COLUMNS, INSERTED_VALUES, EXPECTED_VALUES);
}

// Test retrieval of type Date
TEST_F(Data_Types, Date) {

  const string TEST_TABLE = "DATE_dt";
  vector<pair<string,string>> TABLE_COLUMNS = {
    {"a", "DATE"}
  };
  const string INSERTED_VALUES = "(NULL), ('0001-01-01'), ('1900-02-28'), ('2000-12-13'), ('9999-12-31')";
  const vector<vector<string>> EXPECTED_VALUES = {
    {NULL_STR, "0001-01-01", "1900-02-28", "2000-12-13", "9999-12-31"}
  };

  DataTypesTestCommon(TEST_TABLE, TABLE_COLUMNS, INSERTED_VALUES, EXPECTED_VALUES);
}

// Test retrieval of type DateTime
TEST_F(Data_Types, DateTime) {

  const string TEST_TABLE = "DATETIME_dt";
  vector<pair<string,string>> TABLE_COLUMNS = {
    {"a", "DATETIME"}
  };

  const string INSERTED_VALUES = 
    "(NULL), ('1753-01-01 00:00:00.000'), ('1900-02-28 23:59:59.989'), ('1900-02-28 23:59:59.990'), ('1900-02-28 23:59:59.991'), "
    "('1900-02-28 23:59:59.992'), ('1900-02-28 23:59:59.993'), ('1900-02-28 23:59:59.994'), ('1900-02-28 23:59:59.995'), "
    "('1900-02-28 23:59:59.996'), ('1900-02-28 23:59:59.997'), ('1900-02-28 23:59:59.998'), ('1900-02-28 23:59:59.999'), "
    "('2000-02-28 23:59:59.989'), ('2000-12-13 12:58:23.123'), ('9999-12-31 23:59:59.997')";
  const vector<vector<string>> EXPECTED_VALUES = {
    {NULL_STR, "1753-01-01 00:00:00.000", "1900-02-28 23:59:59.990", "1900-02-28 23:59:59.990", "1900-02-28 23:59:59.990", 
    "1900-02-28 23:59:59.993", "1900-02-28 23:59:59.993", "1900-02-28 23:59:59.993", "1900-02-28 23:59:59.997", 
    "1900-02-28 23:59:59.997", "1900-02-28 23:59:59.997", "1900-02-28 23:59:59.997", "1900-03-01 00:00:00.000", 
    "2000-02-28 23:59:59.990", "2000-12-13 12:58:23.123", "9999-12-31 23:59:59.997"}
  };

  DataTypesTestCommon(TEST_TABLE, TABLE_COLUMNS, INSERTED_VALUES, EXPECTED_VALUES);
}
// Test retrieval of type Float
TEST_F(Data_Types, Float) {

  const string TEST_TABLE = "FLOAT_dt";
  vector<pair<string,string>> TABLE_COLUMNS = {
    {"a", "FLOAT"}
  };

  const string INSERTED_VALUES = 
    "(NULL), (-1.79E+308), (-0122455324.5), (-004), (-000002), (0), (1.050), (01.05), (0000000000000000086), (1.79E+308)";
  const vector<vector<string>> EXPECTED_VALUES = {
    {NULL_STR, "-1.79E+308", "-122455324.5", "-4.0", "-2.0", "0.0", "1.05", "1.05", "86.0", "1.79E+308"}
  };
  
  DataTypesTestCommon(TEST_TABLE, TABLE_COLUMNS, INSERTED_VALUES, EXPECTED_VALUES);
}

// Test retrieval of type Int
TEST_F(Data_Types, Int) {
  
  const string TEST_TABLE = "INT_dt";
  vector<pair<string,string>> TABLE_COLUMNS = {
    {"a", "INT"}
  };

  const string INSERTED_VALUES = 
    "(NULL), (-2147483648), (-12345), (-01645), (-10), (0), (004), (10), (22), (2147483647)";
  const vector<vector<string>> EXPECTED_VALUES = {
    {NULL_STR, "-2147483648", "-12345", "-1645", "-10", "0", "4", "10", "22", "2147483647"}
  };

  DataTypesTestCommon(TEST_TABLE, TABLE_COLUMNS, INSERTED_VALUES, EXPECTED_VALUES);
}

// Test retrieval of type Money
// This test differs from others in the following:
// 1. the way the INSERTED_VALUES are defined - they already contain the 'order of insertion' values
// 2. the way the INSERTED_VALUES are inserted - loop through the 'literal' inserted values since they 'hard code' the 'order of insertions' values
// The reason it was done this way is because in SQL Server you cannot mix & match certain different money type syntax in an insert. 
// For example, if I had a table with 1 column of type MONEY I cannot do a single insert of the values ('$10'), (4) without getting a conversion error. 
TEST_F(Data_Types, Money) {
  OdbcHandler odbcHandler;

  const string TEST_TABLE = "MONEY_dt";
  const string ORDER_BY_COLS = "OrderOfInsertion";
  const vector<pair<string,string>> TABLE_COLUMNS = {
    {"a", "smallmoney"},
    {"b", "money"},
    {ORDER_BY_COLS, "INT"}
  };

  const vector<string> INSERTED_VALUES = {
    "(NULL, NULL, 1)", "('-214,748.3648','-922,337,203,685,477.5808', 2)", "(-214748.3648,'-10.0', 3)", 
    "('-10.05','-10.0', 4)", "('$10','$10', 5)", "('10.05','10.0', 6)", "(100.5,10.05, 7)", "(14748.3647,-922337203685477.5808, 8)",
    "('$214748.3647','$22337203685477.5807', 9)", "('214,748.3647','922,337,203,685,477.5807', 10)", "('$214,748.3647','$922,337,203,685,477.5807', 11)"
    };

  vector<vector<string>> expectedValues = {
    {NULL_STR, "-214748.3648", "-214748.3648", "-10.0500", "10.0000", "10.0500", "100.5000", "14748.3647", "214748.3647", 
    "214748.3647", "214748.3647"}, 
    {NULL_STR, "-922337203685477.5808", "-10.0000", "-10.0000", "10.0000", "10.0000", "10.0500", "-922337203685477.5808", "22337203685477.5807", 
     "922337203685477.5807", "922337203685477.5807"}
  };
  
  DatabaseObjects dbObjects;
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(TEST_TABLE, TABLE_COLUMNS));

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));
  
  for (short i = 0; i < INSERTED_VALUES.size(); i++) {
    ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(InsertStatement(TEST_TABLE, INSERTED_VALUES[i])));

  }
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(SelectStatement(TEST_TABLE, { "*" }, { ORDER_BY_COLS })));
  
  SQLSMALLINT sNumResults;
  SQLNumResultCols(odbcHandler.GetStatementHandle(), &sNumResults);
  ASSERT_EQ(sNumResults, TABLE_COLUMNS.size());

  fetchAndCompare(odbcHandler, expectedValues);
}

// Test retrieval of type Real
TEST_F(Data_Types, Real) {

  const string TEST_TABLE = "REAL_dt";
  vector<pair<string,string>> TABLE_COLUMNS = {
    {"a", "REAL"}
  };

  const string INSERTED_VALUES = 
    "(NULL), (-3.40E+38), (-0122455324.5), (-004), (-000002), (0), (1.050), (01.05), (0000000000000000086), (3.40E+38)";
  const vector<vector<string>> EXPECTED_VALUES = {
    {NULL_STR, "-3.4E+38", "-1.2245533E+8", "-4.0", "-2.0", "0.0", "1.05", "1.05", "86.0", "3.4E+38"}
  };

  DataTypesTestCommon(TEST_TABLE, TABLE_COLUMNS, INSERTED_VALUES, EXPECTED_VALUES);
}

// Test retrieval of type SmallDatetime
TEST_F(Data_Types, SmallDatetime) {

  const string TEST_TABLE = "SMALLDATETIME_dt";
  vector<pair<string,string>> TABLE_COLUMNS = {
    {"a", "SMALLDATETIME"}
  };

  const string INSERTED_VALUES = 
    "(NULL), ('1900-01-01 00:00:00'), ('1900-02-28 23:45:29'), ('1900-02-28 23:59:59.999'), "
    "('1900-12-13 12:58:30'), ('2000-02-28 23:45:29'), ('2000-02-28 23:45:29.998'), ('2000-02-28 23:45:29.999'), "
    "('2000-02-28 23:45:30'), ('2000-02-28 23:59:59.999'), ('2000-12-13 12:58:23'), ('2007-05-08 12:35:29'), "
    "('2007-05-08 12:35:30'), ('2007-05-08 12:59:59.998'), ('2079-06-06 23:59:29')";
  const vector<vector<string>> EXPECTED_VALUES = {
    {NULL_STR, "1900-01-01 00:00:00", "1900-02-28 23:45:00", "1900-03-01 00:00:00", 
    "1900-12-13 12:59:00", "2000-02-28 23:45:00", "2000-02-28 23:45:00", "2000-02-28 23:46:00",
    "2000-02-28 23:46:00", "2000-02-29 00:00:00", "2000-12-13 12:58:00", "2007-05-08 12:35:00", 
    "2007-05-08 12:36:00", "2007-05-08 13:00:00", "2079-06-06 23:59:00"}
  };

  DataTypesTestCommon(TEST_TABLE, TABLE_COLUMNS, INSERTED_VALUES, EXPECTED_VALUES);
}

// Test retrieval of type SmallInt
TEST_F(Data_Types, SmallInt) {
  
  const string TEST_TABLE = "SMALLINT_dt";
  vector<pair<string,string>> TABLE_COLUMNS = {
    {"a", "SMALLINT"}
  };

  const string INSERTED_VALUES = 
    "(NULL), (-32768), (-1234), (-029), (-10), (0), (002), (100), (876), (32767)";
  const vector<vector<string>> EXPECTED_VALUES = {
    {NULL_STR, "-32768", "-1234", "-29", "-10", "0", "2", "100", "876", "32767"}
  };

  DataTypesTestCommon(TEST_TABLE, TABLE_COLUMNS, INSERTED_VALUES, EXPECTED_VALUES);
}

// Test retrieval of type TableType
TEST_F(Data_Types, TableType) {

  const string TEST_TABLE = "tableType";
  vector<pair<string,string>> TABLE_COLUMNS = {
    {"a", "text not null"},
    {"b", "int primary key"},
    {"c", "int"}
  };

  const vector<vector<string>> EXPECTED_VALUES = {
    {}
  };

  DataTypesTestCommon(TEST_TABLE, TABLE_COLUMNS, "", EXPECTED_VALUES);
}

// Test retrieval of type Text
TEST_F(Data_Types, Text) {
  
  const string TEST_TABLE = "TEXT_dt";
  vector<pair<string,string>> TABLE_COLUMNS = {
    {"a", "text"},
    {"b", "ntext"}
  };

  string blankFileData = readFromFile("utils/blank.txt");
  string sampleFileData = readFromFile("utils/sample.txt");
  string devanagariFileData = readFromFile("utils/devanagari.txt");

  const string INSERTED_VALUES = 
    "(NULL, NULL), "
    "(\'" + blankFileData + "\', \'" + blankFileData + "\'), "
    "(\'" + sampleFileData + "\', \'" + sampleFileData + "\'), "
    "(NULL, \'" + devanagariFileData + "\')";
  
  const vector<vector<string>> EXPECTED_VALUES = {
    {NULL_STR, "", "AAAAAAAAAAAAAAAAAAAA\nBBBBBBBBBB\nCCCCC\nbadksjvbajsdcbvjads\nsejvhsdbfjhcgvasdhgcvsj\n21639812365091264", 
    NULL_STR}, 
    {NULL_STR, "", "AAAAAAAAAAAAAAAAAAAA\nBBBBBBBBBB\nCCCCC\nbadksjvbajsdcbvjads\nsejvhsdbfjhcgvasdhgcvsj\n21639812365091264", 
    "ऀँंःऄअआइईउऊऋऌऍऎएऐऑऒओऔकखगघङचछजझञटठडढणतथदधनऩपफबभमयरऱलळऴवशषसहऺऻ़ऽािीुूृॄॅॆेैॉॊोौ्ॎॏॐ॒॑॓॔ॕॖॗक़ख़ग़ज़ड़ढ़फ़य़ॠॡॢॣ।॥०१२३४५६७८९॰ॱॲॳॴॵॶॷॹॺॻॼॽॾॿ"}
  };

  DataTypesTestCommon(TEST_TABLE, TABLE_COLUMNS, INSERTED_VALUES, EXPECTED_VALUES);
}

// Test retrieval of type TinyInt
TEST_F(Data_Types, TinyInt) {
  
  const string TEST_TABLE = "TINYINT_dt";
  vector<pair<string,string>> TABLE_COLUMNS = {
    {"a", "TINYINT"}
  };

  const string INSERTED_VALUES = "(NULL), (0), (0), (0), (002), (004), (86), (100), (120), (255)";
  const vector<vector<string>> EXPECTED_VALUES = {
    {NULL_STR, "0", "0", "0", "2", "4", "86", "100", "120", "255"}
  };

  DataTypesTestCommon(TEST_TABLE, TABLE_COLUMNS, INSERTED_VALUES, EXPECTED_VALUES);
}

// Test retrieval of type UniqueIdentifier
TEST_F(Data_Types, UniqueIdentifier) {

  const string TEST_TABLE = "UNIQUEIDENTIFIER_dt";
  vector<pair<string,string>> TABLE_COLUMNS = {
    {"a", "UNIQUEIDENTIFIER"}
  };

  const string INSERTED_VALUES = 
    "(NULL), ('51f178a6-53c7-472c-9be1-1c08942342d7'), ('dba2726c-2131-409f-aefa-5c8079571623'), ('851763b5-b068-42ae-88ec-764bfb0e5605'), "
    "('253fb146-7e45-45ef-9d92-bbe14a8ad1b2'), ('60aeaa5c-e272-4b17-bad0-c25710fd7a60'), ('d424fdef-1404-4bac-8289-c725b540f93d'), "
    "('bab96bc8-60b9-40dd-b0de-c90a80f5739e'), ('dd8cb046-461d-411e-be40-d219252ce849'), ('b84ebcc9-c927-4cfe-b08e-dc7f25b5087c'), "
    "('b3400fa7-3a60-40ec-b40e-fc85a3eb262d')";
  const vector<vector<string>> EXPECTED_VALUES = {
    {NULL_STR, "51F178A6-53C7-472C-9BE1-1C08942342D7", "DBA2726C-2131-409F-AEFA-5C8079571623", "851763B5-B068-42AE-88EC-764BFB0E5605", 
    "253FB146-7E45-45EF-9D92-BBE14A8AD1B2", "60AEAA5C-E272-4B17-BAD0-C25710FD7A60", "D424FDEF-1404-4BAC-8289-C725B540F93D", 
    "BAB96BC8-60B9-40DD-B0DE-C90A80F5739E", "DD8CB046-461D-411E-BE40-D219252CE849", "B84EBCC9-C927-4CFE-B08E-DC7F25B5087C", 
    "B3400FA7-3A60-40EC-B40E-FC85A3EB262D"}
  };

  DataTypesTestCommon(TEST_TABLE, TABLE_COLUMNS, INSERTED_VALUES, EXPECTED_VALUES);
}

// Test retrieval of type Varchar
TEST_F(Data_Types, Varchar) {
  
  const string TEST_TABLE = "VARCHAR_dt";
  vector<pair<string,string>> TABLE_COLUMNS = {
    {"a", "VARCHAR(24)"},
    {"b", "NVARCHAR(24)"}
  };

  const string INSERTED_VALUES = "(NULL, NULL), (' ',' '), (' John',' Doe'), ('John','Doe')";
  const vector<vector<string>> EXPECTED_VALUES = {
    {NULL_STR,  " ", " John", "John"}, 
    {NULL_STR,  " ", " Doe", "Doe"}
  };

  DataTypesTestCommon(TEST_TABLE, TABLE_COLUMNS, INSERTED_VALUES, EXPECTED_VALUES);
}
