#include <gtest/gtest.h>
#include <sqlext.h>
#include "../src/drivers.h"
#include "../src/odbc_handler.h"
#include "../src/query_generator.h"
#include "psqlodbc_tests_common.h"

using std::pair;

const string TABLE_NAME = "master_dbo.ntext_table_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "ntext_data";
const string DATATYPE = "sys.ntext";
const string VIEW_NAME = "master_dbo.ntext_view_odbc_test";
const string STRING_4000 = "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";

const string STRING_1 = "a";
const string STRING_20 = "0123456789abcdefghij";

const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, " int PRIMARY KEY"},
    {COL2_NAME, DATATYPE}
};

class PSQL_Datatypes_Ntext: public testing::Test {
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

TEST_F(PSQL_Datatypes_Ntext, Table_Creation) {
  const vector<int> LENGTH_EXPECTED = {4, 8190};
  const vector<int> PRECISION_EXPECTED = {0, 0};
  const vector<int> SCALE_EXPECTED = {0, 0};
  const vector<string> NAME_EXPECTED = {"int4", "text"};
  const vector<string> PREFIX_EXPECTED = {"int4", "'"};
  const vector<string> SUFFIX_EXPECTED = {"int4", "'"};

  const vector<int> is_case_sensitive = {0, 1};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testCommonCharColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS.size(), COL1_NAME, LENGTH_EXPECTED, 
    PRECISION_EXPECTED, SCALE_EXPECTED, NAME_EXPECTED, is_case_sensitive, PREFIX_EXPECTED, SUFFIX_EXPECTED);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Ntext, Table_Create_Fail) {
  const vector<vector<pair<string, string>>> invalid_columns {
    {{"invalid1", DATATYPE + "(4)"}} // Cannot specify a column width on data type datatime.
  };

  // Assert that table creation will always fail with invalid column definitions
  testTableCreationFailure(ServerType::PSQL, TABLE_NAME, invalid_columns);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

// // inserted values differ that of expected?
TEST_F(PSQL_Datatypes_Ntext, Insertion_Success) {
  const vector<string> inserted_values = {
    "NULL", // NULL value
    STRING_1,
    STRING_4000,
    STRING_20,
    "" // blank value
  };

  const vector<string> expected = {
    "NULL", // NULL value
    STRING_1,
    STRING_4000,
    STRING_20,
    "" // blank value
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, inserted_values, expected);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

// TEST_F(PSQL_Datatypes_Ntext, Insertion_Failure) {
//   const vector<string> inserted_values = {
//     STRING_128 + "t"
//   };

//   createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
//   testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, inserted_values, false);
//   dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
// }

TEST_F(PSQL_Datatypes_Ntext, Updata_Success) {
  const vector<string> inserted_values = {
    "a"
  };

  const vector<string> updatad_values = {
    "NULL",
    STRING_1,
    STRING_20,
    STRING_4000,
    "" // blank value
  };

  const vector<string> expected_updatad_values = {
    "NULL",
    STRING_1,
    STRING_20,
    STRING_4000,
    "" // blank value
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, inserted_values, inserted_values);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, updatad_values, expected_updatad_values);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

// TEST_F(PSQL_Datatypes_Ntext, Updata_Fail) {
//   const vector<string> inserted_values = {
//     STRING_1
//   };

//   const vector<string> updatad_values = {
//     STRING_128 + "t"
//   };

//   createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
//   testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, inserted_values, inserted_values);
//   testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, inserted_values, updatad_values);
//   dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
// }

TEST_F(PSQL_Datatypes_Ntext, View_creation) {
  const vector<string> inserted_values = {
    "NULL", // NULL values
    STRING_1,
    STRING_20,
    STRING_4000,
    "" // blank value
  };

  const vector<string> expected = {
    "NULL", // NULL values
    STRING_1,
    STRING_20,
    STRING_4000,
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

TEST_F(PSQL_Datatypes_Ntext, Table_Single_Primary_Keys) {
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
    "" // blank value
  };

  const vector<string> expected = {
    STRING_1,
    STRING_20,
    "" // blank value
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, inserted_values, expected);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Ntext, Table_Composite_Primary_Keys) {
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
    "" // blank value
  };

  const vector<string> expected = {
    STRING_1,
    STRING_20,
    "" // blank value
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, inserted_values, expected);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Ntext, Table_Unique_Constraint) {

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
    "" // blank value
  };

  const vector<string> expected = {
    STRING_1,
    STRING_20,
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

TEST_F(PSQL_Datatypes_Ntext, String_Operators) {
  const int BUFFER_LENGTH = 8192;
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

const int COL_LENGTH[NUM_COLS] = {8190, 8190};

vector<pair<string, string>> TABLE_COLUMNS_NTEXT = {
  {COL_NAMES[0], DATATYPE + " PRIMARY KEY"},
  {COL_NAMES[1], DATATYPE}
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
    COL_NAMES[0] + "||" + COL_NAMES[1],
    "lower(" + COL_NAMES[1] + ")",
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
    string current = inserted_data[i];
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