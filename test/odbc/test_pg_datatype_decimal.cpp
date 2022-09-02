#include <gtest/gtest.h>
#include <sqlext.h>
#include "odbc_handler.h"
#include "query_generator.h"
#include <iostream>

using std::pair;

const string TABLE_NAME = "master_dbo.decimal_table_odbc_test";
const string VIEW_NAME = "master_dbo.decimal_view_odbc_test";
const string DATATYPE = "sys.decimal";
const int NUM_COLS = 5;
const string COL_NAMES[NUM_COLS] = {"pk_1_0", "dec_5_5", "dec_38_38", "dec_38_0", "dec_4_2"};
const int COL_PRECISION[NUM_COLS] = {1, 5, 38, 38, 4};
const int COL_SCALE[NUM_COLS] = {0, 5, 38, 0, 2};

const string COL_TYPES[NUM_COLS] = {
  DATATYPE + "(" + std::to_string(COL_PRECISION[0]) + "," + std::to_string(COL_SCALE[0]) +  ")",
  DATATYPE + "(" + std::to_string(COL_PRECISION[1]) + "," + std::to_string(COL_SCALE[1]) + ")",
  DATATYPE + "(" + std::to_string(COL_PRECISION[2]) + "," + std::to_string(COL_SCALE[2]) + ")",
  DATATYPE + "(" + std::to_string(COL_PRECISION[3]) + "," + std::to_string(COL_SCALE[3]) + ")",
  DATATYPE + "(" + std::to_string(COL_PRECISION[4]) + "," + std::to_string(COL_SCALE[4]) + ")"
};

vector<pair<string, string>> TABLE_COLUMNS = {
  {COL_NAMES[0], COL_TYPES[0] + " PRIMARY KEY"},
  {COL_NAMES[1], COL_TYPES[1]},
  {COL_NAMES[2], COL_TYPES[2]},
  {COL_NAMES[3], COL_TYPES[3]},
  {COL_NAMES[4], COL_TYPES[4]}
};

const string MAX_DEC_5_5 = "0.99999";
const string MAX_DEC_38_38 = "0.99999999999999999999999999999999999999";
const string MAX_DEC_38_0 = "99999999999999999999999999999999999999";
const string MAX_DEC_4_2 = "99.99";

// const string MIN_DEC_5_5 = "0.00000";
// const string MIN_DEC_38_38 = "0.00000000000000000000000000000000000000";
// const string MIN_DEC_38_0 = "0";
// const string MIN_DEC_4_2 = "0.00";

class PSQL_DataTypes_Decimal : public testing::Test{

  void SetUp() override {

    OdbcHandler test_setup;
    test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
  }

  void TearDown() override {

    OdbcHandler test_cleanup;
    test_cleanup.ConnectAndExecQuery(DropObjectStatement("VIEW", VIEW_NAME));
    test_cleanup.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
  }
};

int GetExpectedLengthFromPrecision(const int &precision) {

  if (precision < 10)
    return 5;
  else if (precision < 20)
    return 9;
  else if (precision < 29)
    return 13;
    
  return 17;
}

// pads 0 at the end of the results depending on the scale number
// TODO: Format
string FormatDecWithScale(string decimal, const int &scale) {

  size_t dec_pos = decimal.find('.');

  if (dec_pos == std::string::npos) {
    if (scale == 0) {
      return decimal;
    }

    dec_pos = decimal.size();
    decimal += ".";
  }

  int zeros_needed = scale - (decimal.size() - dec_pos - 1);

  for (int i = 0; i < zeros_needed; i++) {
    decimal += "0";
  }

  return decimal;

}

// helper function to initialize insert string (1, "", "", ""), etc.
string InitializeInsertString(const vector<vector<string>> &inserted_values) {

  string insert_string{};
  string comma{};

  for (int i = 0; i< inserted_values.size(); ++i) {

    insert_string += comma + "(";
    string comma2{};

    for (int j = 0; j < NUM_COLS; j++) {
      if (inserted_values[i][j] != "NULL")
        insert_string += comma2 + "'" + inserted_values[i][j] + "'";
      else
        insert_string += comma2 + inserted_values[i][j];
      comma2 = ",";
    }

    insert_string += ")";
    comma = ",";
  }
  return insert_string;
}

