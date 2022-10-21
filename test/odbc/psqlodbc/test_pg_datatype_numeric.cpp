#include <gtest/gtest.h>
#include <sqlext.h>
#include "../src/drivers.h"
#include "../src/odbc_handler.h"
#include "../src/query_generator.h"

using std::pair;

const string PG_TABLE_NAME = "master_dbo.numeric_table_odbc_test";
const string BBF_TABLE_NAME = "master.dbo.numeric_table_odbc_test";
const string VIEW_NAME = "master_dbo.numeric_view_odbc_test";
const string DATATYPE = "numeric";
const int NUM_COLS = 5;
const string COL_NAMES[NUM_COLS] = {"pk_1_0", "num_5_5", "num_38_38", "num_38_0", "num_4_2"};
const int COL_PRECISION[NUM_COLS] = {1, 5, 38, 38, 4};
const int COL_SCALE[NUM_COLS] = {0, 5, 38, 0, 2};

const int PG_LENGTH_EXPECTED[NUM_COLS] = {3, 5, 38, 38, 4}; 
const int BBF_LENGTH_EXPECTED[NUM_COLS] = {1, 5, 38, 38, 4}; 

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

class PSQL_DataTypes_Numeric : public testing::Test{

    void SetUp() override {

    OdbcHandler test_setup(Drivers::GetDriver(ServerType::PSQL));
    test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE", PG_TABLE_NAME));
  }

  void TearDown() override {

    OdbcHandler test_cleanup(Drivers::GetDriver(ServerType::PSQL));
    test_cleanup.ConnectAndExecQuery(DropObjectStatement("VIEW", VIEW_NAME));
    test_cleanup.ExecQuery(DropObjectStatement("TABLE", PG_TABLE_NAME));
  }
};


class MSSQL_DataTypes_Numeric : public testing::Test{

    void SetUp() override {

    OdbcHandler test_setup(Drivers::GetDriver(ServerType::MSSQL));
    test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));
  }

  void TearDown() override {

    OdbcHandler test_cleanup(Drivers::GetDriver(ServerType::MSSQL));
    test_cleanup.ConnectAndExecQuery(DropObjectStatement("VIEW", VIEW_NAME));
    test_cleanup.ExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));
  }
};

// pads 0 at the end of the results depending on the scale number
string FormatDecWithScale(string decimal, const int &scale) {

  size_t dec_pos = decimal.find('.');

  if (dec_pos == std::string::npos) {
    if (scale == 0) // if no decimal sign and scale is 0, no need to append
      return decimal;
    dec_pos = decimal.size();
    decimal += ".";
  }

  // add extra 0s
  int zeros_needed = scale - (decimal.size() - dec_pos - 1);
  for (int i = 0; i < zeros_needed; i++) {
    decimal += "0";
  }

  return decimal;
}

string BBF_FormatDecWithScale(string decimal, const int &scale) {

  size_t dec_pos = decimal.find('.');

  if (dec_pos == std::string::npos) {
    if (scale == 0) // if no decimal sign and scale is 0, no need to append
      return decimal;
    dec_pos = decimal.size();
    decimal += ".";
  }

  // add extra 0s
  int zeros_needed = scale - (decimal.size() - dec_pos - 1);
  for (int i = 0; i < zeros_needed; i++) {
    decimal += "0";
  }

  dec_pos = decimal.find('.');

  if ((decimal[dec_pos - 1] == '0' && (dec_pos - 1) == 0) || (decimal[0] == '-' and decimal[1] == '0')){
    decimal.erase(dec_pos - 1, 1);
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
      insert_string += comma2 + inserted_values[i][j];
      comma2 = ",";
    }

    insert_string += ")";
    comma = ",";
  }
  return insert_string;
}

