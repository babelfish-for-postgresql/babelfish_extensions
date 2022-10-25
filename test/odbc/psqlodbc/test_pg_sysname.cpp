#include <gtest/gtest.h>
#include <sqlext.h>
#include "../src/drivers.h"
#include "../src/odbc_handler.h"
#include "../src/query_generator.h"
#include "psqlodbc_tests_common.h"

using std::pair;

const string TABLE_NAME = "master_dbo.sysname_table_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "sysname_data";
const string DATATYPE = "sys.sysname";
const string VIEW_NAME = "master_dbo.sysname_view_odbc_test";
const string STRING_128 = "TQR6vCl9UH5qg2UEJMleJaa3yToVaUbhhxQ7e0SgHjrKg1TYvyUzTrLlO64uPEj572WjgLK6X5muDjK64tcWBr4bBp8hjnV"
  "ftzfLIYFEFCK0nAIuGhnjHIiB8Qc3ywbK";

const string STRING_1 = "a";
const string STRING_20 = "0123456789abcdefghij";

const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, " int PRIMARY KEY"},
    {COL2_NAME, DATATYPE}
};

class PSQL_Datatypes_Sysname: public testing::Test {
   void SetUp() override {
    if(!Drivers::DriverExists(ServerType::PSQL)) {
      GTEST_SKIP() << "PSQL Driver not present: skipping all tests for this fixture.";
    }

    OdbcHandler test_setup(Drivers::GetDriver(ServerType::PSQL));
    test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
   }

   void TearDown() override {
    if(!Drivers::DriverExists(ServerType::PSQL)) {
        GTEST_SKIP() << "PSQL Driver not present: skipping tear down.";
    }
    OdbcHandler test_cleanup(Drivers::GetDriver(ServerType::PSQL));
    test_cleanup.ConnectAndExecQuery(DropObjectStatement("VIEW", VIEW_NAME));
    test_cleanup.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
   }

};