TEST_F(PSQL_DataTypes_Decimal, ColAttributes) {

  const int LENGTH_EXPECTED = 10;
  const int PRECISION_EXPECTED = 0;
  const int SCALE_EXPECTED = 0;
  const string NAME_EXPECTED = "numeric";
  const string DISPLAY_SIZE_EXPECTED = "idk";
  
  const int BUFFER_SIZE = 256;
  char name[BUFFER_SIZE];
  char display_size[BUFFER_SIZE];
  SQLLEN length;
  SQLLEN precision;
  SQLLEN scale;
  SQLLEN is_case_sensitive;

  RETCODE rcode;
  OdbcHandler odbcHandler;

  // Create a table with columns defined with the specific datatype being tested. 
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
  odbcHandler.CloseStmt();

  // Select * From Table to ensure that it exists
  odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string> {COL_NAMES[0]}));

  for (int i = 1; i <= NUM_COLS; i++) {

    // TODO: Figure out the length of decimal values
    // Make sure column attributes are correct
    // rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
    //                         i,
    //                         SQL_DESC_LENGTH, // Get the length of the column
    //                         NULL,
    //                         0,
    //                         NULL,
    //                         (SQLLEN*) &length);
    // ASSERT_EQ(rcode, SQL_SUCCESS);
    // ASSERT_EQ(length, COL_PRECISION[i-1] + 2);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_DISPLAY_SIZE, // Get the display size of the column (size of char in columns)
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &length);
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(length, COL_PRECISION[i-1] + 2); // add 2 since we also add the decimal and negative characters
    
    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_PRECISION, // Get the precision of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &precision); 
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(precision, COL_PRECISION[i-1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_SCALE, // Get the scale of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &scale); 
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(scale, COL_SCALE[i-1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_TYPE_NAME, // Get the type name of the column
                            name,
                            BUFFER_SIZE,
                            NULL,
                            NULL);
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(string(name), NAME_EXPECTED);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_CASE_SENSITIVE, // Get the case sensitivity of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &is_case_sensitive); 
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(is_case_sensitive, SQL_FALSE);

  }

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
}

TEST_F(PSQL_DataTypes_Decimal, Insertion_Success) {

  const int BUFFER_LENGTH = 8192;

  char col_results[NUM_COLS][BUFFER_LENGTH];
  SQLLEN col_len[NUM_COLS];
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler odbcHandler;

  vector<vector<string>> inserted_values = {
    {"1", "0", "0", "0", "0" }, // smallest numbers
    {"2", MAX_DEC_5_5, MAX_DEC_38_38, MAX_DEC_38_0, MAX_DEC_4_2}, // max values
    {"3", "0.694", "0.4347509234", "8532", "42.8"}, // random regular values
    {"4", "NULL", "NULL", "NULL", "NULL"} // NULL values
  };

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns{};

  // initialize bind_columns
  for (int i = 0; i < NUM_COLS; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN*> tuple_to_insert(i+1, SQL_C_CHAR, (SQLPOINTER) &col_results[i], BUFFER_LENGTH, &col_len[i]);
    bind_columns.push_back(tuple_to_insert);
  }

  string insert_string = InitializeInsertString(inserted_values);

  // Create table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(TABLE_NAME, insert_string));
 
  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, inserted_values.size());
  
  odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string> {COL_NAMES[0]}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < inserted_values.size(); ++i) {
    
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);

    for (int j = 0; j < NUM_COLS; j++) {

      if (inserted_values[i][j] != "NULL") {
        ASSERT_EQ(string(col_results[j]), FormatDecWithScale(inserted_values[i][j], COL_SCALE[j]));
        // ASSERT_EQ(col_len[j], inserted_values[i][j].size()); TO DO: Figure out how many bytes for decimal
      } 
      else 
        ASSERT_EQ(col_len[j], SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
}

// TEST_F(PSQL_DataTypes_Decimal, Insertion_Failure) {

//   const int BUFFER_LENGTH = 8192;

//   char col_results[NUM_COLS][BUFFER_LENGTH];
//   SQLLEN col_len[NUM_COLS];

//   RETCODE rcode;
//   OdbcHandler odbcHandler;

//   vector<vector<string>> inserted_values = {
//     {"1", STRING_1 + "1", "", "" }, // first col exceeds by 1 char
//     {"2", "", STRING_8000 + "1", ""}, // second col exceeds by 1 char
//     {"3", "", "", STRING_20 + "1"}, // third col exceeds by 1 char
//   };

//   // Create table
//   odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
//   odbcHandler.CloseStmt();

//   // Insert invalid values in table and assert error
//   for (int i = 0; i < inserted_values.size(); i++) {

//     string insert_string = "(";
//     string comma{};

//     // create insert_string (1, ..., ..., ...)
//     for (int j = 0; j < NUM_COLS; j++) {
//       insert_string += comma + "'" + inserted_values[i][j] + "'";
//       comma = ",";
//     }
//     insert_string += ")";

//     rcode = SQLExecDirect(odbcHandler.GetStatementHandle(), (SQLCHAR*) InsertStatement(TABLE_NAME, insert_string).c_str(), SQL_NTS);
//     ASSERT_EQ(rcode, SQL_ERROR);
//     odbcHandler.CloseStmt();
//   }

//   // Select all from the table to make sure nothing was inserted
//   odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string> {COL_NAMES[0]}));
//   rcode = SQLFetch(odbcHandler.GetStatementHandle());
//   ASSERT_EQ(rcode, SQL_NO_DATA);

//   odbcHandler.CloseStmt();
//   odbcHandler.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
// }

// TEST_F(PSQL_DataTypes_Decimal, Update_Success) {

//   const int BUFFER_LENGTH = 8192;
//   const int AFFECTED_ROWS_EXPECTED = 1;
//   const string PK_VAL = "1";

//   char col_results[NUM_COLS][BUFFER_LENGTH];
//   SQLLEN col_len[NUM_COLS];
//   SQLLEN affected_rows;

//   RETCODE rcode;
//   OdbcHandler odbcHandler;

//   vector<vector<string>> inserted_values = {
//     {PK_VAL, "1", "2", "3"} 
//   };

//   vector<vector<string>> updated_values = {
//     {PK_VAL, "a", "b", "c"}, // standard values
//     {PK_VAL, STRING_1, STRING_8000, STRING_20}, // max values
//     {PK_VAL, "", "", ""} // min values
//   };

//   vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns{};

//   // initialize bind_columns
//   for (int i = 0; i < NUM_COLS; i++) {
//     tuple<int, int, SQLPOINTER, int, SQLLEN*> tuple_to_insert(i+1, SQL_C_CHAR, (SQLPOINTER) &col_results[i], BUFFER_LENGTH, &col_len[i]);
//     bind_columns.push_back(tuple_to_insert);
//   }

//   string insert_string = InitializeInsertString(inserted_values);


//   // Create table
//   odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
//   odbcHandler.CloseStmt();

//   // Insert valid values into the table and assert affected rows
//   odbcHandler.ExecQuery(InsertStatement(TABLE_NAME, insert_string));
 
//   rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affected_rows);
//   ASSERT_EQ(rcode, SQL_SUCCESS);
//   ASSERT_EQ(affected_rows, inserted_values.size());
  
//   odbcHandler.CloseStmt();

//   // Select all from the tables and assert that the following attributes of the type is correct:
//   odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string> {COL_NAMES[0]}));

//   // Make sure inserted values are correct
//   ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

//   for (int i = 0; i < inserted_values.size(); ++i) {
//     rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
//     ASSERT_EQ(rcode, SQL_SUCCESS);

//     for (int j = 0; j < NUM_COLS; j++) {
//       ASSERT_EQ(string(col_results[j]), inserted_values[i][j]);
//       ASSERT_EQ(col_len[j], inserted_values[i][j].size());
//     }
//   }

//   rcode = SQLFetch(odbcHandler.GetStatementHandle());
//   ASSERT_EQ(rcode, SQL_NO_DATA);
//   odbcHandler.CloseStmt();

//   for (int i = 0; i < updated_values.size(); i++) {

//     vector<pair<string,string>> update_col;
//     // setup update column
//     for (int j = 0; j <NUM_COLS; j++) {
//       string value = string("'") + updated_values[i][j] + string("'");
//       update_col.push_back(pair<string,string>(COL_NAMES[j], value));
//     }

//     odbcHandler.ExecQuery(UpdateTableStatement(TABLE_NAME, update_col, COL_NAMES[0] + "='" + PK_VAL + "'"));

//     rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affected_rows);
//     ASSERT_EQ(rcode, SQL_SUCCESS);
//     ASSERT_EQ(affected_rows, AFFECTED_ROWS_EXPECTED);

//     odbcHandler.CloseStmt();

//     odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string> {COL_NAMES[0]}));
//     rcode = SQLFetch(odbcHandler.GetStatementHandle());

//     for (int j = 0; j < NUM_COLS; j++) {
      
//       ASSERT_EQ(string(col_results[j]), updated_values[i][j]);
//       ASSERT_EQ(col_len[j], updated_values[i][j].size());
//     }

//     rcode = SQLFetch(odbcHandler.GetStatementHandle());
//     ASSERT_EQ(rcode, SQL_NO_DATA);
//     odbcHandler.CloseStmt();
//   }

//   odbcHandler.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
// }

// TEST_F(PSQL_DataTypes_Decimal, Update_Fail) {

//   const int BUFFER_LENGTH = 8192;
//   const int AFFECTED_ROWS_EXPECTED = 1;
//   const string PK_VAL = "1";

//   char col_results[NUM_COLS][BUFFER_LENGTH];
//   SQLLEN col_len[NUM_COLS];
//   SQLLEN affected_rows;

//   RETCODE rcode;
//   OdbcHandler odbcHandler;

//   vector<vector<string>> inserted_values = {
//     {PK_VAL, "1", "2", "3"} 
//   };

//   vector<vector<string>> updated_values = {
//     {PK_VAL, STRING_1 + "1", STRING_8000 + "1", STRING_20 + "1"} // max values + 1 char
//   };

//   vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns{};

//   // initialize bind_columns
//   for (int i = 0; i < NUM_COLS; i++) {
//     tuple<int, int, SQLPOINTER, int, SQLLEN*> tuple_to_insert(i+1, SQL_C_CHAR, (SQLPOINTER) &col_results[i], BUFFER_LENGTH, &col_len[i]);
//     bind_columns.push_back(tuple_to_insert);
//   }

//   string insert_string = InitializeInsertString(inserted_values);

//   // Create table
//   odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
//   odbcHandler.CloseStmt();

//   // Insert valid values into the table and assert affected rows
//   odbcHandler.ExecQuery(InsertStatement(TABLE_NAME, insert_string));
 
//   rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affected_rows);
//   ASSERT_EQ(rcode, SQL_SUCCESS);
//   ASSERT_EQ(affected_rows, inserted_values.size());
  
//   odbcHandler.CloseStmt();

//   // Select all from the tables and assert that the following attributes of the type is correct:
//   odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string> {COL_NAMES[0]}));

//   // Make sure inserted values are correct
//   ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

//   for (int i = 0; i < inserted_values.size(); ++i) {
//     rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
//     ASSERT_EQ(rcode, SQL_SUCCESS);

//     for (int j = 0; j < NUM_COLS; j++) {
//       ASSERT_EQ(string(col_results[j]), inserted_values[i][j]);
//       ASSERT_EQ(col_len[j], inserted_values[i][j].size());
//     }
//   }

//   rcode = SQLFetch(odbcHandler.GetStatementHandle());
//   ASSERT_EQ(rcode, SQL_NO_DATA);
//   odbcHandler.CloseStmt();

//   vector<pair<string,string>> update_col;

//   // setup update column
//   for (int j = 0; j <NUM_COLS; j++) {
//     string value = string("'") + updated_values[0][j] + string("'");
//     update_col.push_back(pair<string,string>(COL_NAMES[j], value));
//   }

//   // Update value and assert an error is present
//   rcode = SQLExecDirect(odbcHandler.GetStatementHandle(),
//                         (SQLCHAR*) UpdateTableStatement(TABLE_NAME, update_col, COL_NAMES[0] + "='" + PK_VAL + "'").c_str(), 
//                         SQL_NTS);

//   ASSERT_EQ(rcode, SQL_ERROR);

//   odbcHandler.CloseStmt();

//   odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string> {COL_NAMES[0]}));
//   rcode = SQLFetch(odbcHandler.GetStatementHandle());
//   ASSERT_EQ(rcode, SQL_SUCCESS);

//   // Assert that the results did not change
//   for (int i = 0; i < NUM_COLS; i++) {
//     ASSERT_EQ(string(col_results[i]), inserted_values[0][i]);
//     ASSERT_EQ(col_len[i], inserted_values[0][i].size());
//   }

//   rcode = SQLFetch(odbcHandler.GetStatementHandle());
//   ASSERT_EQ(rcode, SQL_NO_DATA);

//   odbcHandler.CloseStmt();
//   odbcHandler.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
// }

// TEST_F(PSQL_DataTypes_Decimal, View_creation) {

//   const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;
//   const int BUFFER_LENGTH = 8192;

//   char col_results[NUM_COLS][BUFFER_LENGTH];
//   SQLLEN col_len[NUM_COLS];
//   SQLLEN affected_rows;

//   RETCODE rcode;
//   OdbcHandler odbcHandler;

//   vector<vector<string>> inserted_values = {
//     {"1", "", "", "" }, // empty strings
//     {"2", STRING_1, STRING_8000, STRING_20}, // max values
//     {"3", "a", "def", "ghi"}, // regular values
//     {"4", "NULL", "NULL", "NULL"} // NULL values
//   };

//   vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns{};

//   // initialize bind_columns
//   for (int i = 0; i < NUM_COLS; i++) {
//     tuple<int, int, SQLPOINTER, int, SQLLEN*> tuple_to_insert(i+1, SQL_C_CHAR, (SQLPOINTER) &col_results[i], BUFFER_LENGTH, &col_len[i]);
//     bind_columns.push_back(tuple_to_insert);
//   }

//   string insert_string = InitializeInsertString(inserted_values);

//   // Create table
//   odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
//   odbcHandler.CloseStmt();

//   // Insert valid values into the table and assert affected rows
//   odbcHandler.ExecQuery(InsertStatement(TABLE_NAME, insert_string));
 
//   rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affected_rows);
//   ASSERT_EQ(rcode, SQL_SUCCESS);
//   ASSERT_EQ(affected_rows, inserted_values.size());
  
//   odbcHandler.CloseStmt();

//   // Create view
//   odbcHandler.ExecQuery(CreateViewStatement(VIEW_NAME, VIEW_QUERY));
//   odbcHandler.CloseStmt();

//   // Select all from the tables and assert that the following attributes of the type is correct:
//   odbcHandler.ExecQuery(SelectStatement(VIEW_NAME, {"*"}, vector<string> {COL_NAMES[0]}));

//   // Make sure inserted values are correct
//   ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

//   for (int i = 0; i < inserted_values.size(); ++i) {
    
//     rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
//     ASSERT_EQ(rcode, SQL_SUCCESS);

//     for (int j = 0; j < NUM_COLS; j++) {
      
//       if (inserted_values[i][j] != "NULL") {

//         ASSERT_EQ(string(col_results[j]), inserted_values[i][j]);
//         ASSERT_EQ(col_len[j], inserted_values[i][j].size());
//       } 
//       else {
//         ASSERT_EQ(col_len[j], SQL_NULL_DATA);
//       }
//     }
//   }

//   // Assert that there is no more data
//   rcode = SQLFetch(odbcHandler.GetStatementHandle());
//   ASSERT_EQ(rcode, SQL_NO_DATA);

//   odbcHandler.CloseStmt();
//   odbcHandler.ExecQuery(DropObjectStatement("VIEW", VIEW_NAME));
// }