TEST_F(PSQL_DataTypes_Numeric, ColAttributes) {

  const string NAME_EXPECTED = "numeric";
  
  const int BUFFER_SIZE = 256;
  char name[BUFFER_SIZE];
  SQLLEN length;
  SQLLEN precision;
  SQLLEN scale;
  SQLLEN display_size;

  RETCODE rcode;
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));
  OdbcHandler BBF_OdbcHandler(Drivers::GetDriver(ServerType::MSSQL));

  // Create a table with columns defined with the specific datatype being tested. 
  BBF_OdbcHandler.ConnectAndExecQuery(CreateTableStatement(BBF_TABLE_NAME, TABLE_COLUMNS));
  BBF_OdbcHandler.CloseStmt();
  // Select * From Table to ensure that it exists
  odbcHandler.ConnectAndExecQuery(SelectStatement(PG_TABLE_NAME, {"*"}, vector<string> {COL_NAMES[0]}));
  for (int i = 1; i <= NUM_COLS; i++) {

    // Make sure column attributes are correct
    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_LENGTH, // Get the length of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &length);
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(length, PG_LENGTH_EXPECTED[i - 1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_DISPLAY_SIZE, // Get the display size of the column (size of char in columns)
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &display_size);
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(display_size, COL_PRECISION[i - 1] + 2); // add 2 since we also add the decimal and negative characters
    
    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_PRECISION, // Get the precision of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &precision); 
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(precision, COL_PRECISION[i - 1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_SCALE, // Get the scale of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &scale); 
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(scale, COL_SCALE[i - 1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_TYPE_NAME, // Get the type name of the column
                            name,
                            BUFFER_SIZE,
                            NULL,
                            NULL);
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(string(name), NAME_EXPECTED);

  }

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
}

TEST_F(MSSQL_DataTypes_Numeric, ColAttributes) {

  const string NAME_EXPECTED = "numeric";
  
  const int BUFFER_SIZE = 256;
  char name[BUFFER_SIZE];
  SQLLEN length;
  SQLLEN precision;
  SQLLEN scale;
  SQLLEN display_size;

  RETCODE rcode;
  OdbcHandler BBF_OdbcHandler(Drivers::GetDriver(ServerType::MSSQL));

  // Create a table with columns defined with the specific datatype being tested. 
  BBF_OdbcHandler.ConnectAndExecQuery(CreateTableStatement(BBF_TABLE_NAME, TABLE_COLUMNS));
  BBF_OdbcHandler.CloseStmt();
  // Select * From Table to ensure that it exists
  BBF_OdbcHandler.ExecQuery(SelectStatement(BBF_TABLE_NAME, {"*"}, vector<string> {COL_NAMES[0]}));
  for (int i = 1; i <= NUM_COLS; i++) {

    // Make sure column attributes are correct
    rcode = SQLColAttribute(BBF_OdbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_LENGTH, // Get the length of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &length);
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(length, BBF_LENGTH_EXPECTED[i - 1]);

    rcode = SQLColAttribute(BBF_OdbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_DISPLAY_SIZE, // Get the display size of the column (size of char in columns)
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &display_size);
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(display_size, COL_PRECISION[i - 1] + 2); // add 2 since we also add the decimal and negative characters
    
    rcode = SQLColAttribute(BBF_OdbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_PRECISION, // Get the precision of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &precision); 
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(precision, COL_PRECISION[i - 1]);

    rcode = SQLColAttribute(BBF_OdbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_SCALE, // Get the scale of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &scale); 
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(scale, COL_SCALE[i - 1]);

    rcode = SQLColAttribute(BBF_OdbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_TYPE_NAME, // Get the type name of the column
                            name,
                            BUFFER_SIZE,
                            NULL,
                            NULL);
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(string(name), NAME_EXPECTED);

  }

  rcode = SQLFetch(BBF_OdbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
}

TEST_F(MSSQL_DataTypes_Numeric, Table_Create_Fail) {

  vector<vector<pair<string, string>>> invalid_columns{
    {{"invalid1", DATATYPE + "(0,0)"}}, // must have precision of 1 or greater
    {{"invalid2", DATATYPE + "(10,11)"}}, // scale cannot be larger than precision
    {{"invalid3", DATATYPE + "(10, -1)"}} // precision must be 0 or greater
    // Does not work on Postgres endpoint
    // , {{"invalid4", DATATYPE + "(39, 39)"}} // max precision is 38 
  };

  RETCODE rcode;
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::MSSQL));

  // Create a table with columns defined with the specific datatype being tested. 
  odbcHandler.Connect();
  odbcHandler.AllocateStmtHandle();

  // Assert that table creation will always fail with invalid column definitions
  for (int i = 0; i < invalid_columns.size(); i++) {
    rcode = SQLExecDirect(odbcHandler.GetStatementHandle(),
                        (SQLCHAR*) CreateTableStatement(BBF_TABLE_NAME, invalid_columns[i]).c_str(),
                        SQL_NTS);

    ASSERT_EQ(rcode, SQL_ERROR);
  }

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));
}

TEST_F(PSQL_DataTypes_Numeric, Insertion_Success) {

  const int BUFFER_LENGTH = 8192;

  char col_results[NUM_COLS][BUFFER_LENGTH];
  SQLLEN col_len[NUM_COLS];
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler PG_OdbcHandler(Drivers::GetDriver(ServerType::PSQL));
  OdbcHandler BBF_OdbcHandler(Drivers::GetDriver(ServerType::MSSQL));

  vector<vector<string>> inserted_values = {
    {"1", "0", "0", "0", "0" }, // smallest numbers
    {"2", MAX_DEC_5_5, MAX_DEC_38_38, MAX_DEC_38_0, MAX_DEC_4_2}, // max values
    {"3", "-0.694", "0.4347509234", "-8532", "42.8"}, // random regular values
    {"4", "NULL", "NULL", "NULL", "NULL"} // NULL values
  };

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns{};

  // initialize bind_columns
  for (int i = 0; i < NUM_COLS; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN*> tuple_to_insert(i + 1, SQL_C_CHAR, (SQLPOINTER) &col_results[i], BUFFER_LENGTH, &col_len[i]);
    bind_columns.push_back(tuple_to_insert);
  }

  string insert_string = InitializeInsertString(inserted_values);

  // Create table
  BBF_OdbcHandler.ConnectAndExecQuery(CreateTableStatement(BBF_TABLE_NAME, TABLE_COLUMNS));
  BBF_OdbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  PG_OdbcHandler.ConnectAndExecQuery(InsertStatement(PG_TABLE_NAME, insert_string));
 
  rcode = SQLRowCount(PG_OdbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, inserted_values.size());
  
  PG_OdbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  PG_OdbcHandler.ExecQuery(SelectStatement(PG_TABLE_NAME, {"*"}, vector<string> {COL_NAMES[0]}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(PG_OdbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < inserted_values.size(); ++i) {
    
    rcode = SQLFetch(PG_OdbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);

    for (int j = 0; j < NUM_COLS; j++) {

      if (inserted_values[i][j] != "NULL") {

        string expected = FormatDecWithScale(inserted_values[i][j], COL_SCALE[j]);
        ASSERT_EQ(string(col_results[j]), expected);
        ASSERT_EQ(col_len[j], expected.size());
      
      } 
      else 
        ASSERT_EQ(col_len[j], SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(PG_OdbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  PG_OdbcHandler.CloseStmt();
  PG_OdbcHandler.ExecQuery(DropObjectStatement("TABLE", PG_TABLE_NAME));
}

TEST_F(MSSQL_DataTypes_Numeric, Insertion_Success) {

  const int BUFFER_LENGTH = 8192;

  char col_results[NUM_COLS][BUFFER_LENGTH];
  SQLLEN col_len[NUM_COLS];
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler BBF_OdbcHandler(Drivers::GetDriver(ServerType::MSSQL));

  vector<vector<string>> inserted_values = {
    {"1", "0", "0", "0", "0" }, // smallest numbers
    {"2", MAX_DEC_5_5, MAX_DEC_38_38, MAX_DEC_38_0, MAX_DEC_4_2}, // max values
    {"3", "-0.694", "0.4347509234", "-8532", "40.8"}, // random regular values
    {"4", "NULL", "NULL", "NULL", "42.88"} // NULL values
  };

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns{};

  // initialize bind_columns
  for (int i = 0; i < NUM_COLS; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN*> tuple_to_insert(i + 1, SQL_C_CHAR, (SQLPOINTER) &col_results[i], BUFFER_LENGTH, &col_len[i]);
    bind_columns.push_back(tuple_to_insert);
  }

  string insert_string = InitializeInsertString(inserted_values);

  // Create table
  BBF_OdbcHandler.ConnectAndExecQuery(CreateTableStatement(BBF_TABLE_NAME, TABLE_COLUMNS));
  BBF_OdbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  BBF_OdbcHandler.ExecQuery(InsertStatement(BBF_TABLE_NAME, insert_string));
 
  rcode = SQLRowCount(BBF_OdbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, inserted_values.size());
  
  BBF_OdbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  BBF_OdbcHandler.ExecQuery(SelectStatement(BBF_TABLE_NAME, {"*"}, vector<string> {COL_NAMES[0]}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(BBF_OdbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < inserted_values.size(); ++i) {
    
    rcode = SQLFetch(BBF_OdbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);

    for (int j = 0; j < NUM_COLS; j++) {

      if (inserted_values[i][j] != "NULL") {

        string expected = BBF_FormatDecWithScale(inserted_values[i][j], COL_SCALE[j]);
        ASSERT_EQ(string(col_results[j]), expected);
        ASSERT_EQ(col_len[j], expected.size());
      
      } 
      else 
        ASSERT_EQ(col_len[j], SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(BBF_OdbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  BBF_OdbcHandler.CloseStmt();
  BBF_OdbcHandler.ExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));
}

TEST_F(PSQL_DataTypes_Numeric, Insertion_Failure) {

  const int BUFFER_LENGTH = 8192;

  char col_results[NUM_COLS][BUFFER_LENGTH];
  SQLLEN col_len[NUM_COLS];

  RETCODE rcode;
  OdbcHandler PG_OdbcHandler(Drivers::GetDriver(ServerType::PSQL));
  OdbcHandler BBF_OdbcHandler(Drivers::GetDriver(ServerType::MSSQL));

  vector<vector<string>> inserted_values = {
    {"1", MAX_DEC_5_5 + "9", "0", "0", "0" }, // first col exceeds by 1 digit
    {"2", "0", MAX_DEC_38_38 + "9", "0", "0"}, // second col exceeds by 1 digit
    {"3", "0", "0", MAX_DEC_38_0 + ".5", "0"}, // third col exceeds by 1 digit (extra decimal)
    {"4", "0", "0", "0",  "9" + MAX_DEC_4_2} // fourth col exceeds by adding a digit in the front
  };

  // Create table
  BBF_OdbcHandler.ConnectAndExecQuery(CreateTableStatement(BBF_TABLE_NAME, TABLE_COLUMNS));
  BBF_OdbcHandler.CloseStmt();
  PG_OdbcHandler.Connect(true);

  // Insert invalid values in table and assert error
  for (int i = 0; i < inserted_values.size(); i++) {

    string insert_string = "(";
    string comma{};

    // create insert_string (1, ..., ..., ...)
    for (int j = 0; j < NUM_COLS; j++) {
      insert_string += comma + inserted_values[i][j];
      comma = ",";
    }
    insert_string += ")";

    rcode = SQLExecDirect(PG_OdbcHandler.GetStatementHandle(), (SQLCHAR*) InsertStatement(PG_TABLE_NAME, insert_string).c_str(), SQL_NTS);
    ASSERT_EQ(rcode, SQL_ERROR);
    PG_OdbcHandler.CloseStmt();
  }

  // Select all from the table to make sure nothing was inserted
  PG_OdbcHandler.ExecQuery(SelectStatement(PG_TABLE_NAME, {"*"}, vector<string> {COL_NAMES[0]}));
  rcode = SQLFetch(PG_OdbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  PG_OdbcHandler.CloseStmt();
  PG_OdbcHandler.ExecQuery(DropObjectStatement("TABLE", PG_TABLE_NAME));
}

TEST_F(MSSQL_DataTypes_Numeric, Insertion_Failure) {

  const int BUFFER_LENGTH = 8192;

  char col_results[NUM_COLS][BUFFER_LENGTH];
  SQLLEN col_len[NUM_COLS];

  RETCODE rcode;
  OdbcHandler BBF_OdbcHandler(Drivers::GetDriver(ServerType::MSSQL));

  vector<vector<string>> inserted_values = {
    {"1", MAX_DEC_5_5 + "9", "0", "0", "0" }, // first col exceeds by 1 digit
    {"2", "0", MAX_DEC_38_38 + "9", "0", "0"}, // second col exceeds by 1 digit
    {"3", "0", "0", MAX_DEC_38_0 + ".5", "0"}, // third col exceeds by 1 digit (extra decimal)
    {"4", "0", "0", "0",  "9" + MAX_DEC_4_2} // fourth col exceeds by adding a digit in the front
  };

  // Create table
  BBF_OdbcHandler.ConnectAndExecQuery(CreateTableStatement(BBF_TABLE_NAME, TABLE_COLUMNS));
  BBF_OdbcHandler.CloseStmt();

  // Insert invalid values in table and assert error
  for (int i = 0; i < inserted_values.size(); i++) {

    string insert_string = "(";
    string comma{};

    // create insert_string (1, ..., ..., ...)
    for (int j = 0; j < NUM_COLS; j++) {
      insert_string += comma + inserted_values[i][j];
      comma = ",";
    }
    insert_string += ")";

    rcode = SQLExecDirect(BBF_OdbcHandler.GetStatementHandle(), (SQLCHAR*) InsertStatement(BBF_TABLE_NAME, insert_string).c_str(), SQL_NTS);
    ASSERT_EQ(rcode, SQL_ERROR);
    BBF_OdbcHandler.CloseStmt();
  }

  // Select all from the table to make sure nothing was inserted
  BBF_OdbcHandler.ExecQuery(SelectStatement(BBF_TABLE_NAME, {"*"}, vector<string> {COL_NAMES[0]}));
  rcode = SQLFetch(BBF_OdbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  BBF_OdbcHandler.CloseStmt();
  BBF_OdbcHandler.ExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));
}

TEST_F(PSQL_DataTypes_Numeric, Update_Success) {

  const int BUFFER_LENGTH = 8192;
  const int AFFECTED_ROWS_EXPECTED = 1;
  const string PK_VAL = "1";

  char col_results[NUM_COLS][BUFFER_LENGTH];
  SQLLEN col_len[NUM_COLS];
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler PG_OdbcHandler(Drivers::GetDriver(ServerType::PSQL));
  OdbcHandler BBF_OdbcHandler(Drivers::GetDriver(ServerType::MSSQL));

  vector<vector<string>> inserted_values = {
    {PK_VAL, "0.1", "0.2", "3", "4.4"} 
  };

  vector<vector<string>> updated_values = {
    {PK_VAL, "0.2", "0.3", "4", "55.5"}, // standard values
    {PK_VAL, MAX_DEC_5_5, MAX_DEC_38_38, MAX_DEC_38_0, MAX_DEC_4_2}, // max values
    {PK_VAL, "0", "0", "0", "0"} // min values
  };

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns{};

  // initialize bind_columns
  for (int i = 0; i < NUM_COLS; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN*> tuple_to_insert(i + 1, SQL_C_CHAR, (SQLPOINTER) &col_results[i], BUFFER_LENGTH, &col_len[i]);
    bind_columns.push_back(tuple_to_insert);
  }

  string insert_string = InitializeInsertString(inserted_values);

  // Create table
  BBF_OdbcHandler.ConnectAndExecQuery(CreateTableStatement(BBF_TABLE_NAME, TABLE_COLUMNS));
  BBF_OdbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  PG_OdbcHandler.ConnectAndExecQuery(InsertStatement(PG_TABLE_NAME, insert_string));
 
  rcode = SQLRowCount(PG_OdbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, inserted_values.size());
  
  PG_OdbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  PG_OdbcHandler.ExecQuery(SelectStatement(PG_TABLE_NAME, {"*"}, vector<string> {COL_NAMES[0]}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(PG_OdbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < inserted_values.size(); ++i) {
    rcode = SQLFetch(PG_OdbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);

    for (int j = 0; j < NUM_COLS; j++) {

      string expected = FormatDecWithScale(inserted_values[i][j], COL_SCALE[j]);
      ASSERT_EQ(string(col_results[j]), expected);
      ASSERT_EQ(col_len[j], expected.size());
    }
  }

  rcode = SQLFetch(PG_OdbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
  PG_OdbcHandler.CloseStmt();

  for (int i = 0; i < updated_values.size(); i++) {

    vector<pair<string,string>> update_col;
    // setup update column
    for (int j = 0; j <NUM_COLS; j++) {
      string value = string("'") + updated_values[i][j] + string("'");
      update_col.push_back(pair<string,string>(COL_NAMES[j], value));
    }

    PG_OdbcHandler.ExecQuery(UpdateTableStatement(PG_TABLE_NAME, update_col, COL_NAMES[0] + "='" + PK_VAL + "'"));

    rcode = SQLRowCount(PG_OdbcHandler.GetStatementHandle(), &affected_rows);
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(affected_rows, AFFECTED_ROWS_EXPECTED);

    PG_OdbcHandler.CloseStmt();

    PG_OdbcHandler.ExecQuery(SelectStatement(PG_TABLE_NAME, {"*"}, vector<string> {COL_NAMES[0]}));
    rcode = SQLFetch(PG_OdbcHandler.GetStatementHandle());

    for (int j = 0; j < NUM_COLS; j++) {
      
      string expected = FormatDecWithScale(updated_values[i][j], COL_SCALE[j]);
      ASSERT_EQ(string(col_results[j]), expected);
      ASSERT_EQ(col_len[j], expected.size()); 
    }

    rcode = SQLFetch(PG_OdbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_NO_DATA);
    PG_OdbcHandler.CloseStmt();
  }

  PG_OdbcHandler.ExecQuery(DropObjectStatement("TABLE", PG_TABLE_NAME));
}

TEST_F(MSSQL_DataTypes_Numeric, Update_Success) {

  const int BUFFER_LENGTH = 8192;
  const int AFFECTED_ROWS_EXPECTED = 1;
  const string PK_VAL = "1";

  char col_results[NUM_COLS][BUFFER_LENGTH];
  SQLLEN col_len[NUM_COLS];
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler BBF_OdbcHandler(Drivers::GetDriver(ServerType::MSSQL));

  vector<vector<string>> inserted_values = {
    {PK_VAL, "0.1", "0.2", "3", "4.4"} 
  };

  vector<vector<string>> updated_values = {
    {PK_VAL, "0.2", "0.3", "4", "55.5"}, // standard values
    {PK_VAL, MAX_DEC_5_5, MAX_DEC_38_38, MAX_DEC_38_0, MAX_DEC_4_2}, // max values
    {PK_VAL, "0", "0", "0", "0"} // min values
  };

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns{};

  // initialize bind_columns
  for (int i = 0; i < NUM_COLS; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN*> tuple_to_insert(i + 1, SQL_C_CHAR, (SQLPOINTER) &col_results[i], BUFFER_LENGTH, &col_len[i]);
    bind_columns.push_back(tuple_to_insert);
  }

  string insert_string = InitializeInsertString(inserted_values);

  // Create table
  BBF_OdbcHandler.ConnectAndExecQuery(CreateTableStatement(BBF_TABLE_NAME, TABLE_COLUMNS));
  BBF_OdbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  BBF_OdbcHandler.ExecQuery(InsertStatement(BBF_TABLE_NAME, insert_string));
 
  rcode = SQLRowCount(BBF_OdbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, inserted_values.size());
  
  BBF_OdbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  BBF_OdbcHandler.ExecQuery(SelectStatement(BBF_TABLE_NAME, {"*"}, vector<string> {COL_NAMES[0]}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(BBF_OdbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < inserted_values.size(); ++i) {
    rcode = SQLFetch(BBF_OdbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);

    for (int j = 0; j < NUM_COLS; j++) {

      string expected = BBF_FormatDecWithScale(inserted_values[i][j], COL_SCALE[j]);
      ASSERT_EQ(string(col_results[j]), expected);
      ASSERT_EQ(col_len[j], expected.size());
    }
  }

  rcode = SQLFetch(BBF_OdbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
  BBF_OdbcHandler.CloseStmt();

  for (int i = 0; i < updated_values.size(); i++) {

    vector<pair<string,string>> update_col;
    // setup update column
    for (int j = 0; j <NUM_COLS; j++) {
      string value = string("'") + updated_values[i][j] + string("'");
      update_col.push_back(pair<string,string>(COL_NAMES[j], value));
    }

    BBF_OdbcHandler.ExecQuery(UpdateTableStatement(BBF_TABLE_NAME, update_col, COL_NAMES[0] + "='" + PK_VAL + "'"));

    rcode = SQLRowCount(BBF_OdbcHandler.GetStatementHandle(), &affected_rows);
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(affected_rows, AFFECTED_ROWS_EXPECTED);

    BBF_OdbcHandler.CloseStmt();

    BBF_OdbcHandler.ExecQuery(SelectStatement(BBF_TABLE_NAME, {"*"}, vector<string> {COL_NAMES[0]}));
    rcode = SQLFetch(BBF_OdbcHandler.GetStatementHandle());

    for (int j = 0; j < NUM_COLS; j++) {
      
      string expected = BBF_FormatDecWithScale(updated_values[i][j], COL_SCALE[j]);
      ASSERT_EQ(string(col_results[j]), expected);
      ASSERT_EQ(col_len[j], expected.size()); 
    }

    rcode = SQLFetch(BBF_OdbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_NO_DATA);
    BBF_OdbcHandler.CloseStmt();
  }

  BBF_OdbcHandler.ExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));
}

TEST_F(PSQL_DataTypes_Numeric, Update_Fail) {

  const int BUFFER_LENGTH = 8192;
  const int AFFECTED_ROWS_EXPECTED = 1;
  const string PK_VAL = "1";

  char col_results[NUM_COLS][BUFFER_LENGTH];
  SQLLEN col_len[NUM_COLS];
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler PG_OdbcHandler(Drivers::GetDriver(ServerType::PSQL));
  OdbcHandler BBF_OdbcHandler(Drivers::GetDriver(ServerType::MSSQL));

  vector<vector<string>> inserted_values = {
    {PK_VAL, "0.1", "0.2", "3", "4.4"} 
  };

  vector<vector<string>> updated_values = {
    {"1", MAX_DEC_5_5 + "9", "0", "0", "0" }, // first col exceeds by 1 digit
  };

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns{};

  // initialize bind_columns
  for (int i = 0; i < NUM_COLS; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN*> tuple_to_insert(i + 1, SQL_C_CHAR, (SQLPOINTER) &col_results[i], BUFFER_LENGTH, &col_len[i]);
    bind_columns.push_back(tuple_to_insert);
  }

  string insert_string = InitializeInsertString(inserted_values);

  // Create table
  BBF_OdbcHandler.ConnectAndExecQuery(CreateTableStatement(BBF_TABLE_NAME, TABLE_COLUMNS));
  BBF_OdbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  PG_OdbcHandler.ConnectAndExecQuery(InsertStatement(PG_TABLE_NAME, insert_string));
 
  rcode = SQLRowCount(PG_OdbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, inserted_values.size());
  
  PG_OdbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  PG_OdbcHandler.ExecQuery(SelectStatement(PG_TABLE_NAME, {"*"}, vector<string> {COL_NAMES[0]}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(PG_OdbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < inserted_values.size(); ++i) {
    rcode = SQLFetch(PG_OdbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);

    for (int j = 0; j < NUM_COLS; j++) {
      string expected = FormatDecWithScale(inserted_values[i][j], COL_SCALE[j]);
      ASSERT_EQ(string(col_results[j]), expected);
      ASSERT_EQ(col_len[j], expected.size());
    }
  }

  rcode = SQLFetch(PG_OdbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  for (int i = 0; i < inserted_values.size(); i++) 
  {
    PG_OdbcHandler.CloseStmt();
    vector<pair<string,string>> update_col;

    // setup update column
    for (int j = 0; j <NUM_COLS; j++) {
      update_col.push_back(pair<string,string>(COL_NAMES[j], updated_values[i][j]));
    }

    // Update value and assert an error is present
    rcode = SQLExecDirect(PG_OdbcHandler.GetStatementHandle(),
                          (SQLCHAR*) UpdateTableStatement(PG_TABLE_NAME, update_col, COL_NAMES[0] + "='" + PK_VAL + "'").c_str(), 
                          SQL_NTS);
    ASSERT_EQ(rcode, SQL_ERROR);

    PG_OdbcHandler.CloseStmt();

    PG_OdbcHandler.ExecQuery(SelectStatement(PG_TABLE_NAME, {"*"}, vector<string> {COL_NAMES[0]}));
    rcode = SQLFetch(PG_OdbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_SUCCESS);

    // Assert that the results did not change
    for (int j = 0; j < NUM_COLS; j++) {
      string expected = FormatDecWithScale(inserted_values[i][j], COL_SCALE[j]);
      ASSERT_EQ(string(col_results[j]), expected);
      ASSERT_EQ(col_len[j], expected.size());;
    }
  }

  rcode = SQLFetch(PG_OdbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  PG_OdbcHandler.CloseStmt();
  PG_OdbcHandler.ExecQuery(DropObjectStatement("TABLE", PG_TABLE_NAME));
}

TEST_F(MSSQL_DataTypes_Numeric, Update_Fail) {

  const int BUFFER_LENGTH = 8192;
  const int AFFECTED_ROWS_EXPECTED = 1;
  const string PK_VAL = "1";

  char col_results[NUM_COLS][BUFFER_LENGTH];
  SQLLEN col_len[NUM_COLS];
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler BBF_OdbcHandler(Drivers::GetDriver(ServerType::MSSQL));

  vector<vector<string>> inserted_values = {
    {PK_VAL, "0.1", "0.2", "3", "4.4"} 
  };

  vector<vector<string>> updated_values = {
    {"1", MAX_DEC_5_5 + "9", "0", "0", "0" }, // first col exceeds by 1 digit
  };

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns{};

  // initialize bind_columns
  for (int i = 0; i < NUM_COLS; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN*> tuple_to_insert(i + 1, SQL_C_CHAR, (SQLPOINTER) &col_results[i], BUFFER_LENGTH, &col_len[i]);
    bind_columns.push_back(tuple_to_insert);
  }

  string insert_string = InitializeInsertString(inserted_values);

  // Create table
  BBF_OdbcHandler.ConnectAndExecQuery(CreateTableStatement(BBF_TABLE_NAME, TABLE_COLUMNS));
  BBF_OdbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  BBF_OdbcHandler.ExecQuery(InsertStatement(BBF_TABLE_NAME, insert_string));
 
  rcode = SQLRowCount(BBF_OdbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, inserted_values.size());
  
  BBF_OdbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  BBF_OdbcHandler.ExecQuery(SelectStatement(BBF_TABLE_NAME, {"*"}, vector<string> {COL_NAMES[0]}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(BBF_OdbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < inserted_values.size(); ++i) {
    rcode = SQLFetch(BBF_OdbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);

    for (int j = 0; j < NUM_COLS; j++) {
      string expected = BBF_FormatDecWithScale(inserted_values[i][j], COL_SCALE[j]);
      ASSERT_EQ(string(col_results[j]), expected);
      ASSERT_EQ(col_len[j], expected.size());
    }
  }

  rcode = SQLFetch(BBF_OdbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  for (int i = 0; i < inserted_values.size(); i++) 
  {
    BBF_OdbcHandler.CloseStmt();
    vector<pair<string,string>> update_col;

    // setup update column
    for (int j = 0; j <NUM_COLS; j++) {
      update_col.push_back(pair<string,string>(COL_NAMES[j], updated_values[i][j]));
    }

    // Update value and assert an error is present
    rcode = SQLExecDirect(BBF_OdbcHandler.GetStatementHandle(),
                          (SQLCHAR*) UpdateTableStatement(BBF_TABLE_NAME, update_col, COL_NAMES[0] + "='" + PK_VAL + "'").c_str(), 
                          SQL_NTS);
    ASSERT_EQ(rcode, SQL_ERROR);

    BBF_OdbcHandler.CloseStmt();

    BBF_OdbcHandler.ExecQuery(SelectStatement(BBF_TABLE_NAME, {"*"}, vector<string> {COL_NAMES[0]}));
    rcode = SQLFetch(BBF_OdbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_SUCCESS);

    // Assert that the results did not change
    for (int j = 0; j < NUM_COLS; j++) {
      string expected = BBF_FormatDecWithScale(inserted_values[i][j], COL_SCALE[j]);
      ASSERT_EQ(string(col_results[j]), expected);
      ASSERT_EQ(col_len[j], expected.size());;
    }
  }

  rcode = SQLFetch(BBF_OdbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  BBF_OdbcHandler.CloseStmt();
  BBF_OdbcHandler.ExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));
}

TEST_F(PSQL_DataTypes_Numeric,Arithmetic_Operators) {

  const int BUFFER_LENGTH = 8192;
  const int BYTES_EXPECTED = 8;
  const int NUM_COLS = 2;
  const string COL_NAMES[NUM_COLS] = {"pk", "decimal"};
  const string COL_TYPES[NUM_COLS] = {
    DATATYPE + "(" + std::to_string(COL_PRECISION[0]) + "," + std::to_string(COL_SCALE[0]) +  ")",
    DATATYPE + "(" + std::to_string(COL_PRECISION[1]) + "," + std::to_string(COL_SCALE[1]) + ")"
  };

  vector<pair<string, string>> TABLE_COLUMNS = {
    {COL_NAMES[0], COL_TYPES[0] + " PRIMARY KEY"},
    {COL_NAMES[1], COL_TYPES[1]}
  };
  // unsure of how these values are calculated, but they match with postgres' (non-sys) decimal type
  // Postgres documentation just says they're bytes size are variable

  unsigned char pk;
  unsigned char data[BUFFER_LENGTH];
  SQLLEN pk_len;
  SQLLEN data_len;
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler PG_OdbcHandler(Drivers::GetDriver(ServerType::PSQL));
  OdbcHandler BBF_OdbcHandler(Drivers::GetDriver(ServerType::MSSQL));

  vector <string> inserted_pk = {
    "8"
  };

  vector <string> inserted_data = {
    "0.55555"
  };

  vector <string> operations_query = {
    COL_NAMES[0] + "+" + COL_NAMES[1],
    COL_NAMES[0] + "-" + COL_NAMES[1],
    COL_NAMES[0] + "*" + COL_NAMES[1],
    COL_NAMES[0] + "/" + COL_NAMES[1],
    "ABS(" + COL_NAMES[0] + ")",
    "POWER(" + COL_NAMES[0] + "," + COL_NAMES[1] + ")",
    "||/ " + COL_NAMES[0],
    "LOG(" + COL_NAMES[0] + ")"    
  };

  vector<vector<string>>expected_results = {{},{}};

  // initialization of expected_results
  for (int i = 0; i < inserted_pk.size(); i++) {
    expected_results[i].push_back("8.55555");
    expected_results[i].push_back("7.44445");
    expected_results[i].push_back("4.44440");
    expected_results[i].push_back("14.4001440014400144");
    expected_results[i].push_back("8");
    expected_results[i].push_back("3.1747654273961317");
    expected_results[i].push_back("2");
    expected_results[i].push_back("0.9030899869919436");
  }

  char col_results[operations_query.size()][BUFFER_LENGTH];
  SQLLEN col_len[operations_query.size()];
  vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns = {};

  // initialization for bind_columns
  for (int i = 0; i < operations_query.size(); i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN*> tuple_to_insert(i + 1, SQL_C_CHAR, (SQLPOINTER) &col_results[i], BUFFER_LENGTH, &col_len[i]);
    bind_columns.push_back(tuple_to_insert);
  }

  string insert_string{}; 
  string comma{};
  
  // insert_string initialization
  for (int i = 0; i< inserted_pk.size() ; ++i) {
    insert_string += comma + "(" + inserted_pk[i] + "," + inserted_data[i] + ")";
    comma = ",";
  }

  // Create table
  BBF_OdbcHandler.ConnectAndExecQuery(CreateTableStatement(BBF_TABLE_NAME, TABLE_COLUMNS));
  BBF_OdbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  PG_OdbcHandler.ConnectAndExecQuery(InsertStatement(PG_TABLE_NAME, insert_string));
 
  rcode = SQLRowCount(PG_OdbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, inserted_data.size());
  

  // Make sure inserted values are correct and operations
  ASSERT_NO_FATAL_FAILURE(PG_OdbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < inserted_data.size(); ++i) {
    
    PG_OdbcHandler.CloseStmt();
    PG_OdbcHandler.ExecQuery(SelectStatement(PG_TABLE_NAME, operations_query, vector<string> {}, COL_NAMES[0] + "=" + inserted_pk[i]));
    ASSERT_NO_FATAL_FAILURE(PG_OdbcHandler.BindColumns(bind_columns));

    rcode = SQLFetch(PG_OdbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_SUCCESS);

    for (int j = 0; j < operations_query.size(); j++) {
      ASSERT_EQ(col_len[j], expected_results[i][j].size());
      ASSERT_EQ(col_results[j], expected_results[i][j]);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(PG_OdbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  PG_OdbcHandler.CloseStmt();
  PG_OdbcHandler.ExecQuery(DropObjectStatement("TABLE", PG_TABLE_NAME));
}

TEST_F(MSSQL_DataTypes_Numeric,Arithmetic_Operators) {

  const int BUFFER_LENGTH=8192;
  const int BYTES_EXPECTED = 8;
  const int NUM_COLS = 2;
  const string COL_NAMES[NUM_COLS] = {"pk", "decimal"};
  const string COL_TYPES[NUM_COLS] = {
    DATATYPE + "(" + std::to_string(COL_PRECISION[0]) + "," + std::to_string(COL_SCALE[0]) +  ")",
    DATATYPE + "(" + std::to_string(COL_PRECISION[1]) + "," + std::to_string(COL_SCALE[1]) + ")"
  };

  vector<pair<string, string>> TABLE_COLUMNS = {
    {COL_NAMES[0], COL_TYPES[0] + " PRIMARY KEY"},
    {COL_NAMES[1], COL_TYPES[1]}
  };
  // unsure of how these values are calculated, but they match with postgres' (non-sys) decimal type
  // Postgres documentation just says they're bytes size are variable

  unsigned char pk;
  unsigned char data[BUFFER_LENGTH];
  SQLLEN pk_len;
  SQLLEN data_len;
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler BBF_OdbcHandler(Drivers::GetDriver(ServerType::MSSQL));

  vector <string> inserted_pk = {
    "8"
  };

  vector <string> inserted_data = {
    "0.55555"
  };

  vector <string> operations_query = {
    COL_NAMES[0] + "+" + COL_NAMES[1],
    COL_NAMES[0] + "-" + COL_NAMES[1],
    COL_NAMES[0] + "*" + COL_NAMES[1],
    COL_NAMES[0] + "/" + COL_NAMES[1],
    "ABS("+COL_NAMES[0]+")",
    "POWER("+COL_NAMES[0]+","+COL_NAMES[1]+")",
    "SQRT("+COL_NAMES[0]+")",
    "LOG("+COL_NAMES[0]+")"    
  };

  vector<vector<string>>expected_results = {{},{}};

  // initialization of expected_results
  for (int i = 0; i < inserted_pk.size(); i++) {
    expected_results[i].push_back("8.55555");
    expected_results[i].push_back("7.44445");
    expected_results[i].push_back("4.44440");
    expected_results[i].push_back("14.400144");
    expected_results[i].push_back("8.00000000");
    expected_results[i].push_back("3.17476542");
    expected_results[i].push_back("2.82842712");
    expected_results[i].push_back(".90308998");
  }

  char col_results[operations_query.size()][BUFFER_LENGTH];
  SQLLEN col_len[operations_query.size()];
  vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns = {};

  // initialization for bind_columns
  for (int i = 0; i < operations_query.size(); i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN*> tuple_to_insert(i + 1, SQL_C_CHAR, (SQLPOINTER) &col_results[i], BUFFER_LENGTH, &col_len[i]);
    bind_columns.push_back(tuple_to_insert);
  }

  string insert_string{}; 
  string comma{};
  
  // insert_string initialization
  for (int i = 0; i< inserted_pk.size() ; ++i) {
    insert_string += comma + "(" + inserted_pk[i] + "," + inserted_data[i] + ")";
    comma = ",";
  }

  // Create table
  BBF_OdbcHandler.ConnectAndExecQuery(CreateTableStatement(BBF_TABLE_NAME, TABLE_COLUMNS));
  BBF_OdbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  BBF_OdbcHandler.ExecQuery(InsertStatement(BBF_TABLE_NAME, insert_string));
 
  rcode = SQLRowCount(BBF_OdbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, inserted_data.size());
  

  // Make sure inserted values are correct and operations
  ASSERT_NO_FATAL_FAILURE(BBF_OdbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < inserted_data.size(); ++i) {
    
    BBF_OdbcHandler.CloseStmt();
    BBF_OdbcHandler.ExecQuery(SelectStatement(BBF_TABLE_NAME, operations_query, vector<string> {}, COL_NAMES[0] + "=" + inserted_pk[i]));
    ASSERT_NO_FATAL_FAILURE(BBF_OdbcHandler.BindColumns(bind_columns));

    rcode = SQLFetch(BBF_OdbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_SUCCESS);

    for (int j = 0; j < operations_query.size(); j++) {
      ASSERT_EQ(col_len[j], expected_results[i][j].size());
      ASSERT_EQ(col_results[j], expected_results[i][j]);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(BBF_OdbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  BBF_OdbcHandler.CloseStmt();
  BBF_OdbcHandler.ExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));
}

TEST_F(PSQL_DataTypes_Numeric, View_creation) {

  const string VIEW_QUERY = "SELECT * FROM " + PG_TABLE_NAME;
  const int BUFFER_LENGTH = 8192;

  char col_results[NUM_COLS][BUFFER_LENGTH];
  SQLLEN col_len[NUM_COLS];
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler PG_OdbcHandler(Drivers::GetDriver(ServerType::PSQL));
  OdbcHandler BBF_OdbcHandler(Drivers::GetDriver(ServerType::MSSQL));

  vector<vector<string>> inserted_values = {
    {"1", "0", "0", "0", "0" }, // smallest numbers
    {"2", MAX_DEC_5_5, MAX_DEC_38_38, MAX_DEC_38_0, MAX_DEC_4_2}, // max values
    {"3", "-0.694", "0.4347509234", "-8532", "42.8"}, // random regular values
    {"4", "NULL", "NULL", "NULL", "NULL"} // NULL values
  };

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns{};

  // initialize bind_columns
  for (int i = 0; i < NUM_COLS; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN*> tuple_to_insert(i + 1, SQL_C_CHAR, (SQLPOINTER) &col_results[i], BUFFER_LENGTH, &col_len[i]);
    bind_columns.push_back(tuple_to_insert);
  }

  string insert_string = InitializeInsertString(inserted_values);

  // Create table
  BBF_OdbcHandler.ConnectAndExecQuery(CreateTableStatement(BBF_TABLE_NAME, TABLE_COLUMNS));
  BBF_OdbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  PG_OdbcHandler.ConnectAndExecQuery(InsertStatement(PG_TABLE_NAME, insert_string));
 
  rcode = SQLRowCount(PG_OdbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, inserted_values.size());
  
  PG_OdbcHandler.CloseStmt();

  // Create view
  PG_OdbcHandler.ExecQuery(CreateViewStatement(VIEW_NAME, VIEW_QUERY));
  PG_OdbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  PG_OdbcHandler.ExecQuery(SelectStatement(VIEW_NAME, {"*"}, vector<string> {COL_NAMES[0]}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(PG_OdbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < inserted_values.size(); ++i) {
    
    rcode = SQLFetch(PG_OdbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);

    for (int j = 0; j < NUM_COLS; j++) {
      
      if (inserted_values[i][j] != "NULL") {

        string expected = FormatDecWithScale(inserted_values[i][j], COL_SCALE[j]);
        ASSERT_EQ(string(col_results[j]), expected);
        ASSERT_EQ(col_len[j], expected.size());
      } 
      else {
        ASSERT_EQ(col_len[j], SQL_NULL_DATA);
      }
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(PG_OdbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  PG_OdbcHandler.CloseStmt();
  PG_OdbcHandler.ExecQuery(DropObjectStatement("VIEW", VIEW_NAME));
}

TEST_F(PSQL_DataTypes_Numeric, Table_Composite_Keys) {

  const int BUFFER_LENGTH=8192;

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL_NAMES[0], "int" },
    {COL_NAMES[1], DATATYPE}
  };
  const string PKTABLE_NAME = PG_TABLE_NAME.substr(PG_TABLE_NAME.find('.') + 1, PG_TABLE_NAME.length());
  const string SCHEMA_NAME = PG_TABLE_NAME.substr(0, PG_TABLE_NAME.find('.'));

  const vector<string> PK_COLUMNS = {
    COL_NAMES[0],
    COL_NAMES[1]
  };

  string table_constraints{"PRIMARY KEY ("};
  string comma{};
  for (int i = 0; i < PK_COLUMNS.size(); i++) {
    table_constraints += comma + PK_COLUMNS[i];
    comma = ",";
  };
  table_constraints += ")";

  const int PK_BYTES_EXPECTED = 4;

  int pk;
  char data[BUFFER_LENGTH];
  SQLLEN pk_len;
  SQLLEN data_len;
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler PG_OdbcHandler(Drivers::GetDriver(ServerType::PSQL));
  OdbcHandler BBF_OdbcHandler(Drivers::GetDriver(ServerType::MSSQL));

  const vector<string> VALID_INSERTED_VALUES = {
    "0", "1"
  };
  const int NUM_OF_INSERTS = VALID_INSERTED_VALUES.size();

  string insert_string{};
  comma = "";

  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    insert_string += comma + "(" + std::to_string(i) + ", '" + VALID_INSERTED_VALUES[i] + "')";
    comma = ",";
  }

  BBF_OdbcHandler.ConnectAndExecQuery(CreateTableStatement(BBF_TABLE_NAME, TABLE_COLUMNS, table_constraints));
  // std::cout<<CreateTableStatement(TABLE_NAME, TABLE_COLUMNS, table_constraints)<<'\n';
  BBF_OdbcHandler.CloseStmt();
  PG_OdbcHandler.Connect(true);

  // Check if composite key still matches after creation
  char table_name[BUFFER_LENGTH];
  char column_name[BUFFER_LENGTH];
  int key_sq{};
  char pk_name[BUFFER_LENGTH];

  const vector<tuple<int, int, SQLPOINTER, int>> CONSTRAINT_BIND_COLUMNS = {
    {3, SQL_C_CHAR, table_name, BUFFER_LENGTH},
    {4, SQL_C_CHAR, column_name, BUFFER_LENGTH},
    {5, SQL_C_ULONG, &key_sq, BUFFER_LENGTH},
    {6, SQL_C_CHAR, pk_name, BUFFER_LENGTH}
  };
  ASSERT_NO_FATAL_FAILURE(PG_OdbcHandler.BindColumns(CONSTRAINT_BIND_COLUMNS));

  rcode = SQLPrimaryKeys(PG_OdbcHandler.GetStatementHandle(), NULL, 0, (SQLCHAR *)SCHEMA_NAME.c_str(), SQL_NTS, (SQLCHAR *)PKTABLE_NAME.c_str(), SQL_NTS);
  ASSERT_EQ(rcode, SQL_SUCCESS);

  int curr_sq{0};
  for (auto columnName : PK_COLUMNS) {
    ++curr_sq;
    rcode = SQLFetch(PG_OdbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_SUCCESS);

    ASSERT_EQ(string(table_name), PKTABLE_NAME);
    ASSERT_EQ(string(column_name), columnName);
    ASSERT_EQ(key_sq, curr_sq);
  }
  rcode = SQLFetch(PG_OdbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
  PG_OdbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  PG_OdbcHandler.ExecQuery(InsertStatement(PG_TABLE_NAME, insert_string));

  rcode = SQLRowCount(PG_OdbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, NUM_OF_INSERTS);

  PG_OdbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  PG_OdbcHandler.ExecQuery(SelectStatement(PG_TABLE_NAME, {"*"}, vector<string>{COL_NAMES[0]}));

  // Make sure inserted values are correct
  const vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> BIND_COLUMNS = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, SQL_C_CHAR, &data, BUFFER_LENGTH, &data_len}
  };

  ASSERT_NO_FATAL_FAILURE(PG_OdbcHandler.BindColumns(BIND_COLUMNS));

  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    rcode = SQLFetch(PG_OdbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(pk_len, PK_BYTES_EXPECTED);
    ASSERT_EQ(pk, i);
    if (VALID_INSERTED_VALUES[i] != "NULL") {
      ASSERT_EQ(data_len, VALID_INSERTED_VALUES[i].size());
      ASSERT_EQ(data, VALID_INSERTED_VALUES[i]);
    }
    else {
      ASSERT_EQ(data_len, SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(PG_OdbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  PG_OdbcHandler.CloseStmt();

  // Attempt to insert values that violates composite constraint and assert that they all fail
  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    insert_string += comma + "(" + std::to_string(i) + "," + VALID_INSERTED_VALUES[i] + ")";
    comma = ",";
  }

  rcode = SQLExecDirect(PG_OdbcHandler.GetStatementHandle(), (SQLCHAR *)InsertStatement(PG_TABLE_NAME, insert_string).c_str(), SQL_NTS);
  ASSERT_EQ(rcode, SQL_ERROR);

  PG_OdbcHandler.ExecQuery(DropObjectStatement("TABLE", PG_TABLE_NAME));
}

TEST_F(MSSQL_DataTypes_Numeric, Table_Composite_Keys) {

  const int BUFFER_LENGTH=8192;

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL_NAMES[0], "int" },
    {COL_NAMES[1], DATATYPE}
  };

  size_t first_period = BBF_TABLE_NAME.find('.') + 1;
  size_t second_period = BBF_TABLE_NAME.find('.', first_period);
  const string SCHEMA_NAME = BBF_TABLE_NAME.substr(first_period, second_period - first_period);
  const string PKTABLE_NAME = BBF_TABLE_NAME.substr(second_period + 1, BBF_TABLE_NAME.length() - second_period);

  const vector<string> PK_COLUMNS = {
    COL_NAMES[0],
    COL_NAMES[1]
  };

  string table_constraints{"PRIMARY KEY ("};
  string comma{};
  for (int i = 0; i < PK_COLUMNS.size(); i++) {
    table_constraints += comma + PK_COLUMNS[i];
    comma = ",";
  };
  table_constraints += ")";

  const int PK_BYTES_EXPECTED = 4;

  int pk;
  char data[BUFFER_LENGTH];
  SQLLEN pk_len;
  SQLLEN data_len;
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler BBF_OdbcHandler(Drivers::GetDriver(ServerType::MSSQL));

  const vector<string> VALID_INSERTED_VALUES = {
    "0", "1"
  };
  const int NUM_OF_INSERTS = VALID_INSERTED_VALUES.size();

  string insert_string{};
  comma = "";

  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    insert_string += comma + "(" + std::to_string(i) + ", '" + VALID_INSERTED_VALUES[i] + "')";
    comma = ",";
  }

  BBF_OdbcHandler.ConnectAndExecQuery(CreateTableStatement(BBF_TABLE_NAME, TABLE_COLUMNS, table_constraints));
  // std::cout<<CreateTableStatement(TABLE_NAME, TABLE_COLUMNS, table_constraints)<<'\n';
  BBF_OdbcHandler.CloseStmt();

  // Check if composite key still matches after creation
  char table_name[BUFFER_LENGTH];
  char column_name[BUFFER_LENGTH];
  int key_sq{};
  char pk_name[BUFFER_LENGTH];

  const vector<tuple<int, int, SQLPOINTER, int>> CONSTRAINT_BIND_COLUMNS = {
    {3, SQL_C_CHAR, table_name, BUFFER_LENGTH},
    {4, SQL_C_CHAR, column_name, BUFFER_LENGTH},
    {5, SQL_C_ULONG, &key_sq, BUFFER_LENGTH},
    {6, SQL_C_CHAR, pk_name, BUFFER_LENGTH}
  };
  ASSERT_NO_FATAL_FAILURE(BBF_OdbcHandler.BindColumns(CONSTRAINT_BIND_COLUMNS));

  rcode = SQLPrimaryKeys(BBF_OdbcHandler.GetStatementHandle(), NULL, 0, (SQLCHAR *)SCHEMA_NAME.c_str(), SQL_NTS, (SQLCHAR *)PKTABLE_NAME.c_str(), SQL_NTS);
  ASSERT_EQ(rcode, SQL_SUCCESS);

  int curr_sq{0};
  for (auto columnName : PK_COLUMNS) {
    ++curr_sq;
    rcode = SQLFetch(BBF_OdbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_SUCCESS);

    ASSERT_EQ(string(table_name), PKTABLE_NAME);
    ASSERT_EQ(string(column_name), columnName);
    ASSERT_EQ(key_sq, curr_sq);
  }
  rcode = SQLFetch(BBF_OdbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
  BBF_OdbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  BBF_OdbcHandler.ExecQuery(InsertStatement(BBF_TABLE_NAME, insert_string));

  rcode = SQLRowCount(BBF_OdbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, NUM_OF_INSERTS);

  BBF_OdbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  BBF_OdbcHandler.ExecQuery(SelectStatement(BBF_TABLE_NAME, {"*"}, vector<string>{COL_NAMES[0]}));

  // Make sure inserted values are correct
  const vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> BIND_COLUMNS = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, SQL_C_CHAR, &data, BUFFER_LENGTH, &data_len}
  };

  ASSERT_NO_FATAL_FAILURE(BBF_OdbcHandler.BindColumns(BIND_COLUMNS));

  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    rcode = SQLFetch(BBF_OdbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(pk_len, PK_BYTES_EXPECTED);
    ASSERT_EQ(pk, i);
    if (VALID_INSERTED_VALUES[i] != "NULL") {
      ASSERT_EQ(data_len, VALID_INSERTED_VALUES[i].size());
      ASSERT_EQ(data, VALID_INSERTED_VALUES[i]);
    }
    else {
      ASSERT_EQ(data_len, SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(BBF_OdbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  BBF_OdbcHandler.CloseStmt();

  // Attempt to insert values that violates composite constraint and assert that they all fail
  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    insert_string += comma + "(" + std::to_string(i) + "," + VALID_INSERTED_VALUES[i] + ")";
    comma = ",";
  }

  rcode = SQLExecDirect(BBF_OdbcHandler.GetStatementHandle(), (SQLCHAR *)InsertStatement(BBF_TABLE_NAME, insert_string).c_str(), SQL_NTS);
  ASSERT_EQ(rcode, SQL_ERROR);

  BBF_OdbcHandler.ExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));
}

TEST_F(PSQL_DataTypes_Numeric, Table_Unique_Constraints) {

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL_NAMES[0], "INT PRIMARY KEY" },
    {COL_NAMES[1], DATATYPE + " UNIQUE NOT NULL"}
  };
 
  const string UNIQUE_COLUMN_NAME = COL_NAMES[1];
  const int BUFFER_LENGTH = 8192;
  const int PK_BYTES_EXPECTED = 4;

  int pk;
  char data[BUFFER_LENGTH];
  SQLLEN pk_len;
  SQLLEN data_len;
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler PG_OdbcHandler(Drivers::GetDriver(ServerType::PSQL));
  OdbcHandler BBF_OdbcHandler(Drivers::GetDriver(ServerType::MSSQL));

  const vector<string> VALID_INSERTED_VALUES = {
    "0", "1"
  };

  const int NUM_OF_INSERTS = VALID_INSERTED_VALUES.size();

  const vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> BIND_COLUMNS = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, SQL_C_CHAR, &data, BUFFER_LENGTH, &data_len}
  };

  string insert_string{};
  string comma{};

  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    insert_string += comma + "(" + std::to_string(i) + "," + VALID_INSERTED_VALUES[i] + ")";
    comma = ",";
  }

  BBF_OdbcHandler.ConnectAndExecQuery(CreateTableStatement(BBF_TABLE_NAME, TABLE_COLUMNS));
  BBF_OdbcHandler.CloseStmt();
  PG_OdbcHandler.Connect(true);

  // Check if unique constraint still matches after creation
  char column_name[BUFFER_LENGTH];
  char type_name[BUFFER_LENGTH];

  vector<tuple<int, int, SQLPOINTER, int>> table_BIND_COLUMNS = {
    {1, SQL_C_CHAR, column_name, BUFFER_LENGTH},
  };
  ASSERT_NO_FATAL_FAILURE(PG_OdbcHandler.BindColumns(table_BIND_COLUMNS));

  const string PK_QUERY =
    "SELECT C.COLUMN_NAME FROM "
    "INFORMATION_SCHEMA.TABLE_CONSTRAINTS T "
    "JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE C "
    "ON C.CONSTRAINT_NAME=T.CONSTRAINT_NAME "
    "WHERE "
    "C.TABLE_NAME='" + PG_TABLE_NAME.substr(PG_TABLE_NAME.find('.') + 1, PG_TABLE_NAME.length()) + "' "
    "AND T.CONSTRAINT_TYPE='UNIQUE'";
  PG_OdbcHandler.ExecQuery(PK_QUERY);
  rcode = SQLFetch(PG_OdbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(string(column_name), UNIQUE_COLUMN_NAME);

  rcode = SQLFetch(PG_OdbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);

  PG_OdbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  PG_OdbcHandler.ExecQuery(InsertStatement(PG_TABLE_NAME, insert_string));

  rcode = SQLRowCount(PG_OdbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, NUM_OF_INSERTS);

  PG_OdbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  PG_OdbcHandler.ExecQuery(SelectStatement(PG_TABLE_NAME, {"*"}, vector<string>{COL_NAMES[1]}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(PG_OdbcHandler.BindColumns(BIND_COLUMNS));

  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    rcode = SQLFetch(PG_OdbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(pk_len, PK_BYTES_EXPECTED);
    ASSERT_EQ(pk, i);

    if (VALID_INSERTED_VALUES[i] != "NULL") {
      ASSERT_EQ(data_len, VALID_INSERTED_VALUES[i].size());
      ASSERT_EQ(data, VALID_INSERTED_VALUES[i]);
    }
    else {
      ASSERT_EQ(data_len, SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(PG_OdbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  PG_OdbcHandler.CloseStmt();

  // Attempt to insert
  const vector<string> INVALID_INSERTED_VALUES = {
    "0",
    "1"
  };
  const int NUM_OF_INVALID = INVALID_INSERTED_VALUES.size();

  // Attempt to insert values that violates unique constraint and assert that they all fail
  for (int i = NUM_OF_INVALID; i < 2 * NUM_OF_INVALID; i++) {
    string insert_string = "(" + std::to_string(i) + "," + INVALID_INSERTED_VALUES[i - NUM_OF_INVALID] + ")";

    rcode = SQLExecDirect(PG_OdbcHandler.GetStatementHandle(), (SQLCHAR *)InsertStatement(PG_TABLE_NAME, insert_string).c_str(), SQL_NTS);
    ASSERT_EQ(rcode, SQL_ERROR);
  }

  PG_OdbcHandler.ExecQuery(DropObjectStatement("TABLE", PG_TABLE_NAME));
}

TEST_F(MSSQL_DataTypes_Numeric, Table_Unique_Constraints) {
  
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL_NAMES[0], "INT PRIMARY KEY" },
    {COL_NAMES[1], DATATYPE + " UNIQUE NOT NULL"}
  };
 
  size_t first_period = BBF_TABLE_NAME.find('.') + 1;
  size_t second_period = BBF_TABLE_NAME.find('.', first_period); 
 
  const string UNIQUE_COLUMN_NAME = COL_NAMES[1];
  const int BUFFER_LENGTH = 8192;
  const int PK_BYTES_EXPECTED = 4;

  int pk;
  char data[BUFFER_LENGTH];
  SQLLEN pk_len;
  SQLLEN data_len;
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler BBF_OdbcHandler(Drivers::GetDriver(ServerType::MSSQL));

  const vector<string> VALID_INSERTED_VALUES = {
    "0", "1"
  };

  const int NUM_OF_INSERTS = VALID_INSERTED_VALUES.size();

  const vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> BIND_COLUMNS = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, SQL_C_CHAR, &data, BUFFER_LENGTH, &data_len}
  };

  string insert_string{};
  string comma{};

  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    insert_string += comma + "(" + std::to_string(i) + "," + VALID_INSERTED_VALUES[i] + ")";
    comma = ",";
  }

  BBF_OdbcHandler.ConnectAndExecQuery(CreateTableStatement(BBF_TABLE_NAME, TABLE_COLUMNS));
  BBF_OdbcHandler.CloseStmt();

  // Check if unique constraint still matches after creation
  char column_name[BUFFER_LENGTH];
  char type_name[BUFFER_LENGTH];

  vector<tuple<int, int, SQLPOINTER, int>> table_BIND_COLUMNS = {
    {1, SQL_C_CHAR, column_name, BUFFER_LENGTH},
  };
  ASSERT_NO_FATAL_FAILURE(BBF_OdbcHandler.BindColumns(table_BIND_COLUMNS));

  const string PK_QUERY =
    "SELECT C.COLUMN_NAME FROM "
    "INFORMATION_SCHEMA.TABLE_CONSTRAINTS T "
    "JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE C "
    "ON C.CONSTRAINT_NAME=T.CONSTRAINT_NAME "
    "WHERE "
    "C.TABLE_NAME='" + BBF_TABLE_NAME.substr(second_period + 1, BBF_TABLE_NAME.length() - second_period) + "' "
    "AND T.CONSTRAINT_TYPE='UNIQUE'";
  BBF_OdbcHandler.ExecQuery(PK_QUERY);
  rcode = SQLFetch(BBF_OdbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(string(column_name), UNIQUE_COLUMN_NAME);

  rcode = SQLFetch(BBF_OdbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);

  BBF_OdbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  BBF_OdbcHandler.ExecQuery(InsertStatement(BBF_TABLE_NAME, insert_string));

  rcode = SQLRowCount(BBF_OdbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, NUM_OF_INSERTS);

  BBF_OdbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  BBF_OdbcHandler.ExecQuery(SelectStatement(BBF_TABLE_NAME, {"*"}, vector<string>{COL_NAMES[1]}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(BBF_OdbcHandler.BindColumns(BIND_COLUMNS));

  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    rcode = SQLFetch(BBF_OdbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(pk_len, PK_BYTES_EXPECTED);
    ASSERT_EQ(pk, i);

    if (VALID_INSERTED_VALUES[i] != "NULL") {
      ASSERT_EQ(data_len, VALID_INSERTED_VALUES[i].size());
      ASSERT_EQ(data, VALID_INSERTED_VALUES[i]);
    }
    else {
      ASSERT_EQ(data_len, SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(BBF_OdbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  BBF_OdbcHandler.CloseStmt();

  // Attempt to insert
  const vector<string> INVALID_INSERTED_VALUES = {
    "0",
    "1"
  };
  const int NUM_OF_INVALID = INVALID_INSERTED_VALUES.size();

  // Attempt to insert values that violates unique constraint and assert that they all fail
  for (int i = NUM_OF_INVALID; i < 2 * NUM_OF_INVALID; i++) {
    string insert_string = "(" + std::to_string(i) + "," + INVALID_INSERTED_VALUES[i - NUM_OF_INVALID] + ")";

    rcode = SQLExecDirect(BBF_OdbcHandler.GetStatementHandle(), (SQLCHAR *)InsertStatement(BBF_TABLE_NAME, insert_string).c_str(), SQL_NTS);
    ASSERT_EQ(rcode, SQL_ERROR);
  }

  BBF_OdbcHandler.ExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));
}