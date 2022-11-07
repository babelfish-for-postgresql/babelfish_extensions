#include "../psqlodbc_tests_common.h"

const string TABLE_NAME = "master_dbo.datetime_table_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "datetime_1";
const string DATATYPE = "sys.datetime";
const string VIEW_NAME = "master_dbo.datetime_view_odbc_test";

const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, " int PRIMARY KEY"},
    {COL2_NAME, DATATYPE}
};

class PSQL_Datatypes_Datetime: public testing::Test {
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

TEST_F(PSQL_Datatypes_Datetime, Table_Creation) {
  const vector<int> LENGTH_EXPECTED = {4, 255};
  const vector<int> PRECISION_EXPECTED = {0, 0};
  const vector<int> SCALE_EXPECTED = {0, 0};
  const vector<string> NAME_EXPECTED = {"int4", "unknown"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testCommonColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS.size(), COL1_NAME, LENGTH_EXPECTED, 
    PRECISION_EXPECTED, SCALE_EXPECTED, NAME_EXPECTED);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

// Doesn't work in SQL Server, but does in BBF & BBF PG connection?
TEST_F(PSQL_Datatypes_Datetime, DISABLED_Table_Create_Fail) {
  const vector<vector<pair<string, string>>> INVALID_COLUMNS {
    {{"invalid1", DATATYPE + "(4)"}} // Cannot specify a column width on data type datetime.
  };

  // Assert that table creation will always fail with invalid column definitions
  testTableCreationFailure(ServerType::PSQL, TABLE_NAME, INVALID_COLUMNS);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

// inserted values differ that of EXPECTED?
TEST_F(PSQL_Datatypes_Datetime, Insertion_Success) {
  const vector<string> INSERTED_VALUES = {
    "NULL", // NULL value
    "1753-01-01 00:00:000", // smallest value
    "2011-04-15 16:44:09.000", // random regular values
    "9999-12-31 23:59:59.997", // max value
    "" // blank value
  };

  const vector<string> EXPECTED = {
    "NULL", // NULL values
    "1753-01-01 00:00:00", // smallest value
    "2011-04-15 16:44:09", // random regular value
    "9999-12-31 23:59:59.997", // max value
    "1900-01-01 00:00:00" // blank value
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Datetime, Insertion_Failure) {
  const vector<string> INSERTED_VALUES = {
    "1752-01-01 00:00:000", // past lowest boundary
    "9999-12-31 23:59:59.999" // past highest boundary
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Datetime, Update_Success) {
  const vector<string> INSERTED_VALUES = {
    "2011-04-15 16:44:09"
  };

  const vector<string> UPDATED_VALUES = {
    "1900-01-31 12:59:59.999", // standard value
    "9999-12-31 23:59:59.997", // max value
    "1753-01-01 00:00:00", // min value
    "" // blank value
  };

  const vector<string> EXPECTED_UPDATED_VALUES = {
    "1900-01-31 12:59:59.999", // standard value
    "9999-12-31 23:59:59.997", // max value
    "1753-01-01 00:00:00", // min value
    "1900-01-01 00:00:00" // blank value
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, UPDATED_VALUES, EXPECTED_UPDATED_VALUES);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Datetime, Update_Fail) {
  const vector<string> INSERTED_VALUES = {
    "2011-04-15 16:44:09"
  };

  const vector<string> UPDATED_VALUES = {
    "1752-01-01 00:00:000"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_VALUES, UPDATED_VALUES);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Datetime, View_creation) {
  const vector<string> INSERTED_VALUES = {
    "NULL", // NULL values
    "1753-01-01 00:00:000", // smallest value
    "2011-04-15 16:44:09.000", // random regular values
    "9999-12-31 23:59:59.997", // max value
    "" // blank value
  };

  const vector<string> EXPECTED = {
    "NULL", // NULL values
    "1753-01-01 00:00:00", // smallest value
    "2011-04-15 16:44:09", // random regular value
    "9999-12-31 23:59:59.997", // max value
    "1900-01-01 00:00:00" // blank value
  };

  const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED);

  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Datetime, Table_Single_Primary_Keys) {
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

  const vector<string> INSERTED_VALUES = {
    "1753-01-01 00:00:000", // smallest value
    "2011-04-15 16:44:09.000", // random regular values
    "9999-12-31 23:59:59.997", // max value
    "" // blank value
  };

  const vector<string> EXPECTED = {
    "1753-01-01 00:00:00", // smallest value
    "2011-04-15 16:44:09", // random regular value
    "9999-12-31 23:59:59.997", // max value
    "1900-01-01 00:00:00" // blank value
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, INSERTED_VALUES.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Datetime, Table_Composite_Primary_Keys) {
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

  const vector<string> INSERTED_VALUES = {
    "1753-01-01 00:00:000", // smallest value
    "2011-04-15 16:44:09.000", // random regular values
    "9999-12-31 23:59:59.997", // max value
    "" // blank value
  };

  const vector<string> EXPECTED = {
    "1753-01-01 00:00:00", // smallest value
    "2011-04-15 16:44:09", // random regular value
    "9999-12-31 23:59:59.997", // max value
    "1900-01-01 00:00:00" // blank value
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Datetime, Table_Unique_Constraint) {

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE}
  };

  const vector<string> UNIQUE_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS);

  // Insert valid values into the table and assert affected rows
  const vector<string> INSERTED_VALUES = {
    "1753-01-01 00:00:000", // smallest value
    "2011-04-15 16:44:09.000", // random regular values
    "9999-12-31 23:59:59.997", // max value
    "" // blank value
  };

  const vector<string> EXPECTED = {
    "1753-01-01 00:00:00", // smallest value
    "2011-04-15 16:44:09", // random regular value
    "9999-12-31 23:59:59.997", // max value
    "1900-01-01 00:00:00" // blank value
  };

  // table name without the schema
  const string TABLE_NAME_WITHOUT_SCHEMA = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, TABLE_NAME_WITHOUT_SCHEMA, UNIQUE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, INSERTED_VALUES.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Datetime, Comparison_Operators) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE}
  };