TEST_F(PSQL_Datatypes_Sysname, Table_Creation) {
  const vector<int> LENGTH_EXPECTED = {4, 128};
  const vector<int> PRECISION_EXPECTED = {0, 0};
  const vector<int> SCALE_EXPECTED = {0, 0};
  const vector<string> NAME_EXPECTED = {"int4", "unknown"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testCommonColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS.size(), COL1_NAME, LENGTH_EXPECTED, 
    PRECISION_EXPECTED, SCALE_EXPECTED, NAME_EXPECTED);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Sysname, Table_Create_Fail) {
  const vector<vector<pair<string, string>>> invalid_columns {
    {{"invalid1", DATATYPE + "(4)"}} // Cannot specify a column width on data type datatime.
  };

  // Assert that table creation will always fail with invalid column definitions
  testTableCreationFailure(ServerType::PSQL, TABLE_NAME, invalid_columns);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

// inserted values differ that of expected?
TEST_F(PSQL_Datatypes_Sysname, Insertion_Success) {
  const vector<string> inserted_values = {
    "NULL", // NULL value
    STRING_1,
    STRING_128,
    STRING_20,
    "" // blank value
  };

  const vector<string> expected = {
    "NULL", // NULL value
    STRING_1,
    STRING_128,
    STRING_20,
    "" // blank value
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, inserted_values, expected);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Sysname, Insertion_Failure) {
  const vector<string> inserted_values = {
    STRING_128 + "t"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, inserted_values, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Sysname, Updata_Success) {
  const vector<string> inserted_values = {
    "a"
  };

  const vector<string> updatad_values = {
    STRING_1,
    STRING_20,
    STRING_128,
    "" // blank value
  };

  const vector<string> expected_updatad_values = {
    STRING_1,
    STRING_20,
    STRING_128,
    "" // blank value
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, inserted_values, inserted_values);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, updatad_values, expected_updatad_values);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Sysname, Updata_Fail) {
  const vector<string> inserted_values = {
    STRING_1
  };

  const vector<string> updatad_values = {
    STRING_128 + "t"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, inserted_values, inserted_values);
  testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, inserted_values, updatad_values);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Sysname, View_creation) {
  const vector<string> inserted_values = {
    "NULL", // NULL values
    STRING_1,
    STRING_20,
    STRING_128,
    "" // blank value
  };

  const vector<string> expected = {
    "NULL", // NULL values
    STRING_1,
    STRING_20,
    STRING_128,
    "" // blank value
  };

  const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, inserted_values, expected);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, inserted_values, expected);

  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Sysname, Table_Single_Primary_Keys) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE}
  };

  const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
  const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

  const vector<string> PK_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

  const vector<string> inserted_values = {
    STRING_1,
    STRING_20,
    STRING_128,
    "" // blank value
  };

  const vector<string> expected = {
    STRING_1,
    STRING_20,
    STRING_128,
    "" // blank value
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, inserted_values, expected);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Sysname, Table_Composite_Primary_Keys) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE}
  };
  const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
  const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

  const vector<string> PK_COLUMNS = {
    COL1_NAME, 
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

  const vector<string> inserted_values = {
    STRING_1,
    STRING_20,
    STRING_128,
    "" // blank value
  };

  const vector<string> expected = {
    STRING_1,
    STRING_20,
    STRING_128,
    "" // blank value
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, inserted_values, expected);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Sysname, Table_Unique_Constraint) {

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE}
  };

  const vector<string> UNIQUE_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS);

  // Insert valid values into the table and assert affected rows
  const vector<string> inserted_values = {
    STRING_1,
    STRING_20,
    STRING_128,
    "" // blank value
  };

  const vector<string> expected = {
    STRING_1,
    STRING_20,
    STRING_128,
    "" // blank value
  };

  // table name without the schema
  const string tableName = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, tableName, UNIQUE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, inserted_values, expected);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, inserted_values, false, inserted_values.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Sysname, String_Operators) {

  const int BUFFER_LENGTH = 256;
  const int BYTES_EXPECTED = 4;
  const int DOUBLE_BYTES_EXPECTE = 8;
  int pk;
  char data[BUFFER_LENGTH];
  SQLLEN pk_len;
  SQLLEN data_len;
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

const int NUM_COLS = 2;
const string COL_NAMES[NUM_COLS] = {"pk", "data"};
const int COL_LENGTH[NUM_COLS] = {128, 128};

const string COL_TYPES[NUM_COLS] = {
  DATATYPE,
  DATATYPE
};

vector<pair<string, string>> TABLE_COLUMNS_NTEXT = {
  {COL_NAMES[0], COL_TYPES[0] + " PRIMARY KEY"},
  {COL_NAMES[1], COL_TYPES[1]}
};


  vector <string> inserted_pk = {
    "123",
    "456"
  };

  vector <string> inserted_data = {
    "One Two Three",
    "Four Five Six"
  };

  vector <string> operations_query = {
    COL_NAMES[0]+ "||" + COL_NAMES[1],
    "lower("+COL_NAMES[1]+")",
    COL_NAMES[0] + ">" + COL_NAMES[1],
    COL_NAMES[0] + ">=" + COL_NAMES[1],
    COL_NAMES[0] + "<=" + COL_NAMES[1],
    COL_NAMES[0] + "<" + COL_NAMES[1],
    COL_NAMES[0] + "<>" + COL_NAMES[1]
  };

  vector<vector<string>>expected_results = {{},{}};

  // initialization of expected_results
  for (int i = 0; i < inserted_pk.size(); i++) {
    expected_results[i].push_back(inserted_pk[i] + inserted_data[i]);
    string current=inserted_data[i];
    transform(current.begin(), current.end(), current.begin(), ::tolower);
    expected_results[i].push_back(current);
    expected_results[i].push_back(std::to_string(inserted_pk[i] > inserted_data[i]));
    expected_results[i].push_back(std::to_string(inserted_pk[i] >= inserted_data[i]));
    expected_results[i].push_back(std::to_string(inserted_pk[i] <= inserted_data[i]));
    expected_results[i].push_back(std::to_string(inserted_pk[i] < inserted_data[i]));
    expected_results[i].push_back(std::to_string(inserted_pk[i] != inserted_data[i]));
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
    insert_string += comma + "(" +"'"+ inserted_pk[i] + "'"+","+"'" + inserted_data[i] + "'"+")";
    comma = ",";
  }

  // Create table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS_NTEXT));
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(TABLE_NAME, insert_string));
  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, inserted_data.size());
  

  // Make sure inserted values are correct and operations
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < inserted_data.size(); ++i) {
    
    odbcHandler.CloseStmt();
    odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, operations_query, vector<string> {}, COL_NAMES[0] + "=" + "'"+inserted_pk[i]+"'"));
    ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_SUCCESS);

    for (int j = 0; j < operations_query.size(); j++) {

      ASSERT_EQ(col_len[j], expected_results[i][j].size());
      ASSERT_EQ(col_results[j], expected_results[i][j]);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
}