#include "../psqlodbc_tests_common.h"

const string TABLE_NAME = "master_dbo.datetime2_table_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "sys.datetime2";
const string VIEW_NAME = "master_dbo.datetime2_view_odbc_test";
const vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, "INT PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME}
};
const int DATA_COLUMN = 2;

class PSQL_DataTypes_DateTime2 : public testing::Test {
  void SetUp() override {
    if (!Drivers::DriverExists(ServerType::PSQL)) {
      GTEST_SKIP() << "PSQL Driver not present: skipping all tests for this fixture.";
    }

    OdbcHandler test_setup(Drivers::GetDriver(ServerType::PSQL));
    test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
  }

  void TearDown() override {
    if (!Drivers::DriverExists(ServerType::PSQL)) {
      GTEST_SKIP() << "PSQL Driver not present: skipping all tests for this fixture.";
    }

    OdbcHandler test_teardown(Drivers::GetDriver(ServerType::PSQL));
    test_teardown.ConnectAndExecQuery(DropObjectStatement("VIEW", VIEW_NAME));
    test_teardown.CloseStmt();
    test_teardown.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
  }
};

TEST_F(PSQL_DataTypes_DateTime2, Table_Creation) {
  // TODO - Expected needs to be fixed.
  const vector<int> LENGTH_EXPECTED = {4, 255};
  const vector<int> PRECISION_EXPECTED = {0, 0};
  const vector<int> SCALE_EXPECTED = {0, 0};
  const vector<string> NAME_EXPECTED = {"int4", "unknown"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testCommonColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS.size(), COL1_NAME, LENGTH_EXPECTED, 
    PRECISION_EXPECTED, SCALE_EXPECTED, NAME_EXPECTED);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_DateTime2, Insertion_Success) {
  const vector<string> INSERTED_VALUES = {
    "NULL",
    "",                           // Default Value
    "0001-01-01",
    "9999-12-31",
    "0001-01-01 00:00:00",
    "9999-12-31 23:59:59.1",
    "9999-12-31 23:59:59.12",
    "9999-12-31 23:59:59.123",
    "9999-12-31 23:59:59.1234",
    "9999-12-31 23:59:59.12345",
    "9999-12-31 23:59:59.123456",
  };

  const vector<string> EXPECTED_VALUES = {
    "NULL",
    "1900-01-01 00:00:00",        // Default Value
    "0001-01-01 00:00:00",
    "9999-12-31 00:00:00",
    "0001-01-01 00:00:00",
    "9999-12-31 23:59:59.1",
    "9999-12-31 23:59:59.12",
    "9999-12-31 23:59:59.123",
    "9999-12-31 23:59:59.1234",
    "9999-12-31 23:59:59.12345",
    "9999-12-31 23:59:59.123456",
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_DateTime2, Insertion_Fail) {
  const vector<string> INVALID_INSERTED_VALUES = {
    // "01-01-2000",             // Format (Valid insert on Ubuntu 20. Invalid insert on Ubuntu 22)
    "December 31, 9999 CE",
    "10000-01-01 00:00:00",   // Year
    "0000-01-01",
    "0000-01-01 00:00:00",
    "0001-32-01 00:00:00",    // Month
    "0001-00-01 00:00:00",
    "0001-01-32 00:00:00",    // Day
    "0001-01-00 00:00:00",
    "0001-02-31 00:00:00",    // Feb 31st
    // "0001-01-01 24:00:00", 	  // Hours (Valid despite being out of range)
    "0001-01-01 00:60:00",    // Minutes
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INVALID_INSERTED_VALUES, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_DateTime2, Update_Success) {
  const vector<string> DATA_INSERTED = {
    "0001-01-01 00:00:00"
  };

  const vector<string> DATA_UPDATED_VALUES = {
    "",                     // Default Value
    "0001-01-01",
    "9999-12-31",
    "0001-01-01 00:00:00",
    "9999-12-31 23:59:59.999999"
  };

  const vector<string> EXPECTED_VALUES = {
    "1900-01-01 00:00:00",  // Default Value
    "0001-01-01 00:00:00",
    "9999-12-31 00:00:00",
    "0001-01-01 00:00:00",
    "9999-12-31 23:59:59.999999"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, DATA_INSERTED, DATA_INSERTED);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, DATA_UPDATED_VALUES, EXPECTED_VALUES);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_DateTime2, Update_Fail) {
  const vector<string> DATA_INSERTED = {
    "0001-01-01 00:00:00"
  };

  const vector<string> DATA_UPDATED_VALUE = {
    "0001-02-31 00:00:000000" // Feb 31st
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, DATA_INSERTED, DATA_INSERTED);
  testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, DATA_INSERTED, DATA_UPDATED_VALUE);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_DateTime2, Comparison_Operators) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> INSERTED_PK = {
    "0001-01-01 00:00:00",
    "1000-01-01 00:00:00"
  };

  const vector<string> INSERTED_DATA = {
    "9999-12-31 23:59:59.999999",
    "1000-01-01 00:00:00"
  };
  const int NUM_OF_DATA = INSERTED_DATA.size();

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

  string insertString{};
  string comma{};
  // insertString initialization
  for (int i = 0; i < NUM_OF_DATA; i++) {
    insertString += comma + "(\'" + INSERTED_PK[i] + "\',\'" + INSERTED_DATA[i] + "\')";
    comma = ",";
  }

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testComparisonOperators(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_PK, INSERTED_DATA, 
    OPERATIONS_QUERY, expected_results, false, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_DateTime2, Comparison_Functions) {
  const vector<string> INSERTED_DATA = {
    "0001-01-01 00:00:00",
    "9999-12-31 00:00:00",
    "9999-12-31 23:59:59.999999",
  };
  const int NUM_OF_DATA = INSERTED_DATA.size();

  const vector<string> OPERATIONS_QUERY = {
    "MIN(" + COL2_NAME + ")",
    "MAX(" + COL2_NAME + ")"
  };

  // initialization of expected_results
  vector<string> expected_results = {};
  int min_expected = 0, max_expected = 0;
  for (int i = 1; i < NUM_OF_DATA; i++) {
    const char *currMin = INSERTED_DATA[min_expected].data();
    const char *currMax = INSERTED_DATA[max_expected].data();
    const char *curr = INSERTED_DATA[i].data();

    min_expected = strcmp(curr, currMin) < 0 ? i : min_expected;
    max_expected = strcmp(curr, currMax) > 0 ? i : max_expected;
  }
  expected_results.push_back(INSERTED_DATA[min_expected]);
  expected_results.push_back(INSERTED_DATA[max_expected]);

  string insertString{};
  string comma{};
  // insertString initialization
  for (int i = 0; i < NUM_OF_DATA; i++) {
    insertString += comma + "(" + std::to_string(i) + ",\'" + INSERTED_DATA[i] + "\')";
    comma = ",";
  }

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testComparisonFunctions(ServerType::PSQL, TABLE_NAME, OPERATIONS_QUERY, expected_results);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_DateTime2, View_Creation) {
  const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;

  const vector<string> INSERTED_VALUES = {
    "0001-01-01",
    "9999-12-31",
    "0001-01-01 00:00:00",
    "9999-12-31 23:59:59.999999",
  };

  const vector<string> EXPECTED_VALUES = {
    "0001-01-01 00:00:00",
    "9999-12-31 00:00:00",
    "0001-01-01 00:00:00",
    "9999-12-31 23:59:59.999999",
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES);

  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_DateTime2, Table_Unique_Constraints) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> UNIQUE_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS);

  const vector<string> INSERTED_VALUES = {
    "0001-01-01 00:00:00",
    "9999-12-31 23:59:59.999999"
  };
 
  // table name without the schema
  const string TABLE_NAME_WITHOUT_SCHEMA = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, TABLE_NAME_WITHOUT_SCHEMA, UNIQUE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, INSERTED_VALUES.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_DateTime2, Table_Single_Primary_Keys) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
  const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

  const vector<string> PK_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

  const vector<string> INSERTED_VALUES = {
      "0001-01-01 00:00:00",
      "9999-12-31 23:59:59.999999"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, INSERTED_VALUES.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_DateTime2, Table_Composite_Primary_Keys) {
  vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_NAME}
  };
  const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
  const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

  const vector<string> PK_COLUMNS = {
    COL1_NAME,
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

  const vector<string> INSERTED_VALUES = {
      "0001-01-01 00:00:00",
      "9999-12-31 23:59:59.999999"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}