  const vector<string> INSERTED_PK = {
    "1753-01-01 00:00:000",
    "9999-12-31 23:59:59.997"
  };

  const vector<string> INSERTED_DATA = {
    "1754-01-01 00:00:000",
    "9999-12-31 23:59:59.997"
  };
  const int NUM_OF_DATA = INSERTED_DATA.size();

  // insertString initialization
  string insertString{};
  string comma{};
  for (int i = 0; i < NUM_OF_DATA; i++) {
    insertString += comma + "(\'" + INSERTED_PK[i] + "\',\'" + INSERTED_DATA[i] + "\')";
    comma = ",";
  }

  const vector<string> OPERATIONS_QUERY = {
    COL1_NAME + "=" + COL2_NAME,
    COL1_NAME + "<>" + COL2_NAME,
    COL1_NAME + "<" + COL2_NAME,
    COL1_NAME + "<=" + COL2_NAME,
    COL1_NAME + ">" + COL2_NAME,
    COL1_NAME + ">=" + COL2_NAME
  };

  // initialization of expected_results
  vector<vector<char>> expected_results = {};

  for (int i = 0; i < NUM_OF_DATA; i++) {
    expected_results.push_back({});
    const char *date_1 = INSERTED_PK[i].data();
    const char *date_2 = INSERTED_DATA[i].data();
    expected_results[i].push_back(strcmp(date_1, date_2) == 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(date_1, date_2) != 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(date_1, date_2) < 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(date_1, date_2) <= 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(date_1, date_2) > 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(date_1, date_2) >= 0 ? '1' : '0');
  }

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testComparisonOperators(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_PK, INSERTED_DATA, 
    OPERATIONS_QUERY, expected_results, false, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

// inserted values differ that of EXPECTED?
TEST_F(PSQL_Datatypes_Datetime, Comparison_Functions) {
  const vector<string> INSERTED_DATA = {
    "1753-01-01 00:00:000",
    "2011-04-15 16:44:09.000",
    "9999-12-31 23:59:59.997"
  };

  const vector<string> EXPECTED_RESULTS = {
    "1753-01-01 00:00:00",
    "2011-04-15 16:44:09",
    "9999-12-31 23:59:59.997"
  };
  const int NUM_OF_DATA = INSERTED_DATA.size();
  
  // insertString initialization
  string insertString{};
  string comma{};
  for (int i = 0; i < NUM_OF_DATA; i++) {
    insertString += comma + "(" + std::to_string(i) + ",\'" + INSERTED_DATA[i] + "\')";
    comma = ",";
  }

  const vector<string> OPERATIONS_QUERY = {
    "MIN(" + COL2_NAME + ")",
    "MAX(" + COL2_NAME + ")"
  };

  // initialization of expected_results
  vector<string> expected_results = {};
  int min_expected = 0, max_expected = 0;

  for (int i = 1; i < NUM_OF_DATA; i++) {
    const char *currMin = EXPECTED_RESULTS[min_expected].data();
    const char *currMax = EXPECTED_RESULTS[max_expected].data();
    const char *curr = EXPECTED_RESULTS[i].data();

    min_expected = strcmp(curr, currMin) < 0 ? i : min_expected;
    max_expected = strcmp(curr, currMax) > 0 ? i : max_expected;
  }
  expected_results.push_back(EXPECTED_RESULTS[min_expected]);
  expected_results.push_back(EXPECTED_RESULTS[max_expected]);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testComparisonFunctions(ServerType::PSQL, TABLE_NAME, OPERATIONS_QUERY, expected_results);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}
